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
    /// @return Quest count
    function getQuestCount() 
        external view 
        returns (uint);


    /// @dev Get quest at index
    /// @param index Quest index
    /// @return Quest at index
    function getQuestAt(uint index) 
        external view 
        returns (Quest memory);
}