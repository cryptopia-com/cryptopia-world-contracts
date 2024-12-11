// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../inventories/types/InventoryEnums.sol";
import "./AssetEnums.sol";

/// @dev Asset info plus balances
struct AssetInfo 
{
    address contractAddress;
    string name;
    string symbol;
    uint[] balances;
}

/// @dev Describes a resource and an amount
struct ResourceData
{
    /// @dev The type of resource required
    Resource resource;

    /// @dev The quantity of the resource needed
    uint amount;
}

/// @dev Describes a resource contract
struct ResourceContract
{
    /// @dev The type of resource required
    Resource resource;

    /// @dev The quantity of the resource needed
    uint amount;

    /// @dev The compensation for the resource
    uint compensation;
}

/// @dev Input for depositing resources
struct ResourceContractDeposit
{
    /// @dev The resource contract index
    uint8 contractIndex;

    /// @dev The inventory to deposit the resources from
    Inventory inventory;

    /// @dev The amount to deposit
    uint amount;
}