// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Unsigned integer box with 3 values
/// @notice Used to return multiple uint values from a function in order to bypass stack depth limitations
struct UintBox3 {    
    uint value1;
    uint value2;
    uint value3;
}