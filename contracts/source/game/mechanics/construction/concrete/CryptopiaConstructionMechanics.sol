// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../../tokens/ERC721/blueprints/IBlueprints.sol";
import "../../../assets/errors/AssetErrors.sol";
import "../../../assets/types/AssetDataTypes.sol";
import "../../../buildings/IBuildingRegister.sol";
import "../../types/LabourDataTypes.sol";
import "../IConstructionMechanics.sol";

contract CryptopiaConstructionMechanics is Initializable, AccessControlUpgradeable, IConstructionMechanics 
{
    /**
     * Storage 
     */
    struct ConstructionContract
    {
        uint64 expiration;

        /// @dev The labour requirements for construction
        LabourContract[] labour;

        /// @dev The resources required for construction
        ResourceContract[] resources;
    }

    // Tile index => Construction data
    mapping (uint16 => ConstructionContract) public constructions;


    /// @dev Refs
    address public treasury;
    address public cryptopiaTokenContract;
    address public titleDeedsContract;
    address public blueprintsContract;
    address public buildingRegisterContract;

    // Settings
    uint constant private TAX_RATE = 100; // 10%
    uint constant private TAX_RATE_PRECISION = 1_000; // 1_000
    uint64 constant private MAX_CONSTRUCTION_TIME = 86400; // 1 day 


    /**
     * Events
     */


    /**
     * Errors
     */


    /// @dev Constructor
    /// @param _treasury The address of the treasury
    /// @param _cryptopiaTokenContract The address of the Cryptopia token contract
    /// @param _titleDeedsContract The address of the title deeds contract
    /// @param _blueprintsContract The address of the blueprints contract
    /// @param _buildingRegisterContract The address of the building register
    function initialize(
        address _treasury,
        address _cryptopiaTokenContract,
        address _titleDeedsContract, 
        address _blueprintsContract,
        address _buildingRegisterContract) 
        public virtual initializer 
    {
        __AccessControl_init();

        // Set refs
        treasury = _treasury;
        cryptopiaTokenContract = _cryptopiaTokenContract;
        titleDeedsContract = _titleDeedsContract;
        blueprintsContract = _blueprintsContract;
        buildingRegisterContract = _buildingRegisterContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Public functions 
     */
    function startConstruction(
        uint titleDeedId, 
        uint blueprintId, 
        uint[] memory labourCompenstations, 
        uint[] memory resourceCompensations) 
        public override 
    {
        // Ensure caller owns the title deed
        if (msg.sender != IERC721(titleDeedsContract).ownerOf(titleDeedId))
        {
            revert TokenNotOwnedByAccount(msg.sender, titleDeedsContract, titleDeedId);
        }

        // Ensure caller owns the blueprint
        if (msg.sender != IERC721(blueprintsContract).ownerOf(blueprintId))
        {
            revert TokenNotOwnedByAccount(msg.sender, blueprintsContract, blueprintId);
        }

        // Convert title deed id to tile index
        uint16 tileIndex = uint16(titleDeedId - 1);

        // Get building from blueprint
        bytes32 building = IBlueprints(blueprintsContract).getBuilding(blueprintId);

        // Burn the blueprint
        IBlueprints(blueprintsContract).__burn(blueprintId);

        // Get construction data
        ConstructionData memory data = IBuildingRegister(buildingRegisterContract)
            .getConstructionData(building);

        // Create snapshot of construction data
        // Note: This is done to prevent the building register from being able to modify the data after construction has started
        constructions[tileIndex].expiration = uint64(block.timestamp) + MAX_CONSTRUCTION_TIME;

        // Track compensation
        uint totalCompensation = 0;

        // Copy labour data
        for (uint i = 0; i < data.requirements.labour.length; i++)
        {
            LabourData memory labourData = data.requirements.labour[i];
            constructions[tileIndex].labour.push(LabourContract(
                labourData.profession,
                labourData.hasMinimumLevel,
                labourData.minLevel,
                labourData.hasMaximumLevel,
                labourData.maxLevel,
                labourData.slots,
                labourData.slots,
                labourData.actionValue1,
                labourData.actionValue2,
                labourCompenstations[i]
            ));

            totalCompensation += labourData.slots * labourCompenstations[i];
        }

        // Copy resource data
        for (uint i = 0; i < data.requirements.resources.length; i++)
        {
            ResourceData memory resourceData = data.requirements.resources[i];
            constructions[tileIndex].resources.push(ResourceContract(
                resourceData.resource,
                resourceData.amount,
                resourceCompensations[i]
            ));

            totalCompensation += resourceData.amount * resourceCompensations[i];
        }

        // Deduct compensation for labour and materials
        if (totalCompensation > 0)
        {
            IERC20(cryptopiaTokenContract).transferFrom(
                msg.sender, address(this), totalCompensation);

            // Deduct tax for treasury
            uint totalTax = totalCompensation * TAX_RATE / TAX_RATE_PRECISION;
            if (totalTax > 0)
            {    
                IERC20(cryptopiaTokenContract).transferFrom(
                    msg.sender, treasury, totalTax);
            }
        }

        // Start construction
        IBuildingRegister(buildingRegisterContract)
            .__startConstruction(tileIndex, building);
    }


    

    // Implement construction mechanics
    // - Owner starts construction (owns land and blueprint)
    //   * Burn blueprint
    //   * Deduct TOS for labor and materials
    //   * Start construction
    // - Players deposit resources in exchange for TOS
    // - Players do the construction work in exchange for TOS (until construction is complete)
}