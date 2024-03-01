// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Unsigned integer box with 2 values
/// @notice Used to return multiple uint values from a function in order to bypass stack depth limitations
struct Uint24Box2 {    
    uint24 value1;
    uint24 value2;
}