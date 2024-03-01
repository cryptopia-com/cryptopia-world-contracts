// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/quests/concrete/CryptopiaQuests.sol";

/// @title Cryptopia Quests Contract
/// @notice Handles the functionality of quests within Cryptopia. 
/// It orchestrates the quest life cycle, including starting quests, completing quest steps, 
/// and claiming rewards. The contract allows players to engage in diverse quests with multiple steps, 
/// providing a dynamic and interactive gameplay experience. It integrates various aspects of the game, 
/// such as player data, inventories, and maps, to offer quests that are not only challenging but also deeply 
/// integrated with the game's lore and mechanics.
/// @dev Inherits from Initializable and AccessControlUpgradeable and implements the IQuests interface. 
/// It manages a comprehensive set of quest-related data and provides a robust system for quest management, 
/// including constraints, steps, and rewards. The contract is designed to be upgradable, ensuring future flexibility 
/// and adaptability for the evolving needs of the game.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentQuests is CryptopiaQuests {
    
    /// @dev Removes all player quest data for `accounts`
    /// @notice Does not implement batched removal because of the limited amount of quests 
    ///         in development and the upgradability of the contract
    /// @param accounts The accounts to clean
    function cleanPlayerData(address[] calldata accounts) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            for (uint j = 0; j < questsIndex.length; j++) 
            {
                delete playerQuestData[accounts[i]][questsIndex[j]];
            }
        }
    }


    /// @dev Removes all quest data
    /// @notice Does not implement batched removal because of the limited amount of quests
    ///         in development and the upgradability of the contract
    function cleanQuestData() 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < questsIndex.length; i++) 
        {
            delete quests[questsIndex[i]].steps;
            delete quests[questsIndex[i]].rewards;
            delete quests[questsIndex[i]];
        }

        delete questsIndex;
    }
}