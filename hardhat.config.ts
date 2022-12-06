import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";

import "hardhat-deploy";

import { getAccounts, getNodeUrl } from "./network";

const config: HardhatUserConfig = {
  solidity: "0.8.17",
  networks: {
    gw_testnet: {
      chainId: 71401,
      url: getNodeUrl("gw_testnet"),
      accounts: getAccounts("gw_testnet"),
      loggingEnabled: true,
    },
  },
  namedAccounts: {
    deployer: 0,
  },
};

export default config;
