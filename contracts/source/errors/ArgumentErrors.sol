// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Emitted when an argument is is invalid
error ArgumentInvalid();

/// @dev Emitted when an account is null    
/// @param account The account that is null
error ArgumentZeroAddress(address account);