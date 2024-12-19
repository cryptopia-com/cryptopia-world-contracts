// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../../source/game/mechanics/construction/concrete/CryptopiaConstructionMechanics.sol";

/// @title Cryptopia Construction Mechanics
/// @notice This contract governs the construction mechanics within Cryptopia, enabling players to engage in building operations. 
/// Players can initiate, manage, and progress the construction of buildings.
/// 
/// The mechanics facilitate interactions such as starting construction projects, depositing resources, 
/// and managing compensations for construction jobs.
/// @dev Inherits from Initializable and AccessControlUpgradeable, implementing the IConstructionMechanics interface.
/// This contract is designed to ensure modularity, scalability, and efficient resource handling. It enforces robust 
/// validation checks to maintain game integrity and fairness while facilitating dynamic construction mechanics.
/// The contract's functions are optimized for seamless interaction with player data, resources, and tile states.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentConstructionMechanics is CryptopiaConstructionMechanics {

    /// @dev Remove the data 
    function clean(uint16[] memory tileIndices) 
        external onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < tileIndices.length; i++) 
        {
            delete constructions[tileIndices[i]];
        }
    }
}