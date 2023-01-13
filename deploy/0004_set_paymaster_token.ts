import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";
import { GaslessERC20Paymaster, PaymasterToken } from "../typechain-types";

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

  const paymasterToken: PaymasterToken | null =
    await hre.ethers.getContractOrNull("PaymasterToken", signer);
  if (!paymasterToken) {
    console.log(
      "\x1b[31m PaymasterToken not deployed, abort.\x1b[0m"
    );
    return;
  }

  // await paymasterToken.mint('0x0D43536d52289a0249222Ab48eE7CE9A5A35361b', hre.ethers.utils.parseEther('100000'))

  const currentTokenAddress = (await gaslessPaymaster.callStatic.paymentToken()).token;
  if (currentTokenAddress === paymasterToken.address) {
    console.log(
      "\x1b[32m Token for paymaster has already set, skipping...\x1b[0m"
    );
    return;
  }

  console.log(
    `\x1b[33m Starting to add payment token for ${gaslessPaymaster.address}...\x1b[0m`
  );
  const receipt = await gaslessPaymaster.updatePaymentToken({
    token: paymasterToken.address,
    rate: hre.ethers.utils.parseEther('10'),
  } as GaslessERC20Paymaster.PaymentTokenStruct).then((tx) => tx.wait());
  console.log(
    `\x1b[32m Payment token added, used ${receipt.gasUsed} gas\x1b[0m`
  );
};
func.tags = ["0004_set_paymaster_token"];
func.dependencies = ["0003_deploy_paymaster_token"];

export default func;
