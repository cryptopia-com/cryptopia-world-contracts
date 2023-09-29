// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../game/inventories/InventoryEnums.sol";

/// @title Craftable interface
/// @dev Allows a Non-fungible token (ERC721) to be crafted
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICraftable {

    /// @dev Allows for the crafting of an `item`
    /// @param item The name of the item to be crafted
    /// @param player The player to craft the item for
    /// @param inventory The inventory to mint the item into
    /// @return uint The token ID of the crafted item
    function craft(bytes32 item, address player, InventoryEnums.Inventories inventory) 
        external 
        returns (uint);
}