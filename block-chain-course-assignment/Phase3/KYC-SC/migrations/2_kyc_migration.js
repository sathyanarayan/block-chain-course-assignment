var KYC = artifacts.require("KYC");

module.exports = function(deployer) {
  // deployment steps
  deployer.deploy(KYC);
};
