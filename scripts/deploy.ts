import "./helpers/converters.ts"; 
import ora from 'ora-classic';
import chalk from 'chalk';
import hre, { ethers, upgrades } from "hardhat"; 
import appConfig, { NetworkConfig } from "../app.config";
import { Contract } from "ethers";
import { Resource } from './types/enums';
import { DeploymentManager } from "./helpers/deployments";
import { waitForMinimumTime } from "./helpers/timers";
import { waitForTransaction } from "./helpers/transactions";

// Settins
const MIN_TIME = 100;

// Roles
const SYSTEM_ROLE = "SYSTEM_ROLE".toKeccak256();

// Deployment
enum DeploymentStatus 
{
    None,
    Deployed,
    Upgraded,
    Skipped
}

// Internal
let deployCounter = 0;
let upgradeCounter = 0;
let skipCounter = 0;

let config: NetworkConfig;
let lastDeploymentStatus = DeploymentStatus.None;
let deploymentManager: DeploymentManager;


/**
 * Deploy contracts
 * 
 * npx hardhat run --network localhost ./scripts/deploy.ts
 */
async function main() {

    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

    upgrades.silenceWarnings(); // Prevents warnings from being printed to the console
    console.log(`\n\nStarting deployment to ${chalk.yellow(hre.network.name)}..`);

    //////////////////////////////////
    /////// Deploy Inventories ///////
    //////////////////////////////////
    const [inventoriesProxy, inventoriesDeploymentStatus] = await ensureDeployed(
        "Inventories", 
        [
            config.CryptopiaTreasury.address
        ]);

    const inventoriesAddress = await inventoriesProxy.address;
    const inventoriesInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("Inventories"), inventoriesAddress);

    if (config.defaultSystem)
    {
        for (let system of config.defaultSystem)
        {
            await ensureSystemRoleGranted(
                "Inventories", system);
        }
    }


    //////////////////////////////////
    //////// Deploy Whitelist ////////
    //////////////////////////////////
    const [whitelistProxy, whitelistDeploymentStatus] = await ensureDeployed(
        "Whitelist", 
        [
            [inventoriesAddress]
        ]);

    const whitelistAddress = await whitelistProxy.address;


    //////////////////////////////////
    //////// Deploy CRT Token ////////
    //////////////////////////////////
    const [TokenProxy, TokenDeploymentStatus] = await ensureDeployed(
        "Token", []);
    const TokenAddress = await TokenProxy.address;


    //////////////////////////////////
    ///// Deploy Account Register ////
    //////////////////////////////////
    const [accountRegisterProxy, accountRegisterDeploymentStatus] = await ensureDeployed(
        "AccountRegister", []);

    const accountRegisterAddress = await accountRegisterProxy.address;
    const accountRegisterInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("AccountRegister"), accountRegisterAddress);

    // SKALE workaround (manual initialization)
    if (accountRegisterDeploymentStatus == DeploymentStatus.Deployed)
    {
        const accountRegisterManualInitializeTransactionLoader =  ora(`Initializing manually..`).start();
        const accountRegisterManualInitializeTransactionStartTime = Date.now();
        await accountRegisterInstance.initializeManually();
        await waitForMinimumTime(accountRegisterManualInitializeTransactionStartTime, MIN_TIME);
        accountRegisterManualInitializeTransactionLoader.succeed(`Initialized manually`);
        lastDeploymentStatus = DeploymentStatus.None;
    }


    //////////////////////////////////
    ///// Deploy Avatar Register /////
    //////////////////////////////////
    const [avatarRegisterProxy, avatarRegisterDeploymentStatus] = await ensureDeployed(
        "AvatarRegister", [accountRegisterAddress]);
    const avatarRegisterAddress = await avatarRegisterProxy.address;


    //////////////////////////////////
    ////// Deploy Asset Register /////
    //////////////////////////////////
    const [assetRegisterProxy, assetRegisterDeploymentStatus] = await ensureDeployed(
        "AssetRegister", []);

    const assetRegisterAddress = await assetRegisterProxy.address;
    const assetRegisterInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("AssetRegister"), assetRegisterAddress);


    //////////////////////////////////
    ////////// Deploy Ships //////////
    //////////////////////////////////
    const [shipTokenProxy, shipTokenDeploymentStatus] = await ensureDeployed(
        "ShipToken", 
        [
            whitelistAddress, 
            config.ERC721.ShipToken.contractURI, 
            config.ERC721.ShipToken.baseTokenURI
        ]);

    const shipTokenAddress = await shipTokenProxy.address;


    //////////////////////////////////
    ///////// Deploy Crafting ////////
    //////////////////////////////////
    const [craftingProxy, craftingDeploymentStatus] = await ensureDeployed(
        "Crafting", [inventoriesAddress]);
    const craftingAddress = await craftingProxy.address;

    // Grant roles
    await ensureSystemRoleGranted(
        "Inventories", "Crafting");


    //////////////////////////////////
    ///// Deploy Player Register /////
    //////////////////////////////////
    const [playerRegisterProxy, playerRegisterDeploymentStatus] = await ensureDeployed(
        "PlayerRegister", 
        [
            accountRegisterAddress, 
            inventoriesAddress, 
            craftingAddress,
            shipTokenAddress, 
            []
        ]);

    const playerRegisterAddress = await playerRegisterProxy.address;
    const playerRegisterInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("PlayerRegister"), playerRegisterAddress);

    // Grant roles
    await ensureSystemRoleGranted("Inventories", "PlayerRegister");
    await ensureSystemRoleGranted("ShipToken", "PlayerRegister");
    await ensureSystemRoleGranted("Crafting", "PlayerRegister");


    //////////////////////////////////
    ////////// Deploy Tools //////////
    //////////////////////////////////
    const [toolTokenProxy, toolTokenDeploymentStatus] = await ensureDeployed(
        "ToolToken", 
        [
            whitelistAddress, 
            config.ERC721.ToolToken.contractURI, 
            config.ERC721.ToolToken.baseTokenURI,
            playerRegisterAddress,
            inventoriesAddress
        ]);

    const toolTokenAddress = await toolTokenProxy.address;

    // Register with inventories
    if (toolTokenDeploymentStatus == DeploymentStatus.Deployed || inventoriesDeploymentStatus == DeploymentStatus.Deployed)
    {
        const registerToolsWithInventoriesTransactionLoader =  ora(`Registering..`).start();
        const registerToolsWithInventoriesTransactionStartTime = Date.now();
        await inventoriesInstance.setNonFungibleAsset(toolTokenAddress, true);
        await waitForMinimumTime(registerToolsWithInventoriesTransactionStartTime, MIN_TIME);
        registerToolsWithInventoriesTransactionLoader.succeed(`Registered with ${chalk.green("Inventories")}`);
        lastDeploymentStatus = DeploymentStatus.None;
    }

    // Grant tool roles
    await ensureSystemRoleGranted("Inventories", "ToolToken");
    await ensureSystemRoleGranted("ToolToken", "Crafting");


    //////////////////////////////////
    /////// Deploy Title Deeds ///////
    //////////////////////////////////
    const [titleDeedTokenProxy, titleDeedTokenDeploymentStatus] = await ensureDeployed(
        "TitleDeedToken", 
        [
            whitelistAddress, 
            config.ERC721.TitleDeedToken.contractURI, 
            config.ERC721.TitleDeedToken.baseTokenURI
        ]);

    const titleDeedTokenAddress = await titleDeedTokenProxy.address;


    //////////////////////////////////
    /////////// Deploy Maps //////////
    //////////////////////////////////
    const [mapsProxy, mapsDeploymentStatus] = await ensureDeployed(
        "Maps", 
        [
            playerRegisterAddress, 
            assetRegisterAddress, 
            titleDeedTokenAddress, 
            TokenAddress
        ]);

    const mapsAddress = await mapsProxy.address;    
    const [mapsExtensionsProxy, mapsExtensionsDeploymentStatus] = await ensureDeployed(
        "MapsExtensions", 
        [
            mapsAddress, 
            titleDeedTokenAddress, 
        ]);

    // Register with player register
    if (mapsDeploymentStatus == DeploymentStatus.Deployed || playerRegisterDeploymentStatus == DeploymentStatus.Deployed)
    {
        const registerPlayerRegisterWithMapsTransactionLoader =  ora(`Registering..`).start();
        const registerPlayerRegisterWithMapsTransactionStartTime = Date.now();
        await playerRegisterInstance.setMapsContract(mapsAddress);
        await waitForMinimumTime(registerPlayerRegisterWithMapsTransactionStartTime, MIN_TIME);
        registerPlayerRegisterWithMapsTransactionLoader.succeed(`Registered with ${chalk.green(deploymentManager.resolveDeploymentKey("PlayerRegister"))}`);
        lastDeploymentStatus = DeploymentStatus.None;
    }

    // Grant roles
    await ensureSystemRoleGranted("TitleDeedToken", "Maps");
    await ensureSystemRoleGranted("Maps", "PlayerRegister");

        
    //////////////////////////////////
    /////// Deploy Quest Items ///////
    //////////////////////////////////
    const [questTokenProxy, questTokenDeploymentStatus] = await ensureDeployed(
        "QuestToken", 
        [
            whitelistAddress, 
            config.ERC721.QuestToken.contractURI, 
            config.ERC721.QuestToken.baseTokenURI,
            inventoriesAddress
        ]);

    // Grant roles
    await ensureSystemRoleGranted(
        "Inventories", "QuestToken");


    //////////////////////////////////
    ////////// Deploy Quests /////////
    //////////////////////////////////
    const [questsProxy, questsDeploymentStatus] = await ensureDeployed(
        "Quests", 
        [
            playerRegisterAddress,
            inventoriesAddress,
            mapsAddress
        ]);

    // Grant roles
    await ensureSystemRoleGranted("ToolToken", "Quests");
    await ensureSystemRoleGranted("PlayerRegister", "Quests");
    await ensureSystemRoleGranted("QuestToken", "Quests");


    //////////////////////////////////
    //// Deploy Resource Gathering ///
    //////////////////////////////////
    const [resourceGatheringProxy, resourceGatheringDeploymentStatus] = await ensureDeployed(
        "ResourceGathering", 
        [
            mapsAddress,
            assetRegisterAddress,
            playerRegisterAddress,
            inventoriesAddress,
            toolTokenAddress
        ]);

    // Grant roles
    await ensureSystemRoleGranted("ToolToken", "ResourceGathering");
    await ensureSystemRoleGranted("Inventories", "ResourceGathering");
    await ensureSystemRoleGranted("PlayerRegister", "ResourceGathering");


    //////////////////////////////////
    ////////// Deploy Assets /////////
    //////////////////////////////////
    let fuelTokenAddress = ""; 
    for (let asset of config.ERC20.AssetToken.resources)
    {
        const [assetTokenProxy, assetTokenDeploymentStatus] = await ensureDeployed(
            "AssetToken", 
            [
                asset.name, 
                asset.symbol,
                inventoriesAddress
            ],
            `AssetToken:${asset.name}`);

        const assetTokenAddress = await assetTokenProxy.address;

        // Register with asset register
        if (assetTokenDeploymentStatus == DeploymentStatus.Deployed || assetRegisterDeploymentStatus == DeploymentStatus.Deployed)
        {
            const registerAssetTransactionLoader = ora(`Registering asset..`).start();
            const registerAssetTransactionStartTime = Date.now();
            await assetRegisterInstance.registerAsset(assetTokenAddress, true, asset.resource);
            await waitForMinimumTime(registerAssetTransactionStartTime, MIN_TIME);
            registerAssetTransactionLoader.succeed(`Registered asset with ${chalk.green(deploymentManager.resolveDeploymentKey("AssetRegister"))}`);
            lastDeploymentStatus = DeploymentStatus.None;
        }

        // Register with inventories
        if (assetTokenDeploymentStatus == DeploymentStatus.Deployed || inventoriesDeploymentStatus == DeploymentStatus.Deployed)
        {
            const registerInventoryTransactionLoader =  ora(`Registering asset..`).start();
            const registerInventoryTransactionStartTime = Date.now();
            await inventoriesInstance.setFungibleAsset(assetTokenAddress, asset.weight);
            await waitForMinimumTime(registerInventoryTransactionStartTime, MIN_TIME);
            registerInventoryTransactionLoader.succeed(`Registered asset with ${chalk.green(deploymentManager.resolveDeploymentKey("Inventories"))}`);
            lastDeploymentStatus = DeploymentStatus.None;
        }

        // Grant roles
        await ensureSystemRoleGranted(`AssetToken:${asset.name}`,"Quests");
        await ensureSystemRoleGranted("Inventories",`AssetToken:${asset.name}`);

        for (let system of asset.system)
        {
            await ensureSystemRoleGranted(
                `AssetToken:${asset.name}`, system);
        }

        if (config.defaultSystem)
        {
            for (let system of config.defaultSystem)
            {
                await ensureSystemRoleGranted(
                    `AssetToken:${asset.name}`, system);
            }
        }

        if (asset.resource == Resource.Fuel)
        {
            fuelTokenAddress = assetTokenAddress;
        }
    }


    //////////////////////////////////
    ///// Deploy Battle Mechanics ////
    //////////////////////////////////
    const [navalBattleMechanicsProxy, navalBattleMechanicsDeploymentStatus] = await ensureDeployed(
        "NavalBattleMechanics", 
        [
            playerRegisterAddress,
            mapsAddress,
            shipTokenAddress
        ]);

    const navalBattleMechanicsAddress = await navalBattleMechanicsProxy.address;

    // Grant roles
    await ensureSystemRoleGranted(
        "ShipToken","NavalBattleMechanics");


    //////////////////////////////////
    ///// Deploy Pirate Mechanics ////
    //////////////////////////////////
    const [pirateMechanicsProxy, pirateMechanicsDeploymentStatus] = await ensureDeployed(
        "PirateMechanics", 
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
    await ensureSystemRoleGranted("NavalBattleMechanics","PirateMechanics");
    await ensureSystemRoleGranted("PlayerRegister","PirateMechanics");
    await ensureSystemRoleGranted("Inventories", "PirateMechanics");
    await ensureSystemRoleGranted("ShipToken","PirateMechanics");
    await ensureSystemRoleGranted("Maps", "PirateMechanics");

    console.log(`\n\nFinished deployment to ${chalk.yellow(hre.network.name)}:`);
    console.log(`  ${chalk.bold(deployCounter)} deployed`);
    console.log(`  ${chalk.bold(upgradeCounter)} upgraded`);
    console.log(`  ${chalk.bold(skipCounter)} skipped\n\n`);
}

