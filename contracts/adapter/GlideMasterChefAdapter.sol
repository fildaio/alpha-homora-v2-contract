// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';

import '../../interfaces/IMasterChefGlide.sol';
import '../../interfaces/IMasterChef.sol';

contract GlideMasterChefAdapter is IMasterChef {
  using SafeERC20 for IERC20;

  IMasterChefGlide public immutable chef; // glide masterChef

  constructor(IMasterChefGlide _chef) public {
    require(address(_chef) != address(0), "WMasterChefForGlide: chef address is zero");
    chef = _chef;
  }

  function sushi() external view override returns (address) {
    return chef.glide();
  }

  function poolInfo(uint pid) external view override returns (
      address lpToken,
      uint allocPoint,
      uint lastRewardBlock,
      uint accSushiPerShare
    ) {

    (lpToken, allocPoint, lastRewardBlock, accSushiPerShare, ) = chef.poolInfo(pid);
  }

  function deposit(uint pid, uint amount) external override {
    (address lpToken, , , , ) = chef.poolInfo(pid);
    IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
    if (IERC20(lpToken).allowance(address(this), address(chef)) != uint(-1)) {
      // We only need to do this once per pool, as LP token's allowance won't decrease if it's -1.
      IERC20(lpToken).safeApprove(address(chef), uint(-1));
    }

    chef.deposit(pid, amount);
  }

  function withdraw(uint pid, uint amount) external override {
    (address lpToken, , , , ) = chef.poolInfo(pid);
    chef.withdraw(pid, amount);
    IERC20(lpToken).safeTransfer(msg.sender, amount);
  }

}
