import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import { removeConsoleLog } from "hardhat-preprocessor";

import "hardhat-deploy";

import { getAccounts, getNodeUrl } from "./network";
import { GaslessERC20Paymaster, IGaslessEntryPoint__factory } from "./typechain-types";

task('gasless-deposit-info').setAction(
  async (taskArgs: any, hre: HardhatRuntimeEnvironment) => {
    const gaslessPaymaster: GaslessERC20Paymaster | null =
      await hre.ethers.getContractOrNull("GaslessERC20Paymaster");
    if (!gaslessPaymaster) {
      console.log(
        "\x1b[31m GaslessERC20Paymaster not deployed, abort.\x1b[0m"
      );
      return;
    }

    const entrypointAddress = await gaslessPaymaster.callStatic.entryPoint()
    const entrypointContract: IGaslessEntryPoint__factory | null =
      await hre.ethers.getContractAt(IGaslessEntryPoint__factory.abi, entrypointAddress);

    const depositInfo = await entrypointContract.callStatic.getDepositInfo(gaslessPaymaster.address)
    console.log('Deposit info:')
    console.log('Is staked', depositInfo.staked)
    console.log('Deposit amount (pCKB)', hre.ethers.utils.formatEther(depositInfo.deposit))
    console.log('Stake amount (pCKB)', hre.ethers.utils.formatEther(depositInfo.stake))
  }
);

const config: HardhatUserConfig = {
  solidity: "0.8.16",
  networks: {
    gw_testnet: {
      chainId: 71401,
      url: getNodeUrl("gw_testnet"),
      accounts: getAccounts("gw_testnet"),
      loggingEnabled: true,
    },
    gw_alphanet: {
      chainId: 202206,
      url: getNodeUrl("gw_alphanet"),
      accounts: getAccounts("gw_alphanet"),
      loggingEnabled: true,
    },
  },
  preprocess: {
    eachLine: removeConsoleLog(
      (hre) =>
        hre.network.name !== "hardhat" && hre.network.name !== "localhost"
    ),
  },
  namedAccounts: {
    deployer: 0,
  },
};

export default config;
