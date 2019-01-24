var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var exchange = artifacts.require("./Exchange.sol");

contract('Simple order test', function (accounts) {


    before(function () {
        var instanceExchange;
        var instanceToken;
        return exchange.deployed().then(function (instance) {
            instanceExchange = instance;
            return instanceExchange.depositEther({from: accounts[0], value: web3.utils.toWei('3', 'ether')});
        }).then(function (txResult) {

            return fixedSupplyToken.deployed();
        }).then(function (myTokenInstance) {
            instanceToken = myTokenInstance;
            return instanceExchange.addToken("FIXED", instanceToken.address);
        }).then(function (txResult) {
            return instanceToken.approve(instanceExchange.address, 2000);
        }).then(function (txResult) {
            return instanceExchange.depositToken("FIXED", 2000);
        });
    });

    it("Should be possible to cancel buy order", function () {
        var myExchangeInstance;

        return exchange.deployed().then(function (instance) {
            myExchangeInstance = instance;
            return myExchangeInstance.buyToken("FIXED", web3.utils.toWei('7', 'finney'), 5);
        }).then(function () {
            return myExchangeInstance.buyToken("FIXED", web3.utils.toWei('7', 'finney'), 10);
        }).then(function () {
            return myExchangeInstance.buyToken("FIXED", web3.utils.toWei('7', 'finney'), 15);
        }).then(function (txtResult) {
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function (orderBook) {
            console.log("Order book size after second buy offer: " + orderBook.length);
            assert.equal(orderBook.length, 1, "OrderBook should have 4 buy offers");
            return myExchangeInstance.cancelOrder("FIXED", false, web3.utils.toWei('7', 'finney'), 2); //  cancel second offer
        }).then(function () {
            return myExchangeInstance.getBuyOrderBook.call("FIXED");
        }).then(function (orderBook) {
            assert.equal(orderBook[0].amount, 20, "Offer for this price should have amount equals to 20 (first offer(5) + third offer(15)");
        })
    });




});