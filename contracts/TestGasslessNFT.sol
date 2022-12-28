// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract TestGasslessNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;

    Counters.Counter private _tokenIdCounter;
    mapping(address => uint256[]) private _userIds;
    mapping(uint256 => uint8) private _userIdIndex;
    uint8 public immutable MAX_MINT;

    struct UserData {
        uint256[] tokenIds;
        string[] images;
    }

    constructor(uint8 maxMint) ERC721("TestGasslessNFT", "TGN") {
        MAX_MINT = maxMint;
    }

    function userList() public view returns (UserData memory) {
        uint256[] memory userIds = _userIds[_msgSender()];
        uint8 length = uint8(userIds.length);

        uint256[] memory tokenIds = new uint256[](length);
        string[] memory images = new string[](length);

        UserData memory data = UserData(tokenIds, images);

        if (length == 0) return data;

        for (uint8 i = 0; i <= length - 1; i++) {
            data.tokenIds[i] = userIds[i];
            data.images[i] = tokenURI(userIds[i]);
        }
        return data;
    }

    function mint(string memory tokenURI) public {
        require(
            _userIds[tx.origin].length < MAX_MINT,
            "TestGasslessNFT: Max amount exceed"
        );
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _userIds[tx.origin].push(tokenId);
        _userIdIndex[tokenId] = uint8(_userIds[tx.origin].length - 1);
        _mint(tx.origin, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function burn(uint256 tokenId) public {
        address owner = ERC721.ownerOf(tokenId);

        uint256[] storage userIds = _userIds[owner];
        uint8 index = _userIdIndex[tokenId];

        require(index < userIds.length, "TestGasslessNFT: Index exceed");

        for (uint8 i = index; i < userIds.length - 1; i++) {
            userIds[i] = userIds[i + 1];
        }
        userIds.pop();

        require(
            _isApprovedOrOwner(tx.origin, tokenId),
            "ERC721: caller is not token owner or approved"
        );
        _burn(tokenId);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return "https://gateway.pinata.cloud/ipfs/";
    }
}
