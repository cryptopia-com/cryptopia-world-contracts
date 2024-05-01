import { HardhatUserConfig, task } from "hardhat/config";
import { DeploymentManager } from "./scripts/helpers/deployments";
import appConfig from "./app.config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';

const secret = JSON.parse(
  require('fs')
    .readFileSync(".secret")
    .toString()
    .trim());

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      
    },
    ganache: {
      url: "http://127.0.0.1:7545",
      chainId: 5777,
      accounts: {
        mnemonic: "scheme learn check guide arm holiday social soul trigger apart photo east",
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10
      }
    },
    polygonMumbai: {
      url: "https://matic.getblock.io/testnet/?api_key=4b8e44c3-94a7-4d7f-be1e-e08ebe8453fd",
      chainId: 80001,
      accounts: {
        mnemonic: secret.polygonMumbai.mnemonic,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10
      }
    },
    skaleChaos: {
      url: "https://staging-v3.skalenodes.com/v1/staging-fast-active-bellatrix",
      chainId: 1351057110,
      accounts: {
        mnemonic: secret.skaleChaos.mnemonic,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10
      }
    },
    skaleNebulaTestnet: {
      url: "https://testnet.skalenodes.com/v1/lanky-ill-funny-testnet",
      chainId: 37084624,
      accounts: {
        mnemonic: secret.skaleNebulaTestnet.mnemonic,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10
      }
    },
    skaleNebulaMainnet: {
      url: "https://mainnet.skalenodes.com/v1/green-giddy-denebola",
      chainId: 1482601649,
      accounts: {
        mnemonic: secret.skaleNebulaMainnet.mnemonic,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10
      }
    }
  },
  solidity: {
    version: "0.8.20",
    settings: {
      optimizer: {
        enabled: true,
        runs: 2000
      }
    }
  },
  etherscan: {
    apiKey: {
      polygonMumbai: secret.polygonMumbai.etherscan,
      skaleChaos: secret.skaleChaos.etherscan,
      skaleNebulaTestnet: secret.skaleNebulaTestnet.etherscan,
      skaleNebulaMainnet: secret.skaleNebulaMainnet.etherscan
    },
    customChains: [
      {
        network: "skaleChaos",
        chainId: 1351057110,
        urls: {
            apiURL: "https://staging-fast-active-bellatrix.explorer.staging-v3.skalenodes.com/api",
            browserURL: "https://staging-fast-active-bellatrix.explorer.staging-v3.skalenodes.com"
        }
      },
      {
        network: "skaleNebulaTestnet",
        chainId: 37084624,
        urls: {
            apiURL: "https://lanky-ill-funny-testnet.explorer.testnet.skalenodes.com/api",
            browserURL: "https://lanky-ill-funny-testnet.explorer.testnet.skalenodes.com/"
        }
      },
      {
        network: "skaleNebulaMainnet",
        chainId: 1482601649,
        urls: {
            apiURL: "https://green-giddy-denebola.explorer.mainnet.skalenodes.com//api",
            browserURL: "https://green-giddy-denebola.explorer.mainnet.skalenodes.com/"
        }
      }
    ]
  },
  // gasReporter: {
  //   enabled: false,
  //   coinmarketcap: "931e13ca-da1b-4faa-8542-081a7cc94217",
  //   gasPrice: 21,
  //   currency: 'USD'
  // }
};

export default config;

/**
 * Mint resources
 * 
 * npx hardhat resource --network skaleNebulaTestnet  --resource "Wood" --to 0xE43D7aCa7978f98Ab8edBc787Ce93a3015ea4d24 --amount 1000000000000000000 --inventory "Ship"
 * npx hardhat resource --network skaleNebulaTestnet  --resource "Stone" --to 0xE43D7aCa7978f98Ab8edBc787Ce93a3015ea4d24 --amount 1000000000000000000 --inventory "Ship"
 * npx hardhat resource --network skaleNebulaTestnet  --resource "Gold" --to YOUR_REMOTE_ADDRESS --amount 10000000000000000000 --inventory "Backpack"
 */
task("resource", "Mint resources")
  .addParam("resource", "The resource to mint")
  .addParam("to", "The address to mint to")
  .addParam("amount", "The amount to mint")
  .addParam("inventory", "The inventory to assign to")
  .setAction(async (taskArguments, hre) =>
  {
    // Config
    const isDevEnvironment = hre.network.name == "hardhat" 
        || hre.network.name == "ganache" 
        || hre.network.name == "localhost";
    const config = appConfig.networks[
        isDevEnvironment ? "development" : hre.network.name];

    const deploymentManager = new DeploymentManager(
        hre.network.name, config.development);

    const tokenDeployment = await deploymentManager.getContractDeployment(deploymentManager.resolveDeploymentKey("AssetToken:" + taskArguments.resource));
    const tokenInstance = await hre.ethers.getContractAt(deploymentManager.resolveContractName("AssetToken"), tokenDeployment.address);

    if (taskArguments.inventory == "Backpack" || taskArguments.inventory == "Ship")
    {
      await tokenInstance.__mintToInventory(taskArguments.to, taskArguments.inventory == "Backpack" ? 1 : 2, taskArguments.amount);
    }
    else 
    {
      await tokenInstance.__mint(taskArguments.to, taskArguments.amount);
    }
  });

  /**
 * Set automatic node mining for local host
 * 
 * npx hardhat setAutomine --network localhost --state true
 * npx hardhat setAutomine --network localhost --state false
 */
task("setAutomine", "Set Automatic Mining")
.addParam("state", "allowAutoMining")
.setAction(async (taskArguments, hre) =>
{
  await hre.network.provider.send("evm_setAutomine", [taskArguments.state == "true" ? true : false]);
});

  /**
 * Set interval for automatic node mining for localhost
 * 
 * npx hardhat setIntervalMining --network localhost --interval 5000
 */
  task("setIntervalMining", "Set Interval Mining")
  .addParam("interval", "intervalMining")
  .setAction(async (taskArguments, hre) =>
  {
    await hre.network.provider.send("evm_setIntervalMining", [parseInt(taskArguments.interval)]);
  });

/**
 * Send gas to localhost account
 * 
 * npx hardhat fundLocalhost --network localhost --address 0x56870EBd9128c9c43823448e3DE6Bf7Dd762a9d4
 */
    task("fundLocalhost", "Fund localhost with gas")
    .addParam("address", "player address to send to")
    .setAction(async (taskArguments, hre) =>
    {
      const [deployer] = await hre.ethers.getSigners();
      await deployer.sendTransaction({
        to: taskArguments.address,
        value: hre.ethers.utils.parseEther("1.0")
      });
    });