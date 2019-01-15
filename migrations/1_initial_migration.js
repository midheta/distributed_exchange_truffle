var Migrations = artifacts.require("./Migrations.sol");
var FixedSupplyToken = artifacts.require("./FixedSupplyToken.sol");
var Exchange = artifacts.require("./Exchange.sol");
module.exports = function(deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(FixedSupplyToken);
  deployer.deploy(Exchange);

};
