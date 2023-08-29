// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

interface Vip{
    function updatePrice(uint256 _price) external;
    function tokenPrice() external view returns(uint256);
}