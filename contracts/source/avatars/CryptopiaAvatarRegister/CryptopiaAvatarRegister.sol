// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../../accounts/CryptopiaAccountRegister/ICryptopiaAccountRegister.sol";
import "../AvatarEnums.sol";
import "./ICryptopiaAvatarRegister.sol";

/// @title Cryptopia Avatar Register
/// @notice Register for avatar data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAvatarRegister is ICryptopiaAvatarRegister, ContextUpgradeable {

    struct AvatarData
    {
        // Required {Male, Female}
        AvatarEnums.Gender gender;

        // Body
        uint8 bodyWeight; // in kilos
        uint8 bodyShape; // muscular for male, roudings for female

        // Colors
        uint8 hairColorIndex;
        uint8 eyeColorIndex;
        uint8 skinColorIndex;

        // Style
        uint8 defaultHairStyleIndex;

        // Outfit
        uint8 defaultHeadWearIndex;
        uint8 defaultTopWearIndex;
        uint8 defaultBottomWearIndex;
        uint8 defaultFootWearIndex;

        // Accessories
        uint8 defaultAccessoryIndex;

        //uint144 facialSettings;
    }


    /**
     * Storage
     */
    // Refs
    address public accountRegisterContract;

    // Account => AvatarData
    mapping (address => AvatarData) public avatarDatas;


    /**
     * Events
     */
    /// @dev Emited when an avatar is changed
    /// @param account The address of the (multisig) account that owns the avatar data
    event ChangeAvatarData(address indexed account);


    /** 
     * Public functions
     */
    /// @param _accountRegisterContract Contract responsible for accounts
    function initialize(
        address _accountRegisterContract) 
        public initializer 
    {
        __Context_init();

        // Assign refs
        accountRegisterContract = _accountRegisterContract;
    }


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
        public virtual override view 
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
        )
    {
        gender = avatarDatas[account].gender;
        bodyWeight = avatarDatas[account].bodyWeight;
        bodyShape = avatarDatas[account].bodyShape;
        hairColorIndex = avatarDatas[account].hairColorIndex;
        eyeColorIndex = avatarDatas[account].eyeColorIndex;
        skinColorIndex = avatarDatas[account].skinColorIndex;
        defaultHairStyleIndex = avatarDatas[account].defaultHairStyleIndex;
        defaultHeadWearIndex = avatarDatas[account].defaultHeadWearIndex;
        defaultTopWearIndex = avatarDatas[account].defaultTopWearIndex;
        defaultBottomWearIndex = avatarDatas[account].defaultBottomWearIndex;
        defaultFootWearIndex = avatarDatas[account].defaultFootWearIndex;
        defaultAccessoryIndex = avatarDatas[account].defaultAccessoryIndex;
    }


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
        public virtual override view 
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
        )
    {
        gender = new AvatarEnums.Gender[](accounts.length);
        bodyWeight = new uint8[](accounts.length);
        bodyShape = new uint8[](accounts.length);
        hairColorIndex = new uint8[](accounts.length);
        eyeColorIndex = new uint8[](accounts.length);
        skinColorIndex = new uint8[](accounts.length);
        defaultHairStyleIndex = new uint8[](accounts.length);
        defaultHeadWearIndex = new uint8[](accounts.length);
        defaultTopWearIndex = new uint8[](accounts.length);
        defaultBottomWearIndex = new uint8[](accounts.length);
        defaultFootWearIndex = new uint8[](accounts.length);
        defaultAccessoryIndex = new uint8[](accounts.length);
        
        for (uint i = 0; i < accounts.length; i++)
        {
            gender[i] = avatarDatas[accounts[i]].gender;
            bodyWeight[i] = avatarDatas[accounts[i]].bodyWeight;
            bodyShape[i] = avatarDatas[accounts[i]].bodyShape;
            hairColorIndex[i] = avatarDatas[accounts[i]].hairColorIndex;
            eyeColorIndex[i] = avatarDatas[accounts[i]].eyeColorIndex;
            skinColorIndex[i] = avatarDatas[accounts[i]].skinColorIndex;
            defaultHairStyleIndex[i] = avatarDatas[accounts[i]].defaultHairStyleIndex;
            defaultHeadWearIndex[i] = avatarDatas[accounts[i]].defaultHeadWearIndex;
            defaultTopWearIndex[i] = avatarDatas[accounts[i]].defaultTopWearIndex;
            defaultBottomWearIndex[i] = avatarDatas[accounts[i]].defaultBottomWearIndex;
            defaultFootWearIndex[i] = avatarDatas[accounts[i]].defaultFootWearIndex;
            defaultAccessoryIndex[i] = avatarDatas[accounts[i]].defaultAccessoryIndex;
        }
    }


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
        uint8 defaultAccessoryIndex) 
    public virtual override 
    {
        address account = _msgSender();
        require(
            ICryptopiaAccountRegister(accountRegisterContract).isRegistered(account), 
            "CryptopiaAvatarRegister: Not registered"
        );

        // Set avatar data
        AvatarData storage avatarData = avatarDatas[account];
        avatarData.gender = gender;
        avatarData.bodyWeight = bodyWeight;
        avatarData.bodyShape = bodyShape;
        avatarData.hairColorIndex = hairColorIndex;
        avatarData.eyeColorIndex = eyeColorIndex;
        avatarData.skinColorIndex = skinColorIndex;
        avatarData.defaultHairStyleIndex = defaultHairStyleIndex;
        avatarData.defaultHeadWearIndex = defaultHeadWearIndex;
        avatarData.defaultTopWearIndex = defaultTopWearIndex;
        avatarData.defaultBottomWearIndex = defaultBottomWearIndex;
        avatarData.defaultFootWearIndex = defaultFootWearIndex;
        avatarData.defaultAccessoryIndex = defaultAccessoryIndex;

        // Emit (assume change)
        emit ChangeAvatarData(account);
    }
}