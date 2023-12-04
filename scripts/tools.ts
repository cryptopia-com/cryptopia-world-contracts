import hre, { ethers } from "hardhat";
import tools from "../data/game/tools";
import { DeploymentManager } from "./helpers/deployments";
import "./helpers/converters.ts";
const chalk = require('chalk');

/**
 * Formats the current timestamp to display only time (HH:mm:ss).
 * @returns {string} The formatted timestamp.
 */
function getTimestamp() {
    const now = new Date();
    return chalk.grey(`[${now.getHours().toString().padStart(2, '0')}:${now.getMinutes().toString().padStart(2, '0')}:${now.getSeconds().toString().padStart(2, '0')}]`);
}

/**
 * Main deployment function.
 */
async function main() {
    const batchSize = 5;
    const deploymentManager = new DeploymentManager(hre.network.name);
    const toolTokenAddress = deploymentManager.getDeployment("CryptopiaToolToken")?.address;

    console.log(`\n${getTimestamp()} Found ${chalk.blue(tools.length.toString())} tools to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`${getTimestamp()} Starting deployment on ${chalk.yellow(hre.network.name)}\n`);

    const toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

    // Deploy tools in batches
    for (let i = 0; i < tools.length; i += batchSize) 
    {
        const batch = tools.slice(i, i + batchSize);

        if (i + batchSize >= tools.length) 
        {
            console.log(`${getTimestamp()} Deploying batch ${chalk.white(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(tools.length / batchSize)}`);
        }
        else 
        {
            console.log(`${getTimestamp()} Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(tools.length / batchSize)}`);
        }
        

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

        console.log(`${getTimestamp()} Transaction sent with hash ${chalk.cyan(transaction.hash)}`);

        const receipt = await transaction.wait();
        console.log(`${getTimestamp()} Transaction confirmed in block ${chalk.green(receipt?.blockNumber)}\n`);
    }

    console.log(`${getTimestamp()} All tools have been successfully deployed\n`);
};

// Run the deployment script and handle any errors.
main().catch((error) => {
    console.error(`\n${getTimestamp()} - ${chalk.redBright('Error during deployment:')} ${chalk.white(error.message)}\n`);
    process.exitCode = 1;
});
