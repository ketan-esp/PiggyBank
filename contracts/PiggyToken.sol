// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PiggyToken is ERC20, Ownable {
    // Addresses
    address public treasuryWallet; // The address of the treasury wallet
    address public auctionPlatform; // The address of the auction platform

    // Token details
    uint256 public constant INITIAL_SUPPLY = 21000000 * (10 ** 18); // Total supply of 21M tokens
    uint256 public tokensPerAuction; // Amount of tokens dedicated to each auction

    // Percentages
    uint256 public burnPercentage; // Percentage of tokens burned in each auction
    uint256 public treasuryPercentage; // Percentage of tokens sent to the treasury in each auction
    uint256 public winnerPercentage; // Percentage of tokens sent to the winner/s in each auction
    uint256 public piggyBankPercentage; // Percentage of tokens locked in the piggy bank NFT in each auction

    // Events
    event AuctionEnded(
        address indexed winner,
        uint256 tokensSent,
        uint256 tokensLocked
    );

    constructor() ERC20("Piggy Bank Token", "PBT") {
        _mint(msg.sender, INITIAL_SUPPLY);
        treasuryWallet = msg.sender;
    }

    function setAuctionPlatform(address _auctionPlatform) external onlyOwner {
        auctionPlatform = _auctionPlatform;
    }

    function setTreasuryWallet(address _treasuryWallet) external onlyOwner {
        treasuryWallet = _treasuryWallet;
    }

    function setTokensPerAuction(uint256 _tokensPerAuction) external onlyOwner {
        tokensPerAuction = _tokensPerAuction;
    }

    function setBurnPercentage(uint256 _burnPercentage) external onlyOwner {
        burnPercentage = _burnPercentage;
    }

    function setTreasuryPercentage(
        uint256 _treasuryPercentage
    ) external onlyOwner {
        treasuryPercentage = _treasuryPercentage;
    }

    function setWinnerPercentage(uint256 _winnerPercentage) external onlyOwner {
        winnerPercentage = _winnerPercentage;
    }

    function setPiggyBankPercentage(
        uint256 _piggyBankPercentage
    ) external onlyOwner {
        piggyBankPercentage = _piggyBankPercentage;
    }

    function endAuction(address winner, uint256 tokensSent) external {
        require(
            msg.sender == auctionPlatform,
            "Only the auction platform can end an auction"
        );
        require(
            tokensSent <= tokensPerAuction,
            "Cannot send more tokens than dedicated to this auction"
        );

        uint256 burnAmount = (tokensSent * burnPercentage) / 100;
        uint256 treasuryAmount = (tokensSent * treasuryPercentage) / 100;
        uint256 winnerAmount = (tokensSent * winnerPercentage) / 100;
        uint256 piggyBankAmount = (tokensSent * piggyBankPercentage) / 100;

        // Send tokens to winner
        _transfer(address(this), winner, winnerAmount);

        // Send tokens to treasury wallet
        _transfer(address(this), treasuryWallet, treasuryAmount);

        // Send tokens to burning address
        _burn(address(this), burnAmount);

        // Send tokens to piggy bank NFT
        uint256 tokensLocked = (winnerAmount * piggyBankPercentage) / 100;
        uint256 tokensSentToWinner = winnerAmount - tokensLocked;
        _transfer(address(this), winner, tokensSentToWinner);
        emit AuctionEnded(winner, tokensSentToWinner, tokensLocked);
    }
}
