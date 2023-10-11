// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "./types/AccountEnums.sol";

/// @title Cryptopia Account Register
/// @notice Creates and registers accounts
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IAccountRegister {

    /// @dev Allows verified creation of a Cryptopia account. Use of create2 allows identical addresses across networks
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, Sex sex) 
        external 
        returns (address payable account);


    /// @dev Check if an account was created and registered 
    /// @param account Account address.
    /// @return true if account is registered.
    function isRegistered(address account) 
        external view 
        returns (bool);


    /// @dev Retrieve account info 
    /// @param account The account to retrieve info for
    /// @return username Account username
    /// @return sex {Undefined, Male, Female}
    function getAccountData(address account) 
        external view 
        returns (
            bytes32 username,
            Sex sex
        );


    /// @dev Retrieve account info for a range of addresses
    /// @param addresses contract adresses
    /// @return username Account usernames
    /// @return sex {Undefined, Male, Female}
    function getAccountDatas(address payable[] memory addresses) 
        external view 
        returns (
            bytes32[] memory username,
            Sex[] memory sex
        );

    
    /// @dev Returns the amount of friends for `account`
    /// @param account The account to query 
    /// @return uint number of friends
    function getFriendCount(address account) 
        external view 
        returns (uint);


    /// @dev Returns the `friend_account` and `friend_username` of the friend at `index` for `account`
    /// @param account The account to retrieve the friend for (subject)
    /// @param index The index of the friend to retrieve
    /// @return friend_account The address of the friend
    /// @return friend_username The unique username of the friend
    /// @return friend_relationship The type of relationship `account` has with the friend
    function getFriendAt(address account, uint index) 
        external view 
        returns (
            address friend_account, 
            bytes32 friend_username,
            Relationship friend_relationship
        );


    /// @dev Returns an array of friends for `account`
    /// @param account The account to retrieve the friends for (subject)
    /// @param skip Location where the cursor will start in the array
    /// @param take The amount of friends to return
    /// @return friend_accounts The addresses of the friends
    /// @return friend_usernames The unique usernames of the friends
    /// @return friend_relationships The type of relationship `account` has with the friends
    function getFriends(address account, uint skip, uint take) 
        external view 
        returns (
            address[] memory friend_accounts, 
            bytes32[] memory friend_usernames,
            Relationship[] memory friend_relationships
        );


    /// @dev Returns true if `account` and `other` are friends
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if `account` and `other` are friends
    function isFriend(address account, address other) 
        external view
        returns (bool);

    
    /// @dev Returns true if `account` and `other` have 'relationship'
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @param relationship The type of relationship to test
    /// @return bool True if `account` and `other` have 'relationship'
    function hasRelationsip(address account, address other, Relationship relationship) 
        external view
        returns (bool);

    
    /// @dev Returns true if a pending friend request between `account` and `other` exists
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if a pending friend request exists
    function hasPendingFriendRequest(address account, address other) 
        external view
        returns (bool);


    /// @dev Request friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to add the friend request for
    /// @param friend_relationship The type of relationship that is requested
    function addFriendRequest(address friend_account, Relationship friend_relationship) 
        external;


    /// @dev Request friendship with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to add the friend requests for
    /// @param friend_relationships The type of relationships that are requested
    function addFriendRequests(address[] memory friend_accounts, Relationship[] memory friend_relationships) 
        external;


    /// @dev Removes the friend request with `friend_account` for `msg.sender`
    /// @param friend_account The account to remove the friend request for
    function removeFriendRequest(address friend_account) 
        external;


    /// @dev Removes the friend requests with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to remove the friend requests for
    function removeFriendRequests(address[] memory friend_accounts) 
        external;

    
    /// @dev Accept friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to accept the friend request for
    function acceptFriendRequest(address friend_account) 
        external;


    /// @dev Accept friendships with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to accept the friend requests for
    function acceptFriendRequests(address[] memory friend_accounts) 
        external;
}