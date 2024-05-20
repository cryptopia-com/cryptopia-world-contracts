import "../helpers/converters.ts";  
import ora from 'ora-classic';
import path from 'path';
import fs from 'fs';
import hre, { ethers } from "hardhat";
import appConfig, { NetworkConfig } from "../../app.config";
import { DeploymentManager } from "../helpers/deployments";
import { waitForMinimumTime } from "../helpers/timers";
import { ItemJsonData } from './types/skins.input';
import { ShipSkinStruct } from "../../typechain-types/contracts/source/tokens/ERC721/ships/IShipSkins.js";

const chalk = require('chalk');

// Settins
const MIN_TIME = 1000;

// Default values
const DEFAULT_BASE_PATH = './data/game/ships/';
const DEFAULT_FILE = 'skins';
const DEFAULT_BATCH_SIZE = 20;

let config: NetworkConfig;
let deploymentManager: DeploymentManager;

/**
 * Main deployment function
 * 
 * npx hardhat run --network localhost ./scripts/ships/skins.publish.ts
 * 
 * @param {string} skinsFilePath - Path to the skins data file.
 * @param {number} batchSize - Size of the deployment batch.
 */
async function main(skinsFilePath: string, batchSize: number) 
{
    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

    if (!fs.existsSync(skinsFilePath)) {
        console.error(chalk.red(`Skins file not found: ${skinsFilePath}`));
        return;
    }

    let skins: ShipSkinStruct[];
    try {
        skins = resolve(require(skinsFilePath));
    } catch (error) {
        if (error instanceof Error) {
            // Now 'error' is typed as 'Error'
            console.error(chalk.red(`Error loading skin data from ${skinsFilePath}: ${error.message}`));
        } else {
            // Handle non-Error objects
            console.error(chalk.red(`An unexpected error occurred while loading skin data from ${skinsFilePath}`));
        }
        return;
    }

    
    const shipSkinTokenAddress = deploymentManager.getContractDeployment(
        deploymentManager.resolveContractName("ShipSkinToken")).address;

    console.log(`\nFound ${chalk.bold(skins.length.toString())} skins to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`Found ${chalk.green(deploymentManager.resolveContractName("ShipSkinToken"))} at ${chalk.cyan(shipSkinTokenAddress)}\n`);

    const shipSkinTokenInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("ShipSkinToken"), shipSkinTokenAddress);

    // Deploy skins in batches
    for (let i = 0; i < skins.length; i += batchSize) 
    {
        const batch = skins.slice(i, i + batchSize);
        if (i + batchSize >= skins.length) 
        {
            console.log(`Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(skins.length / batchSize)}`);
        }
        else 
        {
            console.log(`Deploying batch ${chalk.grey(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(skins.length / batchSize)}`);
        }

        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await shipSkinTokenInstance.setSkins(batch);

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    console.log(`\nDeployed ${chalk.bold(skins.length.toString())} skins on ${chalk.yellow(hre.network.name)}!\n\n`);
};

/**
 * Resolves the data from the JSON file.
 * 
 * @param {ItemJsonData[]} data - Data from the JSON file.
 * @returns {ShipSkinStruct[]} The resolved data.
 */
function resolve(data: ItemJsonData[]): ShipSkinStruct[] {
    const resolvedData: ShipSkinStruct[] = data.map((jsonData) => {
        const skin: ShipSkinStruct = {
            name: jsonData.name.toBytes32(),
            ship: jsonData.ship.toBytes32()
        };

        return skin;
    });

    return resolvedData;
}

const basePath = path.resolve(DEFAULT_BASE_PATH);
const batchSize = DEFAULT_BATCH_SIZE;
const fileName = DEFAULT_FILE;
const filePath = path.resolve(basePath, `${fileName}.json`);

main(filePath, batchSize).catch((error) => 
{
    console.error(`\n${chalk.redBright('Error during deployment:')} ${chalk.white(error.message)}\n`);
    process.exitCode = 1;
});