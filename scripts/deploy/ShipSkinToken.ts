import "../helpers/converters.ts"; 
import ora from 'ora-classic';
import chalk from 'chalk';
import hre, { ethers, upgrades } from "hardhat"; 
import appConfig, { NetworkConfig } from "../../app.config";
import { Contract } from "ethers";
import { DeploymentManager } from "../helpers/deployments";
import { waitForMinimumTime } from "../helpers/timers";
import { waitForTransaction } from "../helpers/transactions";

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
    //////// Deploy Whitelist ////////
    //////////////////////////////////
    const [whitelistProxy, whitelistDeploymentStatus] = await ensureDeployed(
        "Whitelist", 
        [
            []
        ]);

    const whitelistAddress = await whitelistProxy.address;


    //////////////////////////////////
    /////// Deploy Ship Skins ////////
    //////////////////////////////////
    const [shipSkinTokenProxy, shipSkinTokenDeploymentStatus] = await ensureDeployed(
        "ShipSkinToken", 
        [
            whitelistAddress, 
            config.ERC721.ShipSkinToken.contractURI, 
            config.ERC721.ShipSkinToken.baseTokenURI,
            ethers.constants.AddressZero // TEMP
        ]);


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
    if (!system.startsWith("0x"))
    {
        system = deploymentManager.resolveContractName(system);
    }

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