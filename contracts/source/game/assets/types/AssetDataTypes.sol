// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Asset info plus balances
struct AssetInfo 
{
    address contractAddress;
    string name;
    string symbol;
    uint[] balances;
}