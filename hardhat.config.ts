import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

const config: HardhatUserConfig = {
  solidity: {
    version: '0.5.17', // todo update solidity to 0.8.xx
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    localhost: {
      url: 'http://127.0.0.1:8545',
    },
    mainnet: {
      url: 'https://rpcapi.fantom.network',
      chainId: 250,
    },
    testnet: {
      url: 'https://rpc.testnet.fantom.network',
      chainId: 4002,
    },
  },
  mocha: {},
  paths: {
      sources: './contracts',
      tests: './test',
      cache: './cache',
      artifacts: './artifacts',
  },
};

export default config;
