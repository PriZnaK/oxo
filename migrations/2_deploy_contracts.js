const OXO = artifacts.require('./OXO.sol');

module.exports = deployer => {
  deployer.deploy(OXO);
};
