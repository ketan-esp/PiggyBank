// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "./PiggyBankNFT.sol";
import "./PiggyToken.sol";

interface IJackpotNFT is IERC721 {
    function mintJackpotkNFT() external;

    function lock(
        address _user,
        uint _amount,
        uint _nftId,
        uint _lockingPeriod,
        uint _bonusPercentage
    ) external;

    function cashOut(uint _tokenId) external;

    function token() external view returns (IERC20);

    function locks(
        uint
    ) external view returns (address, uint, uint, uint, uint, bool);

    function ownerOf(uint256 tokenId) external view returns (address);
}

interface ISpecialNFT is IERC721 {
    function mintSpecialNFT() external;

    function lock(
        address user,
        uint amount,
        uint nftId,
        uint lockingPeriod,
        uint bonusPercentage
    ) external;

    function cashOut(uint tokenId) external;

    function token() external view returns (IERC20);

    function locks(
        uint nftId
    )
        external
        view
        returns (
            address user,
            uint lockingPeriod,
            uint bonusPercentage,
            uint amount,
            uint startTime,
            bool isCompleted
        );
}

contract Payments is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private auctiontId;

    address[] public winnerAddress;

    bool public started;
    bool public ended;
    uint public numberOfTokensPerAuction;
    uint public endAt;
    uint public receivedBidAmount;
    uint public nftID;
    uint public lockingPeriod;
    uint public bonusPercentage;

    PiggyToken public token;
    PiggyBankNFT public nft;
    IJackpotNFT public jackpotNFT;
    ISpecialNFT public specialNFT;

    event BidReceived(address bidder, uint amount);
    event TransferCompleted(address _from, uint _amount);

    constructor(address _token) public {
        token = PiggyToken(_token);
    }

    function bid(uint bidAmount) external {
        require(bidAmount > 0, "Bid amount must be greter than 0");
        require(
            bidAmount <= token.balanceOf(msg.sender),
            "Insufficient funds for bid"
        );
        require(
            bidAmount <= token.allowance(msg.sender, address(this)),
            "Insufficient allowance for transfer"
        );
        token.transferFrom(msg.sender, address(this), bidAmount);
        receivedBidAmount += bidAmount;

        emit BidReceived(msg.sender, bidAmount);
    }

    function sum(uint[] memory arr) private view returns (uint) {
        uint result = 0;
        for (uint i = 0; i < arr.length; i++) {
            result += arr[i];
        }
        return result;
    }

    function transferPayments(
        address[] memory _winnerAddress,
        uint[] memory _winnerAmount,
        uint _burnAmount,
        uint _treasuryAmount,
        address _treasuryAddress,
        bool[] memory _isActive,
        address _piggyBankNFT,
        uint[] memory _piggyBankNFTId,
        address _jackpotNFT,
        uint _lockPercentage
    ) external payable onlyOwner {
        require(
            _burnAmount + _treasuryAmount + sum(_winnerAmount) == 100,
            "Total cannot be more than 100"
        );
        require(_winnerAddress.length == _winnerAmount.length, "Invalid array");
        require(_winnerAddress.length == _isActive.length, "Invalid array");
        token.burn(_burnAmount);
        token.transfer(_treasuryAddress, _treasuryAmount);
        for (uint i = 0; i < _winnerAddress.length; i++) {
            if (_isActive[i]) {
                uint lockAmount = (_winnerAmount[i] * _lockPercentage) / 10000;

                token.transfer(
                    _winnerAddress[i],
                    _winnerAmount[i] - lockAmount
                );
                token.transfer(_piggyBankNFT, lockAmount);
                nft.lock(_winnerAddress[i], lockAmount, _piggyBankNFTId[i]);
            } else {
                token.transfer(_jackpotNFT, _winnerAmount[i]);
                jackpotNFT.lock(
                    _winnerAddress[i],
                    _winnerAmount[i],
                    nftID,
                    lockingPeriod,
                    bonusPercentage
                );
            }
        }

        emit TransferCompleted(msg.sender, msg.value);
    }

    function transferToSpecialNFT(
        address _specilaNFT,
        uint _tokenId,
        uint _amount,
        uint _lockingPercentage,
        address winner
    ) external payable onlyOwner {
        uint lockAmount = (_amount * _lockingPercentage) / 10000;
        token.transfer(_specilaNFT, lockAmount);
        specialNFT.transferFrom(msg.sender, winner, _tokenId);
        specialNFT.lock(
            msg.sender,
            lockAmount,
            nftID,
            lockingPeriod,
            bonusPercentage
        );
    }
}
