// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/ConstructionDataTypes.sol";

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
interface IConstructionMechanics {

    /// @dev Get construction contract at a tile index
    /// @param tileIndex The tile index
    /// @return The construction contract
    function getConstructionContract(uint16 tileIndex) 
        external view  
        returns (ConstructionContract memory);


    /// @dev Start construction of a building
    /// @param titleDeedId The title deed ID
    /// @param blueprintId The blueprint ID
    /// @param jobCompenstations The job compensations
    /// @param resourceCompensations The resource compensations
    function startConstruction(uint titleDeedId, uint blueprintId, uint[] memory jobCompenstations, uint[] memory resourceCompensations) 
        external;


    /// @dev Deposit resources to a construction site
    /// @notice In order to deposit resources:
    /// - The player must be registered
    /// - The player must be at the construction site
    /// - The player must be able to interact with the tile
    /// - The player must have the required resources in their inventory (backpack or ship when dock access)
    /// @param tileIndex The tile index at which to deposit resources
    /// @param deposits The deposit instructions
    function depositResources(uint16 tileIndex, ResourceContractDeposit[] memory deposits)
        external;


    /// @dev Progress construction
    /// @param tileIndex The tile index
    /// @param contractIndex Job contract index
    function progressConstruction(uint16 tileIndex, uint8 contractIndex) 
        external;


    // /// @dev Complete construction
    // /// @param tileIndex The tile index
    // function completeConstruction(
    //     uint16 tileIndex) 
    //     external;
}