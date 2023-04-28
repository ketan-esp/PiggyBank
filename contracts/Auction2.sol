// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./PiggBankNFT.sol";

contract Auction is Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private auctiontId;

    address public treasuryAddress;
    address public holdingAddress;
    address private constant burnAddress = address(0);

    bool public started;
    bool public ended;

    uint public numberOfTokensPerAuction;
    uint public endAt;
    uint public receivedBidAmount;

    PiggyToken public token;
    IERC1155 public nft;

    uint256 public burnPercentage; // Percentage of tokens burned in each auction(10^2)
    uint256 public treasuryPercentage; // Percentage of tokens sent to the treasury in each auction
    uint256 public winnerPercentage; // Percentage of tokens sent to the winner/s in each auction
    uint256 public piggyBankPercentage; // Percentage of tokens locked in the piggy bank NFT in each auction

    event AuctionStarted(uint auctiontId, uint endTime);
    event Bid(address bidder, uint amount);

    mapping(address => uint) public bids;

    constructor() {}

    function startAuction(
        uint _numberOfTokens,
        uint _endTime
    ) external onlyOwner {
        require(!started, "Auction already started");
        started = true;
        auctiontId.increment();
        uint newAuctionId = auctiontId.current();
        numberOfTokensPerAuction = _numberOfTokens;
        endAt = _endTime;

        emit AuctionStarted(newAuctionId, endAt);
    }

    function bid(uint bidAmount) external {
        require(started, "Auction not started");
        require(block.timestamp < endAt, "Auction ended");
        require(bidAmount > 0, "Bid amount must be gretaer than 0");
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

        bids[msg.sender] = bids[msg.sender] + bidAmount;
        emit Bid(msg.sender, bidAmount);
    }

    function endAuction(
        uint _auctionId,
        address[] memory winnerAddress,
        address[5] memory uplineWinners,
        uint[] memory winningPercentage,
        uint[] memory isActive
    ) external onlyOwner {
        require(started, "Auction not started");
        require(!ended, "Auction already ended");
        require(block.timestamp >= endAt, "Auction not ended");

        ended = true;
        auctiontId.decrement();

        ended = true;

        require(
            winnerAddress.length == winningPercentage.length,
            "Invalid array"
        );
        require(winnerAddress.length == isActive.length, "Invalid array");

        token.transfer(
            burnAddress,
            (burnPercentage * receivedBidAmount) / 10000
        );
        token.transfer(
            treasuryAddress,
            (treasuryPercentage * receivedBidAmount) / 10000
        );
    }

    function setTreasuryWallet(address _treasuryAddress) external {
        treasuryAddress = _treasuryAddress;
    }

    function setHoldingWallet(address _holdingAddress) external {
        holdingAddress = _holdingAddress;
    }

    function setTreasuryPercentage(uint256 _treasuryPercentage) external {
        treasuryPercentage = _treasuryPercentage;
    }

    function setBurnPercentage(uint256 _burnPercentage) external {
        burnPercentage = _burnPercentage;
    }

    function setTokensPerAuction(uint256 _tokensPerAuction) external {
        numberOfTokensPerAuction = _tokensPerAuction;
    }

    function setPiggyBankPercentage(uint256 _piggyBankPercentage) external {
        piggyBankPercentage = _piggyBankPercentage;
    }
}
