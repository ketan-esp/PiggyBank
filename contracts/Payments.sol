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

/**
@title Payments
@dev The Payments contract facilitates the transfer of payments and rewards for different NFTs
using the PiggyToken ERC20 token.
*/

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

    event DepositReceived(address bidder, uint amount);
    event TransferCompleted(address _from, uint _amount);

    /**
@dev Creates a new Payments instance.
@param _token The address of the PiggyToken ERC20 token.
@param _piggyNFT The address of the PiggyBankNFT contract.
@param _jackpotNFT The address of the JackpotNFT contract.
@param _specialNFT The address of the SpecialNFT contract.
*/

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

    /**
@dev Allows users to deposit for NFTs using the PiggyToken ERC20 token.
@param amount The amount of PiggyToken to bid.
*/

    function deposit(uint amount) external {
        require(amount > 0, "Bid amount must be greter than 0");
        require(
            amount <= token.balanceOf(msg.sender),
            "Insufficient funds for bid"
        );
        require(
            amount <= token.allowance(msg.sender, address(this)),
            "Insufficient allowance for transfer"
        );
        token.transferFrom(msg.sender, address(this), amount);
        receivedBidAmount += amount;

        emit DepositReceived(msg.sender, amount);
    }

    /**
@dev Function to transfer winner payments
@param _winnerAddress The addresses of the winners
@param _winnerAmount The amounts to be transferred to each winner
@param _burnAmount The amount of tokens to be burned
@param _treasuryAmount The amount of tokens to be transferred to the treasury
@param _treasuryAddress The address of the treasury
@param _piggyBankNFT The address of the PiggyBankNFT contract
@param _piggyBankNFTId The IDs of the PiggyBankNFTs to be locked
@param _lockPercentage The percentage of tokens to be locked in PiggyBankNFTs
*/

    function transferWinnerPayments(
        address[] memory _winnerAddress,
        uint[] memory _winnerAmount,
        uint _burnAmount,
        uint _treasuryAmount,
        address _treasuryAddress,
        address _piggyBankNFT,
        uint[] memory _piggyBankNFTId,
        uint[] memory _lockPercentage
    ) external onlyOwner {
        require(_winnerAddress.length == _winnerAmount.length, "Invalid array");
        require(
            _winnerAddress.length == _lockPercentage.length,
            "Invalid array"
        );

        token.burn(_burnAmount);
        token.transfer(_treasuryAddress, _treasuryAmount);

        for (uint i = 0; i < _winnerAddress.length; i++) {
            uint lockAmount = (_winnerAmount[i] * _lockPercentage[i]) / 100;
            token.transfer(_winnerAddress[i], _winnerAmount[i] - lockAmount);
            token.transfer(_piggyBankNFT, lockAmount);
            piggyNFT.lock(_winnerAddress[i], lockAmount, _piggyBankNFTId[i]);
        }
    }

    /**
@dev Function to transfer upline payments
@param uplineAddress The addresses of the winners
@param uplineAmount The amounts to be transferred to each winner
@param isActive Checks if a particular address is active or not
@param _jackpotNFTId The ID of the JackpotNFT to be locked
@param _lockingPeriod The duration for which funds will be locked
@param _bonusPercentage The percentage of bonus to be given after the locking period
@param _jackpotNFT address of jackpot nft contract
*/

    function transferUplinePayments(
        address[] memory uplineAddress,
        uint[] memory uplineAmount,
        uint[] memory _piggyBankNFTId,
        uint[] memory _lockPercentage,
        address _piggyBankNFT,
        bool[] memory isActive,
        uint _jackpotNFTId,
        uint _lockingPeriod,
        uint _bonusPercentage,
        address _jackpotNFT
    ) external onlyOwner {
        require(uplineAddress.length == uplineAmount.length, "Invalid array");
        require(
            uplineAddress.length == _lockPercentage.length,
            "Invalid array"
        );
        for (uint i = 0; i < uplineAddress.length; i++) {
            if (isActive[i]) {
                uint lockAmount = (uplineAmount[i] * _lockPercentage[i]) / 100;
                token.transfer(uplineAddress[i], uplineAmount[i] - lockAmount);
                token.transfer(_piggyBankNFT, lockAmount);
                piggyNFT.lock(uplineAddress[i], lockAmount, _piggyBankNFTId[i]);
            } else {
                token.transfer(_jackpotNFT, uplineAmount[i]);
                jackpotNFT.lock(
                    uplineAddress[i],
                    uplineAmount[i],
                    _jackpotNFTId,
                    _lockingPeriod,
                    _bonusPercentage
                );
            }
            // jackpotNFT.transferFrom(address(this), _winnerAddress[i], nftID);
        }
    }

    /**
@dev Function to transfer funds to special NFT
@param _specialNFT The addresses of the NFT
@param _amount Amount of piggy tokens to be locked
@param _lockingPercentage The percentage of tokens to be locked in special NFT
@param winner address of auction winner
@param _nftID The ID of the special nft in which funds are to be locked
@param _lockingPeriod The duration for which funds will be locked
@param _bonusPercentage The percentage of bonus to be given after the locking period
*/

    function transferToSpecialNFT(
        address _specialNFT,
        uint _amount,
        uint _lockingPercentage,
        address winner,
        uint _nftID,
        uint _lockingPeriod,
        uint _bonusPercentage
    ) external payable onlyOwner {
        uint lockAmount = (_amount * _lockingPercentage) / 100;
        token.transfer(_specialNFT, lockAmount);
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
