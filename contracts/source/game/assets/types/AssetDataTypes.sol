// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./AssetEnums.sol";

/// @dev Asset info plus balances
struct AssetInfo 
{
    address contractAddress;
    string name;
    string symbol;
    uint[] balances;
}

/// @dev Represents a requirement for a specific resource and its amount
struct ResourceRequirement 
{
    /// @dev The type of resource required
    Resource resource;

    /// @dev The quantity of the resource needed
    uint amount;
}