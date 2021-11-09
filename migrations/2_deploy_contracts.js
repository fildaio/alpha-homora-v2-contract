const CoreOracle = artifacts.require("CoreOracle");
const ProxyOracle = artifacts.require("ProxyOracle");
const ChainlinkAdapterOracle = artifacts.require("ChainlinkAdapterOracle");
const UniswapV2Oracle = artifacts.require("UniswapV2Oracle");
const HomoraBank = artifacts.require("HomoraBank");
const TransparentUpgradeableProxyImpl = artifacts.require("TransparentUpgradeableProxyImpl");
const ProxyAdmin = "0xA644751161DB352Ffe9F6Bdb89A15F75dcB9ee6F";

module.exports = async function (deployer, network, accounts) {
    await deployer.deploy(ChainlinkAdapterOracle);
    console.log("ChainlinkAdapterOracle deployed: ", ChainlinkAdapterOracle.address);

    await deployer.deploy(UniswapV2Oracle, ChainlinkAdapterOracle.address // _baseOracle
      );
    console.log("UniswapV2Oracle deployed: ", UniswapV2Oracle.address);
  
    await deployer.deploy(CoreOracle);
    console.log("CoreOracle deployed: ", CoreOracle.address);

    await deployer.deploy(ProxyOracle, CoreOracle.address);
    console.log("ProxyOracle deployed: ", ProxyOracle.address);

    await deployer.deploy(HomoraBank);
    console.log("HomoraBank deployed: ", HomoraBank.address);
    await deployer.deploy(TransparentUpgradeableProxyImpl,
      HomoraBank.address, // _logic
      ProxyAdmin, // _admin
      []);
    console.log("HomoraBank Proxy: ", TransparentUpgradeableProxyImpl.address);
};
