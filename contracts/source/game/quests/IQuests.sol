// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/QuestDataTypes.sol";

/// @title Cryptopia quests
/// @dev Provides the mechanics for quests
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