/**
 * Deploy contract
 * 
 * @param {string} contractName - Name of the contract to deploy.
 * @param {unknown[]} args - Arguments to pass to the contract constructor.
 * @param {string} deploymentKey - Key to save the deployment.
 * @returns A tuple containing the contract instance and a boolean indicating if the contract was deployed.
 */
async function ensureDeployed(contractName: string, args?: unknown[], deploymentKey?: string) : Promise<[Contract, DeploymentStatus]> 
{
    if (!deploymentKey)
    {
        deploymentKey = contractName;
    }

    contractName = deploymentManager.resolveContractName(contractName);
    deploymentKey = deploymentManager.resolveDeploymentKey(deploymentKey);

    if (deploymentManager.isContractDeployed(deploymentKey))
    {
        const factory = await ethers.getContractFactory(contractName);
        const deploymentInfo = deploymentManager.getContractDeployment(deploymentKey);

        // Skip
        if (deploymentInfo.bytecode == factory.bytecode)
        {
            if (lastDeploymentStatus != DeploymentStatus.Skipped)
            {
                console.log("\n");
            }

            console.log(`Skipping ${chalk.green(deploymentKey)} (unchanged bytecode)`);
            lastDeploymentStatus = DeploymentStatus.Skipped;
            skipCounter++;
            
            return [
                await ethers.getContractAt(
                    contractName, 
                    deploymentInfo.address), 
                lastDeploymentStatus
            ];
        }

        // Upgrade
        else {
            lastDeploymentStatus = DeploymentStatus.Upgraded;
            return [
                await _upgradeContract(
                    contractName, 
                    deploymentInfo.address, 
                    deploymentKey), 
                lastDeploymentStatus
            ];
        }
    }

    // Deploy
    else {
        lastDeploymentStatus = DeploymentStatus.Deployed;
        return [
            await _deployContract(
                contractName, 
                deploymentKey, 
                args), 
            lastDeploymentStatus
        ];
    }
}

