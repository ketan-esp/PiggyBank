// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

contract PiggyToken is ERC20, Ownable, ERC20Burnable {
    // Token details
    uint256 public constant TOTAL_SUPPLY = 21000000 * (10 ** 18); // Total supply of 21M tokens

    constructor() ERC20("Piggy Bank Token", "PBT") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }
}
