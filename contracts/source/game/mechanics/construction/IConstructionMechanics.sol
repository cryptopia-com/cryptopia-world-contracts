// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/ConstructionDataTypes.sol";

/// @dev Interface for the construction mechanics
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
    /// @param labourCompenstations The labour compensations
    /// @param resourceCompensations The resource compensations
    function startConstruction(
        uint titleDeedId, 
        uint blueprintId, 
        uint[] memory labourCompenstations, 
        uint[] memory resourceCompensations) 
        external;


    /// @dev Deposit resources to a construction site
    /// @notice In order to deposit resources:
    /// - The player must be registered
    /// - The player must be at the construction site
    /// - The player must be able to interact with the tile
    /// - The player must have the required resources in their inventory (backpack or ship when dock access)
    /// @param tileIndex The tile index at which to deposit resources
    /// @param deposits The deposit instructions
    function depositResources(
        uint16 tileIndex, 
        ResourceContractDeposit[] memory deposits)
        external;


    // /// @dev Progress construction
    // /// @param tileIndex The tile index
    // /// @param profession The profession
    // function progressConstruction(
    //     uint16 tileIndex, 
    //     Profession profession) 
    //     external;


    // /// @dev Complete construction
    // /// @param tileIndex The tile index
    // function completeConstruction(
    //     uint16 tileIndex) 
    //     external;
}