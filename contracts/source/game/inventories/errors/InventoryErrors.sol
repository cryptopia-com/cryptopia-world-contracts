// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../types/InventoryEnums.sol";

/// @dev Emitted when the inventory is invalid
/// @param inventory The inventory that was invalid
error InventoryInvalid(Inventory inventory);

/// @dev Emitted the game item with `tokenId` is not found in the inventory
/// @param player The player that the inventory belongs to
/// @param inventory The inventory that the game item was expected to be found in
/// @param asset The asset that the game item belongs to
/// @param tokenId The token id of the game item that was not found
error InventoryItemNotFound(address player, Inventory inventory, address asset, uint tokenId);

/// @dev Emitted when a transfer fails due to insufficient balance in the inventory
/// @param player The player that tried to transfer between inventories
/// @param inventory The inventory that was tried to be transferred from
/// @param asset The asset that was tried to be transferred
/// @param amount The amount that was tried to be transferred
error InventoryInsufficientBalance(address player, Inventory inventory, address asset, uint amount);