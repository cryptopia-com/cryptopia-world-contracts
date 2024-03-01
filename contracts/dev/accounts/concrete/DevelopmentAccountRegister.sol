// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "../../../source/accounts/concrete/CryptopiaAccountRegister.sol";

/// @title CryptopiaAccountRegister
/// @notice This contract is essential for managing player profiles in Cryptopia, 
/// providing mechanisms for account creation and player development. It tracks and manages key player 
/// data, including usernames, gender, and social connections. The contract is designed to ensure 
/// a seamless and engaging player experience, facilitating social interactions within the game through 
/// friend requests and relationship management.
/// @dev Inherits from Initializable, implementing the IAccountRegister interface.
/// It follows an upgradable pattern to support future expansions and modifications. The contract focuses on 
/// detailed player data management, crucial for maintaining the integrity of player interactions and 
/// the overall game dynamics. This includes maintaining friendships, handling friend requests, and 
/// supporting diverse player interactions.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentAccountRegister is CryptopiaAccountRegister, AccessControlUpgradeable {

    /// @dev Initializer
    function initialize() 
        initializer public 
    {
        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev Remove the account data from the register
    /// @param accounts The accounts to remove
    function clean(address[] calldata accounts) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            AccountData storage data = accountDatas[accounts[i]];
            delete usernameToAccount[data.username];
            delete accountDatas[accounts[i]];
        }
    }
}