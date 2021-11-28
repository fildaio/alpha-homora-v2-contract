// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import '@openzeppelin/contracts/token/ERC1155/ERC1155.sol';
import '@openzeppelin/contracts/token/ERC20/SafeERC20.sol';
import '@openzeppelin/contracts/utils/ReentrancyGuard.sol';

import '../utils/HomoraMath.sol';
import '../../interfaces/IERC20Wrapper.sol';
import '../../interfaces/IMiniChefV2.sol';

contract WMiniChefV2 is ERC1155('WMiniChefV2'), ReentrancyGuard, IERC20Wrapper {
  using SafeMath for uint;
  using HomoraMath for uint;
  using SafeERC20 for IERC20;

  IMiniChefV2 public immutable chef; // Sushiswap miniChef
  IERC20 public immutable sushi; // Sushi token

  mapping(uint => uint) public stRewardPerShare;

  constructor(IMiniChefV2 _chef) public {
    chef = _chef;
    sushi = _chef.SUSHI();

  }

  /// @dev Encode pid, sushiPerShare to ERC1155 token id
  /// @param pid Pool id (16-bit)
  /// @param sushiPerShare Sushi amount per share, multiplied by 1e18 (240-bit)
  function encodeId(uint pid, uint sushiPerShare) public pure returns (uint id) {
    require(pid < (1 << 16), 'bad pid');
    require(sushiPerShare < (1 << 240), 'bad sushi per share');
    return (pid << 240) | sushiPerShare;
  }

  /// @dev Decode ERC1155 token id to pid, sushiPerShare
  /// @param id Token id
  function decodeId(uint id) public pure returns (uint pid, uint sushiPerShare) {
    pid = id >> 240; // First 16 bits
    sushiPerShare = id & ((1 << 240) - 1); // Last 240 bits
  }

  /// @dev Return the underlying ERC-20 for the given ERC-1155 token id.
  /// @param id Token id
  function getUnderlyingToken(uint id) external view override returns (address) {
    (uint pid, ) = decodeId(id);
    address lpToken = chef.lpToken(pid);
    return lpToken;
  }

  /// @dev Return the conversion rate from ERC-1155 to ERC-20, multiplied by 2**112.
  function getUnderlyingRate(uint) external view override returns (uint) {
    return 2**112;
  }

  /// @dev Mint ERC1155 token for the given pool id.
  /// @param pid Pool id
  /// @param amount Token amount to wrap
  /// @return The token id that got minted.
  function mint(uint pid, uint amount) external nonReentrant returns (uint) {
    address lpToken = chef.lpToken(pid);
    IERC20(lpToken).safeTransferFrom(msg.sender, address(this), amount);
    if (IERC20(lpToken).allowance(address(this), address(chef)) != uint(-1)) {
      // We only need to do this once per pool, as LP token's allowance won't decrease if it's -1.
      IERC20(lpToken).safeApprove(address(chef), uint(-1));
    }

    chef.deposit(pid, amount, address(this));

    (uint128 sushiPerShare, ,) = chef.poolInfo(pid);
    uint id = encodeId(pid, sushiPerShare);

    IRewarder rewarder = chef.rewarder(pid);
    (stRewardPerShare[id], ,) = rewarder.poolInfo(pid);

    _mint(msg.sender, id, amount, '');
    return id;
  }

  struct BurnLocalParam {
    uint pid;
    uint stSushiPerShare;
    uint128 enSushiPerShare;
    uint stSushi;
    uint enSushi;
    uint128 enRewardPerShare;
    uint stReward;
    uint enReward;
  }

  /// @dev Burn ERC1155 token to redeem LP ERC20 token back plus SUSHI rewards.
  /// @param id Token id
  /// @param amount Token amount to burn
  /// @return The pool id that that you will receive LP token back.
  function burn(uint id, uint amount) external nonReentrant returns (uint) {
    if (amount == uint(-1)) {
      amount = balanceOf(msg.sender, id);
    }

    BurnLocalParam memory param;

    (param.pid, param.stSushiPerShare) = decodeId(id);
    _burn(msg.sender, id, amount);
    chef.withdrawAndHarvest(param.pid, amount, address(this));
    address lpToken = chef.lpToken(param.pid);
    (param.enSushiPerShare, ,) = chef.poolInfo(param.pid);
    IERC20(lpToken).safeTransfer(msg.sender, amount);
    param.stSushi = param.stSushiPerShare.mul(amount).divCeil(1e12);
    param.enSushi = uint(param.enSushiPerShare).mul(amount).div(1e12);
    if (param.enSushi > param.stSushi) {
      sushi.safeTransfer(msg.sender, param.enSushi.sub(param.stSushi));
    }

    IRewarder rewarder = chef.rewarder(param.pid);
    (param.enRewardPerShare, ,) = rewarder.poolInfo(param.pid);
    (IERC20[] memory rewardTokens, ) = rewarder.pendingTokens(param.pid, address(this), 0);
    param.stReward = stRewardPerShare[id].mul(amount).divCeil(1e12);
    param.enReward = uint(param.enRewardPerShare).mul(amount).div(1e12);
    if (param.enReward > param.stReward) {
      rewardTokens[0].safeTransfer(msg.sender, param.enReward.sub(param.stReward));
    }
    return param.pid;
  }

  function rewardToken(uint id) external view returns (address) {
    (uint pid, ) = decodeId(id);
    IRewarder rewarder = chef.rewarder(pid);
    (IERC20[] memory rewardTokens, ) = rewarder.pendingTokens(pid, address(this), 0);
    return address(rewardTokens[0]);
  }
}
