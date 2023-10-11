// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Map enums
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract MapEnums {

     /// @dev Connection between tiles
    enum EdgeType
    {
        Flat,
        Slope,
        Cliff
    } 
}