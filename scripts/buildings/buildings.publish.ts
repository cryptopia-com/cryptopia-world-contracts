import "../helpers/converters.ts";
import ora from 'ora-classic';
import path from 'path';
import fs from 'fs';
import hre, { ethers } from "hardhat";
import appConfig, { NetworkConfig } from "../../app.config";
import { DeploymentManager } from "../helpers/deployments";
import { waitForMinimumTime } from "../helpers/timers";
import { resolveEnum } from "../helpers/enums";
import { Permission, Rarity, Resource, Profession, BuildingType } from '../types/enums';
import { BuildingJsonData } from './types/buildings.input';
import { BuildingStruct } from "../../typechain-types/contracts/source/game/buildings/IBuildingRegister.js";

const chalk = require('chalk');

// Config
let config: NetworkConfig;

// Settins
const MIN_TIME = 1000;

// Default values
const DEFAULT_BASE_PATH = './data/game/buildings/';
const DEFAULT_FILE = 'buildings';
const DEFAULT_BATCH_SIZE = 20;

let deploymentManager: DeploymentManager;

/**
 * Publish buildings
 * 
 * npx hardhat run --network localhost ./scripts/buildings/buildings.publish.ts
 * 
 * @param {string} buildingsFilePath - Path to the buildings data file.
 * @param {number} batchSize - Size of the deployment batch.
 */
async function main(buildingsFilePath: string, batchSize: number) 
{
    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

    if (!fs.existsSync(buildingsFilePath)) {
        console.error(chalk.red(`Buildings file not found: ${buildingsFilePath}`));
        return;
    }

    let buildings: BuildingStruct[];
    try {
        buildings = resolve(require(buildingsFilePath));
    } catch (error) {
        if (error instanceof Error) {
            // Now 'error' is typed as 'Error'
            console.error(chalk.red(`Error loading buildings data from ${buildingsFilePath}: ${error.message}`));
        } else {
            // Handle non-Error objects
            console.error(chalk.red(`An unexpected error occurred while loading buildings data from ${buildingsFilePath}`));
        }
        return;
    }

    const buildingRegisterAddress = deploymentManager.getContractDeployment(
        deploymentManager.resolveContractName("BuildingRegister"))?.address;

    console.log(`\nFound ${chalk.bold(buildings.length.toString())} buildings to deploy on ${chalk.yellow(hre.network.name)}`);
    console.log(`Found ${chalk.green(deploymentManager.resolveContractName("BuildingRegister"))} at ${chalk.cyan(buildingRegisterAddress)}\n`);

    const buildingRegisterInstance = await ethers.getContractAt(deploymentManager.resolveContractName("BuildingRegister"), buildingRegisterAddress);

    // Deploy buildings in batches
    for (let i = 0; i < buildings.length; i += batchSize) 
    {
        const batch = buildings.slice(i, i + batchSize);
        if (i + batchSize >= buildings.length) 
        {
            console.log(`Deploying batch ${`${Math.floor(i / batchSize) + 1}`}/${Math.ceil(buildings.length / batchSize)}`);
        }
        else 
        {
            console.log(`Deploying batch ${chalk.grey(`${Math.floor(i / batchSize) + 1}`)}/${Math.ceil(buildings.length / batchSize)}`);
        }
        

        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await buildingRegisterInstance.setBuildings(batch);

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    console.log(`\nDeployed ${chalk.bold(buildings.length.toString())} buildings on ${chalk.yellow(hre.network.name)}!\n\n`);
};


/**
 * Resolves the data from the JSON file.
 *
 * @param {BuildingJsonData[]} data - Data from the JSON file.
 * @returns {BuildingStruct[]} The resolved data.
 */
function resolve(data: BuildingJsonData[]): BuildingStruct[]
{
    const resolvedBuildings: BuildingStruct[] = [];
    data.forEach((buildingData, i) => {
        resolvedBuildings.push({
            name: buildingData.name.toBytes32(),
            rarity: resolveEnum(Rarity, buildingData.rarity), 
            buildingType: resolveEnum(BuildingType, buildingData.buildingType),
            modules: buildingData.modules,
            co2: buildingData.co2,
            base_health: buildingData.base_health,
            base_defence: buildingData.base_defence,
            base_inventory: buildingData.base_inventory.toWei(),
            upgradableFrom: buildingData.upgradableFrom.toBytes32(),
            construction: {
                constraints: {
                    hasMaxInstanceConstraint: buildingData.construction.constraints.hasMaxInstanceConstraint,
                    maxInstances: buildingData.construction.constraints.maxInstances,
                    lake: resolveEnum(Permission, buildingData.construction.constraints.lake),
                    river: resolveEnum(Permission, buildingData.construction.constraints.river),
                    dock: resolveEnum(Permission, buildingData.construction.constraints.dock),
                    terrain: {
                        flat: buildingData.construction.constraints.terrain.flat,
                        hills: buildingData.construction.constraints.terrain.hills,
                        mountains: buildingData.construction.constraints.terrain.mountains,
                        seastead: buildingData.construction.constraints.terrain.seastead
                    },
                    biome: {
                        none: buildingData.construction.constraints.biome.none,
                        plains: buildingData.construction.constraints.biome.plains,
                        grassland: buildingData.construction.constraints.biome.grassland,
                        forest: buildingData.construction.constraints.biome.forest,
                        rainForest: buildingData.construction.constraints.biome.rainForest,
                        mangrove: buildingData.construction.constraints.biome.mangrove,
                        desert: buildingData.construction.constraints.biome.desert,
                        tundra: buildingData.construction.constraints.biome.tundra,
                        swamp: buildingData.construction.constraints.biome.swamp,
                        reef: buildingData.construction.constraints.biome.reef,
                        vulcanic: buildingData.construction.constraints.biome.vulcanic
                    },
                    environment: {
                        beach: buildingData.construction.constraints.environment.beach,
                        coast: buildingData.construction.constraints.environment.coast,
                        inland: buildingData.construction.constraints.environment.inland,
                        coastalWater: buildingData.construction.constraints.environment.coastalWater,
                        shallowWater: buildingData.construction.constraints.environment.shallowWater,
                        deepWater: buildingData.construction.constraints.environment.deepWater
                    },
                    zone: {
                        neutral: buildingData.construction.constraints.zone.neutral,
                        industrial: buildingData.construction.constraints.zone.industrial,
                        ecological: buildingData.construction.constraints.zone.ecological,
                        metropolitan: buildingData.construction.constraints.zone.metropolitan
                    }
                },
                requirements: {
                    jobs: buildingData.construction.requirements.jobs.map((jobData) => {
                        return {
                            profession: resolveEnum(Profession, jobData.profession),
                            hasMinimumLevel: jobData.hasMinimumLevel,
                            minLevel: jobData.minLevel,
                            hasMaximumLevel: jobData.hasMaximumLevel,
                            maxLevel: jobData.maxLevel,
                            slots: jobData.slots,
                            xp: jobData.xp,
                            actionValue1: jobData.actionValue1,
                            actionValue2: jobData.actionValue2
                        };
                    }
                    ),
                    resources: buildingData.construction.requirements.resources.map((resourceData) => {
                        return {
                            resource: resolveEnum(Resource, resourceData.resource),
                            amount: resourceData.amount.toWei()
                        };
                    })
                }
            }
        });
    });

    return resolvedBuildings;
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