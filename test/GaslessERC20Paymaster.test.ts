import { deployments, ethers, getChainId, web3 } from "hardhat";
import { expect } from "chai";

import { BridgeCosignerManager } from "../typechain";
import { getBridgeRouterEnterLog } from "./helpers";
import { ContractReceipt, constants, utils, BigNumber, Contract } from "ethers";
import { GaslessERC20Paymaster, PaymasterToken, TestGasslessNFT } from "../typechain-types";
import { getPermitSignature } from "./helpers/permit";
import { UserOperationStruct } from "../typechain-types/contracts/GaslessERC20Paymaster";

const setupTest = deployments.createFixture(
  async ({ deployments, getNamedAccounts, ethers }) => {
    await deployments.fixture(["0004_set_paymaster_token"]);
    const { deployer } = await getNamedAccounts();
    const signer = await ethers.getSigner(deployer)
    const gaslessPaymaster: GaslessERC20Paymaster =
      await ethers.getContract("GaslessERC20Paymaster", signer);
    const paymasterToken: PaymasterToken =
      await ethers.getContract("PaymasterToken", signer);
    const gaslessNFT: TestGasslessNFT =
      await ethers.getContract("TestGasslessNFT", signer);
    const chainId = +(await getChainId());
    const defaultValue = ethers.utils.parseEther('10')

    // mint some tokens
    await paymasterToken.mint(signer.address, ethers.utils.parseEther('100')).then(tx => tx.wait())
    return {
      gaslessPaymaster,
      paymasterToken,
      gaslessNFT,
      signer,
      chainId,
      defaultValue
    };
  }
);

describe("GaslessBasePaymaster", () => {
  it("should validatePaymasterUserOp working with permit and got ok", async () => {
    const { signer, gaslessPaymaster, paymasterToken, gaslessNFT, chainId, defaultValue } =
      await setupTest();

    const { v, r, s } = await getPermitSignature(
      signer as unknown as Wallet,
      paymasterToken,
      gaslessPaymaster.address,
      defaultValue,
    );

    const paymasterData = utils.RLP.encode([
      utils.hexlify(constants.MaxUint256),
      utils.hexlify(v),
      r,
      s,
    ]).slice(2)

    const callData = (await gaslessNFT.populateTransaction.mint('QmT9zBn47DVeTvTZFbtaL2MQrnbGB775HQxWCoEUcffWGt')).data

    const userOp: UserOperationStruct = {
      callContract: utils.getAddress(gaslessNFT.address),
      callData: callData,
      callGasLimit: BigNumber.from('2000000'),
      verificationGasLimit: BigNumber.from('2000000'),
      maxFeePerGas: BigNumber.from('60'),
      maxPriorityFeePerGas: BigNumber.from('60'),
      paymasterAndData: `${gaslessPaymaster.address}${paymasterData}`,
    }

    await gaslessPaymaster.validatePaymasterUserOp(userOp).then(tx => tx.wait())
  });
});
