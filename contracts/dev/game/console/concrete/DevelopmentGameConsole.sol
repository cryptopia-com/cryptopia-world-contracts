// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/console/concrete/CryptopiaGameConsole.sol";

/// @title GameConsole 
/// @dev The game console contains a collection of game titles and records highscores, sessions and leaderboards. The game console 
///      runs on-chain sessions that are submitted by players. The game console is not tamper-proof and should be used for casual 
///      games only. There are no guarantees that the highscores are accurate or that they have not been tampered with. This system
///      is not suitable for high-stakes games or games that require high security. 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentGameConsole is CryptopiaGameConsole {

    /// @dev Remove the player data
    /// @param accounts The accounts to remove data from
    function cleanPlayerData(address[] calldata accounts) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < titlesIndex.length; i++) 
        {
            for (uint j = 0; j < accounts.length; j++) 
            {
                delete titles[titlesIndex[i]].playerData[accounts[j]].sessions;
                delete titles[titlesIndex[i]].playerData[accounts[j]];
            }
        }
    }

    /// @dev Remove the title data
    function cleanTitleData() 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        // Delete assets
        for (uint i = 0; i < titlesIndex.length; i++) 
        {
            delete titles[titlesIndex[i]].leaderboard;
            delete titles[titlesIndex[i]];
        }

        delete titlesIndex;
    }
}