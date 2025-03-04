import "../helpers/converters.ts";
import ora from 'ora-classic';
import path from 'path';
import fs from 'fs';
import hre, { ethers } from "hardhat";
import appConfig, { NetworkConfig } from "../../app.config";
import { resolveEnum } from "../helpers/enums";
import { encodeRockData, encodeVegetationData, encodeWildlifeData } from './helpers/encoders';
import { Resource, Biome, Terrain } from '../types/enums';
import { DeploymentManager } from "../helpers/deployments";
import { waitForMinimumTime } from "../helpers/timers";
import { MapJsonData } from './types/maps.input';
import { CryptopiaMaps } from "../../typechain-types/contracts/source/game/maps/concrete/CryptopiaMaps.js";  

const chalk = require('chalk');

// Settins
const MIN_TIME = 1000;

// Default values
const DEFAULT_BASE_PATH = './data/game/maps/';
const DEFAULT_BATCH_SIZE = 100;

let config: NetworkConfig;
let deploymentManager: DeploymentManager;

/**
 * Map deployment function.
 * 
 * npx hardhat run --network localhost ./scripts/maps/maps.publish.ts
 * 
 * @param {string} filePath - Path to the map data file.
 * @param {number} batchSize - Size of the deployment batch.
 */
async function publishMap(filePath: string, batchSize: number) 
{
    if (!fs.existsSync(filePath)) {
        console.error(chalk.red(`Maps file not found: ${filePath}`));
        return;
    }

    const map: MapJsonData = require(filePath);
    let tiles: CryptopiaMaps.TileInputStruct[];
    try {
        tiles = resolve(map);
    } catch (error) {
        if (error instanceof Error) {
            // Now 'error' is typed as 'Error'
            console.error(chalk.red(`Error loading maps data from ${filePath}: ${error.message}`));
        } else {
            // Handle non-Error objects
            console.error(chalk.red(`An unexpected error occurred while loading maps data from ${filePath}`));
        }
        return;
    }

    const mapsAddress = deploymentManager.getContractDeployment(
        deploymentManager.resolveContractName("Maps"))?.address;

    console.log(`\nFound ${map.name} map with ${chalk.bold(tiles.length.toString())} tiles to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`Found ${chalk.green(deploymentManager.resolveContractName("Maps"))} at ${chalk.cyan(mapsAddress)}\n`);

    const mapsInstance = await ethers.getContractAt(
        deploymentManager.resolveContractName("Maps"), mapsAddress);

    let createMap = false;
    let tileStartingIndex = 0;
    const mapCount = (await mapsInstance.getMapCount()).toNumber();
    if (mapCount > 0) 
    {
        const lastMap = await mapsInstance.getMapAt(mapCount - 1);
        
        // Create map
        if (lastMap.finalized)
        {
            tileStartingIndex = lastMap.tileStartIndex + lastMap.sizeX * lastMap.sizeZ;
            createMap = true;
        }

        // Fault
        else if (lastMap.name !== map.name.toBytes32()) 
        {
            console.error(chalk.red(`Map ${lastMap.name} is still under construction`));
            return;
        }

        // Continue
        else 
        {
            console.log(`Continueing with ${chalk.bold(map.name)} map (${map.sizeX}x${map.sizeZ})`);
            tileStartingIndex = lastMap.tileStartIndex;
        }
    } 

    // Create map
    else {
        createMap = true;
    }

    if (createMap)
    {
        console.log(`Creating ${chalk.bold(map.name)} map (${map.sizeX}x${map.sizeZ})`);
        const createMapTransactionLoader = ora(`Creating transaction...`).start();
        const createMapTransactionLoaderStartTime = Date.now();

        // Create the transaction
        const createMapTransaction = await mapsInstance.createMap(
            map.name.toBytes32(), map.sizeX, map.sizeZ);

        await waitForMinimumTime(createMapTransactionLoaderStartTime, MIN_TIME);
        createMapTransactionLoader.succeed(`Transaction created ${chalk.cyan(createMapTransaction.hash)}`);

        const createMapConfirmationLoader = ora(`Waiting for confirmation...`).start();
        const createMapConfirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const createMapReceipt = await createMapTransaction.wait();

        await waitForMinimumTime(createMapConfirmationLoaderStartTime, MIN_TIME);
        createMapConfirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(createMapReceipt?.blockNumber)}\n`);
    }

    // Deploy tiles in batches
    for (let i = 0; i < tiles.length; i += batchSize) 
    {
        const batch = tiles.slice(i, i + batchSize);
        const batchIndices = batch.map((tile, j) => tileStartingIndex + i + j);
        if (i + batchSize >= tiles.length) 
        {
            console.log(`Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(tiles.length / batchSize)}`);
        }
        else 
        {
            console.log(`Deploying batch ${chalk.grey(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(tiles.length / batchSize)}`);
        }

        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await mapsInstance.setTiles(batchIndices, batch);

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    // Finalize map
    console.log(`Finalizing ${chalk.bold(map.name)} map`);
    const finalizeMapTransactionLoader = ora(`Creating transaction...`).start();
    const finalizeMapTransactionLoaderStartTime = Date.now();

    // Create the transaction
    const finalizeMapTransaction = await mapsInstance.finalizeMap();

    await waitForMinimumTime(finalizeMapTransactionLoaderStartTime, MIN_TIME);
    finalizeMapTransactionLoader.succeed(`Transaction created ${chalk.cyan(finalizeMapTransaction.hash)}`);

    const finalizeMapConfirmationLoader = ora(`Waiting for confirmation...`).start();
    const finalizeMapConfirmationLoaderStartTime = Date.now();

    // Wait for confirmation
    const finalizeMapReceipt = await finalizeMapTransaction.wait();

    await waitForMinimumTime(finalizeMapConfirmationLoaderStartTime, MIN_TIME);
    finalizeMapConfirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(finalizeMapReceipt?.blockNumber)}\n`);

    console.log(`\nDeployed ${map.name} map with ${chalk.bold(tiles.length.toString())} tiles on ${chalk.yellow(hre.network.name)}!\n\n`);
};

/**
 * Resolves the data from the JSON file.
 *
 * @param {MapJsonData} data - Data from the JSON file.
 * @returns {CryptopiaMaps.TileInputStruct[]} The resolved data.
 */
function resolve(data: MapJsonData): CryptopiaMaps.TileInputStruct[]
{
    const resolvedTiles: CryptopiaMaps.TileInputStruct[] = [];
    data.tiles.forEach((tileData, i) => {
        resolvedTiles.push({
            initialized: true,
            mapIndex: 0,
            group: tileData.group,
            safety: tileData.safety,
            biome: resolveEnum(Biome, tileData.biome),
            terrain: resolveEnum(Terrain, tileData.terrain),
            elevationLevel: tileData.elevationLevel,
            waterLevel: tileData.waterLevel,
            riverFlags: tileData.riverFlags,
            hasRoad: tileData.hasRoad,
            hasLake: tileData.hasLake,
            rockData: encodeRockData(tileData.rockData),
            vegetationData: encodeVegetationData(tileData.vegetationData),
            wildlifeData: encodeWildlifeData(tileData.wildlifeData),
            resources: tileData.resources.map((resource) => {
                return {
                    resource: resolveEnum(Resource, resource.resource),
                    initialAmount: resource.amount.toWei()
                }
            })
        });
    });

    return resolvedTiles;
}

async function main(basePath: string, batchSize: number) 
{
    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

    const files = fs.readdirSync(basePath);
    let count = 0;
    for (const file of files) 
    {
        if (file.endsWith('.json')) 
        {
            // get file name without extension
            const name = file.split('.').slice(0, -1).join('.');
            if (deploymentManager.isMapDeployed(name))
            {
                continue;
            }

            await publishMap(path.join(basePath, file), batchSize);
            deploymentManager.saveMapDeployment(name);
            count++;
        }
    }

    if (0 == count)
    {
        console.log(`\nNo maps to deploy on ${chalk.yellow(hre.network.name)}!\n\n`);
    }
}

const basePath = path.resolve(DEFAULT_BASE_PATH);
const batchSize = DEFAULT_BATCH_SIZE;

main(basePath, batchSize).catch((error) => 
{
    console.error(`\n${chalk.redBright('Error during deployment:')} ${chalk.white(error.message)}\n`);
    process.exitCode = 1;
});