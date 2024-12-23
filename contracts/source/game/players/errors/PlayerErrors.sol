// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Emitted when `account` is not a player
/// @param account The account that is not a player
error PlayerNotRegistered(address account);

/// @dev Emitted when `account` cannot interact at this time
/// @param account The account that cannot interact
error PlayerCannotInteract(address account);

/// @dev Emitted when `account` is already a player
/// @param account The account that is already a player
/// @param arrival The arrival time of the player
error PlayerIsTraveling(address account, uint64 arrival);

/// @dev Emits if a player attempts to travel while frozen
/// @param account Player that is frozen
/// @param until The datetime at which the player is no longer frozen
error PlayerIsFrozen(address account, uint64 until);

/// @dev Emitted when `player` level is too low
/// @param player The player that has a level that is too low
/// @param level The level of the player
/// @param requiredLevel The required level
error PlayerLevelInsufficient(address player, uint level, uint requiredLevel);