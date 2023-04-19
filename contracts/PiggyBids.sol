// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
interface IPiggyToken {
    function transferFrom(address sender, address recipient, uint amount) external returns(bool);
    function balanceOf(address account) external view returns (uint);
}
*/

contract PiggyBids {
    using SafeERC20 for IERC20;
    address public owner;
    address public DB_ADDR;

    constructor(address _DB_ADDR) {
        owner = msg.sender;
        DB_ADDR = _DB_ADDR;
    }

    //piggy token address
    address private constant PIGGY_TOKEN =
        0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    //busd address
    address private constant BUSD_TOKEN =
        0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;

    mapping(address => uint) private deposits;
    mapping(address => uint) private bids;

    event Deposit(address indexed user, uint amount);
    event Bid(address indexed user, uint amount);

    function depositPiggyTokens(uint amount) public {
        IERC20(PIGGY_TOKEN).transferFrom(msg.sender, address(this), amount);
        deposits[msg.sender] += amount;
        emit Deposit(msg.sender, amount);
    }

    function depositBUSD(uint amount) public {
        IERC20(BUSD_TOKEN).transferFrom(msg.sender, address(this), amount);

        //Split inTo 3
        uint amountPerAddress = (amount) / 3;
        IERC20(BUSD_TOKEN).transfer(address(ADDR_1), amountPerAddress);
        IERC20(BUSD_TOKEN).transfer(address(ADDR_2), amountPerAddress);
        IERC20(BUSD_TOKEN).transfer(address(DB_ADDR), amountPerAddress);

        emit Deposit(address(this), amount);
    }

    function allocateBids(uint amount) public {
        require(amount > 0, "cannot be 0");
        require(deposits[msg.sender] >= amount, "Insufficient Piggy Tokens");

        deposits[msg.sender] -= amount;
        bids[msg.sender] += amount;

        emit Bid(msg.sender, amount);
    }

    function getBids(address user) public view returns (uint) {
        return bids[user];
    }

    function getDeposits(address user) public view returns (uint) {
        return deposits[user];
    }
}
