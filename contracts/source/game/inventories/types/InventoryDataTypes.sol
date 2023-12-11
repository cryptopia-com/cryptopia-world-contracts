// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Inventory space with details on asset weights and types
struct InventorySpace
{
    /// @dev Total combined weight of fungible and non-fungible assets in the inventory
    uint weight;

    /// @dev Maximum weight the inventory can hold, considering module effects and capacity limits
    uint maxWeight;

    /// @dev Array of fungible asset spaces, detailing ERC20 token holdings
    FungibleTokenInventorySpace[] fungible;

    /// @dev Array of non-fungible asset spaces, detailing ERC721 token holdings
    NonFungibleTokenInventorySpace[] nonFungible;
}

/// @dev Space in the inventory for holding fungible tokens (ERC20)
struct FungibleTokenInventorySpace
{
    /// @dev Contract address of the fungible (ERC20) asset
    address asset;

    /// @dev Total amount of the fungible tokens held
    uint amount;
}

/// @dev Space in the inventory for holding non-fungible tokens (ERC721)
struct NonFungibleTokenInventorySpace
{
    /// @dev Contract address of the non-fungible (ERC721) asset
    address asset;

    /// @dev Array of token IDs for the non-fungible tokens held
    uint[] tokenIds;
}

/// @dev Fungible asset transaction instructions
struct FungibleTransactionData
{
    /// @dev The contract address of the fungible asset involved in the transaction
    address asset;

    /// @dev The amount of the fungible asset being transacted
    uint amount;

    /// @dev Indicates if direct assignment or deduction to/from the wallet is permitted
    bool allowWallet;
}

/// @dev Non-fungible asset transaction instructions
struct NonFungibleTransactionData
{
    /// @dev The contract address of the non-fungible asset involved in the transaction
    address asset;

    /// @dev The specific item of the non-fungible asset being transacted
    bytes32 item;

    /// @dev Indicates if direct assignment or deduction to/from the wallet is permitted
    bool allowWallet;
}
