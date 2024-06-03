// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import './IRewarder.sol';

interface IMiniChefV2 {

    struct PoolInfo {
        uint128 accSushiPerShare;
        uint64 lastRewardTime;
        uint64 allocPoint;
    }

    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    function lpToken(uint pid) external view returns(address);
    function rewarder(uint pid) external view returns(IRewarder);
    function deposit(uint256 pid, uint256 amount, address to) external;
    function withdraw(uint256 pid, uint256 amount, address to) external;
    function withdrawAndHarvest(uint256 pid, uint256 amount, address to) external;
    function harvest(uint256 pid, address to) external;
    function SUSHI() view external returns (IERC20);
    function poolInfo(uint pid) view external returns(uint128 accSushiPerShare, uint64 lastRewardTime, uint64 allocPoint);
}
