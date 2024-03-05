import hre from "hardhat"; 
import ora from 'ora-classic';
import chalk from 'chalk';
import { ethers, artifacts } from "hardhat"; 
import nethereumConfig from "../nethereum.config";
import appConfig, { NetworkConfig } from "../app.config";
import { DeploymentManager } from "./helpers/deployments";

const codegen = require('nethereum-codegen');

let config: NetworkConfig;
let deploymentManager: DeploymentManager;

/**
 * Port contracts to C#
 * 
 * npx hardhat run ./scripts/port.ts
 */
async function main() {

    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

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

    // Output bytecode
    if (config.CryptopiaAccount.outputBytecode)
    {
        const AccountFactory = await ethers.getContractFactory("CryptopiaAccount");
        const bytecodeHash = "" + ethers.utils.keccak256(AccountFactory.bytecode);
        console.log("\n------ UPDATE BELOW BYTECODE OF CryptopiaAccount IN THE GAME CLIENT -----\n");
        console.log("bytecodeHash1: " + bytecodeHash);
        console.log((AccountFactory as any).bytecode);
    }

    // Get account implementation address
    const accountRegisterAddress = deploymentManager.getContractDeployment(deploymentManager.resolveContractName("AccountRegister")).address;
    const AccountRegister = await ethers.getContractAt(deploymentManager.resolveContractName("AccountRegister"), accountRegisterAddress);
    const accountImplementationAddress = await AccountRegister.accountImplementation();


    console.log(`\nConfig:\n`);
    console.log(`public const string CURRENCY_ASSET_ID = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("Token")).address}";\n`);
    console.log(`public const string ENTRY_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("Entry")).address}";`);
    console.log(`public const string ACCOUNT_REGISTER_CONTRACT = "${accountRegisterAddress}";`);
    console.log(`public const string ACCOUNT_IMPLEMENTATION_CONTRACT = "${accountImplementationAddress}";`);
    console.log(`public const string AVATAR_REGISTER_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("AvatarRegister")).address}";`);
    console.log(`public const string PLAYER_REGISTER_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("PlayerRegister")).address}";`);
    console.log(`public const string ASSET_REGISTER_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("AssetRegister")).address}";`);
    console.log(`public const string MAP_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("Maps")).address}";`);
    console.log(`public const string MAP_EXTENSIONS_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("MapsExtensions")).address}";`);
    console.log(`public const string TITLE_DEED_TOKEN_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("TitleDeedToken")).address}";`);
    console.log(`public const string INVENTROIES_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("Inventories")).address}";`);
    console.log(`public const string RESOURCE_GATHERING_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("ResourceGathering")).address}";`);
    console.log(`public const string LOYALTY_TOKEN_CONTRACT = "0x0000000000000000000000000000000000000001";`);
    console.log(`public const string SHIP_TOKEN_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("ShipToken")).address}";`);
    console.log(`public const string TOOL_TOKEN_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("ToolToken")).address}";`);
    console.log(`public const string CRAFTING_CONTRACT = "${deploymentManager.getContractDeployment(deploymentManager.resolveContractName("Crafting")).address}";`);
    console.log(`\nFinished porting!\n`);
}

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});