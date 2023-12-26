import "../helpers/converters.ts";  
import ora from 'ora-classic';
import path from 'path';
import fs from 'fs';
import hre, { ethers } from "hardhat";
import { DeploymentManager } from "../helpers/deployments";
import { waitForMinimumTime } from "../helpers/timers";
import { resolveEnum } from "../helpers/enums";
import { Faction, SubFaction } from '../types/enums';
import { QuestJsonData } from './types/quests.input';
import { QuestStruct } from "../../typechain-types/contracts/source/game/quests/IQuests.js";

const chalk = require('chalk');

// Settins
const MIN_TIME = 1000;

// Default values
const DEFAULT_BASE_PATH = './data/game/quests/';
const DEFAULT_FILE = 'quests';
const DEFAULT_BATCH_SIZE = 20;

const deploymentManager = new DeploymentManager(hre.network.name);

/**
 * Main deployment function.
 * 
 * npx hardhat run --network localhost ./scripts/quests/quests.publish.ts
 * 
 * @param {string} questsFilePath - Path to the quests data file.
 * @param {number} batchSize - Size of the deployment batch.
 */
async function main(questsFilePath: string, batchSize: number) 
{
    if (!fs.existsSync(questsFilePath)) {
        console.error(chalk.red(`Quests file not found: ${questsFilePath}`));
        return;
    }

    let quests: QuestStruct[];
    try {
        quests = resolve(require(questsFilePath));
    } catch (error) {
        if (error instanceof Error) {
            // Now 'error' is typed as 'Error'
            console.error(chalk.red(`Error loading quest data from ${questsFilePath}: ${error.message}`));
        } else {
            // Handle non-Error objects
            console.error(chalk.red(`An unexpected error occurred while loading quest data from ${questsFilePath}`));
        }
        return;
    }

    
    const questsAddress = deploymentManager.getContractDeployment("CryptopiaQuests")?.address;

    console.log(`\nFound ${chalk.bold(quests.length.toString())} quests to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`Found ${chalk.green("CryptopiaQuests")} at ${chalk.cyan(questsAddress)}\n`);

    const questsInstance = await ethers.getContractAt("CryptopiaQuests", questsAddress);

    // Deploy quests in batches
    for (let i = 0; i < quests.length; i += batchSize) 
    {
        const batch = quests.slice(i, i + batchSize);
        if (i + batchSize >= quests.length) 
        {
            console.log(`Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(quests.length / batchSize)}`);
        }
        else 
        {
            console.log(`Deploying batch ${chalk.grey(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(quests.length / batchSize)}`);
        }

        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await questsInstance.setQuests(batch);

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    console.log(`\nDeployed ${chalk.bold(quests.length.toString())} quests on ${chalk.yellow(hre.network.name)}!\n\n`);
};

/**
 * Resolves the data from the JSON file.
 * 
 * @param {QuestJsonData[]} data - Data from the JSON file.
 * @returns {QuestStruct[]} The resolved data.
 */
function resolve(data: QuestJsonData[]): QuestStruct[] {
    const resolvedData: QuestStruct[] = data.map((jsonData) => {
        const quest: QuestStruct = {
            name: jsonData.name.toBytes32(),
            hasLevelConstraint: jsonData.hasLevelConstraint,
            level: jsonData.level,
            hasFactionConstraint: jsonData.hasFactionConstraint,
            faction: jsonData.hasFactionConstraint ? resolveEnum(Faction, jsonData.faction) : 0,
            hasSubFactionConstraint: jsonData.hasSubFactionConstraint,
            subFaction: jsonData.hasSubFactionConstraint ? resolveEnum(SubFaction, jsonData.subFaction) : 0,
            hasRecurrenceConstraint: jsonData.hasRecurrenceConstraint,
            maxRecurrences: jsonData.maxRecurrences,
            hasCooldownConstraint: jsonData.hasCooldownConstraint,
            cooldown: jsonData.cooldown,
            hasTimeConstraint: jsonData.hasTimeConstraint,
            maxDuration: jsonData.maxDuration,
            steps: jsonData.steps.map((step) => ({
                name: step.name.toBytes32(),
                hasTileConstraint: step.hasTileConstraint,
                tile: step.tile,
                takeFungible: step.takeFungible.map((tf) => ({
                    asset: deploymentManager.getContractDeployment(tf.asset).address,
                    amount: tf.amount,
                    allowWallet: tf.allowWallet,
                })),
                takeNonFungible: step.takeNonFungible.map((nft) => ({
                    asset: deploymentManager.getContractDeployment(nft.asset).address,
                    item: nft.item.toBytes32(),
                    allowWallet: nft.allowWallet,
                })),
                giveFungible: step.giveFungible.map((fungibleItem) => ({
                    asset: deploymentManager.getContractDeployment(fungibleItem.asset).address,
                    amount: fungibleItem.amount,
                    allowWallet: fungibleItem.allowWallet,
                })),
                giveNonFungible: step.giveNonFungible.map((nft) => ({
                    asset: deploymentManager.getContractDeployment(nft.asset).address,
                    item: nft.item.toBytes32(),
                    allowWallet: nft.allowWallet,
                })),
            })),
            rewards: jsonData.rewards.map((reward) => ({
                name: reward.name.toBytes32(),
                xp: reward.xp,
                karma: reward.karma,
                fungible: reward.fungible.map((fungibleItem) => ({
                    asset: deploymentManager.getContractDeployment(fungibleItem.asset).address,
                    amount: fungibleItem.amount,
                    allowWallet: fungibleItem.allowWallet,
                })),
                nonFungible: reward.nonFungible.map((nft) => ({
                    asset: deploymentManager.getContractDeployment(nft.asset).address,
                    item: nft.item.toBytes32(),
                    allowWallet: nft.allowWallet,
                })),
            })),
        };

        return quest;
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