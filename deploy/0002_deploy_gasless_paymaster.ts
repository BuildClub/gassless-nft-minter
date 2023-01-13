import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("GaslessERC20Paymaster", {
    from: deployer,
    skipIfAlreadyDeployed: true,
    args: [(hre.network.name === "hardhat") ? deployer : "0x791ec459f57362256f313f5512bdb9f6d7cae308"],
    log: true,
  });
};
func.tags = ["0002_deploy_gasless_paymaster"];
func.dependencies = ["0001_deploy_nft"];

export default func;
