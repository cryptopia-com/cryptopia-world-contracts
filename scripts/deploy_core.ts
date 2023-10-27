import hre, { ethers, upgrades } from "hardhat";
import appConfig from "../config";
import "./helpers/converters.ts";

/**
 * Deploy core contracts
 */
async function main() {

    console.log("Deploying contracts to " + hre.network.name);

    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    const config: any = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    // Roles
    const SYSTEM_ROLE = "SYSTEM_ROLE".toKeccak256();
    const MINTER_ROLE = "MINTER_ROLE".toKeccak256();

    // Factories
    const WhitelistFactory = await ethers.getContractFactory("Whitelist");
    const AccountFactory = await ethers.getContractFactory("CryptopiaAccount");
    const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
    const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister"); 
    const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
    const TokenFactory = await ethers.getContractFactory("CryptopiaToken");
    const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
    const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
    const ResourceGatheringFactory = await ethers.getContractFactory("CryptopiaResourceGathering");
    const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
    const ToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
    const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
    const MapFactory = await ethers.getContractFactory("CryptopiaMap");
    const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");

    // Deploy Inventories
    const inventoriesProxy = await (
    await upgrades.deployProxy(
        InventoriesFactory, 
        [
        config.CryptopiaTreasury.address
        ])
    ).waitForDeployment();

    const inventoriesAddress = await inventoriesProxy.getAddress();
    const inventoriesInstance = await ethers.getContractAt("CryptopiaInventories", inventoriesAddress);
    console.log("Inventories deployed to: " + inventoriesAddress);

    // Deploy Whitelist
    const whitelistProxy = await (
        await upgrades.deployProxy(
            WhitelistFactory, 
            [
                [
                    inventoriesAddress
                ]
            ])
    ).waitForDeployment();

    const whitelistAddress = await whitelistProxy.getAddress();
    const whitelistInstance = await ethers.getContractAt("Whitelist", whitelistAddress);
    console.log("Whitelist deployed to: " + whitelistAddress);

    // Deploy CryptopiaToken
    const tokenProxy = await (
        await upgrades.deployProxy(
            TokenFactory, 
            [
                [],
                whitelistAddress
            ])
        ).waitForDeployment();

    const tokenAddress = await tokenProxy.getAddress();
    const tokenInstance = await ethers.getContractAt("CryptopiaToken", tokenAddress);
    console.log("CryptopiaToken deployed to: " + tokenAddress);

    // Deploy Account Register
    const accountRegisterProxy = await (
        await upgrades.deployProxy(
            AccountRegisterFactory, 
            [
                []
            ], 
            { 
                initializer: false 
            })
        ).waitForDeployment();

    const accountRegisterAddress = await accountRegisterProxy.getAddress();
    const accountRegisterInstance = await ethers.getContractAt("CryptopiaAccountRegister", accountRegisterAddress);
    console.log("AccountRegister deployed to: " + accountRegisterAddress);

    // Deploy Asset Register
    const assetRegisterProxy = await (
        await upgrades.deployProxy(
            AssetRegisterFactory, [])
        ).waitForDeployment();

    const assetRegisterAddress = await assetRegisterProxy.getAddress();
    const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);
    console.log("AssetRegister deployed to: " + assetRegisterAddress);

    // Deploy Crafting
    const craftingProxy = await (
        await upgrades.deployProxy(
            CraftingFactory, 
            [
                inventoriesAddress
            ])
        ).waitForDeployment();

    const craftingAddress = await craftingProxy.getAddress();
    const craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);
    console.log("Crafting deployed to: " + craftingAddress);

    // Deploy Ships
    const shipTokenProxy = await (
        await upgrades.deployProxy(
            ShipTokenFactory, 
            [
                whitelistAddress, 
                config.ERC721.CryptopiaShipToken.contractURI, 
                config.ERC721.CryptopiaShipToken.baseTokenURI
            ])
        ).waitForDeployment();

    const shipTokenAddress = await shipTokenProxy.getAddress();
    const shipTokenInstance = await ethers.getContractAt("CryptopiaShipToken", shipTokenAddress);
    console.log("ShipToken deployed to: " + shipTokenAddress);

    // Deploy Player Register
    const playerRegisterProxy = await (
        await upgrades.deployProxy(
            PlayerRegisterFactory, 
            [
                accountRegisterAddress, 
                inventoriesAddress, 
                craftingAddress,
                shipTokenAddress, 
                []
            ])
        ).waitForDeployment();

    const playerRegisterAddress = await playerRegisterProxy.getAddress();
    const playerRegisterInstance = await ethers.getContractAt("CryptopiaPlayerRegister", playerRegisterAddress);
    console.log("PlayerRegister deployed to: " + playerRegisterAddress);

    // Grant player register roles
    await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
    await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);

    // Deploy Tools
    const toolTokenProxy = await (
        await upgrades.deployProxy(
            ToolTokenFactory, 
            [
                whitelistAddress, 
                config.ERC721.CryptopiaToolToken.contractURI, 
                config.ERC721.CryptopiaToolToken.baseTokenURI,
                playerRegisterAddress,
                inventoriesAddress
            ])
        ).waitForDeployment();

    const toolTokenAddress = await toolTokenProxy.getAddress();
    const toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);
    console.log("ToolToken deployed to: " + toolTokenAddress);

    // Add tools to inventory
    await inventoriesInstance.setNonFungibleAsset(toolTokenAddress, true);

    // Grant tool roles
    await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);
    await toolTokenInstance.grantRole(SYSTEM_ROLE, craftingAddress);

    // Deploy Titledeed Token
    const titleDeedTokenProxy = await (
        await upgrades.deployProxy(
            TitleDeedTokenFactory, 
            [
                whitelistAddress, 
                config.ERC721.CryptopiaTitleDeedToken.contractURI, 
                config.ERC721.CryptopiaTitleDeedToken.baseTokenURI
            ])
        ).waitForDeployment();

    const titleDeedTokenAddress = await titleDeedTokenProxy.getAddress();
    const titleDeedTokenInstance = await ethers.getContractAt("CryptopiaTitleDeedToken", titleDeedTokenAddress);
    console.log("TitleDeedToken deployed to: " + titleDeedTokenAddress);

    // Deploy Map
    const mapProxy = await (
        await upgrades.deployProxy(
            MapFactory, 
            [
                playerRegisterAddress, 
                assetRegisterAddress, 
                titleDeedTokenAddress, 
                tokenAddress
            ])
        ).waitForDeployment();

    const mapAddress = await mapProxy.getAddress();
    const mapInstance = await ethers.getContractAt("CryptopiaMap", mapAddress);
    console.log("Map deployed to: " + mapAddress);

    // Grant Map roles
    await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapAddress);

    // Deploy Resource Gathering
    const resourceGatheringProxy = await (
        await upgrades.deployProxy(
            ResourceGatheringFactory,
            [
                mapAddress,
                assetRegisterAddress,
                playerRegisterAddress,
                inventoriesAddress,
                toolTokenAddress
            ])
        ).waitForDeployment();

    const resourceGatheringAddress = await resourceGatheringProxy.getAddress();
    const resourceGatheringInstance = await ethers.getContractAt("CryptopiaResourceGathering", resourceGatheringAddress);
    console.log("ResourceGathering deployed to: " + resourceGatheringAddress);

    // Grant resource roles
    await toolTokenInstance.grantRole(SYSTEM_ROLE, resourceGatheringAddress);
    await inventoriesInstance.grantRole(SYSTEM_ROLE, resourceGatheringAddress);
    await playerRegisterInstance.grantRole(SYSTEM_ROLE, resourceGatheringAddress); 

    // Deploy assets
    for (let asset of config.ERC20.CryptopiaAssetToken.assets)
    {
        const assetTokenProxy = await (
            await upgrades.deployProxy(
                AssetTokenFactory, 
                [
                    asset.name, 
                    asset.symbol, 
                    [],
                    whitelistAddress
                ])
            ).waitForDeployment();

        const assetTokenAddress = await assetTokenProxy.getAddress();
        const assetTokenInstance = await ethers.getContractAt("CryptopiaAssetToken", assetTokenAddress);
        console.log(`AssetToken:${asset.name} deployed to: ${assetTokenAddress}`);

        await assetRegisterInstance.registerAsset(assetTokenAddress, true, asset.resource);
        await inventoriesInstance.setFungibleAsset(assetTokenAddress, asset.weight);

        if (asset.Gatherings != undefined && asset.Gatherings.includes("CryptopiaResourceGathering"))
        {
            await assetTokenInstance.grantRole(MINTER_ROLE, resourceGatheringAddress);
        }
    }

    // Output bytecode
    if (config.CryptopiaAccount.outputBytecode)
    {
        const bytecodeHash = "" + ethers.keccak256(AccountFactory.bytecode);
        console.log("------ UPDATE BELOW BYTECODE OF CryptopiaAccount IN THE GAME CLIENT -----");
        console.log("bytecodeHash1: " + bytecodeHash);
        console.log((AccountFactory as any).bytecode);
    }
}

// Deploy
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
