import "../helpers/converters.ts";  
import ora from 'ora-classic';
import path from 'path';
import fs from 'fs';
import hre, { ethers } from "hardhat";
import appConfig, { NetworkConfig } from "../../app.config";
import { DeploymentManager } from "../helpers/deployments";
import { waitForMinimumTime } from "../helpers/timers";
import { ItemJsonData } from './types/items.input';
import { QuestItemStruct } from "../../typechain-types/contracts/source/tokens/ERC721/quests/IQuestItems.js";

const chalk = require('chalk');

// Settins
const MIN_TIME = 1000;

// Default values
const DEFAULT_BASE_PATH = './data/game/quests/';
const DEFAULT_FILE = 'items';
const DEFAULT_BATCH_SIZE = 20;

let config: NetworkConfig;
let deploymentManager: DeploymentManager;

/**
 * Main deployment function
 * 
 * npx hardhat run --network localhost ./scripts/quests/items.publish.ts
 * 
 * @param {string} questsFilePath - Path to the quests data file.
 * @param {number} batchSize - Size of the deployment batch.
 */
async function main(questsFilePath: string, batchSize: number) 
{
    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

    if (!fs.existsSync(questsFilePath)) {
        console.error(chalk.red(`Quest item file not found: ${questsFilePath}`));
        return;
    }

    let questItems: QuestItemStruct[];
    try {
        questItems = resolve(require(questsFilePath));
    } catch (error) {
        if (error instanceof Error) {
            // Now 'error' is typed as 'Error'
            console.error(chalk.red(`Error loading quest item data from ${questsFilePath}: ${error.message}`));
        } else {
            // Handle non-Error objects
            console.error(chalk.red(`An unexpected error occurred while loading quest item data from ${questsFilePath}`));
        }
        return;
    }

    
    const questTokenAddress = deploymentManager.getContractDeployment(
        deploymentManager.resolveContractName("QuestToken")).address;

    console.log(`\nFound ${chalk.bold(questItems.length.toString())} quests items to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`Found ${chalk.green(deploymentManager.resolveContractName("QuestToken"))} at ${chalk.cyan(questTokenAddress)}\n`);

    const questTokenInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("QuestToken"), questTokenAddress);

    // Deploy quest items in batches
    for (let i = 0; i < questItems.length; i += batchSize) 
    {
        const batch = questItems.slice(i, i + batchSize);
        if (i + batchSize >= questItems.length) 
        {
            console.log(`Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(questItems.length / batchSize)}`);
        }
        else 
        {
            console.log(`Deploying batch ${chalk.grey(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(questItems.length / batchSize)}`);
        }

        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await questTokenInstance.setItems(batch);

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    console.log(`\nDeployed ${chalk.bold(questItems.length.toString())} quest items on ${chalk.yellow(hre.network.name)}!\n\n`);
};

/**
 * Resolves the data from the JSON file.
 * 
 * @param {ItemJsonData[]} data - Data from the JSON file.
 * @returns {QuestItemStruct[]} The resolved data.
 */
function resolve(data: ItemJsonData[]): QuestItemStruct[] {
    const resolvedData: QuestItemStruct[] = data.map((jsonData) => {
        const questItem: QuestItemStruct = {
            name: jsonData.name.toBytes32() 
        };

        return questItem;
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