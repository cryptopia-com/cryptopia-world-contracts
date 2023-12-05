import "./helpers/converters.ts";
import ora from 'ora-classic';
import path from 'path';
import fs from 'fs';
import hre, { ethers } from "hardhat";
import { DeploymentManager } from "./helpers/deployments";
import { waitForMinimumTime } from "./helpers/timers";
import { Tool } from './types/tools/input';

const chalk = require('chalk');

// Settins
const MIN_TIME = 1000;

// Default values
const DEFAULT_BASE_PATH = './data/game/quests/';
const DEFAULT_FILE = 'basic';
const DEFAULT_BATCH_SIZE = 20;

/**
 * Main deployment function.
 * 
 * @param {string} toolsFilePath - Path to the tools data file.
 * @param {number} batchSize - Size of the deployment batch.
 */
async function main(toolsFilePath: string, batchSize: number) 
{
    if (!fs.existsSync(toolsFilePath)) {
        console.error(chalk.red(`Tools file not found: ${toolsFilePath}`));
        return;
    }

    let tools: Tool[];
    try {
        tools = require(toolsFilePath);
    } catch (error) {
        if (error instanceof Error) {
            // Now 'error' is typed as 'Error'
            console.error(chalk.red(`Error loading tools data from ${toolsFilePath}: ${error.message}`));
        } else {
            // Handle non-Error objects
            console.error(chalk.red(`An unexpected error occurred while loading tools data from ${toolsFilePath}`));
        }
        return;
    }

    const deploymentManager = new DeploymentManager(hre.network.name);
    const toolTokenAddress = deploymentManager.getDeployment("CryptopiaToolToken")?.address;

    console.log(`\nFound ${chalk.bold(tools.length.toString())} tools to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`Found ${chalk.green("CryptopiaToolToken")} at ${chalk.cyan(toolTokenAddress)}\n`);

    const toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

    // Deploy tools in batches
    for (let i = 0; i < tools.length; i += batchSize) 
    {
        const batch = tools.slice(i, i + batchSize);
        if (i + batchSize >= tools.length) 
        {
            console.log(`Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(tools.length / batchSize)}`);
        }
        else 
        {
            console.log(`Deploying batch ${chalk.grey(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(tools.length / batchSize)}`);
        }

        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await toolTokenInstance.setTools(
            batch.map((tool) => tool.name.toBytes32()),
            batch.map((tool) => tool.rarity),
            batch.map((tool) => tool.level),
            batch.map((tool) => [
                tool.stats.durability,
                tool.stats.multiplier_cooldown,
                tool.stats.multiplier_xp,
                tool.stats.multiplier_effectiveness,
                tool.stats.value1,
                tool.stats.value2,
                tool.stats.value3
            ]),
            batch.map((tool) => tool.minting.map((item) => item.resource)),
            batch.map((tool) => tool.minting.map((item) => item.amount.toWei()))
        );

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    console.log(`\nDeployed ${chalk.bold(tools.length.toString())} tools on ${chalk.yellow(hre.network.name)}!\n\n`);
};

const basePath = path.resolve(DEFAULT_BASE_PATH);
const batchSize = DEFAULT_BATCH_SIZE;
const fileName = DEFAULT_FILE;
const filePath = path.resolve(basePath, `${fileName}.json`);

main(filePath, batchSize).catch((error) => 
{
    console.error(`\n${chalk.redBright('Error during deployment:')} ${chalk.white(error.message)}\n`);
    process.exitCode = 1;
});