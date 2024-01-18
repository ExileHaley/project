// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IMembership{
    enum Target{
        INVITE,
        REMOVE
    }
    struct Assemble{
        address member;
        uint256 amount;
    }
    function getRankings(Target target) external view returns(address[] memory);
    function getMemberGrades(Target target,address member) external view returns(uint256);
    function multiGetMemberGrades(Target target,address[] memory member) external view returns(Assemble[] memory);

    function distributeRankings(address[] memory members,Target target,string memory mark) external;
    function extractedMark(string memory mark) external view returns(bool);
}

