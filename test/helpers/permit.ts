import {
  BigNumber,
  BigNumberish,
  CallOverrides,
  constants,
  Signature,
  Wallet,
} from "ethers";
import { splitSignature } from "ethers/lib/utils";

interface IToken {
  address: string;
  name(overrides?: CallOverrides | undefined): Promise<string>;
  nonces(
    owner: string,
    overrides?: CallOverrides | undefined
  ): Promise<BigNumber>;
}

export async function getPermitSignature(
  wallet: Wallet,
  token: IToken,
  spender: string,
  value: BigNumberish = constants.MaxUint256,
  deadline = constants.MaxUint256,
  permitConfig?: {
    nonce?: BigNumberish;
    name?: string;
    chainId?: number;
    version?: string;
  }
): Promise<Signature> {
  const [nonce, name, version, chainId] = await Promise.all([
    permitConfig?.nonce ?? token.nonces(wallet.address),
    permitConfig?.name ?? token.name(),
    permitConfig?.version ?? "1",
    permitConfig?.chainId ?? wallet.getChainId(),
  ]);

  const owner = wallet.address;
  const verifyingContract = token.address;

  return splitSignature(
    await wallet._signTypedData(
      {
        name,
        version,
        chainId,
        verifyingContract,
      },
      {
        Permit: [
          {
            name: "owner",
            type: "address",
          },
          {
            name: "spender",
            type: "address",
          },
          {
            name: "value",
            type: "uint256",
          },
          {
            name: "nonce",
            type: "uint256",
          },
          {
            name: "deadline",
            type: "uint256",
          },
        ],
      },
      {
        owner,
        spender,
        value,
        nonce,
        deadline,
      }
    )
  );
}
