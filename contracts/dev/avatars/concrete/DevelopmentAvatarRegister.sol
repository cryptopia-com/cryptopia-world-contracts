// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../source/avatars/concrete/CryptopiaAvatarRegister.sol";

/// @title Cryptopia Avatar Register Contract
/// @notice Manages and stores avatar customization data for players in Cryptopia.
/// This contract serves as a centralized repository for avatar attributes, allowing players to personalize their avatars.
/// It handles the storage of detailed avatar characteristics, including physical features, clothing, and accessories.
/// The customization options are extensive, offering players the ability to create avatars that reflect their unique style and preferences.
/// @dev Inherits from ContextUpgradeable and implements the IAvatarRegister interface.
/// Utilizes a mapping to store avatar data for each player's account, encoded as a bytes32 bitmask.
/// This design ensures efficient storage and retrieval of a wide range of avatar attributes.
/// The contract ensures that only registered accounts can set or modify avatar data, maintaining consistency and security within the game's ecosystem.
/// Events are emitted when avatar data is changed, providing transparency and traceability of modifications.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentAvatarRegister is CryptopiaAvatarRegister, AccessControlUpgradeable {

    /// @dev Initializer
    /// @param _accountRegisterContract Contract responsible for accounts
    function initialize(address _accountRegisterContract)
        public override initializer 
    {
        CryptopiaAvatarRegister.initialize(_accountRegisterContract);

        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev Remove the avatar data from the register
    /// @param accounts The accounts to remove
    function clean(address[] calldata accounts) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            delete avatarDatas[accounts[i]];
        }
    }
}