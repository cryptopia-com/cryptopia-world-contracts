// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Describes a fungible transaction
struct FungibleTransaction
{
    /// @dev The asset that is being transacted
    address asset;

    /// @dev The amount that is being transacted
    uint amount;
}

/// @dev Describes a non-fungible transaction
struct NonFungibleTransaction
{
    /// @dev The asset that is being transacted
    address asset;

    /// @dev The item that is being transacted
    bytes32 item;
}