// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";
import "./interfaces/IPaymasterToken.sol";

contract PaymasterToken is IERC20Permit, ERC20, IPaymasterToken, Ownable {
    string public constant VERSION = "1";

    struct Token {
        string name;
        string symbol;
        uint8 decimals;
    }

    Token internal token;

    constructor(
        string memory _name,
        string memory _symbol,
        uint8 _decimals
    ) ERC20(_name, _symbol) {
        token.name = _name;
        token.symbol = _symbol;
        token.decimals = _decimals;
    }

    /**
     * @notice Update token info
     * @param _newName The new name
     * @param _newSymbol The new symbol
     * @param _newDecimals The new decimals
     */
    function updateTokenInfo(
        string calldata _newName,
        string calldata _newSymbol,
        uint8 _newDecimals
    ) external override onlyOwner {
        // careful with naming convention change here
        token.name = _newName;
        token.symbol = _newSymbol;
        token.decimals = _newDecimals;
    }

    // ============ External Functions ============

    /** @notice Creates `_amnt` tokens and assigns them to `_to`, increasing
     * the total supply.
     * @dev Emits a {Transfer} event with `from` set to the zero address.
     * Requirements:
     * - `to` cannot be the zero address.
     * @param _to The destination address
     * @param _amnt The amount of tokens to be minted
     */
    function mint(address _to, uint256 _amnt) external override onlyOwner {
        _mint(_to, _amnt);
    }

    /**
     * @notice Destroys `_amnt` tokens from `_from`, reducing the
     * total supply.
     * @dev Emits a {Transfer} event with `to` set to the zero address.
     * Requirements:
     * - `_from` cannot be the zero address.
     * - `_from` must have at least `_amnt` tokens.
     * @param _from The address from which to destroy the tokens
     * @param _amnt The amount of tokens to be destroyed
     */
    function burn(address _from, uint256 _amnt) external override onlyOwner {
        _burn(_from, _amnt);
    }

    // ============ ERC 20 ============

    /**
     * @dev Returns the name of the token.
     */
    function name() public view override returns (string memory) {
        return token.name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view override returns (string memory) {
        return token.symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view override returns (uint8) {
        return token.decimals;
    }

    // ============ EIP-2612 support ============
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    mapping(address => uint256) internal _nonces;

    function nonces(address _owner) external view override returns (uint256) {
        return _nonces[_owner];
    }

    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) external override {
        require(_deadline >= block.timestamp, "ERC20Permit: expired deadline");
        bytes32 _hashStruct = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                _owner,
                _spender,
                _value,
                _nonces[_owner]++,
                _deadline
            )
        );
        bytes32 _digest = keccak256(
            abi.encodePacked(hex"1901", DOMAIN_SEPARATOR(), _hashStruct)
        );
        address _signer = ecrecover(_digest, _v, _r, _s);
        require(
            _signer != address(0) && _signer == _owner,
            "ERC20Permit: invalid signature"
        );
        _approve(_owner, _spender, _value);
    }

    function DOMAIN_SEPARATOR() public view override returns (bytes32) {
        uint256 _chainId;
        assembly {
            _chainId := chainid()
        }

        return
            keccak256(
                abi.encode(
                    keccak256(
                        "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                    ),
                    keccak256(bytes(token.name)),
                    keccak256(bytes(VERSION)),
                    _chainId,
                    address(this)
                )
            );
    }
}
