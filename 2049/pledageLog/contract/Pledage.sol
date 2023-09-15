// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

contract Pledage{
    enum Expiration{
        Seven,
        Fifteen,
        Thirty,
        Sixty
    }

    event Register(address registerAddress,address referrerAddress);
    event CreateOption(address owner,uint256 optionId,uint256 amount,uint256 crateTime, Expiration expiration);
    event Withdraw(address owner,uint256 optionId,uint256 amount);
    event ClaimWithPermit(address owner,uint256 amountBNB);
}