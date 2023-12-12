import { HardhatUserConfig } from "hardhat/config";
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
    mumbai: {
      url: "https://matic.getblock.io/testnet/?api_key=4b8e44c3-94a7-4d7f-be1e-e08ebe8453fd",
      chainId: 80001,
      accounts: {
        mnemonic: secret.mumbai.mnemonic,
        path: "m/44'/60'/0'/0",
        initialIndex: 0,
        count: 10
      }
    },
    chaos: {
      url: "https://staging-v3.skalenodes.com/v1/staging-fast-active-bellatrix",
      chainId: 1351057110,
      accounts: {
        mnemonic: secret.chaos.mnemonic,
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
      mumbai: secret.chaos.etherscan,
      chaos: secret.chaos.etherscan,
    },
    customChains: [
      {
         network: "chaos",
         chainId: 1351057110,
         urls: {
            apiURL: "https://staging-fast-active-bellatrix.explorer.staging-v3.skalenodes.com/api",
            browserURL: "https://staging-fast-active-bellatrix.explorer.staging-v3.skalenodes.com"
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