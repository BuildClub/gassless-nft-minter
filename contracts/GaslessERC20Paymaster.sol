// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

/* solhint-disable reason-string */

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "solidity-rlp/contracts/RLPReader.sol";

import "hardhat/console.sol";

import "./GaslessBasePaymaster.sol";

/**
 * A sample paymaster that uses external service to decide whether to pay for the UserOp.
 * The paymaster trusts an external signer to sign the transaction.
 * The calling user must pass the UserOp to that external signer first, which performs
 * whatever off-chain verification before signing the UserOp.
 * Note that this signature is NOT a replacement for wallet signature:
 * - the paymaster signs to agree to PAY for GAS.
 * - the wallet signs to prove identity and wallet ownership.
 */
contract GaslessERC20Paymaster is GaslessBasePaymaster {
    using ECDSA for bytes32;
    using UserOperationLib for UserOperation;
    using SafeERC20 for IERC20;
    using RLPReader for bytes;
    using RLPReader for RLPReader.RLPItem;

    struct PaymentToken {
        address token;
        uint256 rate;
    }

    PaymentToken public paymentToken;

    constructor(IGaslessEntryPoint _entryPoint)
        GaslessBasePaymaster(_entryPoint)
    {}

    function updatePaymentToken(PaymentToken calldata _paymentToken)
        public
        onlyOwner
    {
        paymentToken = _paymentToken;
    }

    function getTokenValue() public view returns (uint256) {
        // NOTE: Could be obtained from the oracle/dex or arbitary rate
        return paymentToken.rate;
    }

    /**
     * verify our external signer signed this request.
     * the "paymasterAndData" is expected to be the paymaster and a signature over the entire request params
     */
    function validatePaymasterUserOp(UserOperation calldata userOp)
        external
        override
        returns (bytes memory context, uint256 deadline)
    {
        super._requireFromEntryPoint();

        require(
            userOp.maxFeePerGas == userOp.maxPriorityFeePerGas,
            "GP: USELESS_CHECK"
        );

        uint256 value = getTokenValue();
        console.log("value", value);

        bytes memory data = userOp.paymasterAndData[20:];

        RLPReader.RLPItem[] memory dataRLPList = data.toRlpItem().toList();

        uint256 opDeadline = dataRLPList[0].toUint();

        console.log("opDeadline", opDeadline);
        require(opDeadline > block.timestamp, "GP: WRONG_DEADLINE");

        uint8 opV = uint8(dataRLPList[1].toUint());

        console.log("opV", opV);
        // bytes32 opR = bytesToBytes32(dataRLPList[2].toBytes(), 32);
        bytes memory uOpR = dataRLPList[2].toBytes();
        bytes memory uOpS = dataRLPList[3].toBytes();
        bytes32 opR;
        bytes32 opS;
        assembly {
            opR := mload(add(uOpR, 32))
            opS := mload(add(uOpS, 32))
        }
        console.log("opR", string(abi.encodePacked(opR)));
        console.log("opS", string(abi.encodePacked(opS)));

        IERC20Permit(paymentToken.token).permit(
            tx.origin,
            address(this),
            value,
            opDeadline,
            opV,
            opR,
            opS
        );
        IERC20(paymentToken.token).safeTransferFrom(
            tx.origin,
            address(this),
            value
        );
        return ("", 0);
    }
}
