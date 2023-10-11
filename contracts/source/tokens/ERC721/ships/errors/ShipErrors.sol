// SPDX-License-Identifier: ISC
pragma solidity ^0.8.0 < 0.9.0;

/**
 * Global Ship Errors
 */
/// @dev Emitted when `ship` is locked
/// @param tokenId The token that is locked
error ShipLocked(uint tokenId);

/// @dev Emitted when `ship` is not owned by `account`
/// @param tokenId The token that is not owned
/// @param account The account that does not own the ship
error ShipNotOwned(uint tokenId, address account);