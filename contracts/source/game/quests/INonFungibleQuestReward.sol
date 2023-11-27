// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Quest reward 
/// @notice A quest reward can be claimed by a player when a quest is completed
interface INonFungibleQuestReward {

    /// @dev Reward `to` with `item`
    /// @param to Address to reward 
    /// @param item Item to reward
    function __reward(address to, bytes32 item) external;
}