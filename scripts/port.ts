import hre from "hardhat"; 
import ora from 'ora-classic';
import chalk from 'chalk';
import { ethers, artifacts } from "hardhat"; 
import nethereumConfig from "../nethereum.config";
import appConfig, { NetworkConfig } from "../app.config";
import { DeploymentManager } from "./helpers/deployments";

const deploymentManager = new DeploymentManager(hre.network.name);
const codegen = require('nethereum-codegen');

// Config
let config: NetworkConfig;

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
    const accountRegisterAddress = deploymentManager.getContractDeployment("CryptopiaAccountRegister").address;
    const AccountRegister = await ethers.getContractAt("CryptopiaAccountRegister", accountRegisterAddress);
    const accountImplementationAddress = await AccountRegister.accountImplementation();


    console.log(`\nConfig:\n`);
    console.log(`public const string CURRENCY_ASSET_ID = "${deploymentManager.getContractDeployment("CryptopiaToken").address}";\n`);
    console.log(`public const string ACCOUNT_REGISTER_CONTRACT = "${accountRegisterAddress}";`);
    console.log(`public const string ACCOUNT_IMPLEMENTATION_CONTRACT = "${accountImplementationAddress}";`);
    console.log(`public const string AVATAR_REGISTER_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaAvatarRegister").address}";`);
    console.log(`public const string PLAYER_REGISTER_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaPlayerRegister").address}";`);
    console.log(`public const string ASSET_REGISTER_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaAssetRegister").address}";`);
    console.log(`public const string MAP_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaMaps").address}";`);
    console.log(`public const string MAP_EXTENSIONS_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaMapsExtensions").address}";`);
    console.log(`public const string TITLE_DEED_TOKEN_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaTitleDeedToken").address}";`);
    console.log(`public const string INVENTROIES_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaInventories").address}";`);
    console.log(`public const string RESOURCE_GATHERING_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaResourceGathering").address}";`);
    console.log(`public const string LOYALTY_TOKEN_CONTRACT = "0x0000000000000000000000000000000000000001";`);
    console.log(`public const string SHIP_TOKEN_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaShipToken").address}";`);
    console.log(`public const string TOOL_TOKEN_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaToolToken").address}";`);
    console.log(`public const string CRAFTING_CONTRACT = "${deploymentManager.getContractDeployment("CryptopiaCrafting").address}";`);
    console.log(`\nFinished porting!\n`);
}

// Deploy
main().catch((error) => 
{
  console.error(error);
  process.exitCode = 1;
});