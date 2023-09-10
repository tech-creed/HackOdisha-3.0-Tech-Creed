const SecureDocsToken = artifacts.require("SecureDocsToken");

module.exports = function(deployer) {
  deployer.deploy(SecureDocsToken)
}