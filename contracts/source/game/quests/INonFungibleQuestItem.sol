// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../inventories/types/InventoryEnums.sol";

/// @dev Quest item
interface INonFungibleQuestItem {

    /// @dev Mint quest item
    /// @param item Item to mint
    /// @param player The player that completed the quest
    /// @param inventory The inventory to mint the item to
    /// @return tokenId Token id of the item that was minted
    function __mintQuestItem(bytes32 item, address player, Inventory inventory) 
        external
        returns (uint tokenId);


    /// @dev Burn quest item
    /// @param item Item to burn
    /// @param tokenId Token id of the item to burn
    /// @param player The player that completed the quest
    /// @param inventory The inventory to burn the item from
    function __burnQuestItem(bytes32 item, uint tokenId, address player, Inventory inventory) 
        external;
}