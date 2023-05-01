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

    struct Deposit {
        uint amount;
        uint tierId;
        uint timestamp;
    }
    PiggyToken public token;
    PiggyBankTier[] _tiers;

    mapping(uint => PiggyBankTier) public tiers;
    mapping(address => Deposit) public deposits;
    mapping(uint => uint) public tokenIdTotierId;
    mapping(address => mapping(uint => bool)) public isActive;

    constructor(address _token) ERC721("") {
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

    function deposit(uint _amount, uint _tierId) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(tiers[_tierId].lockingPeriod > 0, "Invalid tier");
        require(
            token.transferFrom(winneraddress[], address(this), _amount),
            "Transfer failed"
        );

        deposits[msg.sender] = Deposit(_amount, _tierId, block.timestamp);
    }

    function cashOut(uint _tokenId) external {
        Deposit storage depo = deposits[msg.sender];
        require(depo.amount > 0, "No deposit found");

        uint tierId = tokenIdTotierId[_tokenId];

        PiggyBankTier storage tier = tiers[tierId];
        uint elapsed = block.timestamp - depo.timestamp;
        require(elapsed >= tier.lockingPeriod, "Tokens are still locked");

        uint bonusAmount = (depo.amount * tier.bonusPercentage) / 1000;
        uint withdrawAmount = depo.amount + bonusAmount;

        // IERC20 token = IERC20(); //piggyytoken address
        require(token.transfer(msg.sender, withdrawAmount), "Transfer failed");

        depo.amount = 0;
        _burn(msg.sender, _tokenId, depo.amount);
    }
}

contract JackpotNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Deposit {
        uint amount;
        uint timestamp;
    }

    PiggyToken public token;
    mapping(address => Deposit) public deposits;

    event JackpotNFTCreated(address owner, uint tokenId);

    constructor() ERC721("") {}

    function mintJackpotkNFT() external {
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        isActive[msg.sender][newTokenId] = true;

        // emit JacpotNFTCreated(newTokenId);
    }

    function deposit(uint _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            token.transferFrom(uplineaddress[], address(this), _amount),
            "Transfer failed"
        );

        deposits[msg.sender] = Deposit(_amount, block.timestamp);
    }
}

contract SpecialNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Deposit {
        uint amount;
        uint timestamp;
    }

    PiggyToken public token;
    mapping(address => Deposit) public deposits;

    event SpecialNFTCreated(address owner, uint tokenId);

    constructor() ERC721("") {}

    function mintSpecialNFT() external {
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);
        isActive[msg.sender][newTokenId] = true;

        // emit SpecialNFTCreated(newTokenId);
    }

    function deposit(uint _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        require(
            token.transferFrom(owner, address(this), _amount),
            "Transfer failed"
        );

        deposits[msg.sender] = Deposit(_amount, block.timestamp);
    }
}
