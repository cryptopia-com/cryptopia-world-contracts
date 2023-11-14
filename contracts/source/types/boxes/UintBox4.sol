// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Unsigned integer box with 4 values
/// @notice Used to return multiple uint values from a function in order to bypass stack depth limitations
struct UintBox4 {    
    uint value1;
    uint value2;
    uint value3;
    uint value4;
}