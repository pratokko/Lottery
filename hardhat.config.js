require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-chai-matchers");
require("hardhat-deploy");
require("hardhat-gas-reporter");
require("@nomiclabs/hardhat-etherscan");
require("dotenv").config();
require("solidity-coverage");


const GEORLY_RPC_URL = process.env.GEORLY_RPC_URL;
const PRIVATE_KEY = process.env.PRIVATE_KEY;
// const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY;
// const COINMARKETCAP_API_KEY = process.env.COINMARKETCAP_API_KEY;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {

  defaultNetwork: "hardhat",
networks: {
  hardhat: { 
    chainId: 31337,
    blockConfirmations: 1,
  },

  georly: {
    chainId: 5,
    blockConfirmations: 6,
    url: GEORLY_RPC_URL,
    accounts: [PRIVATE_KEY]

  },

},

// etherscan: {
//   // yarn hardhat verify --network <NETWORK> <CONTRACT_ADDRESS> <CONSTRUCTOR_PARAMETERS>
//   apiKey: {
//       goerli: ETHERSCAN_API_KEY,
//       // polygon: POLYGONSCAN_API_KEY,
//     },
    
//     url: "https://api-goerli.etherscan.io/api",
// },

  solidity: "0.8.7",
  namedAccounts: {
    deployer: {
      default: 0,
    },
    player: {
      default: 1,
    },
  }
};
