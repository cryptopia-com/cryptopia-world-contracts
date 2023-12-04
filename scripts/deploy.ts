import hre, { ethers, upgrades } from "hardhat";
import appConfig from "../config";
import { Resource } from './types/enums';
import { DeploymentManager } from "./helpers/deployments";
import "./helpers/converters.ts";

/**
 * Deploy contracts
 */
async function main() {

    console.log("Deploying contracts to " + hre.network.name);

    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    const config: any = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    const deploymentManager = new DeploymentManager(hre.network.name);

    // Roles
    const SYSTEM_ROLE = "SYSTEM_ROLE".toKeccak256();

    // Factories
    const WhitelistFactory = await ethers.getContractFactory("Whitelist");
    const AccountFactory = await ethers.getContractFactory("CryptopiaAccount");
    const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
    const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
    const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
    const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
    const CryptopiaTokenFactory = await ethers.getContractFactory("CryptopiaToken");
    const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
    const ToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
    const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
    const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
    const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
    const ResourceGatheringFactory = await ethers.getContractFactory("CryptopiaResourceGathering");
    const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
    const QuestTokenFactory = await ethers.getContractFactory("CryptopiaQuestToken");
    const QuestsFactory = await ethers.getContractFactory("CryptopiaQuests");
    const NavalBattleMechanicsFactory = await ethers.getContractFactory("CryptopiaNavalBattleMechanics");
    const PirateMechanicsFactory = await ethers.getContractFactory("CryptopiaPirateMechanics");
    

    //////////////////////////////////
    /////// Deploy Inventories ///////
    //////////////////////////////////
    const inventoriesProxy = await (
    await upgrades.deployProxy(
        InventoriesFactory, 
        [
        config.CryptopiaTreasury.address
        ])
    ).waitForDeployment();

    const inventoriesAddress = await inventoriesProxy.getAddress();
    const inventoriesInstance = await ethers.getContractAt("CryptopiaInventories", inventoriesAddress);
    deploymentManager.saveDeployment("CryptopiaInventories", inventoriesAddress);


    //////////////////////////////////
    //////// Deploy Whitelist ////////
    //////////////////////////////////
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
    deploymentManager.saveDeployment("Whitelist", whitelistAddress);


     //////////////////////////////////
     //////// Deploy CRT Token ////////
     //////////////////////////////////
     const cryptopiaTokenProxy = await (
        await upgrades.deployProxy(
            CryptopiaTokenFactory, [])
        ).waitForDeployment();

    const cryptopiaTokenAddress = await cryptopiaTokenProxy.getAddress();
    deploymentManager.saveDeployment("CryptopiaToken", cryptopiaTokenAddress);


    //////////////////////////////////
    ///// Deploy Account Register/////
    //////////////////////////////////
    const accountRegisterProxy = await (
        await upgrades.deployProxy(
            AccountRegisterFactory, [])
        ).waitForDeployment();

    const accountRegisterAddress = await accountRegisterProxy.getAddress();
    deploymentManager.saveDeployment("CryptopiaAccountRegister", accountRegisterAddress);


    //////////////////////////////////
    ////// Deploy Asset Register//////
    //////////////////////////////////
    const assetRegisterProxy = await (
        await upgrades.deployProxy(
            AssetRegisterFactory, [])
        ).waitForDeployment();

    const assetRegisterAddress = await assetRegisterProxy.getAddress();
    const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);
    deploymentManager.saveDeployment("CryptopiaAssetRegister", assetRegisterAddress);


    //////////////////////////////////
    ////////// Deploy Ships //////////
    //////////////////////////////////
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
    deploymentManager.saveDeployment("CryptopiaShipToken", shipTokenAddress);


    //////////////////////////////////
    ///////// Deploy Crafting ////////
    //////////////////////////////////
    const craftingProxy = await (
        await upgrades.deployProxy(
            CraftingFactory, 
            [
                inventoriesAddress
            ])
        ).waitForDeployment();

    const craftingAddress = await craftingProxy.getAddress();
    const craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);
    deploymentManager.saveDeployment("CryptopiaCrafting", craftingAddress);

    // Grant roles
    await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);


    //////////////////////////////////
    ///// Deploy Player Register /////
    //////////////////////////////////
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
    deploymentManager.saveDeployment("CryptopiaPlayerRegister", playerRegisterAddress);

    // Grant roles
    await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
    await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
    await craftingInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


    //////////////////////////////////
    ////////// Deploy Tools //////////
    //////////////////////////////////
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
    deploymentManager.saveDeployment("CryptopiaToolToken", toolTokenAddress);

    // Register
    await inventoriesInstance.setNonFungibleAsset(toolTokenAddress, true);

    // Grant tool roles
    await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);
    await toolTokenInstance.grantRole(SYSTEM_ROLE, craftingAddress);


    //////////////////////////////////
    /////// Deploy Title Deeds ///////
    //////////////////////////////////
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
    deploymentManager.saveDeployment("CryptopiaTitleDeedToken", titleDeedTokenAddress);


    //////////////////////////////////
    /////////// Deploy Maps //////////
    //////////////////////////////////
    const mapsProxy = await (
        await upgrades.deployProxy(
            MapsFactory, 
            [
                playerRegisterAddress, 
                assetRegisterAddress, 
                titleDeedTokenAddress, 
                cryptopiaTokenAddress
            ])
        ).waitForDeployment();

    const mapsAddress = await mapsProxy.getAddress();
    const mapsInstance = await ethers.getContractAt("CryptopiaMaps", mapsAddress);
    deploymentManager.saveDeployment("CryptopiaMaps", mapsAddress);

    // Grant roles
    await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);


    //////////////////////////////////
    /////// Deploy Quest Items ///////
    //////////////////////////////////
    const questTokenProxy = await (
        await upgrades.deployProxy(
            QuestTokenFactory, 
            [
                whitelistAddress,
                config.ERC721.CryptopiaQuestToken.contractURI, 
                config.ERC721.CryptopiaQuestToken.baseTokenURI,
                inventoriesAddress
            ])
    ).waitForDeployment();

    const questTokenAddress = await questTokenProxy.getAddress();
    const questTokenInstance = await ethers.getContractAt("CryptopiaQuestToken", questTokenAddress);
    deploymentManager.saveDeployment("CryptopiaQuestToken", questTokenAddress);

    // Grant roles
    await inventoriesInstance.grantRole(SYSTEM_ROLE, questTokenAddress);


    //////////////////////////////////
    ////////// Deploy Quests /////////
    //////////////////////////////////
    const questsProxy = await (
        await upgrades.deployProxy(
            QuestsFactory, 
            [
                playerRegisterAddress,
                inventoriesAddress,
                mapsAddress
            ])
    ).waitForDeployment();

    const questsAddress = await questsProxy.getAddress();
    deploymentManager.saveDeployment("CryptopiaQuests", questTokenAddress);

    // Grant roles
    await toolTokenInstance.grantRole(SYSTEM_ROLE, questsAddress);
    await playerRegisterInstance.grantRole(SYSTEM_ROLE, questsAddress);
    await questTokenInstance.grantRole(SYSTEM_ROLE, questsAddress);


    //////////////////////////////////
    //// Deploy Resource Gathering ///
    //////////////////////////////////
    const resourceGatheringProxy = await (
        await upgrades.deployProxy(
            ResourceGatheringFactory,
            [
                mapsAddress,
                assetRegisterAddress,
                playerRegisterAddress,
                inventoriesAddress,
                toolTokenAddress
            ])
        ).waitForDeployment();

    const resourceGatheringAddress = await resourceGatheringProxy.getAddress();
    deploymentManager.saveDeployment("CryptopiaResourceGathering", resourceGatheringAddress);

    // Grant roles
    await toolTokenInstance.grantRole(SYSTEM_ROLE, resourceGatheringAddress);
    await inventoriesInstance.grantRole(SYSTEM_ROLE, resourceGatheringAddress);
    await playerRegisterInstance.grantRole(SYSTEM_ROLE, resourceGatheringAddress); 


    //////////////////////////////////
    ////////// Deploy Assets /////////
    //////////////////////////////////
    let fuelTokenAddress = ""; 
    for (let asset of config.ERC20.CryptopiaAssetToken.resources)
    {
        const assetTokenProxy = await (
            await upgrades.deployProxy(
                AssetTokenFactory, 
                [
                    asset.name, 
                    asset.symbol,
                    inventoriesAddress
                ])
            ).waitForDeployment();

        const assetTokenAddress = await assetTokenProxy.getAddress();
        const assetTokenInstance = await ethers.getContractAt("CryptopiaAssetToken", assetTokenAddress);
        deploymentManager.saveDeployment(`CryptopiaAssetToken:${asset.name}`, resourceGatheringAddress);

        // Register
        await assetRegisterInstance.registerAsset(assetTokenAddress, true, asset.resource);
        await inventoriesInstance.setFungibleAsset(assetTokenAddress, asset.weight);

        // Grant roles
        await assetTokenInstance.grantRole(SYSTEM_ROLE, questsAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, assetTokenAddress);

        if (asset.system.includes("CryptopiaResourceGathering"))
        {
            await assetTokenInstance.grantRole(SYSTEM_ROLE, resourceGatheringAddress);
        }

        if (asset.resource == Resource.Fuel)
        {
            fuelTokenAddress = assetTokenAddress;
        }
    }


    //////////////////////////////////
    ///// Deploy Battle Mechanics ////
    //////////////////////////////////
    const navalBattleMechanicsProxy = await (
        await upgrades.deployProxy(
            NavalBattleMechanicsFactory, 
            [
                playerRegisterAddress,
                mapsAddress,
                shipTokenAddress
            ])
    ).waitForDeployment();

    const navalBattleMechanicsAddress = await navalBattleMechanicsProxy.getAddress();
    const navalBattleMechanicsInstance = await ethers.getContractAt("CryptopiaNavalBattleMechanics", navalBattleMechanicsAddress);
    deploymentManager.saveDeployment("CryptopiaNavalBattleMechanics", navalBattleMechanicsAddress);

    // Grant roles
    await shipTokenInstance.grantRole(SYSTEM_ROLE, navalBattleMechanicsAddress);


    //////////////////////////////////
    ///// Deploy Pirate Mechanics ////
    //////////////////////////////////
    const pirateMechanicsProxy = await (
        await upgrades.deployProxy(
            PirateMechanicsFactory, 
            [
                navalBattleMechanicsAddress,
                playerRegisterAddress,
                assetRegisterAddress,
                mapsAddress,
                shipTokenAddress,
                fuelTokenAddress,
                inventoriesAddress
            ])
    ).waitForDeployment();

    const pirateMechanicsAddress = await pirateMechanicsProxy.getAddress();
    deploymentManager.saveDeployment("CryptopiaPirateMechanics", pirateMechanicsAddress);

    // Grant roles
    await navalBattleMechanicsInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
    await playerRegisterInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
    await inventoriesInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
    await shipTokenInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
    await mapsInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);


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
