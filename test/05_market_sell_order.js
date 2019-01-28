var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var exchange = artifacts.require("./Exchange.sol");

contract('Exchange Order Tests', function (accounts) {
    before(function() {
        var instanceExchange;
        var instanceToken;
        return exchange.deployed().then(function (instance) {
            instanceExchange = instance;
            return instanceExchange.depositEther({from: accounts[0], value: web3.utils.toWei('3', 'ether')});
        }).then(function(txResult) {

            return fixedSupplyToken.deployed();
        }).then(function(myTokenInstance) {
            instanceToken = myTokenInstance;
            return instanceExchange.addToken("FIXED", instanceToken.address);
        }).then(function(txResult) {
            return instanceToken.transfer(accounts[1], 2000);
        }).then(function(txResult) {
            return instanceToken.approve(instanceExchange.address, 2000, {from: accounts[1]});
        }).then(function(txResult) {
            return instanceExchange.depositToken("FIXED", 2000, {from: accounts[1]});
        });
    });

    it("should be possible to add fully fulfill buy orders", function () {
        var myExchangeInstance;
        return exchange.deployed().then(function (instance) {
            myExchangeInstance = instance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function (orderBook) {
            assert.equal(orderBook.length, 0, "BuyOrderBook should have 2 elements");
            return myExchangeInstance.buyToken("FIXED", web3.utils.toWei('3', 'finney'), 5);
        }).then(function(txResult) {
            /**
             * Assert the logs
             */
            assert.equal(txResult.logs.length, 1, "There should have been one Log Message emitted.");
            assert.equal(txResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitBuyOrderCreated");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function(orderBook) {
            assert.equal(orderBook.length, 1, "OrderBook should have 1 buy offers");
            assert.equal(orderBook[0].amount, 5, "OrderBook should have a volume of 5 coins someone wants to buy");
            return myExchangeInstance.sellToken("FIXED", web3.utils.toWei('2', 'finney'), 5, {from: accounts[1]});
        }).then(function(txResult) {

            /**
             * Assert the logs
             */
            assert.equal(txResult.logs.length, 1, "There should have been one Log Message emitted.");
            assert.equal(txResult.logs[0].event, "SellOrderFulfilled", "The Log-Event should be SellOrderFulfilled");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function(orderBook) {

            assert.equal(orderBook.length, 0, "OrderBook should have 0 buy offers");
            return myExchangeInstance.getSellOrderBook.call("FIXED");
        });
    });


});