// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Payments {
    address payable[] public winners;
    uint[] public sharePercentage;
    event TransferReceived(address _from, uint _amount);

    constructor() {}

    function addWinners(address payable[] memory _addrs) external {
        for (uint i = 0; i < _addrs.length; i++) {
            winners.push(_addrs[i]);
        }
    }

    function addSharePercentage(uint[] memory _sharePercentage) external {
        uint totalPercentage = 0;
        for (uint i = 0; i < _sharePercentage.length; i++) {
            totalPercentage += _sharePercentage[i];
            sharePercentage.push(_sharePercentage[i]);
        }
        require(totalPercentage == 100, "Percentage must add upto 100");
    }

    receive() external payable {
        require(winners.length == sharePercentage.length, "Invalid array");
        uint totalAmount = msg.value;
        for (uint i = 0; i < winners.length; i++) {
            uint amountToSend = (totalAmount * sharePercentage[i]) / 100;
            winners[i].transfer(amountToSend);
        }
        emit TransferReceived(msg.sender, msg.value);
    }
}
