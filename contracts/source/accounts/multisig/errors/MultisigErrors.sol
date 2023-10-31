// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/**
 * Global Multisig Errors
 */
/// @dev Emitted when the signature set is invalid and does not satisfy the requirements of the multisig wallet
/// @param account The account that initiated the transaction
error InvalidSignatureSet(address account);