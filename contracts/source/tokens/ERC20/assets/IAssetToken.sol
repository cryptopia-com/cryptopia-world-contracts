// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

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
}