// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../FactionEnums.sol";

/// @dev Faction box with 2 values
/// @notice Used to return multiple Faction values from a function in order to bypass stack depth limitations
struct FactionBox2 {    
    Faction value1;
    Faction value2;
}