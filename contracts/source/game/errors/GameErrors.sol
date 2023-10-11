// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../types/FactionEnums.sol";

/// @dev Emitted when an operation is attempted but a cooldown is still active
/// @param player The player with the active cooldown
/// @param cooldownEnd The timestamp when the cooldown ends
error CooldownActive(address player, uint cooldownEnd);

/// @dev Emitted when `faction` is unexpected
/// @param expected The expected faction
/// @param actual The actual faction
error UnexpectedFaction(Faction expected, Faction actual);