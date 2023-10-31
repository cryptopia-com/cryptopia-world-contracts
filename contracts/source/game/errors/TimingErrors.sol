// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Emitted when an operation is attempted but a cooldown is still active
/// @param player The player with the active cooldown
/// @param cooldownEnd The timestamp when the cooldown ends
error CooldownActive(address player, uint cooldownEnd);

/// @dev Emitted when the response time has expired 
/// @param player The player that has exceeded the response time
/// @param deadline The deadline in unix timestamp
error ResponseTimeExpired(address player, uint deadline);