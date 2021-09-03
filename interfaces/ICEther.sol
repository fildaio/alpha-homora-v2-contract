// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface ICEther {
    function balanceOf(address user) external view returns (uint);

    function borrowBalanceCurrent(address account) external returns (uint);

    function borrowBalanceStored(address account) external view returns (uint);

    function borrow(uint borrowAmount) external returns (uint);

    function repayBorrow() external payable returns (uint);
}