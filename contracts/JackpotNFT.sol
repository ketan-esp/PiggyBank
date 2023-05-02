// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./PiggyToken.sol";

contract JackpotNFT is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    struct Lock {
        address user;
        uint lockingPeriod;
        uint bonusPercentage;
        uint amount;
        uint startTime;
        bool isCompleted;
    }

    IERC20 public token;
    mapping(uint => Lock) public locks;

    event JackpotNFTCreated(address owner, uint tokenId);

    constructor(IERC20 _token) ERC721("JackpotNFT", "Jp") {
        token = _token;
    }

    function mintJackpotkNFT() external {
        _tokenIds.increment();
        uint newTokenId = _tokenIds.current();
        _safeMint(msg.sender, newTokenId);

        // emit JacpotNFTCreated(newTokenId);
    }

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
            "Insufficient funds"
        );

        token.transfer(msg.sender, withdrawAmount);

        depo.isCompleted = true;
        _burn(_tokenId);
    }
}
