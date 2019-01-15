var fixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");

contract('MyToken', function(accounts) {
    it("first account should own all tokens", function() {
        var _totalSupply;
        var myTokenInstance;
        return fixedSupplyToken.deployed().then(function(instance) {
            myTokenInstance = instance;
            return myTokenInstance.totalSupply.call();
        }).then(function(totalSupply) {
            _totalSupply = totalSupply;
            return myTokenInstance.balanceOf(accounts[0]);
        }).then(function(balanceAccountOwner) {
            assert.equal(balanceAccountOwner.toNumber(), _totalSupply.toNumber(), "Total Amount of tokens is owned by owner");
        });
    });

    it("second account has no tokens and only the first one has all the tokens", function() {
        var _totalSupply;
        var myTokenInstance;
        return fixedSupplyToken.deployed().then(function(instance) {
            myTokenInstance = instance;
            return myTokenInstance.totalSupply.call();
        }).then(function(totalSupply) {
            _totalSupply = totalSupply;
            return myTokenInstance.balanceOf(accounts[1]);
        }).then(function (balanceAccountOwner) {
            assert.equal(balanceAccountOwner.toNumber(), 0, "Total Amount of tokens for second account is 0");

        });
    });

    // Transfer tokens between two tokens: transfer(address to, uint tokens)
    it("Test if tokens are sent correctly between accounts", function() {
       var _balanceAcc1;
       var _balanceAcc2;
       var _balanceAcc1BeforeTransfer;
       var _balanceAcc2BeforeTransfer;
       var account1Address = accounts[0];
       var account2Address = accounts[1];
       var myTokenInstance;
       return fixedSupplyToken.deployed().then(function (instance) {
           myTokenInstance = instance;
           return myTokenInstance.balanceOf(accounts[0]);
       //    return myTokenInstance.transfer(account2Address, 10);
       }).then(function(acc1BalanceBeforeTransfer) {
           _balanceAcc1BeforeTransfer = acc1BalanceBeforeTransfer;
            return myTokenInstance.balanceOf(accounts[1]);
        }).then(function(acc2BalanceBeforeTransfer) {
           _balanceAcc2BeforeTransfer = acc2BalanceBeforeTransfer;
           return myTokenInstance.transfer(account2Address, 10, {from: account1Address});
       }).then(function() {
           return myTokenInstance.balanceOf(accounts[0]);
       }).then(function(balanceAccount1Owner){
           _balanceAcc1 = balanceAccount1Owner;
           return myTokenInstance.balanceOf(accounts[1]);
       }).then(function (balanceAccount2Owner) {
           _balanceAcc2 = balanceAccount2Owner;
           assert.equal(_balanceAcc1.toNumber(), _balanceAcc1BeforeTransfer - 10);
           assert.equal(_balanceAcc2.toNumber(), _balanceAcc2BeforeTransfer + 10);
       })
    });


});