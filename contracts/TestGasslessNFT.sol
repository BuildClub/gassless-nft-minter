// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TestGasslessNFT is ERC721Burnable, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    mapping(address => uint8) private _userCounts;
    uint8 public immutable MAX_MINT;

    constructor(uint8 maxMint) ERC721("TestGasslessNFT", "TGN") {
        MAX_MINT = maxMint;
    }

    function mint() public {
        require(
            _userCounts[_msgSender()] == MAX_MINT,
            "TestGasslessNFT: Max amount exceed"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _userCounts[_msgSender()]++;
        _safeMint(_msgSender(), tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(
                    abi.encodePacked(baseURI, tokenId.toString(), "400/500")
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://picsum.photos/seed/";
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal virtual override {
        require(to == address(0), "Err: token transfer is BLOCKED");
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }
}