/**
 * Deploy contract
 * 
 * @param {string} contractName - Name of the contract to deploy.
 * @param {string} deploymentKey - Key to save the deployment.
 * @param {unknown[]} args - Arguments to pass to the contract constructor.
 * @returns The contract instance.
 */
async function _deployContract(contractName: string, deploymentKey: string, args?: unknown[], ) : Promise<Contract> 
{
    console.log(`\n\nDeploying ${chalk.green(deploymentKey)} to ${chalk.yellow(hre.network.name)}`);
    let transactionLoader = ora(`Creating transaction...`).start();
    const transactionStartTime = Date.now();

    // Create transaction
    const factory = await ethers.getContractFactory(contractName);
    const instance = await upgrades.deployProxy(factory, args);
    const deploymentTransaction = instance.deployTransaction;

    if (!deploymentTransaction)
    {
        throw new Error(`Failed to create deployment transaction for ${contractName}`);
    }

    await waitForMinimumTime(transactionStartTime, MIN_TIME);
    transactionLoader.succeed(`Transaction created ${chalk.cyan(deploymentTransaction.hash)}`);
    const deploymentLoader = ora(`Waiting for confirmations...`).start();
    const confirmationLoaderStartTime = Date.now();

    // Wait for confirmation
    const receipt = await waitForTransaction(
        deploymentTransaction.hash, 
        config.confirmations ?? 1, 
        config.pollingInterval ?? 1000, 
        config.pollingTimeout ?? 5000);

    if (!receipt) 
    {
        throw new Error(`Transaction receipt not found for hash: ${deploymentTransaction.hash}`);
    }

    const contractAddress = await instance.address;

    // Save deployment
    deploymentManager.saveContractDeployment(deploymentKey, contractName, contractAddress, factory.bytecode, false);

    await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
    deploymentLoader.succeed(`Contract deployed at ${chalk.cyan(contractAddress)} in block ${chalk.cyan(receipt.blockNumber)}`);

    deployCounter++;
    return instance;
}

