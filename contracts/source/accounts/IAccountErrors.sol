// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./AccountEnums.sol";    

/// @title Custom account errors
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IAccountErrors {

    /// @dev Emitted when `account` is not registered
    /// @param account The account that is not registered
    error AccountNotRegistered(address account);

    // @dev Emitted when `username` is invalid
    /// @param username The username that is invalid
    /// @param reason The reason why the username is invalid
    error AccountInvalidUsername(bytes32 username, string reason);

    /// @dev Emitted when `username` is already taken
    /// @param username The username that is already taken
    error AccountDupicateUsername(bytes32 username);

    /// @dev Emitted when `relationship` is invalid
    /// @param relationship The relationship that is invalid
    error AccountInvalidRelationship(AccountEnums.Relationship relationship);

    /// @dev Emitted when `account` is already a friend
    /// @param account The account that is already a friend
    error AccountAlreadyFriends(address account);

    /// @dev Emitted when there is already a pending friend request for `account` 
    /// @param account The account that already has a pending friend request
    error AccountDuplicateFriendRequest(address account);

    /// @dev Emitted when there is no pending friend request for `account`
    /// @param account The account that has no pending friend request
    error AccountMissingFriendRequest(address account);
}