// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../errors/ArgumentErrors.sol";
import "../types/BuildingDataTypes.sol";
import "../types/ConstructionDataTypes.sol";
import "../../maps/IMaps.sol";
import "../IBuildingRegister.sol";

/// @title Cryptopia Buildings Contract
/// @notice Manages the buildings within Cryptopia, including construction, upgrades, and destruction.
/// @dev Inherits from Initializable, AccessControlUpgradeable, and IBuildingRegister and implements the IBuildingRegister interface.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaBuildingRegister is Initializable, AccessControlUpgradeable, IBuildingRegister 
{
    /// @dev Building in Cryptopia
    struct BuildingData 
    {
        /// @dev Index within the buildingsIndex array
        uint index;

        /// @dev Rarity level of the building (Common, Rare, etc.)
        Rarity rarity;

        /// @dev Type of building
        BuildingType buildingType;

        /// @dev The number of module slots available
        uint8 modules;

        /// @dev The CO2 emission level of the building
        /// @notice Reflecting its environmental impact in the game's ecosystem
        uint16 co2;

        /// @dev Base health points of the building (max damage the building can take)
        uint16 base_health;

        /// @dev Base defense rating (ability to resist attacks)
        uint16 base_defence;

        /// @dev Base storage capacity
        uint base_inventory;

        /// @dev Building that can be upgraded from
        bytes32 upgradableFrom;

        /// @dev Construction data
        ConstructionData construction;
    }


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage 
     */
    uint16 constant private CONSTRUCTION_COMPLETE = 1_000;

    /// @dev Refs
    address public mapsContract;

    /// @dev name => BuildingData
    mapping (bytes32 => BuildingData) internal buildings;
    bytes32[] internal buildingsIndex;

    /// @dev tile => BuildingInstance
    mapping (uint16 => BuildingInstance) public buildingInstances;
    mapping (BuildingType => uint) public buildingInstanceCount;

    mapping (uint16 => uint16) public tileGroupToDock; // Assuming 0 is not a valid tile index because tile index zero is always water
    


    /**
     * Events
     */
    /// @dev Emitted when the construction of a building is started
    /// @param tileIndex The index of the tile on which the building is being constructed
    /// @param building The name of the building
    event BuildingConstructionStart(uint16 indexed tileIndex, bytes32 building);

    /// @dev Emitted when the construction of a building progresses
    /// @param tileIndex The index of the tile on which the building is being constructed
    /// @param building The name of the building
    /// @param progress The progress that was added
    /// @param completed True if the building is completed
    event BuildingConstructionProgress(uint16 indexed tileIndex, bytes32 building, uint16 progress, bool completed);

    /// @dev Emitted when a building is destroyed
    /// @param tileIndex The index of the tile at which the building is being destroyed
    /// @param building The name of the building
    event BuildingConstructionDestroy(uint16 indexed tileIndex, bytes32 building);


    /**
     * Errors
     */
    /// @dev Emits if a building does not exist
    /// @param building The name of the building that is not present
    error BuildingNotFound(bytes32 building);

    /// @dev Emits if a building does not exist at the location
    /// @param tileIndex The index of the tile
    error BuildingDoesNotExistAtLocation(uint16 tileIndex);

    /// @dev Emits if a building is not upgradable from the existing building
    /// @param tileIndex The index of the tile
    error UpgadableBuildingDoesNotExistAtLocation(uint16 tileIndex);

    /// @dev Emits if a building is upgradable but not completed
    /// @param tileIndex The index of the tile
    error UpgadableBuildingIsNotCompleteAtLocation(uint16 tileIndex);

    /// @dev Emits if a building already exists at the location
    /// @param tileIndex The index of the tile
    /// @param building The name of the building that is already present
    error BuildingAlreadyExistsAtLocation(uint16 tileIndex, bytes32 building);

    /// @dev Emits if there is no building under construction at the location
    /// @param tileIndex The index of the tile
    error BuildingNotUnderConstructionAtLocation(uint16 tileIndex);

    /// @dev Emits if the construction requirements are not met
    /// @param tileIndex The index of the tile
    /// @param building The name of the building
    error ConstructionRequirementsNotMet(uint16 tileIndex, bytes32 building);


    /// @dev Constructor
    /// @param _mapsContract The address of the maps contract
    function initialize(address _mapsContract)
        public virtual initializer 
    {
        __AccessControl_init();

        // Set refs
        mapsContract = _mapsContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Add or update buildings
    /// @param data Building data
    function setBuildings(Building[] memory data) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < data.length; i++)
        {
            _setBuilding(data[i]);
        }
    }


    /**
     * Public functions 
     */
    /// @dev Get the amount of unique buildings
    /// @return count The amount of unique buildings
    function getBuildingCount() 
        public view 
        returns (uint)
    {
        return buildingsIndex.length;
    }


    /// @dev Get a building by name
    /// @param name The name of the building
    /// @return data Building data
    function getBuilding(bytes32 name) 
        public view 
        returns (Building memory data)
    {
        data = _getBuilding(name);
    }

    
    /// @dev Get a range of buildings
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return buildings_ Range of buildings
    function getBuildings(uint skip, uint take) 
        public view 
        returns (Building[] memory buildings_)
    {
        uint length = take;
        if (buildingsIndex.length < skip + take)
        {
            length = buildingsIndex.length - skip;
        }

        buildings_ = new Building[](length);
        for (uint i = 0; i < length; i++)
        {
            buildings_[i] = _getBuilding(buildingsIndex[skip + i]);
        }
    }


    /// @dev Get a building instance by tile index
    /// @param tileIndex The index of the tile to get the building instance for
    /// @return instance Building instance data
    function getBuildingInstance(uint16 tileIndex) 
        public view 
        returns (BuildingInstance memory instance)
    {
        instance = buildingInstances[tileIndex];
    }


    /// @dev Get a range of building instances
    /// @param tileIndices The indices of the tiles to get the building instances for
    /// @return instances Range of building instances
    function getBuildingInstances(uint16[] memory tileIndices)
        public view 
        returns (BuildingInstance[] memory instances)
    {
        instances = new BuildingInstance[](tileIndices.length);
        for (uint i = 0; i < tileIndices.length; i++)
        {
            instances[i] = buildingInstances[tileIndices[i]];
        }
    }


    /// @dev Get the construction data for a building
    /// @param name The name of the building
    /// @return data Construction data
    function getConstructionData(bytes32 name) 
        public view 
        returns (ConstructionData memory data)
    {
        data = buildings[name].construction;
    }
    

    /**
     * Private functions 
     */
    /// @dev True if a building with `name` exists
    /// @param _name of the building
    function _exists(bytes32 _name) internal view returns (bool) 
    {
        return buildingsIndex.length > 0 && buildingsIndex[buildings[_name].index] == _name;
    }


    /// @dev True if the group has dock access
    /// @param group The group to check
    /// @return hasAccess True if the group has dock access
    function _hasDockAccess(uint16 group) 
        internal view 
        returns (bool) 
    {
        return tileGroupToDock[group] != 0 && // 0 is assumed to be water and thus cannot have a dock
               buildingInstances[tileGroupToDock[group]].construction == CONSTRUCTION_COMPLETE;
    }


    /// @dev Add or update a building
    /// @param building The building data
    function _setBuilding(Building memory building)
        internal
    {
        // Add building
        if (!_exists(building.name))
        {
            buildings[building.name].index = buildingsIndex.length;
            buildingsIndex.push(building.name);
        }

        // Set building data
        BuildingData storage data = buildings[building.name];
        data.rarity = building.rarity;
        data.buildingType = building.buildingType;
        data.modules = building.modules;
        data.co2 = building.co2;
        data.base_health = building.base_health;
        data.base_defence = building.base_defence;
        data.base_inventory = building.base_inventory;
        data.upgradableFrom = building.upgradableFrom;

        // Set construction constraints
        data.construction.constraints = building.construction.constraints;

        // Set labour requirements
        uint16 totalProgress = 0;
        delete data.construction.requirements.labour;
        for (uint i = 0; i < building.construction.requirements.labour.length; i++)
        {
            LabourData memory labourData = building.construction.requirements.labour[i];
            data.construction.requirements.labour.push(LabourData(
                labourData.profession,
                labourData.hasMinimumLevel,
                labourData.minLevel,
                labourData.hasMaximumLevel,
                labourData.maxLevel,
                labourData.slots,
                labourData.actionValue1,
                labourData.actionValue2
            ));

            // Calculate total progress
            totalProgress += uint16(labourData.actionValue1) * labourData.slots;
        }

        // Ensure total progress is CONSTRUCTION_COMPLETE
        if (totalProgress < CONSTRUCTION_COMPLETE)
        {
            revert ArgumentInvalid();
        }

        // Set resource requirements
        delete data.construction.requirements.resources;
        for (uint i = 0; i < building.construction.requirements.resources.length; i++)
        {
            ResourceData memory resourceData = building.construction.requirements.resources[i];
            data.construction.requirements.resources.push(ResourceData(
                resourceData.resource, 
                resourceData.amount
            ));
        }
    }


    /// @dev Retrieve a building by name
    /// @param name The name of the building
    /// @return building Building data
    function _getBuilding(bytes32 name)
        internal view
        returns(Building memory building)
    {
        BuildingData storage data = buildings[name];
        building.name = name;
        building.rarity = data.rarity;
        building.buildingType = data.buildingType;
        building.modules = data.modules;
        building.co2 = data.co2;
        building.base_health = data.base_health;
        building.base_defence = data.base_defence;
        building.base_inventory = data.base_inventory;
        building.upgradableFrom = data.upgradableFrom;
        building.construction = data.construction;
    }


    /**
     * System functions
     */
    /// @dev Start construction of a building
    /// @param tileIndex The index of the tile to start construction on
    /// @param building The name of the building to construct
    function __startConstruction(uint16 tileIndex, bytes32 building)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        BuildingData storage _building = buildings[building];

        // Upgrade
        if (_building.upgradableFrom != bytes32(0))
        {
            // Check if building exists
            if (buildingInstances[tileIndex].name == bytes32(0))
            {
                revert BuildingDoesNotExistAtLocation(tileIndex);
            }

            // Check if building is upgrade for existing building
            if (_building.upgradableFrom != buildingInstances[tileIndex].name)
            {
                revert UpgadableBuildingDoesNotExistAtLocation(tileIndex);
            }

            // Check if existing building is complete
            if (buildingInstances[tileIndex].construction < CONSTRUCTION_COMPLETE)
            {
                revert UpgadableBuildingIsNotCompleteAtLocation(tileIndex);
            }

        }

        // New construction
        else
        {
            // Check if building exists
            if (buildingInstances[tileIndex].name != bytes32(0))
            {
                revert BuildingAlreadyExistsAtLocation(tileIndex, building);
            }
        }

        // Check construction constraints
        ConstructionConstraints storage constraints = _building.construction.constraints;
        TileStatic memory tileDataStatic = IMaps(mapsContract).getTileDataStatic(tileIndex);
        TileDynamic memory tileDataDynamic = IMaps(mapsContract).getTileDataDynamic(tileIndex);
        bool hasDockAccess = _hasDockAccess(tileDataStatic.group);

        // Validate constraints
        if ((constraints.hasMaxInstanceConstraint && buildingInstanceCount[_building.buildingType] >= constraints.maxInstances) ||
            (constraints.lake == Permission.Required && !tileDataStatic.hasLake) ||
            (constraints.lake == Permission.NotAllowed && tileDataStatic.hasLake) || 
            (constraints.river == Permission.Required && tileDataStatic.riverFlags == 0) ||
            (constraints.river == Permission.NotAllowed && tileDataStatic.riverFlags > 0) || 
            (constraints.dock == Permission.Required && !hasDockAccess) ||
            (constraints.dock == Permission.NotAllowed && hasDockAccess))
        {
            revert ConstructionRequirementsNotMet(tileIndex, building);
        }

        // Validate terrain constraints
        if ((tileDataStatic.terrain == Terrain.Flat && !constraints.terrain.flat) ||
            (tileDataStatic.terrain == Terrain.Hills && !constraints.terrain.hills) ||
            (tileDataStatic.terrain == Terrain.Mountains && !constraints.terrain.mountains) ||
            (tileDataStatic.terrain == Terrain.Seastead && !constraints.terrain.seastead))
        {
            revert ConstructionRequirementsNotMet(tileIndex, building);
        }

        // Validate biome constraints
        if ((tileDataStatic.biome == Biome.None && !constraints.biome.none) ||
            (tileDataStatic.biome == Biome.Plains && !constraints.biome.plains) ||
            (tileDataStatic.biome == Biome.Grassland && !constraints.biome.grassland) ||
            (tileDataStatic.biome == Biome.Forest && !constraints.biome.forest) ||
            (tileDataStatic.biome == Biome.RainForest && !constraints.biome.rainForest) ||
            (tileDataStatic.biome == Biome.Mangrove && !constraints.biome.mangrove) ||
            (tileDataStatic.biome == Biome.Desert && !constraints.biome.desert) ||
            (tileDataStatic.biome == Biome.Tundra && !constraints.biome.tundra) ||
            (tileDataStatic.biome == Biome.Swamp && !constraints.biome.swamp) ||
            (tileDataStatic.biome == Biome.Reef && !constraints.biome.reef) ||
            (tileDataStatic.biome == Biome.Vulcanic && !constraints.biome.vulcanic))
        {
            revert ConstructionRequirementsNotMet(tileIndex, building);
        }

        // Validate environment constraints
        if ((tileDataStatic.environment == Environment.Beach && !constraints.environment.beach) ||
            (tileDataStatic.environment == Environment.Coast && !constraints.environment.coast) ||
            (tileDataStatic.environment == Environment.Inland && !constraints.environment.inland) ||
            (tileDataStatic.environment == Environment.CoastalWater && !constraints.environment.coastalWater) ||
            (tileDataStatic.environment == Environment.ShallowWater && !constraints.environment.shallowWater) ||
            (tileDataStatic.environment == Environment.DeepWater && !constraints.environment.deepWater))
        {
            revert ConstructionRequirementsNotMet(tileIndex, building);
        }

        // Validate zone constraints
        if ((tileDataDynamic.zone == Zone.Neutral && !constraints.zone.neutral) ||
            (tileDataDynamic.zone == Zone.Industrial && !constraints.zone.industrial) ||
            (tileDataDynamic.zone == Zone.Ecological && !constraints.zone.ecological) ||
            (tileDataDynamic.zone == Zone.Metropolitan && !constraints.zone.metropolitan))
        {
            revert ConstructionRequirementsNotMet(tileIndex, building);
        }

        // Start construction
        buildingInstances[tileIndex].name = building;
        buildingInstances[tileIndex].construction = 0;
        buildingInstanceCount[_building.buildingType]++;

        // Dock?
        if (buildings[building].buildingType == BuildingType.Dock)
        {
            // Register dock reference
            tileGroupToDock[tileDataStatic.group] = tileIndex;
        }

        // Emit
        emit BuildingConstructionStart(tileIndex, building);
    }


    /// @dev Progress the construction of a building
    /// @param tileIndex The index of the tile to progress construction on
    /// @param progress The new progress value of the building (0-1000)
    function __progressConstruction(uint16 tileIndex, uint16 progress)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        BuildingInstance storage buildingInstance = buildingInstances[tileIndex];
        bytes32 building = buildingInstance.name;

        // Check location has a building
        if (building == bytes32(0))
        {
            revert BuildingDoesNotExistAtLocation(tileIndex);
        }

        // Check if building is under construction
        if (buildingInstance.construction >= CONSTRUCTION_COMPLETE)
        {
            revert BuildingNotUnderConstructionAtLocation(tileIndex);
        }

        // Progress construction
        if (buildingInstance.construction + progress > CONSTRUCTION_COMPLETE)
        {
            progress = CONSTRUCTION_COMPLETE - buildingInstances[tileIndex].construction;
        }

        buildingInstance.construction += progress;

        // Emit
        emit BuildingConstructionProgress(
            tileIndex, 
            building, 
            progress, 
            buildingInstance.construction == CONSTRUCTION_COMPLETE);
    }


    /// @dev Destroy a construction
    /// @param tileIndex The index of the tile to destroy the building on
    function __destroyConstruction(uint16 tileIndex)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        // Check location has a building
        if (buildingInstances[tileIndex].name == bytes32(0))
        {
            revert BuildingDoesNotExistAtLocation(tileIndex);
        }

        bytes32 building = buildingInstances[tileIndex].name;

        // Decrement building count
        buildingInstanceCount[buildings[building].buildingType]--;

        // Dock?
        if (buildings[building].buildingType == BuildingType.Dock)
        {
            // Delete dock reference
            delete tileGroupToDock[IMaps(mapsContract).getTileGroup(tileIndex)];
        }

        // Delete building instance
        delete buildingInstances[tileIndex];

        // Emit
        emit BuildingConstructionDestroy(tileIndex, building);
    }
}