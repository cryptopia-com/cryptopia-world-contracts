// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Emitted when `expected` is required
/// @param expected The expected map
/// @param actual The actual map
error UnexpectedMap(bytes32 expected, bytes32 actual);

/// @dev Emitted when `expected` is required
/// @param expected The expected tile
/// @param actual The actual tile
error UnexpectedTile(uint16 expected, uint16 actual);