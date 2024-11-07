// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

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

        /// @dev Faction type (Eco, Tech, Traditional, Industrial) 
        Faction faction;

        /// @dev SubFaction type (None, Pirate, BountyHunter) 
        SubFaction subFaction;

        /// @dev Rarity level of the building (Common, Rare, etc.)
        Rarity rarity;

        /// @dev Type of building
        BuildingType buildingType;

        /// @dev True if the building is an upgrade
        bool isUpgrade;

        /// @dev The level of the building
        uint8 level;

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
    }


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage 
     */
    uint8 constant private CONSTRUCTION_COMPLETE = 100;

    /// @dev Refs
    address public mapsContract;
    address public titleDeedsContract;
    address public blueprintsContract;

    /// @dev name => BuildingData
    mapping (bytes32 => BuildingData) public buildings;
    bytes32[] internal buildingsIndex;

    mapping (bytes32 => mapping (bytes32 => bool)) internal upgradableFrom;

    /// @dev tile => BuildingInstance
    mapping (uint16 => BuildingInstance) public buildingInstances;


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
    /// @param progress The progress of the construction (new value)
    /// @param complete True if the building is complete
    event BuildingConstructionProgress(uint16 indexed tileIndex, bytes32 building, uint8 progress, bool complete);

    /// @dev Emitted when a building is destroyed
    /// @param tileIndex The index of the tile at which the building is being destroyed
    /// @param building The name of the building
    event BuildingDestroy(uint16 indexed tileIndex, bytes32 building);


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
    /// @param building The name of the expected building
    error UpgadableBuildingDoesNotExistAtLocation(uint16 tileIndex, bytes32 building);

    /// @dev Emits if a building already exists at the location
    /// @param tileIndex The index of the tile
    /// @param building The name of the building that is already present
    error BuildingAlreadyExistsAtLocation(uint16 tileIndex, bytes32 building);

    /// @dev Emits if there is no building under construction at the location
    /// @param tileIndex The index of the tile
    error BuildingNotUnderConstructionAtLocation(uint16 tileIndex);


    /// @dev Constructor
    /// @param _mapsContract The address of the maps contract
    /// @param _titleDeedsContract The address of the title deeds contract
    /// @param _blueprintsContract The address of the blueprints contract
    function initialize(
        address _mapsContract, 
        address _titleDeedsContract, 
        address _blueprintsContract) 
        public virtual initializer 
    {
        __AccessControl_init();

        // Set refs
        mapsContract = _mapsContract;
        titleDeedsContract = _titleDeedsContract;
        blueprintsContract = _blueprintsContract;

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
    

    /**
     * Private functions 
     */
    /// @dev True if a building with `name` exists
    /// @param _name of the building
    function _exists(bytes32 _name) internal view returns (bool) 
    {
        return buildingsIndex.length > 0 && buildingsIndex[buildings[_name].index] == _name;
    }


    function _isUpgrade(bytes32 building) 
        internal view 
        returns (bool) 
    {
        
    }


    /// @dev Check if a building is upgradable
    /// @param building The name of the building
    function _isUpgradable(bytes32 building) 
        internal view 
        returns(bool)
    {
        return buildings[building].upgradableFrom != bytes32(0);
    }


    /// @dev Check if a building is upgradable from another building
    /// @param building The name of the building
    /// @param upgradableFrom The name of the building to upgrade from
    function _isUpgradableFrom(bytes32 building, bytes32 upgradableFrom) 
        internal view 
        returns(bool)
    {
        return buildings[building].upgradableFrom == upgradableFrom;
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
        data.faction = building.faction;
        data.subFaction = building.subFaction;
        data.rarity = building.rarity;
        data.buildingType = building.buildingType;
        data.level = building.level;
        data.modules = building.modules;
        data.co2 = building.co2;
        data.base_health = building.base_health;
        data.base_defence = building.base_defence;
        data.base_inventory = building.base_inventory;
        data.upgradableFrom = building.upgradableFrom;
    }


    /// @dev Retrieve a building by name
    /// @param name The name of the building
    /// @return Building data
    function _getBuilding(bytes32 name)
        internal view
        returns(Building memory)
    {
        BuildingData memory data = buildings[name];
        return Building({
            name: name,
            faction: data.faction,
            subFaction: data.subFaction,
            rarity: data.rarity,
            buildingType: data.buildingType,
            level: data.level,
            modules: data.modules,
            co2: data.co2,
            base_health: data.base_health,
            base_defence: data.base_defence,
            base_inventory: data.base_inventory,
            upgradableFrom: data.upgradableFrom
        });
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
        // Upgradable
        if (_isUpgradable(building))
        {
            // Check if building exists
            if (buildingInstances[tileIndex].name == bytes32(0))
            {
                revert BuildingDoesNotExistAtLocation(tileIndex);
            }

            // Check if building is upgradable from existing building
            if (_isUpgradableFrom(building, buildingInstances[tileIndex].name))
            {
                revert UpgadableBuildingDoesNotExistAtLocation(tileIndex, buildings[building].upgradableFrom);
            }
        }

        // Non-Upgradable
        else
        {
            // Check if building exists
            if (buildingInstances[tileIndex].name != bytes32(0))
            {
                revert BuildingAlreadyExistsAtLocation(tileIndex, building);
            }
        }

        // Start construction
        buildingInstances[tileIndex].name = building;
        buildingInstances[tileIndex].construction = 0;

        // Emit
        emit BuildingConstructionStart(tileIndex, building);
    }


    /// @dev Progress the construction of a building
    /// @param tileIndex The index of the tile to progress construction on
    /// @param building The name of the building to progress
    /// @param progress The new progress value of the building (0-100)
    function __progressConstruction(uint16 tileIndex, bytes32 building, uint8 progress)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        // Check location has a building
        if (buildingInstances[tileIndex].name == bytes32(0))
        {
            revert BuildingDoesNotExistAtLocation(tileIndex);
        }

        // Progress construction
        if (buildingInstances[tileIndex].construction + progress > CONSTRUCTION_COMPLETE)
        {
            buildingInstances[tileIndex].construction = CONSTRUCTION_COMPLETE;
        }
        else
        {
            buildingInstances[tileIndex].construction += progress;
        }

        // Emit
        emit BuildingConstructionProgress(tileIndex, building, progress, progress == CONSTRUCTION_COMPLETE);
    }


    /// @dev Destroy a building
    /// @param tileIndex The index of the tile to destroy the building on
    function __destroyBuilding(uint16 tileIndex)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        // Check location has a building
        if (buildingInstances[tileIndex].name == bytes32(0))
        {
            revert BuildingDoesNotExistAtLocation(tileIndex);
        }

        bytes32 building = buildingInstances[tileIndex].name;

        // Destroy building
        delete buildingInstances[tileIndex];

        // Emit
        emit BuildingDestroy(tileIndex, building);
    }
}