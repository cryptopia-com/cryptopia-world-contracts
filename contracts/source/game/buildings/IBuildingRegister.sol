// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/BuildingDataTypes.sol";
import "./types/ConstructionDataTypes.sol";

/// @title Cryptopia Buildings Register
/// @notice This contract serves as the central registry for all buildings within Cryptopia, providing mechanisms 
/// to manage building data, instances, and construction progress.
/// 
/// The registry facilitates operations such as querying building data, retrieving construction details, 
/// and managing instances across tiles. Additionally, it supports system-level operations like initiating, 
/// progressing, and destroying constructions.
///
/// @dev Inherits from Initializable, AccessControlUpgradeable, and implements the IBuildingRegister interface.
/// It uses modular patterns to maintain code clarity and upgradeability, ensuring compatibility with evolving game requirements.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IBuildingRegister {

    /**
     * Public functions 
     */
    /// @dev True if the group has dock access
    /// @param group The group to check
    /// @return hasAccess True if the group has dock access
    function hasDockAccess(uint16 group) 
        external view 
        returns (bool);

        
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


    /// @param tileIndices The indices of the tiles to get the building instances for
    /// @return instances Range of building instances
    function getBuildingInstances(uint16[] memory tileIndices)
        external view 
        returns (BuildingInstance[] memory instances);


    /// @dev Get the construction data for a building
    /// @param name The name of the building
    /// @return data Construction data
    function getConstructionData(bytes32 name) 
        external view 
        returns (ConstructionData memory data);


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
    /// @param progress The new progress value of the building (0-1000)
    /// @return completed True if the construction is completed
    function __progressConstruction(uint16 tileIndex, uint16 progress)
        external 
        returns (bool completed);


    /// @dev Destroy a construction
    /// @param tileIndex The index of the tile to destroy the building on
    function __destroyConstruction(uint16 tileIndex)
        external;
}