// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/// @title Cryptopia Avatar Register Contract
/// @notice Manages and stores avatar customization data for players in Cryptopia.
/// This contract serves as a centralized repository for avatar attributes, allowing players to personalize their avatars.
/// It handles the storage of detailed avatar characteristics, including physical features, clothing, and accessories.
/// The customization options are extensive, offering players the ability to create avatars that reflect their unique style and preferences.
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