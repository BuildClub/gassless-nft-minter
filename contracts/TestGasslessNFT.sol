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
    mapping(address => uint256[]) private _userIds;
    mapping(uint256 => uint8) private _userIdIndex;
    uint8 public immutable MAX_MINT;

    constructor(uint8 maxMint) ERC721("TestGasslessNFT", "TGN") {
        MAX_MINT = maxMint;
    }

    function userList() public view returns (string[] memory) {
        uint256[] memory userIds = _userIds[_msgSender()];
        uint8 length = uint8(userIds.length);

        string[] memory images = new string[](length);

        if (length == 0) return images;

        for (uint8 i = 0; i <= length - 1; i++) {
            images[i] = tokenURI(userIds[i]);
        }
        return images;
    }

    function mint() public {
        require(
            _userIds[_msgSender()].length < MAX_MINT,
            "TestGasslessNFT: Max amount exceed"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _userIds[_msgSender()].push(tokenId);
        _userIdIndex[tokenId] = uint8(_userIds[_msgSender()].length - 1);
        _safeMint(_msgSender(), tokenId);
    }

    function burn(uint256 tokenId) public override {
        address owner = ERC721.ownerOf(tokenId);

        uint256[] storage userIds = _userIds[owner];
        uint8 index = _userIdIndex[tokenId];

        require(index < userIds.length, "TestGasslessNFT: Index exceed");

        for (uint8 i = index; i < userIds.length - 1; i++) {
            userIds[i] = userIds[i + 1];
        }
        userIds.pop();

        super.burn(tokenId);
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
                    abi.encodePacked(
                        baseURI,
                        Strings.toHexString(
                            uint256(
                                keccak256(abi.encodePacked(tokenId.toString()))
                            ),
                            32
                        ),
                        "/400/500"
                    )
                )
                : "";
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://picsum.photos/seed/";
    }
}
