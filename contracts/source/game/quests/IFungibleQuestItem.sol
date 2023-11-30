// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../inventories/types/InventoryEnums.sol";

/// @dev Quest item
interface IFungibleQuestItem {

    /// @dev Mint quest item
    /// @param amount The amount of tokens to mint
    /// @param player The player that completed the quest
    /// @param inventory The inventory to mint the item to
    function __mintQuestItem(uint amount, address player, Inventory inventory) 
        external;


    /// @dev Burn quest item
    /// @param amount The amount of tokens to burn
    /// @param player The player that completed the quest
    /// @param inventory The inventory to burn the item from
    function __burnQuestItem(uint amount, address player, Inventory inventory) 
        external;
}