// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 <0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol";

import "../../accounts/IAccountRegister.sol";
import "../../accounts/errors/AccountErrors.sol";
import "../IAvatarRegister.sol";

/// @title Cryptopia Avatar Register
/// @notice Register for avatar data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAvatarRegister is IAvatarRegister, ContextUpgradeable {

    /**
     * Storage
     */
    // Refs
    address public accountRegisterContract;

    // Avatar data (bitmask)
    // 16 unused bits = 0xF << 240 
    // modelIndex = 0x6 << 234
    // eyeOuterAngle = 0x6 << 228
    // eyeInnerAngle = 0x6 << 222
    // eyeShrink = 0x6 << 216
    // eyelashLength = 0x6 << 210
    // noseHeight = 0x6 << 204
    // noseWidth = 0x6 << 198
    // noseLength = 0x6 << 192
    // noseHook = 0x6 << 186
    // noseUpturn = 0x6 << 180
    // mouthHeight = 0x6 << 174
    // mouthWidth = 0x6 << 168
    // mouthThin = 0x6 << 162
    // chestHeight = 0x6 << 156
    // chestSize = 0x6 << 150
    // chestDistance = 0x6 << 144
    // waistSize = 0x6 << 138
    // gluteHeight = 0x6 << 132
    // gluteSize = 0x6 << 126
    // bodyThin = 0x6 << 120
    // bodyAthletic = 0x6 << 114
    // bodyHeavy = 0x6 << 108
    // nailLength = 0x6 << 102
    // hairColorIndex = 0x6 << 96
    // eyeColorIndex = 0x6 << 90
    // skinMaterialIndex = 0x6 << 84
    // skinTintIndex = 0x6 << 78
    // defaultHairStyleIndex = 0x6 << 72
    // defaultBrowStyleIndex = 0x6 << 66
    // defaultFaceModelIndex = 0x6 << 60
    // defaultHeadWearIndex = 0x6 << 54
    // defaultTopWearIndex = 0x6 << 48
    // defaultShoulderWearIndex = 0x6 << 42
    // defaultHandModelIndex = 0x6 << 36
    // defaultBottomWearIndex = 0x6 << 30
    // defaultFootWearIndex = 0x6 << 24
    // defaultBackWearIndex = 0x6 << 18
    // defaultEyeWearIndex = 0x6 << 12
    // defaultWaistWearIndex = 0x6 << 6
    // defaultAdornmentIndex = 0x6 << 0
    mapping (address => bytes32) public avatarDatas;


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
    /// @return data The avatar appearance (bitmask)
    function getAvatarData(address account)
        public virtual override view 
        returns (bytes32 data)
    {
        return avatarDatas[account];
    }


    /// @dev Returns data that is used to create the avatar for `account`
    /// @param accounts The addresses of the (mulstisig) accounts to return the avatar data for
    /// @return data The avatar appearance (bitmask)
    function getAvatarDatas(address[] memory accounts)
        public virtual override view 
        returns (bytes32[] memory data)
    {
        data = new bytes32[](accounts.length);
        for (uint i = 0; i < accounts.length; i++)
        {
            data[i] = avatarDatas[accounts[i]];
        }
    }


    /// @dev Sets data that is used to create the avatar for an account (msg.sender)
    /// @param data The avatar appearance (bitmask)
    function setAvatarData(bytes32 data) 
        public virtual override 
    {
        address account = _msgSender();
    
        // Check if account is registered
        if (!IAccountRegister(accountRegisterContract).isRegistered(account)) 
        {
            revert AccountNotRegistered(account);
        }

        // Set avatar data
        avatarDatas[account] = data;

        // Emit (assume change)
        emit ChangeAvatarData(account);
    }
}