// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../types/GenericEnums.sol";
import "../../maps/types/MapDataTypes.sol";
import "../../assets/types/AssetDataTypes.sol";
import "../../mechanics/types/LabourDataTypes.sol";

/// @dev Represents all constraints applicable to a construction
struct ConstructionConstraints
{
    // Map constraints
    bool hasMaxInstanceConstraint;
    uint16 maxInstances;

    // Tile constraints
    Permission lake;
    Permission river;
    Permission dock;

    TileTerrainConstraints terrain;
    TileBiomeConstraints biome;
    TileEnvironmentConstraints environment;
    TileZoneConstraints zone;
}

/// @dev Represents the requirements for constructing a building
struct ConstructionRequirements
{
    /// @dev The labour requirements for construction
    LabourRequirement[] labour;

    /// @dev The resources required for construction
    ResourceRequirement[] resources;
}

/// @dev Represents the constraints and requirements for constructing a building
struct ConstructionData 
{
    /// @dev The constraints for construction
    /// @notice These constraints are used to determine if a building can be constructed on a tile
    ConstructionConstraints constraints;

    /// @dev The requirements for construction
    /// @notice These requirements are used to determine the resources and labour required for construction
    ConstructionRequirements requirements;
}