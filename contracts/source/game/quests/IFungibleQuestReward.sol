// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Quest reward 
/// @notice A quest reward can be claimed by a player when a quest is completed
interface IFungibleQuestReward {

    /// @dev Rewards the player for completing the quest
    /// @param to The address that is being rewarded
    /// @param amount The amount that is being rewarded
    function __reward(address to, uint amount) 
        external;
}