// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Quest reward 
/// @notice A quest reward can be claimed by a player when a quest is completed
interface IFungibleQuestReward {

    /// @dev Reward `to` with `amount`
    /// @param to Address to reward
    /// @param amount Amount to reward
    function __reward(address to, uint amount) external;
}