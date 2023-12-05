import "./helpers/converters.ts";
import ora from 'ora-classic';
import hre, { ethers, upgrades } from "hardhat";
import appConfig from "../config";
import { Contract } from "ethers";
import { Resource } from './types/enums';
import { DeploymentManager } from "./helpers/deployments";
import { waitForMinimumTime } from "./helpers/timers";

const chalk = require('chalk');

// Settins
const MIN_TIME = 100;

// Deployment manager
const deploymentManager = new DeploymentManager(hre.network.name);

// Roles
const SYSTEM_ROLE = "SYSTEM_ROLE".toKeccak256();

// Internal
let deploymentCounter = 0;

/**
 * Deploy contract
 * 
 * @param {string} contractName - Name of the contract to deploy.
 * @param {unknown[]} args - Arguments to pass to the contract constructor
 * @param {string} deploymentKey - Key to save the deployment
 */
async function deployContract(contractName: string, args?: unknown[], deploymentKey?: string) : Promise<Contract> 
{
    if (!deploymentKey)
    {
        deploymentKey = contractName;
    }

    console.log(`\n\nDeploying ${chalk.green(contractName)} to ${chalk.yellow(hre.network.name)}`);
    const transactionLoader = ora(`Creating transaction...`).start();
    const deploymentLoader = ora(`Waiting for transaction...`).start();
    const transactionStartTime = Date.now();

    // Create transaction
    const factory = await ethers.getContractFactory(contractName);
    const deployProxyOperation = await upgrades.deployProxy(factory, args);
    
    await waitForMinimumTime(transactionStartTime, MIN_TIME);
    transactionLoader.succeed(`Transaction created ${chalk.cyan(deployProxyOperation.deploymentTransaction()?.hash)}`);
    deploymentLoader.text = `Waiting for confirmations...`;
    const confirmationLoaderStartTime = Date.now();

    // Wait for confirmation
    const proxy = await deployProxyOperation.waitForDeployment();
    const contractAddress = await proxy.getAddress();

    // Save deployment
    deploymentManager.saveDeployment(deploymentKey, contractName, contractAddress);

    await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
    deploymentLoader.succeed(`Contract deployed at ${chalk.cyan(contractAddress)} in block ${chalk.cyan(deployProxyOperation.deploymentTransaction()?.blockNumber)}`);

    deploymentCounter++;
    return proxy;
}

async function grantSystemRole(granter: string, system: string): Promise<void>
{
    const transactionLoader = ora(`Granting ${chalk.blue("SYSTEM")} role..`).start();
    const transactionStartTime = Date.now();

    const granterDeploymentInfo = deploymentManager.getDeployment(granter);
    const systemDeploymentInfo = deploymentManager.getDeployment(system);

    const granterInstance = await ethers.getContractAt(granterDeploymentInfo.contractName, granterDeploymentInfo.address);
    await granterInstance.grantRole(SYSTEM_ROLE, systemDeploymentInfo.address);

    await waitForMinimumTime(transactionStartTime, MIN_TIME);
    transactionLoader.succeed(`Granted ${chalk.blue("SYSTEM")} role to ${chalk.green(system)} on ${chalk.green(granter)}`);
} 


/**
 * Deploy contracts
 */
