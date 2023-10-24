// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Emitted when `account` is not a player
/// @param account The account that is not a player
error PlayerNotRegistered(address account);

/// @dev Emitted when `account` is already a player
/// @param account The account that is already a player
/// @param arrival The arrival time of the player
error PlayerIsTraveling(address account, uint64 arrival);

/// @dev Emitted when `player` level is too low
/// @param player The player that has a level that is too low
/// @param level The level of the player
/// @param requiredLevel The required level
error PlayerLevelInsufficient(address player, uint level, uint requiredLevel);