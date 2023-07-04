const { ethers } = require("ethers");
const dotenv = require("dotenv");
dotenv.config();

/* global ethers task */
require("@nomiclabs/hardhat-waffle");
require("@nomicfoundation/hardhat-toolbox");
require("hardhat-diamond-abi");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
  const accounts = await ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */

const keys = process.env.WALLET;
const scrollUrl = "https://alpha-rpc.scroll.io/l2";

module.exports = {
  solidity: "0.8.17",
  hardhat: {
    allowUnlimitedContractSize: true,
  },
  diamondAbi: {
    // (required) The name of your Diamond ABI
    name: "DIAMOND-1-HARDHAT",
    strict: false,
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.MUMBAI_KEY,
      scroll: process.env.ETHERSCAN,
      arbitrumGoerli: process.env.ARBISCAN,
    },
    customChains: [
      {
        network: "scroll",
        chainId: 534353,
        urls: {
          apiURL: "https://blockscout.scroll.io/api",
          browserURL: "https://blockscout.scroll.io",
        },
      },
      {
        network: "arbitrumGoerli",
        chainId: 421613,
        urls: {
          apiURL: "https://api-goerli.arbiscan.io/",
          browserURL: "https://goerli.arbiscan.io/",
        },
      },
    ],
  },
  networks: {
    hardhat: {
      forking: {
        url: scrollUrl,
        blockNumber: 1374325,
      },
    },
    localhost: {
      url: "http://127.0.0.1:8545/",
      accounts: [keys],
    },
    scroll: {
      url: scrollUrl,
      accounts: [keys],
    },
    taiko_testnet: {
      url: "https://rpc.test.taiko.xyz",
      chainId: 167005,
      accounts: [keys],
    },
    goerli: {
      url: "https://ethereum-goerli.publicnode.com",
      chainId: 5,
      accounts: [keys],
    },
    mumbai: {
      allowUnlimitedContractSize: true,
      gas: 2100000,
      gasPrice: 8000000000,
      gasLimit: 50000000000000,
      url: "https://rpc-mumbai.maticvigil.com",
      // url: "https://gateway.tenderly.co/public/polygon-mumbai	",
      // url: "https://polygon-mumbai.infura.io/v3/4458cf4d1689497b9a38b1d6bbf05e78/",
      accounts: [keys],
    },
    mantletest: {
      url: "https://rpc.testnet.mantle.xyz/",
      accounts: [keys], // Uses the private key from the .env file
    },
    omni: {
      url: "https://testnet-1.omni.network/",
      accounts: [keys], // Uses the private key from the .env file
    },
    arbitrumGoerli: {
      url: "https://arbitrum-goerli.blockpi.network/v1/rpc/public",
      accounts: [keys],
    },
  },
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
};
