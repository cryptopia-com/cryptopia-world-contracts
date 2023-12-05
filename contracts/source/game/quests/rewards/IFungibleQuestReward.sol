// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../inventories/types/InventoryEnums.sol";

/// @dev Quest reward 
/// @notice A quest reward can be claimed by a player when a quest is completed
interface IFungibleQuestReward {

    /// @dev Mint quest reward
    /// @param amount The amount of tokens to mint
    /// @param player The player that completed the quest
    /// @param inventory The inventory to mint the reward to
    function __mintQuestReward(uint amount, address player, Inventory inventory) 
        external;
}