/**
 * Upgrade contract
 * 
 * @param {string} contractName - Name of the contract to upgrade.
 * @param {string} contractAddress - Address of the contract to upgrade.
 * @param {string} deploymentKey - Key to save the deployment.
 * @returns The contract instance.
 */
async function _upgradeContract(contractName: string, contractAddress: string, deploymentKey: string) : Promise<Contract> 
{
    console.log(`\n\nUpgrading ${chalk.green(deploymentKey)} on ${chalk.yellow(hre.network.name)}`);
    const transactionLoader = ora(`Creating transaction...`).start();
    const deploymentLoader = ora(`Waiting for transaction...`).start();
    const transactionStartTime = Date.now();

    // Create transaction
    const factory = await ethers.getContractFactory(contractName);
    const upgraded = await upgrades.upgradeProxy(contractAddress, factory);
    const deploymentTransaction = upgraded.deployTransaction;

    if (!deploymentTransaction)
    {
        throw new Error(`Failed to create upgrade transaction for ${contractName}`);
    }

    await waitForMinimumTime(transactionStartTime, MIN_TIME);
    transactionLoader.succeed(`Transaction created ${chalk.cyan(deploymentTransaction.hash)}`);
    deploymentLoader.text = `Waiting for confirmations...`;
    const confirmationLoaderStartTime = Date.now();

    // Wait for confirmation
    const receipt = await waitForTransaction(
        deploymentTransaction.hash, 
        config.confirmations ?? 1, 
        config.pollingInterval ?? 1000, 
        config.pollingTimeout ?? 5000);

    if (!receipt) 
    {
        throw new Error(`Transaction receipt not found for hash: ${deploymentTransaction.hash}`);
    }

    // Save deployment
    deploymentManager.saveContractDeployment(deploymentKey, contractName, contractAddress, factory.bytecode, false);

    await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
    deploymentLoader.succeed(`Contract upgraded at ${chalk.cyan(contractAddress)} in block ${chalk.cyan(receipt.blockNumber)}`);

    upgradeCounter++;
    return await ethers.getContractAt(contractName, contractAddress);
}

