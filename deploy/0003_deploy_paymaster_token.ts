import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("PaymasterToken", {
    from: deployer,
    skipIfAlreadyDeployed: true,
    args: ["Gasless Token", "GT", 18],
    log: true,
  });
};
func.tags = ["0003_deploy_paymaster_token"];
func.dependencies = ["0002_deploy_gasless_paymaster"];

export default func;
