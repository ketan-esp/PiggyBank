// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

/**
@title PiggyToken
@dev Piggy Bank Token is an ERC20 token contract with burn and ownable capabilities.
*/

contract PiggyToken is ERC20, Ownable, ERC20Burnable {
    // Token details
    uint256 public constant TOTAL_SUPPLY = 21000000 * (10 ** 18); // Total supply of 21M tokens

    constructor() ERC20("Piggy Bank Token", "PBT") {
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    /**
     * @dev Burns a specific amount of tokens from the caller's balance.
     * @param amount The amount of tokens to be burned.
     */

    function burn(uint256 amount) public override {
        _burn(msg.sender, amount);
    }
}
