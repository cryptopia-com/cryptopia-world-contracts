// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../inventories/types/InventoryEnums.sol";

/// @dev Game console reward 
/// @notice A reward can be claimed by a player when a game is completed on the console
interface INonFungibleGameConsoleReward {

    /// @dev Mint a reward
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param item The item to mint
    function __mintGameConsoleReward(address player, Inventory inventory, bytes32 item)
        external
        returns (uint tokenId);
}