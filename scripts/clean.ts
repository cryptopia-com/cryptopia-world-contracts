import "./helpers/converters.ts";
import ora from 'ora-classic';
import chalk from 'chalk';
import hre, { ethers } from "hardhat"; 
import appConfig, { NetworkConfig } from "../app.config";
import { DeploymentManager } from "./helpers/deployments";
import { waitForMinimumTime } from "./helpers/timers";
import { waitForTransaction } from "./helpers/transactions";

const deploymentManager = new DeploymentManager(hre.network.name);

// Config
let config: NetworkConfig;

// Settings
const MIN_TIME = 1000;
const DEFAULT_BATCH_SIZE = 100;

// Internal
let cleanedCounter = 0;
let skipCounter = 0;

/**
 * Clean contracts
 * 
 * npx hardhat run --network localhost ./scripts/clean.ts
 */
async function main() {

    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    console.log(`\n\nStarting cleaning on ${chalk.yellow(hre.network.name)}..`);

    // Get all registered accounts from CreateAccount events
    const deploymentInfo = deploymentManager.getContractDeployment("DevelopmentAccountRegister");
    const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", deploymentInfo.address);

    console.log(`Found ${chalk.green("DevelopmentAccountRegister")} at ${chalk.cyan(deploymentInfo.address)}\n`);

    // Find all CreateAccount events
    const scanForCreateAccountLoader =  ora(`Scanning..`).start();
    const createAccountFilter = accountRegisterInstance.filters.CreateAccount(null, null, null);
    const createAccountLogs = await ethers.provider.getLogs(createAccountFilter);

    scanForCreateAccountLoader.succeed(`Found ${chalk.bold(createAccountLogs.length.toString())} CreateAccount events`);

    // Check batches of accounts
    const accountsToClean = [];
    for (let i = 0; i < createAccountLogs.length; i += DEFAULT_BATCH_SIZE) 
    {
        // Batch
        const batch = createAccountLogs.slice(i, i + DEFAULT_BATCH_SIZE);
        const batchLoader =  ora(`Checking batch ${i + 1} to ${i + batch.length}`).start();
        const batchStartTime = Date.now();

        // Clean
        const accountDatasInput = batch.map(log => accountRegisterInstance.interface.parseLog(log).args.account);
        const accountDatas = await accountRegisterInstance.getAccountDatas(accountDatasInput);

        for (let j = 0; j < accountDatasInput.length; j++) 
        {
            if (accountDatas[0][j] != "0x".toBytes32()) 
            {
                accountsToClean.push(accountDatasInput[j]);
            }
        }

        await waitForMinimumTime(batchStartTime, MIN_TIME);
        batchLoader.succeed(`Checked batch ${i + 1} to ${i + batch.length}`);
    }

    // Clean batches of accountsToClean
    for (let i = 0; i < accountsToClean.length; i += DEFAULT_BATCH_SIZE) 
    {
        // Batch
        const batch = accountsToClean.slice(i, i + DEFAULT_BATCH_SIZE);
        console.log(`Cleaning batch ${i + 1} to ${i + batch.length}`);

        // Clean
        const transactionLoader = ora(`Creating transaction...`).start();
        const transactionLoaderStartTime = Date.now();

        // Create the transaction
        const transaction = await accountRegisterInstance.clean(batch);

        await waitForMinimumTime(transactionLoaderStartTime, MIN_TIME);
        transactionLoader.succeed(`Transaction created ${chalk.cyan(transaction.hash)}`);

        const confirmationLoader = ora(`Waiting for confirmation...`).start();
        const confirmationLoaderStartTime = Date.now();

        // Wait for confirmation
        const receipt = await transaction.wait();

        await waitForMinimumTime(confirmationLoaderStartTime, MIN_TIME);
        confirmationLoader.succeed(`Transaction ${chalk.green("confirmed")} in block ${chalk.cyan(receipt?.blockNumber)}\n`);
    }

    console.log(`\n\nFinished cleaning on ${chalk.yellow(hre.network.name)}:`);
    console.log(`  ${chalk.bold(cleanedCounter)} cleaned`);
    console.log(`  ${chalk.bold(skipCounter)} skipped\n\n`);
}

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});