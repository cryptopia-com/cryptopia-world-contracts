// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./ICryptopiaStructures.sol";
import "../../map/CryptopiaMap/ICryptopiaMap.sol";
import "../../../tokens/ERC721/ICryptopiaERC721.sol";
import "../../../tokens/ERC721/CryptopiaTitleDeedToken/ICryptopiaTitleDeedToken.sol";
import "../../../tokens/ERC721/CryptopiaBlueprintToken/ICryptopiaBlueprintToken.sol";

/// @title Cryptopia Structures
/// @dev Contains construction and structure data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaStructures is ICryptopiaStructures, Initializable, OwnableUpgradeable {

    enum StructureType 
    {
        Mine,
        Power,
        Factory
    }

    /// @dev Represents a structure (eg. mine, windfarm or factory)
    struct Structure 
    {
        uint index;

        // Category
        StructureType structureType;

        // level => StructureStats
        mapping (uint8 => StructureStats) stats;

        // Construction constraints
        ConstructionConstraints constructionConstraints;

        // level => ConstructionRequirements
        mapping (uint8 => ConstructionRequirements) constructionRequirements;
    }

    /// @dev Stats per level
    struct StructureStats 
    {
        uint hp;
        uint output;
        uint cooldown;
        uint modules;

        uint co2;
        bool co2_isPositive;

        uint population; 
        bool population_isPositive;
    }

    /// @dev A module that can be installed in a constructed structure
    struct StructureModule 
    {
        uint hp;
        bool hp_isPositive;

        uint output;
        bool output_isPositive;

        uint cooldown;
        bool cooldown_isPositive;

        uint co2;
        bool co2_isPositive;

        uint population;
        bool population_isPositive;

        uint modules;
        bool modules_isPositive;
    }

    /// @dev Represents the construction process
    /// @notice When completed the entry is moved from the construction to the constructed section
    struct Construction 
    {
        // Structure that is being constructed
        bytes32 structure;

        // Transport data
        ConstructionTransportData transport; 

        // role => workforce data
        mapping (uint => ConstructionWorkforceData) workforce; 
    }

    /// @dev Placement constraints
    struct ConstructionConstraints
    {
        // If true can be placed on a sea tile
        bool sea;

        // If true can be placed on a land tile
        bool land;

        // faction => allowed
        mapping (uint8 => bool) factions; 
    }

    /// @dev Requirements to construct a structure
    struct ConstructionRequirements 
    {
        // Required transport units; each unit represents a storage slot
        uint transportUnits;

        // resource => required amount
        mapping (address => uint) resources; 
        address[] resourcesIndex;

        // role => required amount 
        mapping (uint => uint) workforce; 
        uint[] workforceIndex;
    }

    /// @dev State of the transport of materials to the construction site
    struct ConstructionTransportData 
    {
        // The amount of transport units left until fulfillment
        uint remaining;

        // The wage that's paid per transport unit (storage slot)
        uint wage;
    }

    /// @dev State of the workforce required to complete the construction
    struct ConstructionWorkforceData
    {
        // The amount of work units (of a particular type) left until completion
        uint remaining;

        // The price that's paid to player that contributes work to the completion of the construction
        uint wage;
    }

    /// @dev Represents a structure that has been constructed
    struct Constructed 
    {
        bytes32 structure;
        uint8 level;

        // Actual after module effects
        uint hp;
        uint output;
        uint cooldown;
        uint co2;
        uint population;

        uint damage;

        // Installed modules
        uint[] modules;
    }


    /**
     * Storage
     */
    address private tokenContract;
    address private blueprintContract;
    address private titleDeedContract;

    /// @dev Structures
    mapping(bytes32 => Structure) private structures;
    bytes32[] private structuresIndex;

    /// @dev Structures that are under construction
    mapping (uint32 => Construction) private construction;

    /// @dev Structures that are constructed
    mapping (uint32 => Constructed) private constructed;


    /**
     * Events
     */
    /// @dev Emitted when construction is started
    event ConstructionStarted(uint32 indexed tileIndex, bytes32 indexed structure);


    /**
     * Modifiers
     */
    /// @dev Ensure that the caller is allowed to spend the blueprint
    /// @param blueprint Token ID of the blueprint
    modifier authorizeBlueprint(uint blueprint) {
        require(ICryptopiaERC721(blueprintContract).isApprovedOrOwner(_msgSender(), blueprint), "Blueprint - Caller is unauthorized");
        _;
    }

    /// @dev Ensure that the caller is authorized to use the title deed
    /// @notice Translates zero based tile index to one based token index
    modifier authorizeTitledeed(uint tile) {
        require(ICryptopiaERC721(titleDeedContract).isApprovedOrOwner(_msgSender(), tile), "TitleDeed - Caller is unauthorized");
        _;
    }


    /**
     * Admin methods
     */
    /// @dev Add or edit a structure
    /// @param structureName Unique structure name
    /// @param structureType Type of structure
    /// @param stats Structure properties
    function setStructure(
        bytes32 structureName, 
        uint8 structureType, 
        uint[8][] memory stats) 
        public 
        onlyOwner 
    {
        structures[structureName].structureType = StructureType(structureType);
        for (uint8 i = 0; i < stats.length; i++)
        {
            // Setup stats per level
            structures[structureName].stats[i].hp = stats[i][0];
            structures[structureName].stats[i].output = stats[i][1];
            structures[structureName].stats[i].cooldown = stats[i][2];
            structures[structureName].stats[i].modules = stats[i][3];
            structures[structureName].stats[i].co2 = stats[i][4];
            structures[structureName].stats[i].co2_isPositive = 0 == stats[i][5] ? false : true;
            structures[structureName].stats[i].population = stats[i][6];
            structures[structureName].stats[i].population_isPositive = 0 == stats[i][7] ? false : true;
        }

        structuresIndex.push(structureName);
        structures[structureName].index = structuresIndex.length - 1;
    }


    /// @dev Add or edit constraints for the construction process (where, who etc.)
    /// @param structureName Unique structure name
    /// @param land Can be constructed on a land tile if true
    /// @param sea Can be constructed on a sea tile if true
    /// @param factions Can be constructed if faction => true 
    function setConstructionConstraints(
        bytes32 structureName, 
        bool land, 
        bool sea, 
        bool[] memory factions) 
        public 
        onlyOwner 
    {
        structures[structureName].constructionConstraints.land = land;
        structures[structureName].constructionConstraints.sea = sea;
        for (uint8 i = 0; i < factions.length; i++)
        {
            structures[structureName].constructionConstraints.factions[i] = factions[i];
        }
    }


    /// @dev Add or edit construction requirements (workforce, transport and resources)
    /// @param structureName Unique structure name
    /// @param transportUnits The amount of storage units 
    function setConstructionRequirements(
        bytes32 structureName, 
        uint[] memory transportUnits, 
        address[][] memory resource_types,
        uint[][] memory resource_amounts,
        uint[][] memory workforce_roles,
        uint[][] memory workforce_amounts) 
        public 
        onlyOwner 
    {
        for (uint8 i = 0; i < transportUnits.length; i++)
        {
            structures[structureName].constructionRequirements[i].transportUnits = transportUnits.length;
            for (uint ii = 0; ii < resource_types[i].length; ii++)
            {
                structures[structureName].constructionRequirements[i].resources[resource_types[i][ii]] = resource_amounts[i][ii];
            }
            
            for (uint ii = 0; ii < workforce_roles[i].length; ii++)
            {
                structures[structureName].constructionRequirements[i].workforce[workforce_roles[i][ii]] = workforce_amounts[i][ii];
            }
        }
    }

    
    /**
     * Public methods
     */
    function startConstruction(
        uint blueprint, 
        uint titleDeed, 
        uint pricePerTransportUnit, 
        uint[] memory pricesPerWorkUnit) 
        public virtual override 
        authorizeBlueprint(blueprint) 
        authorizeTitledeed(titleDeed) 
    {
        bytes32 structureId = ICryptopiaBlueprintToken(blueprintContract).getStructure(blueprint);
        Structure storage structure = structures[structureId];

        uint32 tileIndex = ICryptopiaTitleDeedToken(titleDeedContract).getTile(titleDeed);
        (,,,,, uint8 elevation, uint8 waterLevel,,,,,) = ICryptopiaMap(titleDeedContract).getTile(tileIndex);

        Construction storage _construction = construction[tileIndex];
        Constructed storage _constructed = constructed[tileIndex];

        // No ongoing construction
        require(_construction.structure == 0, "Ongoing construction");

         // No existing structure
        require(_constructed.structure == 0, "Existing structure");

        // Can construct at this location
        bool canConstruct = false;
        if (structure.constructionConstraints.land && waterLevel <= elevation)
        {
            canConstruct = true;
        }

        if (!canConstruct && structure.constructionConstraints.sea && waterLevel > elevation)
        {
            canConstruct = true;
        }

        require(canConstruct, "Unsuitable location");

        // Burn blueprint
        ICryptopiaBlueprintToken(blueprintContract).burn(blueprint);

        // Add construction 
        construction[tileIndex].structure = structureId;

        // Deduct resources
        for (uint i = 0; i < structure.constructionRequirements[0].resourcesIndex.length; i++)
        {
            address resource = structure.constructionRequirements[0].resourcesIndex[i];
            require(
                IERC20Upgradeable(resource).transferFrom(
                    msg.sender, address(this), structure.constructionRequirements[0].resources[resource]), 
                "Unable to transfer resource");
        }

        // Deduct wages
        uint wages = 0;

        // Add transport
        wages += structure.constructionRequirements[0].transportUnits * pricePerTransportUnit;

        // Add to construction
        construction[tileIndex].transport.remaining = structure.constructionRequirements[0].transportUnits;
        construction[tileIndex].transport.wage = pricePerTransportUnit;

        // Add workforce
        for (uint i = 0; i < structure.constructionRequirements[0].workforceIndex.length; i++)
        {
            uint role = structure.constructionRequirements[0].workforceIndex[i];
            uint numberOfWorkers = structure.constructionRequirements[0].workforce[role];

            // Add to construction
            construction[tileIndex].workforce[role].remaining = numberOfWorkers;
            construction[tileIndex].workforce[role].wage = pricesPerWorkUnit[role];

            // Compute total wages
            wages += numberOfWorkers * pricesPerWorkUnit[role];
        }

        if (wages > 0)
        {
            require(
                IERC20Upgradeable(tokenContract).transferFrom(
                    msg.sender, address(this), wages), 
                "Unable to transfer wages");
        }

        // Emit events
        emit ConstructionStarted(tileIndex, structureId);
    }
}