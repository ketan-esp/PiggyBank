// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint amount) external;

    function transfer(address to, uint amount) external;

    function burn(address from, uint amount) external;

    function balanceOf(address account) external view returns (uint256);
}

contract Auction is Ownable {
    IERC20 public token;
    uint public numberOfTokens;
    address public seller;
    address immutable burnAddress = address(0);
    address public treasuryAddress;
    //address[] public winnerAddress;
    address public piggyBankNFTAddress;
    address public holdingAddress;
    address public jackPotNFTAddress;
    address ADDR_1;
    address ADDR_2;
    address DB_ADDR;
    uint public receivedBidAmount;

    address private constant BUSD_TOKEN =
        0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    uint public endAt;
    bool public started;
    bool public ended;
    uint public bidIncrement;
    uint public currentBid;

    uint256 public burnPercentage; // Percentage of tokens burned in each auction(10^2)
    uint256 public treasuryPercentage; // Percentage of tokens sent to the treasury in each auction
    uint256 public winnerPercentage; // Percentage of tokens sent to the winner/s in each auction
    uint256 public piggyBankPercentage; // Percentage of tokens locked in the piggy bank NFT in each auction

    mapping(address => uint) public bids;
    mapping(address => uint) public deposits;

    event Deposit(address indexed user, uint amount);
    event BidAllocation(address indexed user, uint amount);
    event AuctionStarted();
    event Bid(address indexed bidder, uint amount);
    event WeeklyAuctionStarted();

    constructor(address PiggyToken) {
        token = IERC20(PiggyToken);
        owner = msg.sender;
    }

    function startAuction(
        uint _numberOfTokens,
        uint _startingBid,
        uint _bidIncrement,
        uint _endAt
    ) external onlyOwner {
        require(msg.sender == owner, "you are not owner");
        require(!started, "already started");
        bidIncrement = _bidIncrement;
        numberOfTokens = _numberOfTokens;
        started = true;
        currentBid = _startingBid;

        emit AuctionStarted();
    }

    function bid(uint bidAmount) external returns (bool) {
        require(started, "auction not started");
        require(block.timestamp < endAt, "auction ended");
        require(bidAmount > 0, "value < highest bid");
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
        uint id,
        address[] calldata winnerAddress,
        uint[] winningPercentage,
        bool[] isActive
    ) external onlyOwner {
        require(started, "auction not started");
        require(!ended, "auction ended");
        require(block.timestamp >= endAt, "auction not ended");

        ended = true;

        token.transfer(
            burnAddress,
            (burnPercentage * receivedBidAmount) / 10000
        );
        token.transfer(
            treasuryAddress,
            (treasuryPercentage * receivedBidAmount) / 10000
        );

        for (uint i = 0; i < winnerAddress.length; i++) {
                token.transfer(
                    winnerAddress[i],
                    ((winnerPercentage * receivedBidAmount) / 10000) -
                        ((piggyBankPercentage * receivedBidAmount) / 10000)
                );
                token.transfer(
                    PiggyBankNFTAddress,
                    ((piggyBankPercentage)) * receivedBidAmount
                );
            } else {
                token.transfer(
                    address(this),
                    JackPotNFTAddress,
                    numberOfTokens
                );
            }
        }
        //emit AuctionEnded(winnerAddress, winnerPercentage, piggyBankPercentage);
    }

    function setEndTime(uint _endAt) external {
        endAt = _endAt;
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
        numberOfTokens = _tokensPerAuction;
    }

    function setPiggyBankPercentage(uint256 _piggyBankPercentage) external {
        piggyBankPercentage = _piggyBankPercentage;
    }

    //weekly auction
    function startWeeklyAuction(
        uint _numberOfTokens,
        uint _startingBid,
        uint _bidIncrement,
        uint _endAt
    ) external onlyOwner {
        require(msg.sender == owner, "you are not owner");
        require(!started, "already started");

        endAt = block.timestamp + 7 days;
        bidIncrement = _bidIncrement;
        numberOfTokens = _numberOfTokens;
        started = true;
        currentBid = _startingBid;
        burnPercentage = (40 * numberOfTokens) / 100;
        treasuryPercentage = (20 * numberOfTokens) / 100;
        uint holdingPercentage = (40 * numberOfTokens) / 100;

        token.transfer(owner, burnAddress, burnPercentage);
        token.transfer(owner, treasuryAddress, treasuryPercentage);
        token.transfer(owner, holdingAddress, holdingPercentage);

        emit WeeklyAuctionStarted();
    }

    //Deposit functions

    function depositPiggyTokens(uint amount) public {
        IERC20(token).transfer(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        //Split inTo 3
        uint amountPerAddress = (amount) / 3;
        IERC20(token).transfer(address(this), ADDR_1, amountPerAddress);
        IERC20(token).transfer(address(this), ADDR_2, amountPerAddress);
        IERC20(token).transfer(address(this), DB_ADDR, amountPerAddress);

        emit Deposit(address(this), amount);
        emit Deposit(msg.sender, amount);
    }

    function depositBUSD(uint amount) public {
        IERC20(BUSD_TOKEN).transfer(msg.sender, address(this), amount);
    }
}
