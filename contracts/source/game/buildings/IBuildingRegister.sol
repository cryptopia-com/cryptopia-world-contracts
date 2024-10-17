// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/BuildingDataTypes.sol";

/// @title Cryptopia Buildings Contract
/// @notice Manages the buildings within Cryptopia, including construction, upgrades, and destruction.
/// @dev Inherits from Initializable, AccessControlUpgradeable, and IBuildingRegister and implements the IBuildingRegister interface.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IBuildingRegister {

    /**
     * Public functions 
     */
    /// @dev Get the amount of unique buildings
    /// @return count The amount of unique buildings
    function getBuildingCount() 
        external view 
        returns (uint);


    /// @dev Get a building by name
    /// @param name The name of the building
    /// @return building Building data
    function getBuilding(bytes32 name) 
        external view 
        returns (Building memory building);

    
    /// @dev Get a range of buildings
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return buildings Range of buildings
    function getBuildings(uint skip, uint take) 
        external view 
        returns (Building[] memory buildings);


    /// @dev Get a building instance by tile index
    /// @param tileIndex The index of the tile to get the building instance for
    /// @return instance Building instance data
    function getBuildingInstance(uint16 tileIndex) 
        external view 
        returns (BuildingInstance memory instance);


    /// @dev Get a range of building instances
    /// @param tileIndices The indices of the tiles to get the building instances for
    /// @return instances Range of building instances
    function getBuildingInstances(uint16[] memory tileIndices)
        external view 
        returns (BuildingInstance[] memory instances);


    /**
     * System functions
     */
    /// @dev Start construction of a building
    /// @param tileIndex The index of the tile to start construction on
    /// @param building The name of the building to construct
    function __startConstruction(uint16 tileIndex, bytes32 building)
        external; 


    /// @dev Progress the construction of a building
    /// @param tileIndex The index of the tile to progress construction on
    /// @param building The name of the building to progress
    /// @param progress The new progress value of the building (0-100)
    function __progressConstruction(uint16 tileIndex, bytes32 building, uint8 progress)
        external;


    /// @dev Destroy a building
    /// @param tileIndex The index of the tile to destroy the building on
    function __destroyBuilding(uint16 tileIndex)
        external;
}