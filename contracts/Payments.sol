// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "./PiggyBankNFT.sol";
import "./PiggyToken.sol";
import "./JackpotNFT.sol";
import "./SpecialNFT.sol";

contract Payments is Ownable, ERC721Holder {
    address[] public winnerAddress;
    uint[] public winnerAmount;

    uint public receivedBidAmount;
    uint public nftID;
    uint public lockingPeriod;
    uint public bonusPercentage;

    PiggyToken public token;
    PiggyBankNFT public piggyNFT;
    JackpotNFT public jackpotNFT;
    SpecialNFT public specialNFT;

    event BidReceived(address bidder, uint amount);
    event TransferCompleted(address _from, uint _amount);

    constructor(
        address _token,
        address _piggyNFT,
        address _jackpotNFT,
        address _specialNFT
    ) {
        token = PiggyToken(_token);
        piggyNFT = PiggyBankNFT(_piggyNFT);
        jackpotNFT = JackpotNFT(_jackpotNFT);
        specialNFT = SpecialNFT(_specialNFT);
        winnerAddress = new address[](0);
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

    function transferWinnerPayments(
        address[] memory _winnerAddress,
        uint[] memory _winnerAmount,
        uint _burnAmount,
        uint _treasuryAmount,
        address _treasuryAddress,
        address _piggyBankNFT,
        uint[] memory _piggyBankNFTId,
        uint _lockPercentage
    ) external onlyOwner {
        require(_winnerAddress.length == _winnerAmount.length, "Invalid array");

        token.burn(_burnAmount);
        token.transfer(_treasuryAddress, _treasuryAmount);

        for (uint i = 0; i < _winnerAddress.length; i++) {
            uint lockAmount = (_winnerAmount[i] * _lockPercentage) / 100;
            token.transfer(_winnerAddress[i], _winnerAmount[i] - lockAmount);
            token.transfer(_piggyBankNFT, lockAmount);
            piggyNFT.lock(_winnerAddress[i], lockAmount, _piggyBankNFTId[i]);
        }
    }

    function transferUplinePayments(
        address[] memory uplineAddress,
        uint[] memory uplineAmount,
        bool[] memory isActive,
        uint _nftID,
        uint _lockingPeriod,
        uint _bonusPercentage,
        address _jackpotNFT
    ) external {
        require(uplineAddress.length == uplineAmount.length, "Invalid array");
        for (uint i = 0; i < uplineAddress.length; i++) {
            if (isActive[i]) {
                token.transfer(uplineAddress[i], uplineAmount[i]);
            } else {
                token.transfer(_jackpotNFT, uplineAmount[i]);
                jackpotNFT.lock(
                    uplineAddress[i],
                    uplineAmount[i],
                    _nftID,
                    _lockingPeriod,
                    _bonusPercentage
                );
            }
            // jackpotNFT.transferFrom(address(this), _winnerAddress[i], nftID);
        }
    }

    function transferToSpecialNFT(
        address _specilaNFT,
        uint _tokenId,
        uint _amount,
        uint _lockingPercentage,
        address winner,
        uint _nftID,
        uint _lockingPeriod,
        uint _bonusPercentage
    ) external payable onlyOwner {
        uint lockAmount = (_amount * _lockingPercentage) / 100;
        token.transfer(_specilaNFT, lockAmount);
        specialNFT.lock(
            msg.sender,
            lockAmount,
            _nftID,
            _lockingPeriod,
            _bonusPercentage
        );
        //specialNFT.transferFrom(address(this), winner, _tokenId);
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
