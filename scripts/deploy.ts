import "./helpers/converters.ts";
import ora from 'ora-classic';
import chalk from 'chalk';
import hre, { ethers, upgrades } from "hardhat"; 
import appConfig from "../app.config";
import { Contract } from "ethers";
import { Resource } from './types/enums';
import { DeploymentManager } from "./helpers/deployments";
import { waitForMinimumTime } from "./helpers/timers";

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

const deploymentManager = new DeploymentManager(hre.network.name);

// Internal
let deployCounter = 0;
let upgradeCounter = 0;
let skipCounter = 0;
let lastDeploymentStatus = DeploymentStatus.None;


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

    console.log(`\n\nStarting deployment to ${chalk.yellow(hre.network.name)}..`);

    //////////////////////////////////
    /////// Deploy Inventories ///////
    //////////////////////////////////
    const [inventoriesProxy, inventoriesDeploymentStatus] = await ensureDeployed(
        "CryptopiaInventories", 
        [
            config.CryptopiaTreasury.address
        ]);

    const inventoriesAddress = await inventoriesProxy.getAddress();
    const inventoriesInstance = await ethers.getContractAt(
        "CryptopiaInventories", inventoriesAddress);


    //////////////////////////////////
    //////// Deploy Whitelist ////////
    //////////////////////////////////
    const [whitelistProxy, whitelistDeploymentStatus] = await ensureDeployed(
        "Whitelist", 
        [
            [inventoriesAddress]
        ],
        inventoriesDeploymentStatus == DeploymentStatus.Deployed);

    const whitelistAddress = await whitelistProxy.getAddress();


    //////////////////////////////////
    //////// Deploy CRT Token ////////
    //////////////////////////////////
    const [cryptopiaTokenProxy, cryptopiaTokenDeploymentStatus] = await ensureDeployed(
        "CryptopiaToken", []);
    const cryptopiaTokenAddress = await cryptopiaTokenProxy.getAddress();


    //////////////////////////////////
    ///// Deploy Account Register ////
    //////////////////////////////////
    const [accountRegisterProxy, accountRegisterDeploymentStatus] = await ensureDeployed(
        "CryptopiaAccountRegister", []);
    const accountRegisterAddress = await accountRegisterProxy.getAddress();


    //////////////////////////////////
    ////// Deploy Asset Register /////
    //////////////////////////////////
    const [assetRegisterProxy, assetRegisterDeploymentStatus] = await ensureDeployed(
        "CryptopiaAssetRegister", []);

    const assetRegisterAddress = await assetRegisterProxy.getAddress();
    const assetRegisterInstance = await ethers.getContractAt(
        "CryptopiaAssetRegister", assetRegisterAddress);


    //////////////////////////////////
    ////////// Deploy Ships //////////
    //////////////////////////////////
    const [shipTokenProxy, shipTokenDeploymentStatus] = await ensureDeployed(
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
    const [craftingProxy, craftingDeploymentStatus] = await ensureDeployed(
        "CryptopiaCrafting", [inventoriesAddress]);
    const craftingAddress = await craftingProxy.getAddress();

    // Grant roles
    await grantSystemRole(
        "CryptopiaInventories", inventoriesDeploymentStatus, 
        "CryptopiaCrafting", craftingDeploymentStatus);


    //////////////////////////////////
    ///// Deploy Player Register /////
    //////////////////////////////////
    const [playerRegisterProxy, playerRegisterDeploymentStatus] = await ensureDeployed(
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
    await grantSystemRole(
        "CryptopiaInventories", inventoriesDeploymentStatus, 
        "CryptopiaPlayerRegister", playerRegisterDeploymentStatus);

    await grantSystemRole(
        "CryptopiaShipToken", shipTokenDeploymentStatus, 
        "CryptopiaPlayerRegister", playerRegisterDeploymentStatus);

    await grantSystemRole(
        "CryptopiaCrafting", craftingDeploymentStatus, 
        "CryptopiaPlayerRegister", playerRegisterDeploymentStatus);


    //////////////////////////////////
    ////////// Deploy Tools //////////
    //////////////////////////////////
    const [toolTokenProxy, toolTokenDeploymentStatus] = await ensureDeployed(
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
    if (toolTokenDeploymentStatus == DeploymentStatus.Deployed || inventoriesDeploymentStatus == DeploymentStatus.Deployed)
    {
        const registerToolsWithInventoriesTransactionLoader =  ora(`Registering..`).start();
        const registerToolsWithInventoriesTransactionStartTime = Date.now();
        await inventoriesInstance.setNonFungibleAsset(toolTokenAddress, true);
        await waitForMinimumTime(registerToolsWithInventoriesTransactionStartTime, MIN_TIME);
        registerToolsWithInventoriesTransactionLoader.succeed(`Registered with ${chalk.green("CryptopiaInventories")}`);
        lastDeploymentStatus = DeploymentStatus.None;
    }

    // Grant tool roles
    await grantSystemRole(
        "CryptopiaInventories", inventoriesDeploymentStatus, 
        "CryptopiaCrafting", craftingDeploymentStatus);

    await grantSystemRole(
        "CryptopiaToolToken", toolTokenDeploymentStatus, 
        "CryptopiaCrafting", craftingDeploymentStatus);


    //////////////////////////////////
    /////// Deploy Title Deeds ///////
    //////////////////////////////////
    const [titleDeedTokenProxy, titleDeedTokenDeploymentStatus] = await ensureDeployed(
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
    const [mapsProxy, mapsDeploymentStatus] = await ensureDeployed(
        "CryptopiaMaps", 
        [
            playerRegisterAddress, 
            assetRegisterAddress, 
            titleDeedTokenAddress, 
            cryptopiaTokenAddress
        ]);

    const mapsAddress = await mapsProxy.getAddress();

    // Grant roles
    await grantSystemRole(
        "CryptopiaTitleDeedToken", titleDeedTokenDeploymentStatus, 
        "CryptopiaMaps", mapsDeploymentStatus);


    //////////////////////////////////
    /////// Deploy Quest Items ///////
    //////////////////////////////////
    const [questTokenProxy, questTokenDeploymentStatus] = await ensureDeployed(
        "CryptopiaQuestToken", 
        [
            whitelistAddress, 
            config.ERC721.CryptopiaQuestToken.contractURI, 
            config.ERC721.CryptopiaQuestToken.baseTokenURI,
            inventoriesAddress
        ]);

    // Grant roles
    await grantSystemRole(
        "CryptopiaInventories", inventoriesDeploymentStatus, 
        "CryptopiaQuestToken", questTokenDeploymentStatus);


    //////////////////////////////////
    ////////// Deploy Quests /////////
    //////////////////////////////////
    const [questsProxy, questsDeploymentStatus] = await ensureDeployed(
        "CryptopiaQuests", 
        [
            playerRegisterAddress,
            inventoriesAddress,
            mapsAddress
        ]);

    // Grant roles
    await grantSystemRole(
        "CryptopiaToolToken", toolTokenDeploymentStatus, 
        "CryptopiaQuests", questsDeploymentStatus);

    await grantSystemRole(
        "CryptopiaPlayerRegister", playerRegisterDeploymentStatus, 
        "CryptopiaQuests", questsDeploymentStatus);

    await grantSystemRole(
        "CryptopiaQuestToken", questTokenDeploymentStatus, 
        "CryptopiaQuests", questsDeploymentStatus);


    //////////////////////////////////
    //// Deploy Resource Gathering ///
    //////////////////////////////////
    const [resourceGatheringProxy, resourceGatheringDeploymentStatus] = await ensureDeployed(
        "CryptopiaResourceGathering", 
        [
            mapsAddress,
            assetRegisterAddress,
            playerRegisterAddress,
            inventoriesAddress,
            toolTokenAddress
        ]);

    // Grant roles
    await grantSystemRole(
        "CryptopiaToolToken", toolTokenDeploymentStatus, 
        "CryptopiaResourceGathering", resourceGatheringDeploymentStatus);

    await grantSystemRole(
        "CryptopiaInventories", inventoriesDeploymentStatus, 
        "CryptopiaResourceGathering", resourceGatheringDeploymentStatus);

    await grantSystemRole(
        "CryptopiaPlayerRegister", playerRegisterDeploymentStatus, 
        "CryptopiaResourceGathering", resourceGatheringDeploymentStatus);


    //////////////////////////////////
    ////////// Deploy Assets /////////
    //////////////////////////////////
    let fuelTokenAddress = ""; 
    for (let asset of config.ERC20.CryptopiaAssetToken.resources)
    {
        const [assetTokenProxy, assetTokenDeploymentStatus] = await ensureDeployed(
            "CryptopiaAssetToken", 
            [
                asset.name, 
                asset.symbol,
                inventoriesAddress
            ],
            inventoriesDeploymentStatus == DeploymentStatus.Deployed,
            `CryptopiaAssetToken:${asset.name}`);

        const assetTokenAddress = await assetTokenProxy.getAddress();

        // Register with asset register
        if (assetTokenDeploymentStatus == DeploymentStatus.Deployed || assetRegisterDeploymentStatus == DeploymentStatus.Deployed)
        {
            const registerAssetTransactionLoader = ora(`Registering asset..`).start();
            const registerAssetTransactionStartTime = Date.now();
            await assetRegisterInstance.registerAsset(assetTokenAddress, true, asset.resource);
            await waitForMinimumTime(registerAssetTransactionStartTime, MIN_TIME);
            registerAssetTransactionLoader.succeed(`Registered asset with ${chalk.green("CryptopiaAssetRegister")}`);
            lastDeploymentStatus = DeploymentStatus.None;
        }

        // Register with inventories
        if (assetTokenDeploymentStatus == DeploymentStatus.Deployed || inventoriesDeploymentStatus == DeploymentStatus.Deployed)
        {
            const registerInventoryTransactionLoader =  ora(`Registering asset..`).start();
            const registerInventoryTransactionStartTime = Date.now();
            await inventoriesInstance.setFungibleAsset(assetTokenAddress, asset.weight);
            await waitForMinimumTime(registerInventoryTransactionStartTime, MIN_TIME);
            registerInventoryTransactionLoader.succeed(`Registered asset with ${chalk.green("CryptopiaInventories")}`);
            lastDeploymentStatus = DeploymentStatus.None;
        }

        // Grant roles
        await grantSystemRole(
            `CryptopiaAssetToken:${asset.name}`, assetTokenDeploymentStatus,
             "CryptopiaQuests", questsDeploymentStatus);

        await grantSystemRole(
            "CryptopiaInventories", inventoriesDeploymentStatus,
            `CryptopiaAssetToken:${asset.name}`, assetTokenDeploymentStatus);

        if (asset.system.includes("CryptopiaResourceGathering"))
        {
            await grantSystemRole(
                `CryptopiaAssetToken:${asset.name}`, assetTokenDeploymentStatus,
                "CryptopiaResourceGathering", resourceGatheringDeploymentStatus);
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
        "CryptopiaNavalBattleMechanics", 
        [
            playerRegisterAddress,
            mapsAddress,
            shipTokenAddress
        ]);

    const navalBattleMechanicsAddress = await navalBattleMechanicsProxy.getAddress();

    // Grant roles
    await grantSystemRole(
        "CryptopiaShipToken", shipTokenDeploymentStatus,
        "CryptopiaNavalBattleMechanics", navalBattleMechanicsDeploymentStatus);


    //////////////////////////////////
    ///// Deploy Pirate Mechanics ////
    //////////////////////////////////
    const [pirateMechanicsProxy, pirateMechanicsDeploymentStatus] = await ensureDeployed(
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
    await grantSystemRole(
        "CryptopiaNavalBattleMechanics", navalBattleMechanicsDeploymentStatus,
        "CryptopiaPirateMechanics", pirateMechanicsDeploymentStatus);

    await grantSystemRole(
        "CryptopiaPlayerRegister", playerRegisterDeploymentStatus,
        "CryptopiaPirateMechanics", pirateMechanicsDeploymentStatus);

    await grantSystemRole(
        "CryptopiaInventories", inventoriesDeploymentStatus, 
        "CryptopiaPirateMechanics", pirateMechanicsDeploymentStatus);

    await grantSystemRole(
        "CryptopiaShipToken", shipTokenDeploymentStatus,
        "CryptopiaPirateMechanics", pirateMechanicsDeploymentStatus);

    await grantSystemRole(
        "CryptopiaMaps", mapsDeploymentStatus, 
        "CryptopiaPirateMechanics", pirateMechanicsDeploymentStatus);


    // Output bytecode
    if (config.CryptopiaAccount.outputBytecode)
    {
        const AccountFactory = await ethers.getContractFactory("CryptopiaAccount");
        const bytecodeHash = "" + ethers.keccak256(AccountFactory.bytecode);
        console.log("------ UPDATE BELOW BYTECODE OF CryptopiaAccount IN THE GAME CLIENT -----");
        console.log("bytecodeHash1: " + bytecodeHash);
        console.log((AccountFactory as any).bytecode);
    }

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
 * @param {Boolean} forceRedeployment - Force redeployment of the contract.
 * @param {string} deploymentKey - Key to save the deployment.
 * @returns A tuple containing the contract instance and a boolean indicating if the contract was deployed.
 */
async function ensureDeployed(contractName: string, args?: unknown[], forceRedeployment?: Boolean, deploymentKey?: string) : Promise<[Contract, DeploymentStatus]> 
{
    if (!deploymentKey)
    {
        deploymentKey = contractName;
    }

    if (!forceRedeployment && deploymentManager.isDeployed(deploymentKey))
    {
        const factory = await ethers.getContractFactory(contractName);
        const deploymentInfo = deploymentManager.getDeployment(deploymentKey);

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
    deploymentManager.saveDeployment(deploymentKey, contractName, contractAddress, factory.bytecode);

    await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
    deploymentLoader.succeed(`Contract deployed at ${chalk.cyan(contractAddress)} in block ${chalk.cyan(deployProxyOperation.deploymentTransaction()?.blockNumber)}`);

    deployCounter++;
    return proxy;
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
    const upgradeProxyOperation = await upgrades.upgradeProxy(contractAddress, factory);

    await waitForMinimumTime(transactionStartTime, MIN_TIME);
    transactionLoader.succeed(`Transaction created ${chalk.cyan(upgradeProxyOperation.deployTransaction?.hash)}`);
    deploymentLoader.text = `Waiting for confirmations...`;
    const confirmationLoaderStartTime = Date.now();

    // Wait for confirmation
    await upgradeProxyOperation.waitForDeployment();

    // Save deployment
    deploymentManager.saveDeployment(deploymentKey, contractName, contractAddress, factory.bytecode);

    await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
    deploymentLoader.succeed(`Contract upgraded at ${chalk.cyan(contractAddress)} in block ${chalk.cyan(upgradeProxyOperation.deployTransaction?.blockNumber)}`);

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
async function grantSystemRole(granter: string, granterDeploymentStatus: DeploymentStatus, system: string, systemDeploymentStatus: DeploymentStatus): Promise<void>
{
    if (granterDeploymentStatus != DeploymentStatus.Deployed || systemDeploymentStatus != DeploymentStatus.Deployed)
    {
        return Promise.resolve();
    }

    const transactionLoader = ora(`Granting ${chalk.blue("SYSTEM")} role..`).start();
    const transactionStartTime = Date.now();

    const granterDeploymentInfo = deploymentManager.getDeployment(granter);
    const systemDeploymentInfo = deploymentManager.getDeployment(system);

    const granterInstance = await ethers.getContractAt(granterDeploymentInfo.contractName, granterDeploymentInfo.address);
    await granterInstance.grantRole(SYSTEM_ROLE, systemDeploymentInfo.address);

    await waitForMinimumTime(transactionStartTime, MIN_TIME);
    transactionLoader.succeed(`Granted ${chalk.blue("SYSTEM")} role to ${chalk.green(system)} on ${chalk.green(granter)}`);
    lastDeploymentStatus = DeploymentStatus.None;
} 

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});