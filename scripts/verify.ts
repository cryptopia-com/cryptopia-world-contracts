import "./helpers/converters.ts";
import chalk from 'chalk';
import hre from "hardhat"; 
import { DeploymentManager } from "./helpers/deployments";

const deploymentManager = new DeploymentManager(hre.network.name);

// Internal
let verifyCounter = 0;
let skipCounter = 0;

/**
 * Deploy contracts
 */
async function main() {

    console.log(`\n\nStarting verification on ${chalk.yellow(hre.network.name)}..`);

    for (const deployment of Object.values(deploymentManager.getDeployments())) 
    {
        // Skip if already verified
        if (deployment.verified) 
        {
            if (skipCounter + verifyCounter == 0) 
            {
                console.log("\n");
            }

            skipCounter++;
            console.log(`Skipping ${chalk.green(deployment.contractName)} (already verified)`);
            continue;
        }

        // Verify
        console.log(`\n\nVerifying ${chalk.green(deployment.contractName)}..`);

        try {
            await hre.run("verify:verify", {
                address: deployment.address,
            });
        }
        catch (error)
        {
            console.log(`\n\nFailed to verify ${chalk.red(deployment.contractName)}..`);
            continue;
        }

        deploymentManager.setVerified(deployment.contractName, true);
        verifyCounter++;
    }

    console.log(`\n\nFinished verification on ${chalk.yellow(hre.network.name)}:`);
    console.log(`  ${chalk.bold(verifyCounter)} verified`);
    console.log(`  ${chalk.bold(skipCounter)} skipped\n\n`);
}

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});