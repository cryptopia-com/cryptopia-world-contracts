import "./helpers/converters.ts";
import chalk from 'chalk';
import hre from "hardhat"; 
import { DeploymentManager } from "./helpers/deployments";

const deploymentManager = new DeploymentManager(hre.network.name);

// Internal
let verifyCounter = 0;
let skipCounter = 0;

/**
 * Verify contracts on Etherscan.
 * 
 * npx hardhat run --network localhost ./scripts/verify.ts
 */
async function main() {

    console.log(`\n\nStarting verification on ${chalk.yellow(hre.network.name)}..`);

    for (const deploymentKey of Object.keys(deploymentManager.getContractDeployments())) 
    {
        const deployment = deploymentManager.getContractDeployment(deploymentKey);

        // Skip if already verified
        if (deployment.verified) 
        {
            if (skipCounter + verifyCounter == 0) 
            {
                console.log("\n");
            }

            skipCounter++;
            console.log(`Skipping ${chalk.green(deploymentKey)} (already verified)`);
            continue;
        }

        // Verify
        console.log(`\n\nVerifying ${chalk.green(deploymentKey)}..`);

        try {
            await hre.run("verify:verify", {
                address: deployment.address,
            });
        }
        catch (error)
        {
            console.log(`\n\nFailed to verify ${chalk.red(deploymentKey)}..`);
            continue;
        }

        deploymentManager.setContractVerified(deploymentKey, true);
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