// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/Create2Upgradeable.sol";

import "../types/AccountEnums.sol";
import "../errors/AccountErrors.sol";
import "../IAccountRegister.sol";
import "./CryptopiaAccount.sol";

/// @title Cryptopia Account Register
/// @notice Creates and registers accountDatas
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAccountRegister is IAccountRegister {

    struct AccountData
    {
        // Unique and validated username
        bytes32 username;

        // Optional sex {Undefined, Male, Female}
        Sex sex;

        mapping (address => Relationship) friends;
        address[] friendsIndex;

        mapping (address => Relationship) friendRequests;
    }


    /**
     * Storage
     */
    uint constant private USERNAME_MIN_LENGTH = 3;

    mapping(bytes32 => address) public usernameToAccount;
    mapping (address => AccountData) public accountDatas;


    /**
     * Events
     */
    /// @dev Emited when an account is created
    /// @param sender The addres that created the account (tx.origin)
    /// @param account The address of the newly created account (smart-contract)
    /// @param username The unique username of the newly created account (smart-contract)
    /// @param sex {Undefined, Male, Female}
    event CreateAccount(address indexed sender, address indexed account, bytes32 indexed username, Sex sex);

    /// @dev Emited when a friend request is added
    /// @param sender The addres that added the friend request
    /// @param receiver The address that `sender` requests to be friends with
    /// @param relationship The type of friendship
    event AddFriendRequest(address indexed sender, address indexed receiver, Relationship indexed relationship);

    /// @dev Emited when a friend request is removed
    /// @param sender The addres that added the friend request
    /// @param receiver The address that `sender` requested to be friends with
    /// @param relationship The type of friendship
    event RemoveFriendRequest(address indexed sender, address indexed receiver, Relationship indexed relationship);

    /// @dev Emited when a friend request is accepted
    /// @param sender The addres that added the friend request
    /// @param receiver The address that `sender` requested to be friends with
    /// @param relationship The type of friendship
    event AcceptFriendRequest(address indexed sender, address indexed receiver, Relationship indexed relationship);


    /**
     * Errors
     */
    // @dev Emitted when `username` is invalid
    /// @param username The username that is invalid
    /// @param reason The reason why the username is invalid
    error InvalidUsername(bytes32 username, string reason);

    /// @dev Emitted when `username` is already taken
    /// @param username The username that is already taken
    error DupicateUsername(bytes32 username);

    /// @dev Emitted when `relationship` is invalid
    /// @param relationship The relationship that is invalid
    error InvalidRelationship(Relationship relationship);

    /// @dev Emitted when a `account` is invalid for a friend request
    /// @param account The account that is invalid for a friend request
    error InvalidFriendRequest(address account);

    /// @dev Emitted when `account` is already a friend
    /// @param account The account that is already a friend
    error AlreadyFriends(address account);

    /// @dev Emitted when there is already a pending friend request for `account` 
    /// @param account The account that already has a pending friend request
    error DuplicateFriendRequest(address account);

    /// @dev Emitted when there is no pending friend request for `account`
    /// @param account The account that has no pending friend request
    error MissingFriendRequest(address account);


    /**
     * Modifiers
     */
    /// @dev Only allow if `account` is registered
    /// @param account The account to check
    modifier onlyRegistered(address account) 
    {
        if (!_isRegistered(account)) 
        {
            revert AccountNotRegistered(account);
        }
        _;
    }


    /// @dev Only allow validated username
    /// @param username The username to check 
    modifier onlyValidUsername(bytes32 username) 
    {
        (bool isValid, string memory reason) = _validateUsername(username);

        // Ensure valid username
        if (!isValid) 
        {
            revert InvalidUsername(username, reason);
        }

        // Ensure username is not taken
        if (usernameToAccount[username] != address(0)) 
        {
            revert DupicateUsername(username);
        }
        _;
    }


    /** 
     * Public functions
     */
    /// @dev Allows verified creation of a Cryptopia account. Use of create2 allows identical addresses across networks
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, Sex sex)
        public virtual override 
        onlyValidUsername(username)
        returns (address payable account)
    {
        account = payable(Create2Upgradeable.deploy(
            0, username, type(CryptopiaAccount).creationCode));

        CryptopiaAccount(account).initialize(
            owners, required, dailyLimit, username);

        _register(account, username, sex);
    }


    /// @dev Check if an account was created and registered 
    /// @param account Account address
    /// @return true if account is registered
    function isRegistered(address account)
        public virtual override view 
        returns (bool)
    {
        return _isRegistered(account);
    }


    /// @dev Retrieve account info 
    /// @param account The account to retrieve info for
    /// @return username Account username
    /// @return sex {Undefined, Male, Female}
    function getAccountData(address account) 
        public virtual override view 
        returns (
            bytes32 username,
            Sex sex
        )
    {
        username = accountDatas[account].username;
        sex = accountDatas[account].sex;
    }


    /// @dev Retrieve account info for a range of accounts
    /// @param accounts contract adresses
    /// @return username Account usernames
    /// @return sex {Undefined, Male, Female}
    function getAccountDatas(address payable[] memory accounts) 
        public virtual override view  
        returns (
            bytes32[] memory username,
            Sex[] memory sex
        )
    {
        username = new bytes32[](accounts.length);
        sex = new Sex[](accounts.length);
        for (uint i = 0; i < accounts.length; i++)
        {
            if (_isRegistered(accounts[i]))
            {
                username[i] = accountDatas[accounts[i]].username;
                sex[i] = accountDatas[accounts[i]].sex;
            }
        }
    }


    /// @dev Returns the amount of friends for `account`
    /// @param account The account to query 
    /// @return uint number of friends
    function getFriendCount(address account) 
        public override view 
        returns (uint)
    {
        return accountDatas[account].friendsIndex.length;
    }


    /// @dev Returns the `friend_account` and `friend_username` of the friend at `index` for `account`
    /// @param account The account to retrieve the friend for (subject)
    /// @param index The index of the friend to retrieve
    /// @return friend_account The address of the friend
    /// @return friend_username The unique username of the friend
    /// @return friend_relationship The type of relationship `account` has with the friend
    function getFriendAt(address account, uint index) 
        public override view 
        returns (
            address friend_account, 
            bytes32 friend_username,
            Relationship friend_relationship
        )
    {
        friend_account = accountDatas[account].friendsIndex[index];
        friend_username = accountDatas[friend_account].username;
        friend_relationship = accountDatas[account].friends[friend_account];
    }


    /// @dev Returns an array of friends for `account`
    /// @param account The account to retrieve the friends for (subject)
    /// @param skip Location where the cursor will start in the array
    /// @param take The amount of friends to return
    /// @return friend_accounts The addresses of the friends
    /// @return friend_usernames The unique usernames of the friends
    /// @return friend_relationships The type of relationship `account` has with the friends
    function getFriends(address account, uint skip, uint take) 
        public override view 
        returns (
            address[] memory friend_accounts, 
            bytes32[] memory friend_usernames,
            Relationship[] memory friend_relationships
        )
    {
        friend_accounts = new address[](take);
        friend_usernames = new bytes32[](take);
        friend_relationships = new Relationship[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            friend_accounts[i] = accountDatas[account].friendsIndex[index];
            friend_usernames[i] = accountDatas[friend_accounts[i]].username;
            friend_relationships[i] = accountDatas[account].friends[friend_accounts[i]];
            index++;
        }
    }


    /// @dev Returns true if `account` and `other` are friends
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if `account` and `other` are friends
    function isFriend(address account, address other) 
        public override view
        returns (bool)
    {
        return _isFriend(account, other);
    }


    /// @dev Returns true if `account` and `other` have 'relationship'
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @param relationship The type of relationship to test
    /// @return bool True if `account` and `other` have 'relationship'
    function hasRelationsip(address account, address other, Relationship relationship) 
        public override view
        returns (bool)
    {
        return accountDatas[account].friends[other] == relationship;
    }


    /// @dev Returns true if a pending friend request between `account` and `other` exists
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if a pending friend request exists
    function hasPendingFriendRequest(address account, address other) 
        public override view
        returns (bool)
    {
        return _hasPendingFriendRequest(account, other);
    }


    /// @dev Request friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to add the friend request for
    /// @param friend_relationship The type of relationship that is requested
    function addFriendRequest(address friend_account, Relationship friend_relationship) 
        public override 
    {
        _addFriendRequest(friend_account, friend_relationship);
    }


    /// @dev Request friendship with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to add the friend requests for
    /// @param friend_relationships The type of relationships that are requested
    function addFriendRequests(address[] memory friend_accounts, Relationship[] memory friend_relationships) 
       public override 
    {
        for (uint i = 0; i < friend_accounts.length; i++)
        {
            _addFriendRequest(friend_accounts[i], friend_relationships[i]);
        }
    }


    /// @dev Removes the friend request with `friend_account` for `msg.sender`
    /// @param friend_account The account to remove the friend request for
    function removeFriendRequest(address friend_account) 
        public override 
    {
        _removeFriendRequest(friend_account);
    }


    /// @dev Removes the friend requests with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to remove the friend requests for
    function removeFriendRequests(address[] memory friend_accounts) 
        public override 
    {
        for (uint i = 0; i < friend_accounts.length; i++)
        {
            _removeFriendRequest(friend_accounts[i]);
        }
    }

    
    /// @dev Accept friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to accept the friend request for
    function acceptFriendRequest(address friend_account) 
        public override 
    {
        _acceptFriendRequest(friend_account);
    }


    /// @dev Accept friendships with `friend_accounts` for `msg.sender`
    /// @param friend_accounts The accounts to accept the friend requests for
    function acceptFriendRequests(address[] memory friend_accounts) 
        public override 
    {
        for (uint i = 0; i < friend_accounts.length; i++)
        {
            _acceptFriendRequest(friend_accounts[i]);
        }
    }


    /**
     * Internal functions
     */
    /// @dev Registers contract in factory registry.
    /// @param account Address of account contract instantiation
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    function _register(address account, bytes32 username, Sex sex) 
        internal 
    {
        // Register
        usernameToAccount[username] = account;
        accountDatas[account].username = username;
        accountDatas[account].sex = sex;

        // Emit
        emit CreateAccount(tx.origin, account, username, sex);
    }


    /// @dev Check if `account` is registered
    /// @param account The account to check
    /// @return bool True if  `account` is a registered account
    function _isRegistered(address account) 
        internal view 
        returns (bool)
    {
        return accountDatas[account].username != bytes32(0);
    }


    /// @dev Returns true if `account` and `other` are friends
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if `account` and `other` are friends
    function _isFriend(address account, address other) 
        internal view
        returns (bool)
    {
        return accountDatas[account].friends[other] != Relationship.None;
    }


    /// @dev Returns true if a pending friend request between `account` and `other` exists
    /// @param account The (left) account to test 
    /// @param other The other (right) account to test
    /// @return bool True if a pending friend request exists
    function _hasPendingFriendRequest(address account, address other) 
        internal view
        returns (bool)
    {
        return accountDatas[account].friendRequests[other] != Relationship.None && 
               accountDatas[other].friendRequests[account] != Relationship.None;
    }


    /// @dev Request friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to add the friend request for
    /// @param friend_relationship The type of relationship that is requested
    function _addFriendRequest(address friend_account, Relationship friend_relationship) 
        internal 
        onlyRegistered(msg.sender) 
    {
        // Ensure valid relationship
        if (!_validateRelationship(friend_relationship))
        {
            revert InvalidRelationship(friend_relationship);
        }

        // Ensure user isn't sending a friend request to themselves
        if (msg.sender == friend_account)
        {
            revert InvalidFriendRequest(friend_account);
        }

        // Ensure that the friend account is registered
        if (!_isRegistered(friend_account))
        {
            revert AccountNotRegistered(friend_account);
        }

        // Ensure that the friend account is not already a friend
        if (_isFriend(msg.sender, friend_account))
        {
            revert AlreadyFriends(friend_account);
        }

        // Ensure that there is no pending friend request already for the friend account
        if (_hasPendingFriendRequest(msg.sender, friend_account))
        {
            revert DuplicateFriendRequest(friend_account);
        }

        // Add 
        accountDatas[msg.sender].friendRequests[friend_account] = friend_relationship;

        // Emit
        emit AddFriendRequest(msg.sender, friend_account, friend_relationship);
    } 


    /// @dev Removes the friend request with `friend_account` for `msg.sender`
    /// @param friend_account The account to remove the friend request for
    function _removeFriendRequest(address friend_account) 
        internal 
    {
        // Ensure that the friend account is registered
        if (!_hasPendingFriendRequest(msg.sender, friend_account))
        {
            revert MissingFriendRequest(friend_account);
        }

        // Remove 
        Relationship relationship = accountDatas[msg.sender].friendRequests[friend_account];
        accountDatas[msg.sender].friendRequests[friend_account] = Relationship.None;

        // Emit
        emit RemoveFriendRequest(msg.sender, friend_account, relationship);
    }


    /// @dev Accept friendship with `friend_account` for `msg.sender`
    /// @param friend_account The account to accept the friend request for
    function _acceptFriendRequest(address friend_account) 
        internal 
    {
        if (!_hasPendingFriendRequest(friend_account, msg.sender))
        {
            revert MissingFriendRequest(friend_account);
        }

        // Remove friend request
        Relationship relationship = accountDatas[friend_account].friendRequests[msg.sender];
        accountDatas[friend_account].friendRequests[msg.sender] = Relationship.None;

        // Add friendship
        accountDatas[msg.sender].friends[friend_account] = relationship;
        accountDatas[friend_account].friends[msg.sender] = relationship;

        // Emit
        emit AcceptFriendRequest(friend_account, msg.sender, relationship);
    }


    /// @dev Validate `username`
    /// @param username The username value to test
    /// @return isValid True if `username` is valid
    /// @return reason The reason why the username is not valid
    function _validateUsername(bytes32 username)
        internal pure 
        returns (bool isValid, string memory reason)
    {
        bool foundEnd = false;
        for(uint i = 0; i < username.length; i++)
        {
            bytes1 char = username[i];
            if (char == 0x00)
            {
                if (!foundEnd)
                {
                    if (i < USERNAME_MIN_LENGTH)
                    {
                        return (false, "Too short");
                    }

                    foundEnd = true;
                }
                
                continue;
            }
            else if (foundEnd)
            {
                return (false, "Expected end");
            }

            if (!(char >= 0x30 && char <= 0x39) && //9-0
                !(char >= 0x41 && char <= 0x5A) && //A-Z
                !(char >= 0x61 && char <= 0x7A) && //a-z)
                !(char == 0x5F)) // _
            {
                return (false, "Invalid char");
            }
        }

        return (true, "");
    }


    /// @dev Validate `relationship`
    /// @param relationship The relationship value to test
    /// @return bool True if `relationship` is valid
    function _validateRelationship(Relationship relationship)
        internal pure 
        returns (bool)
    {
        return relationship > Relationship.None && relationship <= Relationship.Spouse;
    }
}