// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../types/FactionEnums.sol";

/// @dev Emitted when `faction` is unexpected
/// @param expected The expected faction
/// @param actual The actual faction
error UnexpectedFaction(Faction expected, Faction actual);