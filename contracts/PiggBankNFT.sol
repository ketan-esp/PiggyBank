// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract PiggyBankNFT is ERC1155, Ownable, ERC1155Burnable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    struct PiggyBankTier {
        string name;
        uint lockingPeriod;
        uint bonusPercentage;
    }

    //mapping(uint => PiggyBankTier) public tiers;
    mapping(uint => uint) private tokenTier;
    mapping(address => mapping(uint => uint)) public balances;
    mapping(address => mapping(uint => bool)) public isActive;

    event PiggyBankNFTCreated(address owner, uint tokenId, string tierName);

    PiggyBankTier[] public tiers;

    constructor() ERC1155("") {}

    function createPiggyBankNFT(
        uint _tier,
        uint _quantity,
        bytes memory _data
    ) external {
        PiggyBankTier storage tier = tiers[_tier];
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        uint quantity = _quantity;
        bytes memory data = _data;
        _mint(msg.sender, newTokenId, quantity, data);
        tokenTier[newTokenId] = _tier;
        isActive[msg.sender][newTokenId] = true;

        emit PiggyBankNFTCreated(msg.sender, newTokenId, tier.name);
    }

    function setTiers(
        uint _tier,
        string memory _name,
        uint _lockingPeriod,
        uint _bonusPercentage
    ) external onlyOwner {
        tiers[_tier] = PiggyBankTier({
            name: _name,
            lockingPeriod: _lockingPeriod,
            bonusPercentage: _bonusPercentage
        });
    }

    function getTier(uint _tokenId) public view returns (uint) {
        uint tierIndex = tokenTier[_tokenId];
        PiggyBankTier storage tier = tiers[tierIndex];
        return tier.lockingPeriod;
    }

    function cashOut(uint _tokenId) external {
        require(balances[msg.sender][_tokenId] > 0, "No balance in piggy bank");
        require(isLocked(_tokenId) != true, "NFT is locked");

        uint amount = balances[msg.sender][_tokenId];
        balances[msg.sender][_tokenId] = 0;

        _burn(msg.sender, _tokenId, 1);
        payable(msg.sender).transfer(amount);
    }

    function isLocked(uint _tokenId) public view returns (uint) {
        require(balanceOf(msg.sender, _tokenId) > 0, "Invalid token id");
        uint tierIndex = tokenTier[_tokenId];
        PiggyBankTier storage tier = tiers[tierIndex];
        return tier.lockingPeriod;
    }

    function deposit(uint _tokenId, uint _amount) external {
        require(isActive[msg.sender][_tokenId], "Inactive piggy bank");
        require(_amount > 0, "amount must be greater than 0");

        balances[msg.sender][_tokenId] += _amount;
    }
}

contract JackpotNFT is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => mapping(uint => bool)) public isActive;
    mapping(address => mapping(uint => uint)) public balances;

    event JackpotNFTCreated(address owner, uint tokenId);

    constructor() ERC1155("") {}

    function createJackpotNFT(uint _quantity, bytes memory _data) external {
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        uint quantity = _quantity;
        bytes memory data = _data;
        _mint(msg.sender, newTokenId, quantity, data);
        isActive[msg.sender][newTokenId] = true;

        emit JackpotNFTCreated(msg.sender, newTokenId);
    }

    function deposit(uint _tokenId, uint _amount) external {
        require(isActive[msg.sender][_tokenId], "Inactive piggy bank");
        require(_amount > 0, "amount must be greater than 0");

        balances[msg.sender][_tokenId] += _amount;
    }
}

contract SpecialNFT is ERC1155 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    mapping(address => mapping(uint => bool)) public isActive;
    mapping(address => mapping(uint => uint)) public balances;

    event SpecialNFTCreated(address owner, uint tokenId);

    constructor() ERC1155("") {}

    function createSpecialNFT(uint _quantity, bytes memory _data) external {
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        uint quantity = _quantity;
        bytes memory data = _data;
        _mint(msg.sender, newTokenId, quantity, data);
        isActive[msg.sender][newTokenId] = true;

        emit SpecialNFTCreated(msg.sender, newTokenId);
    }

    function deposit(uint _tokenId, uint _amount) external {
        require(isActive[msg.sender][_tokenId], "Inactive piggy bank");
        require(_amount > 0, "amount must be greater than 0");

        balances[msg.sender][_tokenId] += _amount;
    }
}
