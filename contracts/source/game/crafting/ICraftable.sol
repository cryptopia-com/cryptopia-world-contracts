// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../inventories/types/InventoryEnums.sol";

/// @title Craftable interface
/// @dev Allows a Non-fungible token (ERC721) to be crafted
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICraftable {

    /// @dev Allows for the crafting of an `item`
    /// @param item The name of the item to be crafted
    /// @param player The player to craft the item for
    /// @param inventory The inventory to mint the item into
    /// @return tokenId The token ID of the crafted item
    function __craft(bytes32 item, address player, Inventory inventory) 
        external 
        returns (uint tokenId);
}