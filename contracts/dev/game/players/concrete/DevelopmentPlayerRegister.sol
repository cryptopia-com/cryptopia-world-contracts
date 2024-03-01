// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../source/game/players/concrete/CryptopiaPlayerRegister.sol";

/// @title Cryptopia Players Contract
/// @notice This contract is central to managing player profiles within Cryptopia, 
/// encompassing the creation and progression of player accounts. It efficiently handles player data, 
/// including levels, stats, and inventory management. The contract integrates seamlessly with various 
/// game elements, such as ships and crafting, to provide a comprehensive player experience. 
/// It allows players to embark on their journey, level up, and evolve within the game, 
/// aligning with their chosen faction and adapting their characters to suit their play style.
/// @dev Inherits from Initializable and AccessControlUpgradeable and implements the IPlayerRegister interface.
/// The contract utilizes an upgradable design for scalability and future enhancements. It maintains detailed player data, 
/// enabling intricate game mechanics and interactions. This includes player stats, faction alignment, equipment (ships), 
/// and crafting capabilities. The contract emphasizes a balance between player progression and game dynamics, ensuring 
/// that each player's journey is unique and engaging.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentPlayerRegister is CryptopiaPlayerRegister {

    /// @dev Remove the player data from the register
    /// @param accounts The accounts to remove data from
    function clean(address[] calldata accounts) 
        external 
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < accounts.length; i++) 
        {
            delete playerDatas[accounts[i]];
        }
    }
}