var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var exchange = artifacts.require("./Exchange.sol");

contract('Simple order test', function (accounts) {

    before(function () {
        var instanceExchange;
        var instanceToken;
        return exchange.deployed().then(function (instance) {
            instanceExchange = instance;
            return instanceExchange.depositEther({from: accounts[0], value: web3.toWei(3, "ether")});
        }).then(function (txtResult) {
            return fixedSupplyToken.deployed();
        }).then(function (myTokenInstance) {
            instanceToken = myTokenInstance;
            return instanceExchange.addToken("FIXED", instanceToken.address);
        }).then(function (txtResult) {
            return instanceToken.approve(instanceExchange.address, 2000);
        }).then(function (txtResult) {
            return instanceExchange.depositToken("FIXED", 2000);
        });
    });

    it("should be possible to add a limit buy order", function() {
       var myExchangeInstance;

       return exchange.deployed().then( function (exchangeInstance) {
           myExchangeInstance = exchangeInstance;
           return myExchangeInstance.getBuyOrderBook.call("FIXED");
       }).then(function (orderBook) {
           assert.equal(orderBook.length, 2, "OrderBook should have 2 elements");
           assert.equal(orderBook[0].length, 0, "OrderBook should have 0 buy offers");
           return myExchangeInstance.buyToken("FIXED", web3.toWei(1, "finney"), 5);
       }).then(function (txtResult) {
           assert.equal(txtResult.logs.length, 1, "There should have been one Log Message emmited");
           assert.equal(txtResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitedBuyCreated");
           return myExchangeInstance.getBuyOrderBook.call("FIXED");
       }).then(function(orderBook) {
           assert.equal(orderBook[0].length, 1);
           assert.equal(orderBook[1].length, 1);
       })
    });


    it("should be possible to add three limit buy orders", function() {
        var myExchangeInstance;
        var orderBookLenghtBeforeBuy;

        return exchange.deployed().then( function (exchangeInstance) {
            myExchangeInstance = exchangeInstance;
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function (orderBook) {
            orderBookLenghtBeforeBuy = orderBook[0].length;
            return myExchangeInstance.buyToken("FIXED", web3.toWei(2, "finney"), 5); // WE ADD ONE OFFER ON TOP OF ANOTHER, DOESN'T INCREASE ORDERBOOK
        }).then(function (txtResult) {
            assert.equal(txtResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitedBuyCreated");
            return myExchangeInstance.buyToken("FIXED", web3.toWei(1.4, "finney"), 5); // We add a new offer in the middle
        }).then(function (txtResult) {
            assert.equal(txtResult.logs[0].event, "LimitBuyOrderCreated", "The Log-Event should be LimitBuyOrderCreated");
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function(orderBook) {
            assert.equal(orderBook[0].length, orderBookLenghtBeforeBuy + 2, "OrderBook should have 2 more buy offer");
            assert.equal(orderBook[1].length, orderBookLenghtBeforeBuy + 2, "OrderBook should have 2 more buy volume elements");
        })
    });


});