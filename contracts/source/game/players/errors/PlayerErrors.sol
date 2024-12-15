// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../types/PlayerEnums.sol";

/// @dev Emitted when `account` is not a player
/// @param account The account that is not a player
error PlayerNotRegistered(address account);

/// @dev Emitted when `account` is not in the expected location
/// @param account The account that is not in the expected location
/// @param expected The expected location
/// @param actual The actual location
error PlayerNotInExpectedLocation(address account, uint16 expected, uint16 actual);

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
/// @param minLevel The required min level
error PlayerLevelTooLow(address player, uint level, uint minLevel);

/// @dev Emitted when `player` level is too high
/// @param player The player that has a level that is too high
/// @param level The level of the player
/// @param maxLevel The required max level
error PlayerLevelTooHigh(address player, uint level, uint maxLevel);

/// @dev Emitted when `player` does not have the required profession
/// @param player The player that does not have the required profession
/// @param profession The required profession
error PlayerMissingProfession(address player, Profession profession);