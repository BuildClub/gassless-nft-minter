import { HardhatRuntimeEnvironment } from "hardhat/types";
import { DeployFunction } from "hardhat-deploy/types";

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre;
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("TestGasslessNFT", {
    from: deployer,
    skipIfAlreadyDeployed: true,
    args: [3],
    log: true,
  });
};
func.tags = ["0001_deploy_nft"];

export default func;
