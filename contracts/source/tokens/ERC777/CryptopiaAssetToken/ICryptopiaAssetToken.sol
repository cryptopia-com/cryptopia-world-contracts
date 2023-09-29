// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Cryptopia Asset Token
/// @notice Cryptoipa asset such as natural resources.
/// @dev Implements the ERC777 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaAssetToken {

    /// @dev Mints 'amount' token to an address
    /// @param to Account to mint the tokens for
    /// @param amount Amount of tokens to mint
    function mintTo(address to, uint amount) external;
}