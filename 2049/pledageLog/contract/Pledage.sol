// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface Pledage{
    enum Expiration{
        zero,
        one,
        three,
        six,
        year
    }
    event Provide(address owner, uint256 amount, uint256 time, Expiration expiration);
    event Withdraw(uint256 orderId, address receiver, address token, uint256 amount,uint256 time);

    function getBnbPrice() external view returns(uint256);

    function getTokenPrice() external view returns(uint256);
}