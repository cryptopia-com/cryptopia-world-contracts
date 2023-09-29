// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../AvatarEnums.sol";

/// @title Cryptopia Avatar Register
/// @notice Register for avatar data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaAvatarRegister {

    /// @dev Returns data that is used to create the avatar for `account`
    /// @param account The address of the (mulstisig) account to return the avatar data for
    /// @return gender {Male, Female}
    /// @return bodyWeight The avatar body weight in kilos
    /// @return bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @return hairColorIndex Refers to a hair color in the game client
    /// @return eyeColorIndex Refers to an eye color in the game client
    /// @return skinColorIndex Refers to a skin color in the game client
    /// @return defaultHairStyleIndex Refers to a default hair style in the game client
    /// @return defaultHeadWearIndex Refers to default headwear in the game client (0 signals no headwear)
    /// @return defaultTopWearIndex Refers to default topwear in the game client (0 signals no topwear)
    /// @return defaultBottomWearIndex Refers to default bottomwear in the game client (0 signals no bottomwear)
    /// @return defaultFootWearIndex Refers to default footwear in the game client (0 signals no footwear)
    /// @return defaultAccessoryIndex Refers to default accessories in the game client (0 signals no accessory)
    function getAvatarData(address account)
        external view 
        returns (
            AvatarEnums.Gender gender,
            uint8 bodyWeight,
            uint8 bodyShape,
            uint8 hairColorIndex,
            uint8 eyeColorIndex,
            uint8 skinColorIndex,
            uint8 defaultHairStyleIndex,
            uint8 defaultHeadWearIndex,
            uint8 defaultTopWearIndex,
            uint8 defaultBottomWearIndex,
            uint8 defaultFootWearIndex,
            uint8 defaultAccessoryIndex
        );


    /// @dev Returns data that is used to create the avatar for `account`
    /// @param accounts The addresses of the (mulstisig) accounts to return the avatar data for
    /// @return gender {Male, Female}
    /// @return bodyWeight The avatar body weight in kilos
    /// @return bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @return hairColorIndex Refers to a hair color in the game client
    /// @return eyeColorIndex Refers to an eye color in the game client
    /// @return skinColorIndex Refers to a skin color in the game client
    /// @return defaultHairStyleIndex Refers to a default hair style in the game client
    /// @return defaultHeadWearIndex Refers to default headwear in the game client (0 signals no headwear)
    /// @return defaultTopWearIndex Refers to default topwear in the game client (0 signals no topwear)
    /// @return defaultBottomWearIndex Refers to default bottomwear in the game client (0 signals no bottomwear)
    /// @return defaultFootWearIndex Refers to default footwear in the game client (0 signals no footwear)
    /// @return defaultAccessoryIndex Refers to default accessories in the game client (0 signals no accessory)
    function getAvatarDatas(address[] memory accounts)
        external view 
        returns (
            AvatarEnums.Gender[] memory gender,
            uint8[] memory bodyWeight,
            uint8[] memory bodyShape,
            uint8[] memory hairColorIndex,
            uint8[] memory eyeColorIndex,
            uint8[] memory skinColorIndex,
            uint8[] memory defaultHairStyleIndex,
            uint8[] memory defaultHeadWearIndex,
            uint8[] memory defaultTopWearIndex,
            uint8[] memory defaultBottomWearIndex,
            uint8[] memory defaultFootWearIndex,
            uint8[] memory defaultAccessoryIndex
        );


    /// @dev Sets data that is used to create the avatar for an account (msg.sender)
    /// @param gender {Male, Female}
    /// @param bodyWeight The avatar body weight in kilos
    /// @param bodyShape The avatar body shape, the higher the value the better the shape (muscles for male, roundings for female)
    /// @param hairColorIndex Refers to a hair color in the game client
    /// @param eyeColorIndex Refers to an eye color in the game client
    /// @param skinColorIndex Refers to a skin color in the game client
    /// @param defaultHairStyleIndex Refers to a default hair style in the game client
    /// @param defaultHeadWearIndex Refers to default headwear in the game client (0 signals no headwear)
    /// @param defaultTopWearIndex Refers to default topwear in the game client (0 signals no topwear)
    /// @param defaultBottomWearIndex Refers to default bottomwear in the game client (0 signals no bottomwear)
    /// @param defaultFootWearIndex Refers to default footwear in the game client (0 signals no footwear)
    /// @param defaultAccessoryIndex Refers to default accessories in the game client (0 signals no accessory)
    function setAvatarData(
        AvatarEnums.Gender gender,
        uint8 bodyWeight,
        uint8 bodyShape,
        uint8 hairColorIndex,
        uint8 eyeColorIndex,
        uint8 skinColorIndex,
        uint8 defaultHairStyleIndex,
        uint8 defaultHeadWearIndex,
        uint8 defaultTopWearIndex,
        uint8 defaultBottomWearIndex,
        uint8 defaultFootWearIndex,
        uint8 defaultAccessoryIndex
    ) external;
}