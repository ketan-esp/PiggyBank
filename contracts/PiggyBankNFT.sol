// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/utils/Counters.sol";
import "./PiggyToken.sol";

contract PiggyBankNFT is ERC721, Ownable, ERC721Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct PiggyBankTier {
        uint lockingPeriod;
        uint bonusPercentage;
    }

    struct Lock {
        address user;
        uint amount;
        uint lockingPeriod;
        uint bonusPercentage;
        uint startTime;
        bool isCompleted;
    }

    PiggyToken public token;

    mapping(uint => PiggyBankTier) public tiers;
    mapping(uint => Lock) public locks;
    mapping(uint => uint) public tokenIdTotierId;
    mapping(address => mapping(uint => bool)) public isActive;

    constructor(address _token) ERC721("PiggyBankNFT", "PB") {
        token = PiggyToken(_token);
    }

    function setTiers(
        uint _tierId,
        uint _lockingPeriod,
        uint _bonusPercentage
    ) external onlyOwner {
        require(_lockingPeriod > 0, "Locking period must be greater than 0");
        require(tiers[_tierId].lockingPeriod == 0, "Tier id already exists");
        tiers[_tierId] = PiggyBankTier(_lockingPeriod, _bonusPercentage);
    }

    function mintPiggyBankNFT(uint _tierId) external {
        require(tiers[_tierId].lockingPeriod > 0, "Invalid tier");
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        tokenIdTotierId[newTokenId] = _tierId;
        isActive[msg.sender][newTokenId] = true;

        // emit PiggyBankNFTCreated(msg.sender, newTokenId, _tierId);
    }

    function lock(address _user, uint _amount, uint _nftId) external {
        require(_amount > 0, "Amount must be greater than 0");
        uint _tierId = tokenIdTotierId[_nftId];
        require(tiers[_tierId].lockingPeriod > 0, "Invalid tier");

        locks[_nftId] = Lock(
            _user,
            _amount,
            tiers[_tierId].lockingPeriod,
            tiers[_tierId].bonusPercentage,
            block.timestamp,
            false
        );
    }

    function cashOut(uint _tokenId) external {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner");

        Lock storage depo = locks[_tokenId];
        require(depo.amount > 0, "No deposit found");
        require(!depo.isCompleted, "Already cashed out");

        uint elapsed = block.timestamp - depo.startTime;
        require(elapsed > depo.lockingPeriod, "Tokens are still locked");

        uint bonusAmount = (depo.amount * depo.bonusPercentage) / 10000;
        uint withdrawAmount = depo.amount + bonusAmount;
        require(
            token.balanceOf(address(this)) >= withdrawAmount,
            "Insufficient funds in NFT locking pool"
        );

        token.transfer(msg.sender, withdrawAmount);

        depo.isCompleted = true;
        _burn(_tokenId);
    }
}
