// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Factory is ERC721, ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    //NFT structure
    struct NFT {
        string name;
        string symbol;
        string imageURI;
        uint jackpot;
        bool locked;
    }

    //Jackpot auction
    struct Auction {
        uint tokenId;
        uint startingPrice;
        uint endTime;
    }

    //Token locking
    struct Lock {
        uint tokenId;
        uint lockTime;
    }

    mapping(uint => NFT) private nfts;
    mapping(uint => Auction) private auctions;
    mapping(address => Lock) private locks;

    constructor() ERC721("Piggy Banks", "PB") {}

    function createNFT(
        string memory _name,
        string memory _symbol,
        string memory _imageURI
    ) public onlyOwner returns (uint) {
        _tokenIds.increment();

        uint newTokenId = _tokenIds.current();
        _mint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, _imageURI);

        nfts[newTokenId] = NFT(_name, _symbol, _imageURI, 0, false);

        return newTokenId;
    }

    function createJackpotNFT(
        string memory _name,
        string memory _symbol,
        string memory _imageURI,
        uint jackpot
    ) public onlyOwner returns (uint) {
        uint tokenId = createNFT(_name, _symbol, _imageURI);
        nfts[tokenId].jackpot = jackpot;
        return tokenId;
    }

    function startAuction(
        uint _tokenId,
        uint _startingPrice,
        uint duration
    ) public onlyOwner {
        require(_exists(_tokenId), "token does not exist");
        require(nfts[_tokenId].jackpot > 0, "not a jackpot nft");
        uint _endTime = block.timestamp + duration;
        auctions[_tokenId] = Auction(_tokenId, _startingPrice, _endTime);
    }

    function getNFT(uint _tokenId) public view returns (NFT memory) {
        require(_exists(_tokenId), "token does not exist");
        return nfts[_tokenId];
    }

    function bid(uint tokenId) public payable {
        require(
            auctions[tokenId].endTime > block.timestamp,
            "auction has ended"
        );
        require(
            msg.value >= auctions[tokenId].startingPrice,
            "price cannot be less than starting price"
        );
        address payable NFTowner = payable(ownerOf(tokenId));
        NFTowner.transfer(msg.value);
        _transfer(NFTowner, msg.sender, tokenId);
        delete auctions[tokenId];
    }

    function createLock(uint _tokenId, uint duration) public {
        require(_exists(_tokenId), "token does not exist");
        require(ownerOf(_tokenId) == msg.sender, "caller is not owner");
        uint _lockTime = block.timestamp + duration;
        locks[msg.sender] = Lock(_tokenId, _lockTime);
    }

    //Override functions

    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        super._burn(tokenId);
    }

    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }
}
