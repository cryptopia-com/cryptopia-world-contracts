// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @title Player freeze control
interface IPlayerFreezeControl {

    /**
     * System functions
     */
    /// @dev Prevents `account` from traveling `until`
    /// @param account The player to lock
    /// @param until The datetime on which the lock expires
    function __freeze(address account, uint64 until) 
        external;

    
    /// @dev Unfreeze `account`
    /// @param account The player to unfreeze
    function __unfreeze(address account)
        external;
}