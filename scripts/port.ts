import ora from 'ora-classic';
import chalk from 'chalk';
import { artifacts  } from "hardhat"; 
import nethereumConfig from "../nethereum.config";

const codegen = require('nethereum-codegen');

/**
 * Port contracts to C#
 * 
 * npx hardhat run ./scripts/port.ts
 */
async function main() {

    console.log(`\nFound ${nethereumConfig.contracts.length} contracts to port\n`);

    codegen.generateNetStandardClassLibrary(
        nethereumConfig.projectName, 
        nethereumConfig.projectPath, 
        nethereumConfig.lang);

    for (let i = 0; i < nethereumConfig.contracts.length; i++) 
    {
        const contractName = nethereumConfig.contracts[i];
        const contractArtifact = await artifacts.readArtifact(contractName);

        const loader = ora("Porting..").start();

        const abi: any[] = [];
        for (let j = 0; j < contractArtifact.abi.length; j++)
        {
            if (contractArtifact.abi[j].type !== "function" || !contractArtifact.abi[j].name.startsWith('__'))
            {
                abi.push(contractArtifact.abi[j]);
            }
        }

        codegen.generateAllClasses(
            JSON.stringify(abi),
            contractArtifact.bytecode,
            contractName,
            nethereumConfig.namespace,
            nethereumConfig.projectPath,
            nethereumConfig.lang);

        loader.succeed(`Ported ${chalk.green(contractName)} contract`);
    }

    console.log(`\nFinished porting!\n`);
}

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});