var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var exchange = artifacts.require("./Exchange.sol");

contract('Exchange basic tests', function (accounts) {

    it("Case1 - Success : Deposit and withdraw Contract Token", function () {
        var myTokenInstance;
        var exchangeInstance;
        var tokenBalanceInTokenAfterDeposit;
        var tokenBalanceInExchangeAfterDeposit;
        var tokenBalanceInTokenAfterWithdraw;
        var tokenBalanceInExchangeAfterWithdraw;
        return fixedSupplyToken.deployed().then(function (instance) {
            myTokenInstance = instance;
            return exchange.deployed();
        })
            .then(function (instance) {
                exchangeInstance = instance;
                return exchangeInstance.addToken("FIXED", fixedSupplyToken.address);
            }).then(function (txResult) {
                assert.equal(txResult.logs[0].event, "TokenAddedToSystem", "TokenAddedToSystem Event shown");
                return exchangeInstance.hasToken.call("FIXED");
            })
            // Approve from Token Contract that Exchange can take 1000 tokens
            .then(function () {
                return myTokenInstance.approve(exchangeInstance.address, 1000);
            }) // Deposit 1000 tokens from the exchange
            .then(function (approved) {
                // console.log(approved);
                return exchangeInstance.depositToken("FIXED", 1000)
            }) // Assert that current account has 999 000 tokes left
            .then(function () {
                return myTokenInstance.balanceOf.call(accounts[0]);
            }).then(function (balance) {
                tokenBalanceInTokenAfterDeposit = balance.toNumber();
                assert.equal(tokenBalanceInTokenAfterDeposit, 999000);
                return exchangeInstance.getBalance.call("FIXED");
            }) // Assert that exchange has 1000 tokens
            .then(function (balance) {
                // Koristenje console log-a:
                //  console.log(balance);
                tokenBalanceInExchangeAfterDeposit = balance.toNumber();
                assert.equal(tokenBalanceInExchangeAfterDeposit, 1000);
                return exchangeInstance.withdrawToken("FIXED", 1000);
            }) // Withdraw the token on Exchange and check the balance
            .then(function () {
                return myTokenInstance.balanceOf.call(accounts[0]);
            }).then(function (balance) {
                tokenBalanceInTokenAfterWithdraw = balance.toNumber();
                assert.equal(tokenBalanceInTokenAfterWithdraw, 1000000);
                return exchangeInstance.getBalance.call("FIXED");
            }).then(function (balance) {
                tokenBalanceInExchangeAfterWithdraw = balance.toNumber();
                assert.equal(tokenBalanceInExchangeAfterWithdraw, 0);
            })
    });


//     it("Add token to Exchange", function() {
//         var myTokenInstance;
//         var exchangeInstance;
//
//         return fixedSupplyToken.deployed().then(function(instance) {
//             myTokenInstance = instance;
//             return exchange.deployed();})
//             .then(function(instance) {
//                 exchangeInstance = instance;
//                 return exchangeInstance.addToken("FIXED", fixedSupplyToken.address);
//             }) // Approve from Token Contract that Exchange can take 1000 tokens
//             .then(function(txResult){
//                 assert.equal(txResult.logs[0].event, "TokenAddedToSystem", "TokenAddedToSystem Event shown");
//                 return exchangeInstance.hasToken.call("FIXED");
//             }).then(function (hasToken) {
//                 assert.equal(hasToken, true, "Token was added");
//                 return exchangeInstance.hasToken.call("SOMETHING");
//             }).then(function (hasToken) {
//                 assert.equal(hasToken, false);
//             })
//     });
// });


// it("should be possible to Deposit and Withdrawal Ether", function () {
//     var myExchangeInstance;
//     var balanceBeforeTransaction = web3.eth.getBalance(accounts[0]);
//     var balanceAfterDeposit;
//     var balanceAfterWithdrawal;
//     var gasUsed = 0;
//
//     return exchange.deployed().then(function (instance) {
//         myExchangeInstance = instance;
//         return myExchangeInstance.depositEther({from: accounts[0], value: web3.toWei(1, "ether")});
//     }).then(function (txHash) {
//         gasUsed += txHash.receipt.cumulativeGasUsed * web3.eth.getTransaction(txHash.receipt.transactionHash).gasPrice.toNumber(); //here we have a problem
//         balanceAfterDeposit = web3.eth.getBalance(accounts[0]);
//         return myExchangeInstance.getEthBalanceInWei.call();
//     }).then(function (balanceInWei) {
//         assert.equal(balanceInWei.toNumber(), web3.toWei(1, "ether"), "There is one ether available");
//         assert.isAtLeast(balanceBeforeTransaction.toNumber() - balanceAfterDeposit.toNumber(), web3.toWei(1, "ether"),  "Balances of account are the same");
//         return myExchangeInstance.withdrawEther(web3.toWei(1, "ether"));
//     }).then(function (txHash) {
//         balanceAfterWithdrawal = web3.eth.getBalance(accounts[0]);
//         return myExchangeInstance.getEthBalanceInWei.call();
//     }).then(function (balanceInWei) {
//         assert.equal(balanceInWei.toNumber(), 0, "There is no ether available anymore");
//         assert.isAtLeast(balanceAfterWithdrawal.toNumber(), balanceBeforeTransaction.toNumber() - gasUsed*2, "There is one ether available");
//
//     });
// });


});