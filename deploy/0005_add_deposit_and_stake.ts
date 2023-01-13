import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { GaslessERC20Paymaster, IGaslessEntryPoint__factory, PaymasterToken } from "../typechain-types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();
  const signer = await hre.ethers.getSigner(deployer);

  const gaslessPaymaster: GaslessERC20Paymaster | null =
    await hre.ethers.getContractOrNull("GaslessERC20Paymaster", signer);
  if (!gaslessPaymaster) {
    console.log(
      "\x1b[31m GaslessERC20Paymaster not deployed, abort.\x1b[0m"
    );
    return;
  }

  const depositAmount = hre.ethers.utils.parseEther('200')
  const stakeAmount = hre.ethers.utils.parseEther('200')
  const stakeDelay = 3600 * 30

  const senderBalance = await hre.ethers.provider.getBalance(signer.address)
  if (senderBalance.lte(depositAmount.add(stakeAmount))) {
    console.log(
      `\x1b[31m Not enough balance for send on address ${signer.address} (got: ${hre.ethers.utils.formatEther(senderBalance)}, required: ${hre.ethers.utils.formatEther(depositAmount.add(stakeAmount))}) \x1b[0m`
    )
    return
  }

  const entrypointAddress = await gaslessPaymaster.callStatic.entryPoint()

  const entrypointContract: IGaslessEntryPoint__factory | null =
    await hre.ethers.getContractAt(IGaslessEntryPoint__factory.abi, entrypointAddress);

  const depositInfo = await entrypointContract.callStatic.getDepositInfo(gaslessPaymaster.address)

  if (!depositInfo.deposit.gte(depositAmount)) {
    console.log(
      `\x1b[33m Starting to deposit for ${gaslessPaymaster.address}...\x1b[0m`
    );
    let receipt = await gaslessPaymaster.connect(signer).deposit({ value: depositAmount }).then((tx) => tx.wait());
    console.log(
      `\x1b[32m Deposit added, used ${receipt.gasUsed} gas\x1b[0m`
    );
  } else {
    console.log(
      `\x1b[32m Enough on deposit, skipping...\x1b[0m`
    );
  }

  if (!depositInfo.staked || !depositInfo.stake.gte(stakeAmount)) {
    console.log(
      `\x1b[33m Starting to stake for ${gaslessPaymaster.address}...\x1b[0m`
    );
    const receipt2 = await gaslessPaymaster.connect(signer).addStake(3600 * 30, { value: stakeAmount }).then((tx) => tx.wait());
    console.log(
      `\x1b[32m Stake added, used ${receipt2.gasUsed} gas\x1b[0m`
    );
  } else {
    console.log(
      `\x1b[32m Enough on stake, skipping...\x1b[0m`
    );
  }
};
func.tags = ["0005_add_deposit_and_stake"];
func.dependencies = ["0004_set_paymaster_token"];

export default func;
