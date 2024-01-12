import { HardhatUserConfig, task } from "hardhat/config";
import { DeploymentManager } from "./scripts/helpers/deployments";
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
      url: "https://staging-v3.skalenodes.com/v1/staging-faint-slimy-achird",
      chainId: 503129905,
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
        chainId: 503129905,
        urls: {
            apiURL: "https://staging-faint-slimy-achird.explorer.staging-v3.skalenodes.com/api",
            browserURL: "https://staging-faint-slimy-achird.explorer.staging-v3.skalenodes.com"
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

// Tasks
task("account", "Prints account info", async function (taskArguments, hre) 
{
  const deploymentManager = new DeploymentManager(hre.network.name);
  const deployment = await deploymentManager.getContractDeployment("CryptopiaMapsExtensions");
  const instance = await hre.ethers.getContractAt("CryptopiaMapsExtensions", deployment.address);
  
  const info = await instance.getPlayerNavigationData(["0x2b169fcE71699D801DC57e2883766957aaC99C5F"]);
  console.log(JSON.stringify(info, null, 2));
});