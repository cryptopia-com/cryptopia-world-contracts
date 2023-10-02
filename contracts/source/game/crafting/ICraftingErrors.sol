// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../game/inventories/InventoryEnums.sol";

/// @title Custom crafting errors
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICraftingErrors {

    /// @dev Emitted when the crafting slot is empty
    /// @param player The player that attempted to craft
    /// @param slot The slot that was empty
    error CraftingSlotIsEmpty(address player, uint slot);

    /// @dev Emitted when the crafting slot is not ready
    /// @param player The player that attempted to craft
    /// @param slot The slot that was not ready
    error CraftingSlotNotReady(address player, uint slot);

    /// @dev Emitted when the recipe is invalid
    /// @param asset The asset that was used in the recipe
    /// @param recipe The recipe that was invalid
    error CraftingInvalidRecipe(address asset, bytes32 recipe);

    /// @dev Emitted when the inventory is invalid
    /// @param inventory The inventory that was invalid
    error CraftingInvalidInventory(InventoryEnums.Inventories inventory);
}
