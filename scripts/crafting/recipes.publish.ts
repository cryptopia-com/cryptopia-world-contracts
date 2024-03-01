import "../helpers/converters.ts";  
import ora from 'ora-classic';
import path from 'path';
import fs from 'fs';
import hre, { ethers } from "hardhat";
import appConfig, { NetworkConfig } from "../../app.config";
import { DeploymentManager } from "../helpers/deployments";
import { waitForMinimumTime } from "../helpers/timers";
import { IngredientJsonData, RecipeJsonData } from './types/recipes.input';
import { CraftingRecipeStruct } from "../../typechain-types/contracts/source/game/crafting/ICrafting.js";

const chalk = require('chalk');

// Settins
const MIN_TIME = 1000;

// Default values
const DEFAULT_BASE_PATH = './data/game/crafting/';
const DEFAULT_FILE = 'recipes';
const DEFAULT_BATCH_SIZE = 20;

let config: NetworkConfig;
let deploymentManager: DeploymentManager;

/**
 * Main deployment function.
 * 
 * npx hardhat run --network localhost ./scripts/crafting/recipes.publish.ts
 * 
 * @param {string} recipesFilePath - Path to the recipes data file.
 * @param {number} batchSize - Size of the deployment batch.
 */
async function main(recipesFilePath: string, batchSize: number) 
{
    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

    if (!fs.existsSync(recipesFilePath)) {
        console.error(chalk.red(`Recipes file not found: ${recipesFilePath}`));
        return;
    }

    let recipes: CraftingRecipeStruct[];
    try {
        recipes = resolve(require(recipesFilePath));
    } catch (error) {
        if (error instanceof Error) {
            // Now 'error' is typed as 'Error'
            console.error(chalk.red(`Error loading recipes data from ${recipesFilePath}: ${error.message}`));
        } else {
            // Handle non-Error objects
            console.error(chalk.red(`An unexpected error occurred while loading recipe data from ${recipesFilePath}`));
        }
        return;
    }

    
    const craftingAddress = deploymentManager.getContractDeployment(
        deploymentManager.resolveContractName("Crafting"))?.address;

    console.log(`\nFound ${chalk.bold(recipes.length.toString())} recipes to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`Found ${chalk.green(deploymentManager.resolveContractName("Crafting"))} at ${chalk.cyan(craftingAddress)}\n`);

    const craftingInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("Crafting"), craftingAddress);

    // Deploy recipes in batches
    for (let i = 0; i < recipes.length; i += batchSize) 
    {
        const batch = recipes.slice(i, i + batchSize);
        if (i + batchSize >= recipes.length) 
        {
            console.log(`Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(recipes.length / batchSize)}`);
        }
        else 
        {
            console.log(`Deploying batch ${chalk.grey(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(recipes.length / batchSize)}`);
        }

        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await craftingInstance.setRecipes(batch);

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    console.log(`\nDeployed ${chalk.bold(recipes.length.toString())} recipes on ${chalk.yellow(hre.network.name)}!\n\n`);
};

/**
 * Resolves the data from the JSON file.
 *
 * @param {RecipeJsonData[]} data - Data from the JSON file.
 * @returns {CraftingRecipeStruct[]} The resolved data.
 */
function resolve(data: RecipeJsonData[]): CraftingRecipeStruct[]
{
    const resolvedRecipes: CraftingRecipeStruct[] = [];
    data.forEach((recipeData, i) => {
        resolvedRecipes.push({
            level: recipeData.level,
            learnable: recipeData.learnable,
            asset: deploymentManager.getContractDeployment(
                deploymentManager.resolveDeploymentKey(recipeData.asset)).address,
            item: recipeData.item.toBytes32(), 
            craftingTime: recipeData.craftingTime,
            ingredients: recipeData.ingredients.map((ingredient: IngredientJsonData) => {
                return {
                    asset: deploymentManager.getContractDeployment(
                        deploymentManager.resolveDeploymentKey(ingredient.asset)).address,
                    amount: ingredient.amount.toWei()
                };
            })
        });
    });

    return resolvedRecipes;
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