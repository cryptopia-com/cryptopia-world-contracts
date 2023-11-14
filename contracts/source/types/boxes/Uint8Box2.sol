// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Unsigned integer box with 2 values
/// @notice Used to return multiple uint values from a function in order to bypass stack depth limitations
struct Uint8Box2 {    
    uint8 value1;
    uint8 value2;
}