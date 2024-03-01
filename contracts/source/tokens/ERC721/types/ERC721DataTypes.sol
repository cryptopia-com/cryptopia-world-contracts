// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @dev Represents a pair of tokens
/// @notice Used as return type to prevent stack too deep errors and save gas
struct TokenPair {
    uint tokenId1;
    uint tokenId2;
}