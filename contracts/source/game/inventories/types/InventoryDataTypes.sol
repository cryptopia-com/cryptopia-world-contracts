// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

struct InventorySpace
{
    // Combined weight (fungible + non-fungible)
    uint weight;

    // Maximum combined weight (including module effects etc.)
    uint maxWeight;

    // Fungible assets
    FungibleTokenInventorySpace[] fungible;

    // Non-fungible assets
    NonFungibleTokenInventorySpace[] nonFungible;
}

struct FungibleTokenInventorySpace
{
    // Contract address (ERC20)
    address asset;

    // Amount of tokens
    uint amount;
}

struct NonFungibleTokenInventorySpace
{
    // Contract address (ERC20)
    address asset;

    // Token IDs 
    uint[] tokenIds;
}

/// @dev Describes a fungible transaction
struct FungibleTransactionData
{
    /// @dev The asset that is being transacted
    address asset;

    /// @dev The amount that is being transacted
    uint amount;

    /// @dev Whether or not direct assignment/deduction to/from the wallet is allowed
    bool allowWallet;
}

/// @dev Describes a non-fungible transaction
struct NonFungibleTransactionData
{
    /// @dev The asset that is being transacted
    address asset;

    /// @dev The item that is being transacted
    bytes32 item;

    /// @dev Whether or not direct assignment/deduction to/from the wallet is allowed
    bool allowWallet;
}