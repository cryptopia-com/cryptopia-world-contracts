// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @title Player freeze control
interface IPlayerFreezeControl {

    /**
     * System functions
     */
    /// @dev Freezes `account` `until`
    /// @param account The player to freeze
    /// @param until The datetime on which the lock expires
    function __freeze(address account, uint64 until) 
        external;

    
    /// @dev Freezes `account1` and `account2` `until`
    /// @param account1 The first player to freeze
    /// @param account2 The second player to freeze
    /// @param until The datetime on which the lock expires
    function __freeze(address account1, address account2, uint64 until) 
        external;

    
    /// @dev Unfreeze `account`
    /// @param account The player to unfreeze
    function __unfreeze(address account)
        external;
        

    /// @dev Unfreeze `account1` and `account2`
    /// @param account1 The first player to unfreeze
    /// @param account2 The second player to unfreeze
    function __unfreeze(address account1, address account2)
        external;
}