async function main() {

    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    const config: any = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    //////////////////////////////////
    /////// Deploy Inventories ///////
    //////////////////////////////////
    const inventoriesProxy = await deployContract(
        "CryptopiaInventories", 
        [
            config.CryptopiaTreasury.address
        ]);

    const inventoriesAddress = await inventoriesProxy.getAddress();
    const inventoriesInstance = await ethers.getContractAt("CryptopiaInventories", inventoriesAddress);


    //////////////////////////////////
    //////// Deploy Whitelist ////////
    //////////////////////////////////
    const whitelistProxy = await deployContract(
        "Whitelist", 
        [
            [inventoriesAddress]
        ]);

    const whitelistAddress = await whitelistProxy.getAddress();


    //////////////////////////////////
    //////// Deploy CRT Token ////////
    //////////////////////////////////
    const cryptopiaTokenProxy = await deployContract("CryptopiaToken", []);
    const cryptopiaTokenAddress = await cryptopiaTokenProxy.getAddress();


    //////////////////////////////////
    ///// Deploy Account Register ////
    //////////////////////////////////
    const accountRegisterProxy = await deployContract("CryptopiaAccountRegister", []);
    const accountRegisterAddress = await accountRegisterProxy.getAddress();


    //////////////////////////////////
    ////// Deploy Asset Register /////
    //////////////////////////////////
    const assetRegisterProxy = await deployContract("CryptopiaAssetRegister", []);
    const assetRegisterAddress = await assetRegisterProxy.getAddress();
    const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);


    //////////////////////////////////
    ////////// Deploy Ships //////////
    //////////////////////////////////
    const shipTokenProxy = await deployContract(
        "CryptopiaShipToken", 
        [
            whitelistAddress, 
            config.ERC721.CryptopiaShipToken.contractURI, 
            config.ERC721.CryptopiaShipToken.baseTokenURI
        ]);

    const shipTokenAddress = await shipTokenProxy.getAddress();


    //////////////////////////////////
    ///////// Deploy Crafting ////////
    //////////////////////////////////
    const craftingProxy = await deployContract("CryptopiaCrafting", [inventoriesAddress]);
    const craftingAddress = await craftingProxy.getAddress();

    // Grant roles
    await grantSystemRole("CryptopiaInventories", "CryptopiaCrafting");


    //////////////////////////////////
    ///// Deploy Player Register /////
    //////////////////////////////////
    const playerRegisterProxy = await deployContract(
        "CryptopiaPlayerRegister", 
        [
            accountRegisterAddress, 
            inventoriesAddress, 
            craftingAddress,
            shipTokenAddress, 
            []
        ]);

    const playerRegisterAddress = await playerRegisterProxy.getAddress();

    // Grant roles
    await grantSystemRole("CryptopiaInventories", "CryptopiaPlayerRegister");
    await grantSystemRole("CryptopiaShipToken", "CryptopiaPlayerRegister");
    await grantSystemRole("CryptopiaCrafting", "CryptopiaPlayerRegister");


    //////////////////////////////////
    ////////// Deploy Tools //////////
    //////////////////////////////////
    const toolTokenProxy = await deployContract(
        "CryptopiaToolToken", 
        [
            whitelistAddress, 
            config.ERC721.CryptopiaToolToken.contractURI, 
            config.ERC721.CryptopiaToolToken.baseTokenURI,
            playerRegisterAddress,
            inventoriesAddress
        ]);

    const toolTokenAddress = await toolTokenProxy.getAddress();

    // Register with inventories
    const registerToolsWithInventoriesTransactionLoader =  ora(`Registering..`).start();
    const registerToolsWithInventoriesTransactionStartTime = Date.now();
    await inventoriesInstance.setNonFungibleAsset(toolTokenAddress, true);
    await waitForMinimumTime(registerToolsWithInventoriesTransactionStartTime, MIN_TIME);
    registerToolsWithInventoriesTransactionLoader.succeed(`Registered with ${chalk.green("CryptopiaInventories")}`);

    // Grant tool roles
    await grantSystemRole("CryptopiaInventories", "CryptopiaCrafting");
    await grantSystemRole("CryptopiaToolToken", "CryptopiaCrafting");


    //////////////////////////////////
    /////// Deploy Title Deeds ///////
    //////////////////////////////////
    const titleDeedTokenProxy = await deployContract(
        "CryptopiaTitleDeedToken", 
        [
            whitelistAddress, 
            config.ERC721.CryptopiaTitleDeedToken.contractURI, 
            config.ERC721.CryptopiaTitleDeedToken.baseTokenURI
        ]);

    const titleDeedTokenAddress = await titleDeedTokenProxy.getAddress();


    //////////////////////////////////
    /////////// Deploy Maps //////////
    //////////////////////////////////
    const mapsProxy = await deployContract(
        "CryptopiaMaps", 
        [
            playerRegisterAddress, 
            assetRegisterAddress, 
            titleDeedTokenAddress, 
            cryptopiaTokenAddress
        ]);

    const mapsAddress = await mapsProxy.getAddress();

    // Grant roles
    await grantSystemRole("CryptopiaTitleDeedToken", "CryptopiaMaps");


    //////////////////////////////////
    /////// Deploy Quest Items ///////
    //////////////////////////////////
    await deployContract(
        "CryptopiaQuestToken", 
        [
            whitelistAddress, 
            config.ERC721.CryptopiaQuestToken.contractURI, 
            config.ERC721.CryptopiaQuestToken.baseTokenURI,
            inventoriesAddress
        ]);

    // Grant roles
    await grantSystemRole("CryptopiaInventories", "CryptopiaQuestToken");


    //////////////////////////////////
    ////////// Deploy Quests /////////
    //////////////////////////////////
    await deployContract(
        "CryptopiaQuests", 
        [
            playerRegisterAddress,
            inventoriesAddress,
            mapsAddress
        ]);

    // Grant roles
    await grantSystemRole("CryptopiaToolToken", "CryptopiaQuests");
    await grantSystemRole("CryptopiaPlayerRegister", "CryptopiaQuests");
    await grantSystemRole("CryptopiaQuestToken", "CryptopiaQuests");


    //////////////////////////////////
    //// Deploy Resource Gathering ///
    //////////////////////////////////
    await deployContract(
        "CryptopiaResourceGathering", 
        [
            mapsAddress,
            assetRegisterAddress,
            playerRegisterAddress,
            inventoriesAddress,
            toolTokenAddress
        ]);

    // Grant roles
    await grantSystemRole("CryptopiaToolToken", "CryptopiaResourceGathering");
    await grantSystemRole("CryptopiaInventories", "CryptopiaResourceGathering");
    await grantSystemRole("CryptopiaPlayerRegister", "CryptopiaResourceGathering");


    //////////////////////////////////
    ////////// Deploy Assets /////////
    //////////////////////////////////
    let fuelTokenAddress = ""; 
    for (let asset of config.ERC20.CryptopiaAssetToken.resources)
    {
        const assetTokenProxy = await deployContract(
            "CryptopiaAssetToken", 
            [
                asset.name, 
                asset.symbol,
                inventoriesAddress
            ],
            `CryptopiaAssetToken:${asset.name}`);

        const assetTokenAddress = await assetTokenProxy.getAddress();

        // Register with asset register
        const registerAssetTransactionLoader = ora(`Registering..`).start();
        const registerAssetTransactionStartTime = Date.now();
        await assetRegisterInstance.registerAsset(assetTokenAddress, true, asset.resource);
        await waitForMinimumTime(registerAssetTransactionStartTime, MIN_TIME);
        registerAssetTransactionLoader.succeed(`Registered with ${chalk.green("CryptopiaAssetRegister")}`);

        // Register with inventories
        const registerInventoryTransactionLoader =  ora(`Registering..`).start();
        const registerInventoryTransactionStartTime = Date.now();
        await inventoriesInstance.setFungibleAsset(assetTokenAddress, asset.weight);
        await waitForMinimumTime(registerInventoryTransactionStartTime, MIN_TIME);
        registerInventoryTransactionLoader.succeed(`Registered with ${chalk.green("CryptopiaInventories")}`);

        // Grant roles
        await grantSystemRole(`CryptopiaAssetToken:${asset.name}`, "CryptopiaQuests");
        await grantSystemRole("CryptopiaInventories", `CryptopiaAssetToken:${asset.name}`);

        if (asset.system.includes("CryptopiaResourceGathering"))
        {
            await grantSystemRole(`CryptopiaAssetToken:${asset.name}`, "CryptopiaResourceGathering");
        }

        if (asset.resource == Resource.Fuel)
        {
            fuelTokenAddress = assetTokenAddress;
        }
    }


    //////////////////////////////////
    ///// Deploy Battle Mechanics ////
    //////////////////////////////////
    const navalBattleMechanicsProxy = await deployContract(
        "CryptopiaNavalBattleMechanics", 
        [
            playerRegisterAddress,
            mapsAddress,
            shipTokenAddress
        ]);

    const navalBattleMechanicsAddress = await navalBattleMechanicsProxy.getAddress();

    // Grant roles
    await grantSystemRole("CryptopiaShipToken", "CryptopiaNavalBattleMechanics");


    //////////////////////////////////
    ///// Deploy Pirate Mechanics ////
    //////////////////////////////////
    await deployContract(
        "CryptopiaPirateMechanics", 
        [
            navalBattleMechanicsAddress,
            playerRegisterAddress,
            assetRegisterAddress,
            mapsAddress,
            shipTokenAddress,
            fuelTokenAddress,
            inventoriesAddress
        ]);

    // Grant roles
    await grantSystemRole("CryptopiaNavalBattleMechanics", "CryptopiaPirateMechanics");
    await grantSystemRole("CryptopiaPlayerRegister", "CryptopiaPirateMechanics");
    await grantSystemRole("CryptopiaInventories", "CryptopiaPirateMechanics");
    await grantSystemRole("CryptopiaShipToken", "CryptopiaPirateMechanics");
    await grantSystemRole("CryptopiaMaps", "CryptopiaPirateMechanics");


    // Output bytecode
    if (config.CryptopiaAccount.outputBytecode)
    {
        const AccountFactory = await ethers.getContractFactory("CryptopiaAccount");
        const bytecodeHash = "" + ethers.keccak256(AccountFactory.bytecode);
        console.log("------ UPDATE BELOW BYTECODE OF CryptopiaAccount IN THE GAME CLIENT -----");
        console.log("bytecodeHash1: " + bytecodeHash);
        console.log((AccountFactory as any).bytecode);
    }

    console.log(`\n\nDeployed ${chalk.bold(deploymentCounter.toString())} contracts on ${chalk.yellow(hre.network.name)}!`);
}

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});