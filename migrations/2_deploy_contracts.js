const CoreOracle = artifacts.require("CoreOracle");
const ProxyOracle = artifacts.require("ProxyOracle");
const ChainlinkAdapterOracle = artifacts.require("ChainlinkAdapterOracle");
const UniswapV2Oracle = artifacts.require("UniswapV2Oracle");
const WERC20 = artifacts.require("WERC20");
const HomoraBank = artifacts.require("HomoraBank");
const UniswapV2SpellV1 = artifacts.require("UniswapV2SpellV1");
const TransparentUpgradeableProxyImpl = artifacts.require("TransparentUpgradeableProxyImpl");
const ProxyAdmin = "0x076979a0B3C87334E5d72E3afCaFaa80F7888Cac";

module.exports = async function (deployer, network, accounts) {
  if (network == 'matic') {
    const assets = [
      '0xD6DF932A45C0f255f85145f286eA0b292B21C90B', // AAVE
      '0xc2132d05d31c914a87c6611c10748aeb04b58e8f', // USDT
      '0x8f3cf7ad23cd3cadbd9735aff958023239c6a063', // DAI
      '0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6', // WBTC
      '0x7ceb23fd6bc0add59e62ac25578270cff1b9f619', // WETH
      '0x2791bca1f2de4661ed88a30c99a7a9449aa84174', // USDC
    ]

    const assetBorrowFactors = [
      16300, 10500, 10500, 12600, 12600, 10500
    ]
  
    const priceSources = [
      '0x72484B12719E23115761D5DA1646945632979bB6',
      '0x0A6513e40db6EB1b165753AD52E80663aeA50545',
      '0x4746DeC9e833A82EC7C2C1356372CcF2cfcD2F3D',
      '0xDE31F8bFBD8c84b5360CFACCa3539B938dd78ae6',
      '0xF9680D99D6C9589e2a93a78A04A279e509205945',
      '0xfE4A8cc5b5B2366C1B58Bea3858e81843581b2F7'
    ]

    const maxPriceDelayTimes = [
      7200,7200,7200,7200,7200,7200
    ]
    const lpTokens = [
      '0x853ee4b2a13f8a742d64c8f088be7ba2131f670d', // ETH-USDC
      '0xadbf1854e5883eb8aa7baf50705338739e558e5b', // ETH-MATIC
      '0xf6422b997c7f54d1c6a6e103bcb1499eea0a7046', // ETH-USDT
      '0x4a35582a710e1f4b2030a3f826da20bfb6703c09'  // DAI-ETH
    ]
    await deployer.deploy(ChainlinkAdapterOracle);
    console.log("ChainlinkAdapterOracle deployed: ", ChainlinkAdapterOracle.address);

    const chainlinkAdapterOracleInstance = await ChainlinkAdapterOracle.deployed();
    await chainlinkAdapterOracleInstance.setRefETHUSD("0xAB594600376Ec9fD91F8e885dADF0CE036862dE0");
    await chainlinkAdapterOracleInstance.setRefsUSD(assets, priceSources);
    await chainlinkAdapterOracleInstance.setMaxDelayTimes(assets, maxPriceDelayTimes);
    console.log("ChainlinkAdapterOracle configured");
  
    await deployer.deploy(CoreOracle);
    console.log("CoreOracle deployed: ", CoreOracle.address);

    await deployer.deploy(UniswapV2Oracle, CoreOracle.address // _baseOracle
    );
    console.log("UniswapV2Oracle deployed: ", UniswapV2Oracle.address);

    const coreOracleInstance = await CoreOracle.deployed(); 
    await coreOracleInstance.setRoute(assets, [ChainlinkAdapterOracle.address, ChainlinkAdapterOracle.address, ChainlinkAdapterOracle.address, ChainlinkAdapterOracle.address, ChainlinkAdapterOracle.address, ChainlinkAdapterOracle.address]);
    await coreOracleInstance.setRoute(lpTokens, [UniswapV2Oracle.address, UniswapV2Oracle.address, UniswapV2Oracle.address, UniswapV2Oracle.address]);
    console.log("CoreOracle configured");

    await deployer.deploy(ProxyOracle, CoreOracle.address);
    console.log("ProxyOracle deployed: ", ProxyOracle.address);

    const proxyOracleInstance = await ProxyOracle.deployed();
    await proxyOracleInstance.setTokenFactors(assets, assetBorrowFactors, [0,0,0,0,0,0], [11000,11000,11000,11000,11000,11000]);
    await proxyOracleInstance.setTokenFactors(lpTokens, [16300,16300,16300,16300], [7900,6100,6900,6900],[11000,11000,11000,11000]);
    console.log("Done to set token factors");

    await deployer.deploy(WERC20);
    await proxyOracleInstance.setWhitelistERC1155([WERC20.address], true);
    console.log("Done to set erc 1155")

    await deployer.deploy(HomoraBank);
    console.log("HomoraBank deployed: ", HomoraBank.address);
    await deployer.deploy(TransparentUpgradeableProxyImpl,
      HomoraBank.address, // _logic
      ProxyAdmin, // _admin
      []);
    console.log("HomoraBank Proxy: ", TransparentUpgradeableProxyImpl.address);
    const homoraBankInstance = await HomoraBank.at(TransparentUpgradeableProxyImpl.address);
    await homoraBankInstance.initialize(ProxyOracle.address, 2000);
    // USDT
    await homoraBankInstance.addBank("0xc2132d05d31c914a87c6611c10748aeb04b58e8f", "0xAb55dB8E2F7505C2191E7dDB5de5e266994A95b6");
    // AAVE
    await homoraBankInstance.addBank("0xD6DF932A45C0f255f85145f286eA0b292B21C90B", "0xd8DA16c621C75070786b205a28F3C0eCc29CD0cf");
    // DAI
    await homoraBankInstance.addBank("0x8f3cf7ad23cd3cadbd9735aff958023239c6a063", "0x770318C1cFbe92B23ac09ef40B056d11Eb2d6b22");
    // WBTC
    await homoraBankInstance.addBank("0x1bfd67037b42cf73acf2047067bd4f2c47d9bfd6", "0x9d63046BF361c2351bcc6e939039AB97fCdeB885");
    // WETH
    await homoraBankInstance.addBank("0x7ceb23fd6bc0add59e62ac25578270cff1b9f619", "0x4A256E7ba0Fb46e4C7fC111e7aE8Bee8e7a9D811");
    // USDC
    await homoraBankInstance.addBank("0x2791bca1f2de4661ed88a30c99a7a9449aa84174", "0xEDE060556E7F3d4C5576494490c70217e9e57826");
    console.log("Done to add bank");

    await deployer.deploy(UniswapV2SpellV1,
      TransparentUpgradeableProxyImpl.address, // _bank
      WERC20.address, // _werc20
      "0xa5E0829CaCEd8fFDD4De3c43696c57F7D7A678ff" // _router
    );
    console.log("UniswapV2SpellV1 deployed: ", UniswapV2SpellV1.address);

    await homoraBankInstance.setWhitelistSpells([UniswapV2SpellV1.address], [true]);
    console.log("Done to setWhitelistSpells");
    await homoraBankInstance.setWhitelistSpells(assets, [true,true,true,true,true,true]);

  }
};
