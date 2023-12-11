// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/QuestDataTypes.sol";

/// @title Cryptopia Quests Contract
/// @notice Handles the functionality of quests within Cryptopia. 
/// It orchestrates the quest life cycle, including starting quests, completing quest steps, 
/// and claiming rewards. The contract allows players to engage in diverse quests with multiple steps, 
/// providing a dynamic and interactive gameplay experience. It integrates various aspects of the game, 
/// such as player data, inventories, and maps, to offer quests that are not only challenging but also deeply 
/// integrated with the game's lore and mechanics.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IQuests {

    /** 
     * Public functions
     */
    /// @dev Get quest count
    /// @return count number of quests
    function getQuestCount() 
        external view 
        returns (uint count);


    /// @dev Get quest at index
    /// @param index Quest index
    /// @return quest at index
    function getQuestAt(uint index) 
        external view 
        returns (Quest memory quest);

    
    /// @dev Get quests with pagination
    /// @param skip Number of quests to skip
    /// @param take Number of quests to take
    /// @return quests range of quests
    function getQuests(uint skip, uint take) 
        external view 
        returns (Quest[] memory quests);
}