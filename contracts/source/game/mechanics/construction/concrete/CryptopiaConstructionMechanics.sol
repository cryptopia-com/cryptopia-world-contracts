// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../../tokens/ERC20/assets/IAssetToken.sol";
import "../../../../tokens/ERC721/blueprints/IBlueprints.sol";
import "../../../players/errors/PlayerErrors.sol";
import "../../../inventories/types/InventoryEnums.sol";
import "../../../inventories/errors/InventoryErrors.sol";
import "../../../inventories/IInventories.sol";
import "../../../assets/errors/AssetErrors.sol";
import "../../../assets/IAssetRegister.sol";
import "../../../buildings/IBuildingRegister.sol";
import "../../../maps/IMaps.sol";
import "../types/ConstructionDataTypes.sol";
import "../IConstructionMechanics.sol";

contract CryptopiaConstructionMechanics is Initializable, AccessControlUpgradeable, IConstructionMechanics 
{
    /**
     * Storage 
     */
    // Tile index => Construction data
    mapping (uint16 => ConstructionContract) public constructions;


    // Refs
    address public treasury;
    address public cryptopiaTokenContract;
    address public titleDeedsContract;
    address public blueprintsContract;
    address public assetRegisterContract;
    address public buildingRegisterContract;
    address public inventoriesContract;
    address public mapsContract;


    // Settings
    uint constant private TAX_RATE = 100; // 10%
    uint constant private TAX_RATE_PRECISION = 1_000; // 1_000
    uint64 constant private MAX_CONSTRUCTION_TIME = 86400; // 1 day 


    /**
     * Events
     */
    /// @dev Emitted when a resource is deposited
    /// @param player The player that deposited the resources
    /// @param tileIndex The tile index at which the resources were deposited
    /// @param resource The resource that was deposited
    /// @param amount The amount that was deposited
    event ConstructionResourceDeposit(address indexed player, uint16 indexed tileIndex, Resource resource, uint amount);


    /**
     * Errors
     */
    /// @dev Error when construction is not in progress at the tile index
    error ConstructionNotInProgress(uint16 tileIndex);


    /// @dev Constructor
    /// @param _treasury The address of the treasury
    /// @param _cryptopiaTokenContract The address of the Cryptopia token contract
    /// @param _titleDeedsContract The address of the title deeds contract
    /// @param _blueprintsContract The address of the blueprints contract
    /// @param _assetRegisterContract Location of the asset register contract
    /// @param _buildingRegisterContract The address of the building register
    /// @param _inventoriesContract The address of the inventories contract
    /// @param _mapsContract The address of the maps contract   
    function initialize(
        address _treasury,
        address _cryptopiaTokenContract,
        address _titleDeedsContract, 
        address _blueprintsContract,
        address _assetRegisterContract,
        address _buildingRegisterContract,
        address _inventoriesContract,
        address _mapsContract) 
        public virtual initializer 
    {
        __AccessControl_init();

        // Set refs
        treasury = _treasury;
        cryptopiaTokenContract = _cryptopiaTokenContract;
        titleDeedsContract = _titleDeedsContract;
        blueprintsContract = _blueprintsContract;
        assetRegisterContract = _assetRegisterContract;
        buildingRegisterContract = _buildingRegisterContract;
        inventoriesContract = _inventoriesContract;
        mapsContract = _mapsContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Public functions 
     */
    /// @dev Get construction contract at a tile index
    /// @param tileIndex The tile index
    /// @return The construction contract
    function getConstructionContract(uint16 tileIndex) 
        public view override 
        returns (ConstructionContract memory)
    {
        return constructions[tileIndex];
    }


    /// @dev Start construction of a building
    /// @notice In order to start construction:
    /// - The player must own the title deed
    /// - The player must own the blueprint (blueprint is burned)
    /// - The player must pay the labour and resource compensations
    /// @param titleDeedId The title deed ID
    /// @param blueprintId The blueprint ID
    /// @param labourCompenstations The labour compensations
    /// @param resourceCompensations The resource compensations
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
        public override 
    {
        ConstructionContract storage constructionContract = constructions[tileIndex];

        // Ensure construction is in progress
        if (constructionContract.expiration < block.timestamp)
        {
            revert ConstructionNotInProgress(tileIndex);
        }

        // Get Player location data
        (
            uint16 playerTileIndex,
            uint16 playerTileGroup,
            bool playerCanInteract
        ) = IMaps(mapsContract).getPlayerLocationData(msg.sender);

        // Check if player is at the construction site
        if (playerTileIndex != tileIndex)
        {
            revert PlayerNotInExpectedLocation(msg.sender, tileIndex, playerTileIndex);
        }

        // Check if player can interact with the tile
        if (!playerCanInteract)
        {
            revert PlayerCannotInteract(msg.sender);
        }

        bool hasDockAccess = IBuildingRegister(buildingRegisterContract) // Todo: could only be called when a ship inventory is referenced
            .hasDockAccess(playerTileGroup);
        
        // Track compensation
        uint totalCompensation = 0;

        // Deposit resources
        for (uint i = 0; i < deposits.length; i++)
        {
            ResourceContractDeposit memory resourceDeposit = deposits[i];
            ResourceContract storage resourceContract = constructionContract.resources[resourceDeposit.contractIndex];

            // Validate inventory (backpack or ship when dock access)
            if (Inventory.Backpack != resourceDeposit.inventory && 
              !(Inventory.Ship == resourceDeposit.inventory && hasDockAccess))
            {
                revert InventoryNotAccessible(resourceDeposit.inventory, playerTileIndex);
            }

            // Calculate amount to deposit
            uint amount = deposits[i].amount;
            if (amount > resourceContract.amount)
            {
                amount = resourceContract.amount;
            }

            // Mark resource as deposited
            resourceContract.amount -= amount;

            // Count towards total compensation
            totalCompensation += amount * resourceContract.compensation;

            // Check if resource is fully deposited
            if (0 == resourceContract.amount)
            {
                constructionContract.resourceProgress++;
            }

            // Resolve asset
            address asset = IAssetRegister(assetRegisterContract)
                .getAssetByResrouce(resourceContract.resource);

            // Deduct resources from inventory
            IInventories(inventoriesContract)
                .__deductFungibleToken(msg.sender, resourceDeposit.inventory, asset, amount, true);

            // Emit event
            emit ConstructionResourceDeposit(msg.sender, tileIndex, resourceContract.resource, amount);
        }

        // Transfer compensation
        if (totalCompensation > 0)
        {
            IERC20(cryptopiaTokenContract)
                .transfer(msg.sender, totalCompensation);
        }
    }
}