// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../inventories/types/InventoryEnums.sol";

/// @dev Quest reward 
/// @notice A quest reward can be claimed by a player when a quest is completed
interface INonFungibleQuestReward {

    /// @dev Mint a quest reward
    /// @param item The item to mint
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    function __mintQuestReward(bytes32 item, address player, Inventory inventory)
        external
        returns (uint tokenId);
}