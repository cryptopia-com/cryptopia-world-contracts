// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/**
 * Global Book Errors
 */
/// @dev Emitted when `book` does not exist
/// @param book The book that does not exist
error BookNotFound(bytes32 book);

/// @dev Emitted when `book` is not owned by `account`
/// @param tokenId The token that is not owned
/// @param account The account that does not own the book
error BookNotOwned(uint tokenId, address account);

/// @dev Emitted when `book` is already consumed
/// @param tokenId The token that is already consumed
/// @param account The account that consumed the book
error BookAlreadyConsumed(uint tokenId, address account);