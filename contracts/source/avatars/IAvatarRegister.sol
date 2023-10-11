// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Cryptopia Avatar Register
/// @notice Register for avatar data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IAvatarRegister {

    /// @dev Returns data that is used to create the avatar for `account`
    /// @param account The address of the (mulstisig) account to return the avatar data for
    /// @return data The avatar appearance (bitmask)
    function getAvatarData(address account)
        external view 
        returns (bytes32 data);


    /// @dev Returns data that is used to create the avatar for `account`
    /// @param accounts The addresses of the (mulstisig) accounts to return the avatar data for
    /// @return data The avatar appearance (bitmask)
    function getAvatarDatas(address[] memory accounts)
        external view 
        returns (bytes32[] memory data);


    /// @dev Sets data that is used to create the avatar for an account (msg.sender)
    /// @param data The avatar appearance (bitmask)
    function setAvatarData(bytes32 data) 
        external;
}