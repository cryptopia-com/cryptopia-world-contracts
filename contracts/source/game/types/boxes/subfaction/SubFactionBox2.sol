// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../FactionEnums.sol";

/// @dev SubFaction box with 2 values
/// @notice Used to return multiple SubFaction values from a function in order to bypass stack depth limitations
struct SubFactionBox2 {    
    SubFaction value1;
    SubFaction value2;
}