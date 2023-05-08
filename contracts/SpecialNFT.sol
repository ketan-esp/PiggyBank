// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PiggyToken.sol";

/**
@title SpecialNFT
@dev Implements a special ERC721 Non-Fungible Token with the ability to lock funds
*/

contract SpecialNFT is ERC721, Ownable, ERC721Burnable, ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    /**
@dev Represents a single lock on an NFT
*/

    struct Lock {
        address user;
        uint lockingPeriod;
        uint bonusPercentage;
        uint amount;
        uint startTime;
        bool isCompleted;
    }

    PiggyToken public token;
    mapping(uint => Lock) public locks;

    event SpecialNFTCreated(address owner, uint tokenId);

    /**
@dev Initializes the contract with a PiggyToken instance
@param _token The address of PiggyToken contract
*/

    constructor(address _token) ERC721("SpecialNFT", "SNFT") {
        token = PiggyToken(_token);
    }

    /**
@dev Mints a new special NFT
@param _paymentContract The address of the payment contract to receive the NFT
@param uri The URI of the token metadata
*/

    function mintSpecialNFT(
        address _paymentContract,
        string memory uri
    ) external {
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _safeMint(_paymentContract, newTokenId);
        _setTokenURI(newTokenId, uri);

        emit SpecialNFTCreated(_paymentContract, newTokenId);
    }

    /**
@dev Locks funds for a specific NFT
@param _user The address of the user who is locking the funds
@param _amount The amount of funds to be locked
@param _nftId The ID of the NFT
@param _lockingPeriod The duration for which funds will be locked
@param _bonusPercentage The percentage of bonus to be given after the locking period
*/
    function lock(
        address _user,
        uint _amount,
        uint _nftId,
        uint _lockingPeriod,
        uint _bonusPercentage
    ) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(_lockingPeriod > 0, "Locking period cannot be 0");

        locks[_nftId] = Lock(
            _user,
            _amount,
            _lockingPeriod,
            _bonusPercentage,
            block.timestamp,
            false
        );
    }

    /**
@dev Withdraws locked funds for a specific NFT
@param _tokenId The ID of the NFT
*/
    function cashOut(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");

        Lock storage depo = locks[_tokenId];
        require(depo.amount > 0, "No deposit found");
        require(!depo.isCompleted, "Already cashed out");

        uint elapsed = block.timestamp - depo.startTime;
        require(elapsed > depo.lockingPeriod, "Tokens are still locked");

        uint bonusAmount = (depo.amount * depo.bonusPercentage) / 100;
        uint withdrawAmount = depo.amount + bonusAmount;
        require(
            token.balanceOf(address(this)) >= withdrawAmount,
            "Insufficient balance"
        );

        token.transfer(msg.sender, withdrawAmount);

        depo.isCompleted = true;
        _burn(_tokenId);
    }

    function getBalanceByTokenId(uint _tokenId) public view returns (uint) {
        Lock storage depo = locks[_tokenId];
        require(depo.amount > 0, "No deposit found");
        uint elapsed = block.timestamp - depo.startTime;
        uint bonusAmount = 0;
        if (elapsed > depo.lockingPeriod) {
            bonusAmount = (depo.amount * depo.bonusPercentage) / 100;
            bonusAmount += depo.amount;
        } else {
            bonusAmount = depo.amount;
        }
        return bonusAmount;
    }

    //override functions
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

    //withdraw function
    function withdraw(uint _amount) public onlyOwner {
        require(
            token.balanceOf(address(this)) > _amount,
            "Insufficient funds in contract"
        );
        token.transfer(msg.sender, _amount);
    }
}
