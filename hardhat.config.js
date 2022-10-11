require('@nomiclabs/hardhat-waffle');
require('@nomiclabs/hardhat-ethers');
require('@nomiclabs/hardhat-truffle5');
require('@nomiclabs/hardhat-web3');
require('@openzeppelin/test-helpers');
require('hardhat-contract-sizer');

module.exports = {
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true
    },
    localhost: {
      url: 'http://127.0.0.1:8545'
    },
    mainnet: {
      url: 'https://rpcapi.fantom.network',
      chainId: 250
    },
    testnet: {
      url: 'https://rpc.testnet.fantom.network',
      chainId: 4002
    }
  },
  contractSizer: {
    runOnCompile: true,
  },
  mocha: {},
  abiExporter: {
    path: './build/contracts',
    clear: true,
    flat: true,
    spacing: 2
  },
  solidity: {
    version: '0.5.17',
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  gasReporter: {
    currency: 'USD',
    enabled: false,
    gasPrice: 50
  }
};
