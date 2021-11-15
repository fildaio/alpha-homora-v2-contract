// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/IStakingDualRewards.sol';

contract WStakingDualRewards is ERC1155('WStakingDualRewards'), ReentrancyGuard, IERC20Wrapper {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  address public immutable staking; // Staking reward contract address
  address public immutable underlying; // Underlying token address
  address public immutable rewardA; // Reward token address
  address public immutable rewardB; // Reward token address

  uint stRewardPerTokenB;

  constructor(
    address _staking,
    address _underlying,
    address _rewardA,
    address _rewardB
  ) public {
    staking = _staking;
    underlying = _underlying;
    rewardA = _rewardA;
    rewardB = _rewardB;
    IERC20(_underlying).safeApprove(_staking, uint(-1));
  }

  /// @dev Return the underlying ERC20 for the given ERC1155 token id.
  function getUnderlyingToken(uint) external view override returns (address) {
    return underlying;
  }

  /// @dev Return the conversion rate from ERC1155 to ERC20, multiplied 2**112.
  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  /// @dev Mint ERC1155 token for the specified amount
  /// @param amount Token amount to wrap
  function mint(uint amount) external nonReentrant returns (uint) {
    IERC20(underlying).safeTransferFrom(msg.sender, address(this), amount);
    IStakingDualRewards(staking).stake(amount);
    uint rewardPerToken = IStakingDualRewards(staking).rewardPerTokenA();
    stRewardPerTokenB = IStakingDualRewards(staking).rewardPerTokenB();
    _mint(msg.sender, rewardPerToken, amount, '');
    return rewardPerToken;
  }

  /// @dev Burn ERC1155 token to redeem ERC20 token back.
  /// @param id Token id to burn
  /// @param amount Token amount to burn
  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }
    _burn(msg.sender, id, amount);
    IStakingDualRewards(staking).withdraw(amount);
    IStakingDualRewards(staking).getReward();
    IERC20(underlying).safeTransfer(msg.sender, amount);
    uint stRewardPerToken = id;
    uint enRewardPerToken = IStakingDualRewards(staking).rewardPerTokenA();
    uint stReward = stRewardPerToken.mul(amount).divCeil(1e18);
    uint enReward = enRewardPerToken.mul(amount).div(1e18);
    if (enReward > stReward) {
      IERC20(rewardA).safeTransfer(msg.sender, enReward.sub(stReward));
    }

    uint enRewardPerTokenB = IStakingDualRewards(staking).rewardPerTokenB();
    uint stRewardB = stRewardPerTokenB.mul(amount).divCeil(1e18);
    uint enRewardB = enRewardPerTokenB.mul(amount).div(1e18);
    if (enRewardB > stRewardB) {
      IERC20(rewardB).safeTransfer(msg.sender, enRewardB.sub(stRewardB));
    }

    return enRewardPerToken;
  }
}
