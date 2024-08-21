// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Bool box with 2 values
/// @notice Used to return multiple uint values from a function in order to bypass stack depth limitations
struct BoolBox2 {    
    bool value1;
    bool value2;
}