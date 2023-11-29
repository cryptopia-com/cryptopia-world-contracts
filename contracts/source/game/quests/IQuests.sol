// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../types/FactionEnums.sol";

/// @title Cryptopia quests
/// @dev Provides the mechanics for quests
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IQuests {

    /** 
     * Public functions
     */
    function complete(uint questId, uint step) external;
}