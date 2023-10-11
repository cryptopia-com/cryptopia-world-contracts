// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/**
 * Global Account Errors
 */
/// @dev Emitted when `account` is not registered
/// @param account The account that is not registered
error AccountNotRegistered(address account);