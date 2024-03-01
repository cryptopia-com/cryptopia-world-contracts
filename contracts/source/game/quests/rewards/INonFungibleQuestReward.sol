// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../inventories/types/InventoryEnums.sol";

/// @dev Quest reward 
/// @notice A quest reward can be claimed by a player when a quest is completed
interface INonFungibleQuestReward {

    /// @dev Mint a quest reward
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param item The item to mint
    function __mintQuestReward(address player, Inventory inventory, bytes32 item)
        external
        returns (uint tokenId);
}