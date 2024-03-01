// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../game/inventories/IInventories.sol";

/// @title Asset Token
/// @notice Assets such as natural resources
/// @dev Implements the ERC20 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IAssetToken {

    /**
     * System functions
     */
    /// @dev Mints 'amount' token to an address
    /// @param to Account to mint the tokens for
    /// @param amount Amount of tokens to mint
    function __mintTo(address to, uint amount) external;

    
    /// @dev Mints 'amount' of tokens to 'player' and assigns them to 'inventory'
    /// @param player The player that completed the quest
    /// @param inventory The inventory to mint the tokens to
    /// @param amount The amount of tokens to mint
    function __mintToInventory(address player, Inventory inventory, uint amount) external;
}