/**
 * Grant system role
 * 
 * @param {string} granter - Name of the contract that grants the role.
 * @param {string} granterDeploymentStatus - Deployment status of the granter.
 * @param {string} system - Name of the contract that receives the role.
 * @param {string} systemDeploymentStatus - Deployment status of the system.
 */
async function ensureSystemRoleGranted(granter: string, system: string): Promise<void>
{
    granter = deploymentManager.resolveContractName(granter);
    system = deploymentManager.resolveContractName(system);

    if (deploymentManager.isSystemRoleGranted(granter, system))
    {
        return Promise.resolve();
    }

    const transactionLoader = ora(`Granting ${chalk.blue("SYSTEM")} role..`).start();
    const transactionStartTime = Date.now();

    const granterDeploymentInfo = deploymentManager.getContractDeployment(granter);

    let systemAddress = "";
    if (system.startsWith("0x"))
    {
        systemAddress = system;
    }
    else 
    {
        const systemDeploymentInfo = deploymentManager.getContractDeployment(system);
        systemAddress = systemDeploymentInfo.address;
    }
    
    const granterInstance = await ethers.getContractAt(granterDeploymentInfo.contractName, granterDeploymentInfo.address);
    await granterInstance.grantRole(SYSTEM_ROLE, systemAddress);

    await waitForMinimumTime(transactionStartTime, MIN_TIME);
    transactionLoader.succeed(`Granted ${chalk.blue("SYSTEM")} role to ${chalk.green(system)} on ${chalk.green(granter)}`);
    deploymentManager.saveSystemRoleGrant(granter, system);

    lastDeploymentStatus = DeploymentStatus.None;
} 

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});