// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IMasterChefGlide {
  function glide() external view returns (address);

  function poolInfo(uint pid)
    external
    view
    returns (
      address lpToken,
      uint allocPoint,
      uint lastRewardBlock,
      uint accGlidePerShare,
      uint256 lpSupply
    );

  function deposit(uint pid, uint amount) external;

  function withdraw(uint pid, uint amount) external;
}
