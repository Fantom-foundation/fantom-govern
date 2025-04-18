import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@openzeppelin/hardhat-upgrades"

const config: HardhatUserConfig = {
    solidity: {
        version: '0.8.27',
        settings: {
            evmVersion: 'cancun',
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
            url: 'https://rpc.sonic.soniclabs.com',
            chainId: 146,
            hardfork: "cancun",
        },
        testnet: {
            url: 'https://rpc.blaze.soniclabs.com',
            chainId: 57054,
            hardfork: "cancun",
        },
    },
    etherscan: {
        customChains: [
            {
                network: "sonic",
                chainId: 146,
                urls: {
                    apiURL: "https://api.sonicscan.org/api",
                    browserURL: "https://sonicscan.org/"
                }
            }
        ],
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
