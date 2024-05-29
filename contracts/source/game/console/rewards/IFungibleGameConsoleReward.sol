// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../inventories/types/InventoryEnums.sol";

/// @dev Game console reward 
/// @notice A reward can be claimed by a player when a game is completed on the console
interface IFungibleGameConsoleReward {

    /// @dev Mint a reward
    /// @param player The player that completed the game
    /// @param inventory The inventory to mint the reward to
    /// @param amount The amount of tokens to mint
    function __mintGameConsoleReward(address player, Inventory inventory, uint amount) 
        external;
}