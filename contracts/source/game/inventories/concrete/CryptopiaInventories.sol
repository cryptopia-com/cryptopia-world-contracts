// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../IInventories.sol";
import "../types/InventoryEnums.sol";
import "../errors/InventoryErrors.sol";
import "../../players/IPlayerRegister.sol";
import "../../players/errors/PlayerErrors.sol";
import "../../players/control/IPlayerFreezeControl.sol";
import "../../assets/errors/AssetErrors.sol";
import "../../../errors/ArgumentErrors.sol";

/// @title Cryptopia Inventories Contract
/// @notice Manages player and ship inventories in Cryptopia, handling both fungible (ERC20) and non-fungible (ERC721) assets.
/// It allows for transferring, assigning, and deducting assets from inventories while managing their weight and capacity limits.
/// Integrates with ERC20 and ERC721 contracts for robust asset management within the game's ecosystem.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaInventories is Initializable, AccessControlUpgradeable, IInventories, IPlayerFreezeControl, IERC721Receiver {

    /// @dev Represents an asset with a specific weight and index, used 
    /// for inventory weight calculations and mapping identification
    struct Asset 
    {
        /// @dev Position of the asset in its respective index array for quick access
        uint index;

        /// @dev Unit weight of the asset, used for calculating total inventory weight
        uint weight;
    }

    /// @dev Inventory space that holds fungible and non-fungible assets
    struct InventorySpaceData
    {
        /// @dev Combined weight of both fungible and non-fungible assets
        uint weight;

        /// @dev Maximum allowable weight for this inventory
        uint maxWeight;

        /// @dev Mapping of fungible asset addresses (ERC20 tokens) to their quantities
        mapping (address => uint) fungible;

        /// @dev Mapping of non-fungible asset addresses (ERC721 tokens) to their specific inventory data
        mapping (address => NonFungibleTokenInventorySpaceData) nonFungible;
    }

    /// @dev Manages the non-fungible token (NFT) data within an inventory space
    struct NonFungibleTokenInventorySpaceData
    {
        /// @dev Mapping from NFT token ID to its index in the tokensIndex array
        mapping (uint => uint) tokens;
        uint[] tokensIndex;
    }

    /// @dev Represents data associated with an NFT in the inventory system
    struct NonFungibleTokenData
    {
        /// @dev Address of the owner of the token
        address owner;

        /// @dev Inventory location (e.g., player's backpack or ship) where the token is stored
        Inventory inventory;
    }

    /// @dev Holds data about a player's inventory
    struct PlayerInventoryData
    {
        /// @dev Timestamp marking when the freeze status expires
        /// @notice Restricts inventory interactions until this time passes
        uint64 frozenUntil;
    }


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    /// @dev Defines the weight of a single inventory slot in kilograms
    uint constant public INVENTORY_SLOT_SIZE = 1_000_000_000_000_000_000_000; // 10kg

    /// @dev Mapping of fungible assets (ERC20 tokens) to their corresponding asset data
    mapping (address => Asset) public fungible; 
    address[] internal fungibleIndex;

    /// @dev Mapping of non-fungible assets (ERC721 tokens) to their corresponding asset data
    mapping (address => Asset) public nonFungible; 
    address[] internal nonFungibleIndex;

    /// @dev Mapping from player address to the tokenId of their equipped ship
    mapping (address => uint) public playerToShip;

    /// @dev Nested mapping for non-fungible token data, mapping asset addresses to tokenIds and their data
    mapping (address => mapping (uint => NonFungibleTokenData)) public nonFungibleTokenDatas;

    /// @dev Mapping of ship tokenIds to their inventory space data
    mapping (uint => InventorySpaceData) public shipInventories;

    /// @dev Mapping from player addresses to their inventory data, covering both starter ships and backpacks
    mapping (address => InventorySpaceData) public playerInventories;

    /// @dev Mapping from player addresses to their inventory-specific data
    mapping (address => PlayerInventoryData) public playerData;

    // Refs
    address public treasury;


    /**
     * Events
     */
    /// @dev Emitted when the backpack inventory of a player was updated
    /// @param player The player for who the backpack inventory was updated
    /// @param maxWeight The new max weight that the player can cary
    event PlayerInventoryChange(address indexed player, uint maxWeight);

    /// @dev Emitted when the inventory of a ship was updated
    /// @param ship The tokenId of the ship for wich the inventory was updated
    /// @param maxWeight The new max weight that the ship can cary
    event ShipInventoryChange(uint indexed ship, uint maxWeight);

    /// @dev Assign `asset` internally to `inventory`
    /// @param player The receiver of the asset
    /// @param inventory Assigned to inventory {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenId The token ID to send (zero indicates fungible)
    event InventoryAssign(address indexed player, Inventory inventory, address indexed asset, uint amount, uint tokenId);

    /// @dev Deduct `asset` internally from `inventory` to treasury
    /// @param player The owener of the asset
    /// @param inventory Deducted from inventory {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenId The token ID to send (zero indicates fungible)
    event InventoryDeduct(address indexed player, Inventory inventory, address indexed asset, uint amount, uint tokenId);

    /// @dev Transfer `asset` internally from 'inventory_from' to `inventory_to`
    /// @param player_from The sender (owner) of the asset
    /// @param player_to The receiver of the asset (can be the same as player_from)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenId The token ID to send (zero indicates fungible)
    event InventoryTransfer(address indexed player_from, address indexed player_to, Inventory inventory_from, Inventory inventory_to, address indexed asset, uint amount, uint tokenId);


    /**
     * Errors
     */
    /// @dev Emitted when the inventory is not supported
    /// @param inventory The inventory that is not supported
    error InventoryUnsupported(Inventory inventory);

    /// @dev Emitted when a deposit fails
    /// @param account The account that tried to deposit
    /// @param inventory The inventory type that was tried to be deposited to {BackPack | Ship}
    /// @param asset The asset that was tried to be deposited
    /// @param amount The amount that was tried to be deposited
    /// @param tokenId The token id that was tried to be deposited (zero if not applicable)
    error InventoryDepositFailed(address account, Inventory inventory, address asset, uint amount, uint tokenId);

    /// @dev Emitted when a withdraw fails
    /// @param account The account that tried to withdraw
    /// @param inventory The inventory type that was tried to be withdrawn from {BackPack | Ship}
    /// @param asset The asset that was tried to be withdrawn
    /// @param amount The amount that was tried to be withdrawn
    /// @param tokenId The token id that was tried to be withdrawn (zero if not applicable)
    error InventoryWithdrawFailed(address account, Inventory inventory, address asset, uint amount, uint tokenId);

    /// @dev Emitted when the backpack is too heavy
    /// @param player The player whose backpack is too heavy
    error PlayerInventoryTooHeavy(address player);

    /// @dev Emitted when the ship is too heavy
    /// @param ship The ship that is too heavy
    error ShipInventoryTooHeavy(uint ship);


    /**
     * Modifiers
     */
    /// @dev Reverts if the inventories of `player` are frozen
    /// @param player The account of the player to check
    modifier notFrozen(address player) 
    {
        if (playerData[player].frozenUntil > block.timestamp)
        {
            revert PlayerIsFrozen(player, playerData[player].frozenUntil);
        }
        _;
    }


    /// @dev Construct
    /// @param _treasury token (ERC20) receiver
    function initialize(address _treasury) 
        public virtual initializer 
    {
        __AccessControl_init();

        // Refs
        treasury = _treasury;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Set the `weight` for the fungible `asset` (zero invalidates the asset)
    /// @param asset The asset contract address
    /// @param weight The asset unit weight (kg/100)
    function setFungibleAsset(address asset, uint weight)
        public virtual   
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        fungible[asset].weight = weight;
        if (0 == fungibleIndex.length || fungibleIndex[fungible[asset].index] != asset)
        {
            fungible[asset].index = fungibleIndex.length;
            fungibleIndex.push(asset);
        }
    }

    
    /// @dev Set the `weight` for the non-fungible `asset` (zero invalidates the asset)
    /// @param asset The asset contract address
    /// @param accepted If true the inventory will accept the NFT asset
    function setNonFungibleAsset(address asset, bool accepted)
        public virtual   
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        nonFungible[asset].weight = accepted ? INVENTORY_SLOT_SIZE : 0;
        if (0 == nonFungibleIndex.length || nonFungibleIndex[nonFungible[asset].index] != asset)
        {
            nonFungible[asset].index = nonFungibleIndex.length;
            nonFungibleIndex.push(asset);
        }
    }


    /**
     * Public functions
     */
    /// @dev True if the inventories of `player` are frozen
    /// @param player The account of the player to check
    /// @return frozen True if the inventories of `player` are frozen
    function isFrozen(address player)
        public virtual override view
        returns (bool frozen)
    {
        return playerData[player].frozenUntil > block.timestamp;
    }


    /// @dev Retrieves info about 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @return weight The current total weight of player's inventory
    /// @return maxWeight The maximum weight of the player's inventory
    function getPlayerInventoryInfo(address player) 
        public virtual override view 
        returns (uint weight, uint maxWeight)
    {
        weight = playerInventories[player].weight;
        maxWeight = playerInventories[player].maxWeight;
    }


    /// @dev Retrieves the contents from 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @return inventory The inventory space of the player (backpack)
    function getPlayerInventory(address player) 
        public virtual override view 
        returns (InventorySpace memory inventory)
    {
        inventory = InventorySpace({
            weight: playerInventories[player].weight,
            maxWeight: playerInventories[player].maxWeight,
            fungible: new FungibleTokenInventorySpace[](fungibleIndex.length), 
            nonFungible: new NonFungibleTokenInventorySpace[](nonFungibleIndex.length) 
        });


        // Fungible
        for (uint i = 0; i < fungibleIndex.length; i++)
        {
            inventory.fungible[i] = FungibleTokenInventorySpace({
                asset: fungibleIndex[i],
                amount: playerInventories[player].fungible[fungibleIndex[i]]
            });
        }

        // Non-fungible
        for (uint i = 0; i < nonFungibleIndex.length; i++)
        {
            inventory.nonFungible[i] = NonFungibleTokenInventorySpace({
                asset: nonFungibleIndex[i],
                tokenIds: playerInventories[player].nonFungible[nonFungibleIndex[i]].tokensIndex
            });
        }
    }


    /// @dev Retrieves the amount of 'asset' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of fungible assets
    /// @return balance Amount of fungible tokens
    function getPlayerBalanceFungible(address player, address asset) 
        public virtual override view 
        returns (uint balance)
    {
        balance = playerInventories[player].fungible[asset];
    }


    /// @dev Retrieves the 'asset' 'tokenIds' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of non-fungible assets
    /// @return balance Amount of non-fungible tokens
    function getPlayerBalanceNonFungible(address player, address asset) 
        public virtual override view 
        returns (uint balance)
    {
        balance = playerInventories[player].nonFungible[asset].tokensIndex.length;
    }


    /// @dev Retrieves info about 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @return weight The current total weight of ship's inventory
    /// @return maxWeight The maximum weight of the ship's inventory
    function getShipInventoryInfo(uint ship) 
        public virtual override view 
        returns (uint weight, uint maxWeight)
    {
        weight = shipInventories[ship].weight;
        maxWeight = shipInventories[ship].maxWeight;
    }


    /// @dev Retrieves the contents from 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @return inventory The inventory space of the ship
    function getShipInventory(uint ship) 
        public virtual override view 
        returns (InventorySpace memory inventory)
    {
        inventory = InventorySpace({
            weight: shipInventories[ship].weight,
            maxWeight: shipInventories[ship].maxWeight,
            fungible: new FungibleTokenInventorySpace[](fungibleIndex.length), 
            nonFungible: new NonFungibleTokenInventorySpace[](nonFungibleIndex.length) 
        });


        // Fungible
        for (uint i = 0; i < fungibleIndex.length; i++)
        {
            inventory.fungible[i] = FungibleTokenInventorySpace({
                asset: fungibleIndex[i],
                amount: shipInventories[ship].fungible[fungibleIndex[i]]
            });
        }

        // Non-fungible
        for (uint i = 0; i < nonFungibleIndex.length; i++)
        {
            inventory.nonFungible[i] = NonFungibleTokenInventorySpace({
                asset: nonFungibleIndex[i],
                tokenIds: shipInventories[ship].nonFungible[nonFungibleIndex[i]].tokensIndex
            });
        }
    }


    /// @dev Retrieves the amount of 'asset' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of fungible assets
    /// @return balance Amount of fungible tokens
    function getShipBalanceFungible(uint ship, address asset) 
        public virtual override view 
        returns (uint balance)
    {
        balance = shipInventories[ship].fungible[asset];
    }


    /// @dev Retrieves the 'asset' 'tokenIds' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of non-fungible assets
    /// @return balance Amount of non-fungible tokens
    function getShipBalanceNonFungible(uint ship, address asset) 
        public virtual override view 
        returns (uint balance)
    {
        balance = shipInventories[ship].nonFungible[asset].tokensIndex.length;
    }


    /// @dev Returns non-fungible token data for `tokenId` of `asset`
    /// @param asset the contract address of the non-fungible asset
    /// @param tokenId the token ID to retrieve data about
    /// @return owner the account (player) that owns the token in the inventory
    /// @return inventory {Inventory} the inventory space where the token is stored 
    function getNonFungibleTokenData(address asset, uint tokenId)
        public virtual override view 
        returns (
            address owner, 
            Inventory inventory
        )
    {
        owner = nonFungibleTokenDatas[asset][tokenId].owner;
        inventory = nonFungibleTokenDatas[asset][tokenId].inventory;
    }


    /// @dev Transfer `asset` from 'inventory_from' to `inventory_to`
    /// @param player_to The receiving player (can be _msgSender())
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenIds The token ID to send (zero indicates fungible)
    function transfer(address[] memory player_to, Inventory[] memory inventory_from, Inventory[] memory inventory_to, address[] memory asset, uint[] memory amount, uint[][] memory tokenIds)
        public virtual override 
        notFrozen(_msgSender())
    {
        address player_from = _msgSender();
        bool seenOtherPlayers = false;
        for (uint i = 0; i < player_to.length; i++)
        {
            if (0 != tokenIds[i].length)
            {
                for (uint j = 0; j < tokenIds[i].length; j++)
                {
                    // Non-Fungible
                    _transferNonFungible(
                        player_from, player_to[i], inventory_from[i], inventory_to[i], asset[i], tokenIds[i][j]);
                }
            }
            else if (0 != amount[i])
            {
                // Fungible
                _transferFungible(
                    player_from, player_to[i], inventory_from[i], inventory_to[i], asset[i], amount[i]);
            }
            else 
            {
                // Amount and token id zero
                revert ArgumentInvalid();
            }

            if (player_from != player_to[i])
            {
                seenOtherPlayers = true;
            }
        }

        // Ensure inventory limits
        if (!seenOtherPlayers)
        {
            _ensurePlayerInventoryWithinLimit(player_from);
            _ensureShipInventoryWithinLimit(playerToShip[player_from]);
        }
        else 
        {
            for (uint i = 0; i < player_to.length; i++)
            {
                _ensureInventoryWithinLimit(player_to[i], inventory_to[i]);
            }
        }
    }


    /// @dev Drop `asset` from `inventory`
    /// @param inventory The inventory to drop the asset from {BackPack | Ship}
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to drop (zero indicates non-fungible)
    /// @param tokenId The token ID to drop (zero indicates fungible)
    function drop(Inventory inventory, address asset, uint amount, uint tokenId)
        public virtual override 
        notFrozen(_msgSender())
    {
        if (0 != tokenId)
        {
            // Non-Fungible
            _deductNonFungibleToken(_msgSender(), inventory, asset, tokenId, false);
        }
        else if (0 != amount)
        {
            // Fungible
            _deductFungibleToken(_msgSender(), inventory, asset, amount, false);
        }
        else 
        {
            // Amount and token id zero
            revert ArgumentInvalid();
        }
    }


    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) 
        public virtual override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }


    /**
     * System functions
     */
    /// @dev Prevents `account` from traveling `until`
    /// @param account The player to lock
    /// @param until The datetime on which the lock expires
    function __freeze(address account, uint64 until) 
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account].frozenUntil = until;
    }


    /// @dev Freezes `account1` and `account2` `until`
    /// @param account1 The first player to freeze
    /// @param account2 The second player to freeze
    /// @param until The datetime on which the lock expires
    function __freeze(address account1, address account2, uint64 until) 
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account1].frozenUntil = until;
        playerData[account2].frozenUntil = until;
    }

    
    /// @dev Unfreeze `account`
    /// @param account The player to unfreeze
    function __unfreeze(address account)
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account].frozenUntil = 0;
    }


    /// @dev Unfreeze `account1` and `account2`
    /// @param account1 The first player to unfreeze
    /// @param account2 The second player to unfreeze
    function __unfreeze(address account1, address account2)
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account1].frozenUntil = 0;
        playerData[account2].frozenUntil = 0;
    }


    /// @dev Create inventories for `player` and `ship`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes player does not have inventories yet
    /// - Assumes ship does not have inventories yet
    /// @param player The player that owns the inventories
    /// @param ship The tokenId of the ship that owns the inventories
    /// @param maxWeight_backpack The max weight of the player's backpack
    /// @param maxWeight_ship The max weight of the ship's inventory
    function __create(address player, uint ship, uint maxWeight_backpack, uint maxWeight_ship)
        public virtual override 
    {
        // Set ship
        playerToShip[player] = ship;

        // Create inventories
        playerInventories[player].maxWeight = maxWeight_backpack;
        shipInventories[ship].maxWeight = maxWeight_ship;

        // Emit
        emit PlayerInventoryChange(player, maxWeight_backpack);
        emit ShipInventoryChange(ship, maxWeight_ship);
    }


    /// @dev Update equipted ship for `player`
    /// @param player The player that equipted the `ship`
    /// @param ship The tokenId of the equipted ship
    /// @param maxWeight The new max weight of the ship
    function __setPlayerShip(address player, uint ship, uint maxWeight) 
        public virtual override 
        notFrozen(player)
        onlyRole(SYSTEM_ROLE) 
    {
        // Set ship
        playerToShip[player] = ship;

        // Update inventory
        _setShipInventory(ship, maxWeight);
    }


    /// @dev Update a ships inventory max weight
    /// - Fails if the ships weight exeeds the new max weight
    /// @param ship The tokenId of the ship to update
    /// @param maxWeight The new max weight of the ship
    function __setShipInventory(uint ship, uint maxWeight)
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
    {
        _setShipInventory(ship, maxWeight);
    }


    /// @dev Update a player's personal inventories 
    /// @param player The player of whom we're updateing the inventories
    /// @param maxWeight The new max weight of the player's backpack
    function __setPlayerInventory(address player, uint maxWeight)
        public virtual override  
        onlyRole(SYSTEM_ROLE) 
    {
        if (playerInventories[player].maxWeight == maxWeight)
        {
            return;
        }

        // Check if backpack not is too heavy
        if (playerInventories[player].weight > maxWeight)
        {
            revert PlayerInventoryTooHeavy(player);
        }

        // Update
        playerInventories[player].maxWeight = maxWeight;

        // Emit
        emit PlayerInventoryChange(player, maxWeight);
    }


    /// @dev Assigns `amount` of `asset` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes amount of asset is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to assign
    function __assignFungibleToken(address player, Inventory inventory, address asset, uint amount)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        _assignFungibleToken(player, inventory, asset, amount);
    }

    
    /// @dev Assigns `tokenId` from `asset` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes tokenId is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param tokenId The token id from asset to assign
    function __assignNonFungibleToken(address player, Inventory inventory, address asset, uint tokenId)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        _assignNonFungibleToken(player, inventory, asset, tokenId);
    }


    /// @dev Assigns `tokenIds` from `assets` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes tokenId is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param tokenIds The token ids from asset to assign
    function __assignNonFungibleTokens(address player, Inventory inventory, address asset, uint[] memory tokenIds)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        for (uint i = 0; i < tokenIds.length; i++)
        {
            _assignNonFungibleToken(
                player, inventory, asset, tokenIds[i]);
        } 
    }


    /// @dev Assigns fungible and non-fungible tokens in a single transaction
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes amount is deposited to the contract
    /// - Assumes tokenId is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param tokenId The token ids from asset to assign
    function __assign(address player, Inventory[] memory inventory, address[] memory asset, uint[] memory amount, uint[] memory tokenId)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    { 
        for (uint i = 0; i < asset.length; i++)
        {
            if (0 != tokenId[i])
            {
                // Non-Fungible
                _assignNonFungibleToken(
                    player, inventory[i], asset[i], tokenId[i]);
            }
            else if (0 != amount[i])
            {
                // Fungible
                _assignFungibleToken(
                    player, inventory[i], asset[i], amount[i]);
            }
            else 
            {
                // Amount and token id zero
                revert ArgumentInvalid();
            }
        }
    }


    /// @dev Deducts `amount` of `asset` from the `inventory` of `player` 
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes amount of asset is allocated to player
    /// - Checks if the players inventory is frozen
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to deduct
    /// @param sendToTreasury If true the deducted assets will be sent to the treasury
    function __deductFungibleToken(address player, Inventory inventory, address asset, uint amount, bool sendToTreasury)
        public virtual override 
        notFrozen(player)
        onlyRole(SYSTEM_ROLE)
    {
        _deductFungibleToken(player, inventory, asset, amount, sendToTreasury);
    }


    /// @dev Deducts `amount` of `asset` from the `inventory` of `player` 
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes amount of asset is allocated to player
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to deduct
    /// @param sendToTreasury If true the deducted assets will be sent to the treasury
    function __deductFungibleTokenUnchecked(address player, Inventory inventory, address asset, uint amount, bool sendToTreasury)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        _deductFungibleToken(player, inventory, asset, amount, sendToTreasury);
    }


    /// @dev Deducts `tokenId` from `asset` from the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes tokenId of asset is allocated to player
    /// - Checks if the players inventory is frozen
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {BackPack | Ship}
    /// @param asset The asset contract address
    /// @param tokenId The token id from asset to deduct
    /// @param sendToTreasury If true the deducted assets will be sent to the treasury
    function __deductNonFungibleToken(address player, Inventory inventory, address asset, uint tokenId, bool sendToTreasury)
        public virtual override 
        notFrozen(player)
        onlyRole(SYSTEM_ROLE)
    {
        _deductNonFungibleToken(player, inventory, asset, tokenId, sendToTreasury);
    }

    
    /// @dev Deducts `tokenId` from `asset` from the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes tokenId of asset is allocated to player
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {BackPack | Ship}
    /// @param asset The asset contract address
    /// @param tokenId The token id from asset to deduct
    /// @param sendToTreasury If true the deducted assets will be sent to the treasury
    function __deductNonFungibleTokenUnchecked(address player, Inventory inventory, address asset, uint tokenId, bool sendToTreasury)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        _deductNonFungibleToken(player, inventory, asset, tokenId, sendToTreasury);
    }


    /// @dev Deducts fungible and non-fungible tokens in a single transaction
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes amount of asset is allocated to player
    /// - Checks if the players inventory is frozen
    /// @param player The inventory owner to deduct the assets from
    /// @param inventory The inventory type to deduct the assets from {BackPack | Ship}
    /// @param asset The asset contract addresses 
    /// @param amount The amounts of assets to deduct
    /// @param sendToTreasury If true the deducted assets will be sent to the treasury
    function __deduct(address player, Inventory inventory, address[] memory asset, uint[] memory amount, bool sendToTreasury)
        public virtual override 
        notFrozen(player)
        onlyRole(SYSTEM_ROLE)
    {
        for (uint i = 0; i < asset.length; i++)
        {
            _deductFungibleToken(player, inventory, asset[i], amount[i], sendToTreasury);
        }
    }


    /// @dev Deducts fungible and non-fungible tokens in a single transaction
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes amount of asset is allocated to player
    /// @param player The inventory owner to deduct the assets from
    /// @param inventory The inventory type to deduct the assets from {BackPack | Ship}
    /// @param asset The asset contract addresses 
    /// @param amount The amounts of assets to deduct
    /// @param sendToTreasury If true the deducted assets will be sent to the treasury
    function __deductUnchecked(address player, Inventory inventory, address[] memory asset, uint[] memory amount, bool sendToTreasury)
        public virtual override  
        onlyRole(SYSTEM_ROLE)
    {
        for (uint i = 0; i < asset.length; i++)
        {
            _deductFungibleToken(player, inventory, asset[i], amount[i], sendToTreasury);
        }
    }


    /// @dev Transfers `asset` from `player_from` to `player_to`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes amount of asset is allocated to player
    /// - Checks if the players inventories are frozen
    /// @param player_from The sending player
    /// @param player_to The receiving player
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to transfer (zero indicates non-fungible)
    /// @param tokenId The token ID to transfer (zero indicates fungible)
    function __transfer(address player_from, address player_to, Inventory[] memory inventory_from, Inventory[] memory inventory_to, address[] memory asset, uint[] memory amount, uint[] memory tokenId)
        public virtual override 
        notFrozen(player_from)
        notFrozen(player_to)
        onlyRole(SYSTEM_ROLE)
    {
        for (uint i = 0; i < asset.length; i++)
        {
            if (0 != tokenId[i])
            {
                // Non-Fungible
                _transferNonFungible(
                    player_from, player_to, inventory_from[i], inventory_to[i], asset[i], tokenId[i]);
            }
            else if (0 != amount[i])
            {
                // Fungible
                _transferFungible(
                    player_from, player_to, inventory_from[i], inventory_to[i], asset[i], amount[i]);
            }
            else 
            {
                // Amount and token id zero
                revert ArgumentInvalid();
            }
        }

        // Check inventory limits
        _ensurePlayerInventoryWithinLimit(player_to);
        _ensureShipInventoryWithinLimit(playerToShip[player_to]);
    }


    /// @dev Transfers `asset` from `player_from` to `player_to`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes amount of asset is allocated to player
    /// - Assumes missing amount and tokenId indicates skipping
    /// @param player_from The sending player
    /// @param player_to The receiving player
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to transfer (zero indicates non-fungible)
    /// @param tokenId The token ID to transfer (zero indicates fungible)
    function __transferUnchecked(address player_from, address player_to, Inventory[] memory inventory_from, Inventory[] memory inventory_to, address[] memory asset, uint[] memory amount, uint[] memory tokenId)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        for (uint i = 0; i < asset.length; i++)
        {
            if (0 != tokenId[i])
            {
                // Non-Fungible
                _transferNonFungible(
                    player_from, player_to, inventory_from[i], inventory_to[i], asset[i], tokenId[i]);
            }
            else if (0 != amount[i])
            {
                // Fungible
                _transferFungible(
                    player_from, player_to, inventory_from[i], inventory_to[i], asset[i], amount[i]);
            }
        }

        // Check inventory limits
        _ensurePlayerInventoryWithinLimit(player_to);
        _ensureShipInventoryWithinLimit(playerToShip[player_to]);
    }


    /**
     * Internal functions
     */
    /// @dev Update a ships inventory max weight
    /// - Fails if the ships weight exeeds the new max weight
    /// @param ship The tokenId of the ship to update
    /// @param maxWeight The new max weight of the ship
    function _setShipInventory(uint ship, uint maxWeight)
        internal 
    {
        if (shipInventories[ship].maxWeight == maxWeight)
        {
            return;
        }
        
        // Check if ship not is too heavy
        if (shipInventories[ship].weight > maxWeight)
        {
            revert ShipInventoryTooHeavy(ship);
        }

        // Update
        shipInventories[ship].maxWeight = maxWeight;

        // Emit 
        emit ShipInventoryChange(ship, maxWeight);
    }


    /// @dev Transfer fungible `asset` from 'inventory_from' to `inventory_to`
    /// @param player_from Owner of the asset
    /// @param player_to The receiver of the asset (can be the same as player_from)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC20 contract
    /// @param amount The amount of fungible tokens to send 
    function _transferFungible(address player_from, address player_to, Inventory inventory_from, Inventory inventory_to, address asset, uint amount) 
        internal 
    {
        uint weight = fungible[asset].weight * amount;

        // Check if supported (no weight means not supported)
        if (0 == weight)
        {
            revert UnsupportedAsset(asset);
        }

        // Substract
        if (inventory_from == Inventory.Wallet)
        {
            // Deposit externally
            if (!IERC20(asset).transferFrom(player_from, address(this), amount)) 
            {
                revert InventoryDepositFailed(
                    player_from, inventory_to, asset, amount, 0);
            }
        }
        else if (inventory_from == Inventory.Backpack)
        {
            InventorySpaceData storage inventory = playerInventories[player_from];
            if (inventory.fungible[asset] < amount)
            {
                revert InventoryInsufficientBalance(
                    player_from, inventory_from, asset, amount);
            }

            // Deduct from backpack
            inventory.weight -= weight;
            inventory.fungible[asset] -= amount;
        }
        else if (inventory_from == Inventory.Ship)
        {
            InventorySpaceData storage inventory = shipInventories[playerToShip[player_from]];
            if (inventory.fungible[asset] < amount)
            {
                revert InventoryInsufficientBalance(
                    player_from, inventory_from, asset, amount);
            }

            // Deduct from ship
            inventory.weight -= weight;
            inventory.fungible[asset] -= amount;
        }
        else 
        {
            revert InventoryUnsupported(inventory_from);
        }

        // Add
        if (inventory_to == Inventory.Wallet)
        {
            // Withdraw externally
            if (!IERC20(asset).transfer(player_to, amount)) 
            {
                revert InventoryWithdrawFailed(
                    player_to, inventory_from, asset, amount, 0);
            }
    
        }
        else if (inventory_to == Inventory.Backpack) 
        {
            InventorySpaceData storage inventory = playerInventories[player_to];
            
            // Add to backpack
            inventory.weight += weight;
            inventory.fungible[asset] += amount;
        }
        else if (inventory_to == Inventory.Ship)
        {
            InventorySpaceData storage inventory = shipInventories[playerToShip[player_to]];
            
            // Add to ship
            inventory.weight += weight;
            inventory.fungible[asset] += amount;
        }
        else 
        {
            revert InventoryUnsupported(inventory_to);
        }

        // Emit
        emit InventoryTransfer(player_from, player_to, inventory_from, inventory_to, asset, amount, 0);
    }

    /// @dev Transfer non-fungible `asset` from 'inventory_from' to `inventory_to`
    /// @param player_from Owner of the asset
    /// @param player_to The receiver of the asset (can be the same as player_from)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC20 contract
    /// @param tokenId The token to transfer
    function _transferNonFungible(address player_from, address player_to, Inventory inventory_from, Inventory inventory_to, address asset, uint tokenId) 
        internal 
    {
        // Only supported (no weight means not supported)
        if (nonFungible[asset].weight == 0)
        {
            revert UnsupportedAsset(asset);
        }

        // Substract
        if (inventory_from == Inventory.Wallet)
        {
            // Deposit from wallet
            IERC721(asset).transferFrom(
                player_from, address(this), tokenId);
        }
        else if (inventory_from == Inventory.Backpack)
        {
            InventorySpaceData storage inventory = playerInventories[player_from];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventorySpaceData storage nonFungibleInventory = inventory.nonFungible[asset];

            // Check if token is owned by player
            if (nonFungibleTokenData.owner != player_from)
            {
                revert TokenNotOwnedByAccount(
                    player_from, asset, tokenId);
            }

            // Check if token is in backpack
            if (nonFungibleTokenData.inventory != Inventory.Backpack)
            {
                revert InventoryItemNotFound(
                    player_from, inventory_from, asset, tokenId);
            }

            // Deduct from backpack
            inventory.weight -= INVENTORY_SLOT_SIZE;
            delete nonFungibleTokenDatas[asset][tokenId];

            uint tokenIndex = nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex[tokenIndex] = nonFungibleInventory.tokensIndex[nonFungibleInventory.tokensIndex.length - 1];
            nonFungibleInventory.tokens[nonFungibleInventory.tokensIndex[tokenIndex]] = tokenIndex;

            delete nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex.pop();
        }
        else if (inventory_from == Inventory.Ship)
        {
            InventorySpaceData storage inventory = shipInventories[playerToShip[player_from]];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventorySpaceData storage nonFungibleInventory = inventory.nonFungible[asset];

            // Check if token is owned by player
            if (nonFungibleTokenData.owner != player_from)
            {
                revert TokenNotOwnedByAccount(
                    player_from, asset, tokenId);
            }

            // Check if token is in ship
            if (nonFungibleTokenData.inventory != Inventory.Ship)
            {
                revert InventoryItemNotFound(
                    player_from, inventory_from, asset, tokenId);
            }

            // Deduct from ship
            inventory.weight -= INVENTORY_SLOT_SIZE;
            delete nonFungibleTokenDatas[asset][tokenId];

            uint tokenIndex = nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex[tokenIndex] = nonFungibleInventory.tokensIndex[nonFungibleInventory.tokensIndex.length - 1];
            nonFungibleInventory.tokens[nonFungibleInventory.tokensIndex[tokenIndex]] = tokenIndex;

            delete nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex.pop();
        }
        else 
        {
            revert InventoryUnsupported(inventory_from);
        }

        // Add
        if (inventory_to == Inventory.Wallet)
        {
            // Withdraw externally
            IERC721(asset)
                .transferFrom(address(this), player_to, tokenId);
        }
        else if (inventory_to == Inventory.Backpack) 
        {
            InventorySpaceData storage inventory = playerInventories[player_from];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventorySpaceData storage nonFungibleInventory = inventory.nonFungible[asset];

            // Add to backpack
            inventory.weight += INVENTORY_SLOT_SIZE;
            nonFungibleTokenData.owner = player_to;
            nonFungibleTokenData.inventory = Inventory.Backpack;
            nonFungibleInventory.tokensIndex.push(tokenId);
            nonFungibleInventory.tokens[tokenId] = nonFungibleInventory.tokensIndex.length - 1;
        }
        else if (inventory_to == Inventory.Ship)
        {
            InventorySpaceData storage inventory = shipInventories[playerToShip[player_to]];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventorySpaceData storage nonFungibleInventory = inventory.nonFungible[asset];

            // Add to ship
            inventory.weight += INVENTORY_SLOT_SIZE;
            nonFungibleTokenData.owner = player_to;
            nonFungibleTokenData.inventory = Inventory.Ship;
            nonFungibleInventory.tokens[tokenId] = nonFungibleInventory.tokensIndex.length;
            nonFungibleInventory.tokensIndex.push(tokenId);
        }
        else 
        {
            revert InventoryUnsupported(inventory_to);
        }

        // Emit
        emit InventoryTransfer(player_from, player_to, inventory_from, inventory_to, asset, 1, tokenId);
    }


    /// @dev Assigns `amount` of `asset` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes amount of asset is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to assign
    function _assignFungibleToken(address player, Inventory inventory, address asset, uint amount)
        internal 
    {
        // SYSTEM caller > Assume asset exists
        uint weight = fungible[asset].weight * amount; 

        // SYSTEM caller > Assume inventory exists
        if (inventory == Inventory.Ship) 
        {
            InventorySpaceData storage shipInventory = shipInventories[playerToShip[player]];
            if (shipInventory.weight + weight > shipInventory.maxWeight)
            {
                revert ShipInventoryTooHeavy(playerToShip[player]);
            }

            // Add to ship
            shipInventory.weight += weight;
            shipInventory.fungible[asset] += amount;
        }
        else 
        {
            InventorySpaceData storage backpackInventory = playerInventories[player];
            if (backpackInventory.weight + weight > backpackInventory.maxWeight)
            {
                revert PlayerInventoryTooHeavy(player);
            }

            // Add to backpack
            backpackInventory.weight += weight;
            backpackInventory.fungible[asset] += amount;
        }

        // Emit
        emit InventoryAssign(player, inventory, asset, amount, 0);
    }


    /// @dev Assigns `tokenId` from `asset` to the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Weight will be zero if player does not exist
    /// - Assumes tokenId is deposited to the contract
    /// @param player The inventory owner to assign the asset to
    /// @param inventory The inventory type to assign the asset to {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param tokenId The token id from asset to assign
    function _assignNonFungibleToken(address player, Inventory inventory, address asset, uint tokenId)
        internal 
    {
        // SYSTEM caller > Assume inventory exists
        if (inventory == Inventory.Ship) 
        {
            InventorySpaceData storage shipInventory = shipInventories[playerToShip[player]];
            if (shipInventory.weight + INVENTORY_SLOT_SIZE > shipInventory.maxWeight)
            {
                revert ShipInventoryTooHeavy(playerToShip[player]);
            }

            // Add to ship
            shipInventory.weight += INVENTORY_SLOT_SIZE;
            shipInventory.nonFungible[asset].tokens[tokenId] = shipInventory.nonFungible[asset].tokensIndex.length;
            shipInventory.nonFungible[asset].tokensIndex.push(tokenId);
        }
        else 
        {
            InventorySpaceData storage backpackInventory = playerInventories[player];
            if (backpackInventory.weight + INVENTORY_SLOT_SIZE > backpackInventory.maxWeight)
            {
                revert PlayerInventoryTooHeavy(player);
            }

            // Add to backpack
            backpackInventory.weight += INVENTORY_SLOT_SIZE;
            backpackInventory.nonFungible[asset].tokens[tokenId] = backpackInventory.nonFungible[asset].tokensIndex.length;
            backpackInventory.nonFungible[asset].tokensIndex.push(tokenId);
        }

        nonFungibleTokenDatas[asset][tokenId].owner = player;
        nonFungibleTokenDatas[asset][tokenId].inventory = inventory;

        // Emit
        emit InventoryAssign(player, inventory, asset, 1, tokenId);
    }


    /// @dev Deduct `amount` of `asset` from the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to deduct
    /// @param sendToTreasury If true, sends the asset to the treasury
    function _deductFungibleToken(address player, Inventory inventory, address asset, uint amount, bool sendToTreasury)
        internal 
    {
        // SYSTEM caller > Assume asset exists
        uint weight = fungible[asset].weight * amount; 

        // SYSTEM caller > Assume inventory exists
        if (inventory == Inventory.Ship) 
        {
            InventorySpaceData storage shipInventory = shipInventories[playerToShip[player]];
            if (shipInventory.fungible[asset] < amount)
            {
                revert InventoryInsufficientBalance(
                    player, inventory, asset, amount);
            }

            // Deduct from ship
            shipInventory.weight -= weight;
            shipInventory.fungible[asset] -= amount;
        }
        else 
        {
            InventorySpaceData storage backpackInventory = playerInventories[player];
            if (backpackInventory.fungible[asset] < amount)
            {
                revert InventoryInsufficientBalance(
                    player, inventory, asset, amount);
            }

            // Deduct from backpack
            backpackInventory.weight -= weight;
            backpackInventory.fungible[asset] -= amount;
        }

        // Send to treasury
        if (sendToTreasury && !IERC20(asset).transfer(treasury, amount)) 
        {
            revert InventoryWithdrawFailed(
                treasury, inventory, asset, amount, 0);
        }

        // Emit
        emit InventoryDeduct(player, inventory, asset, amount, 0);
    }


    /// @dev Deduct `tokenId` from `asset` from the `inventory` of `player`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {BackPack | Ship}
    /// @param asset The asset contract address
    /// @param tokenId The token id from asset to deduct
    /// @param sendToTreasury If true, sends the asset to the treasury
    function _deductNonFungibleToken(address player, Inventory inventory, address asset, uint tokenId, bool sendToTreasury)
        internal 
    {
        // SYSTEM caller > Assume inventory exists
        if (inventory == Inventory.Ship) 
        {
            InventorySpaceData storage inventorySpace = shipInventories[playerToShip[player]];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventorySpaceData storage nonFungibleInventory = inventorySpace.nonFungible[asset];

            // Check if token is owned by player
            if (nonFungibleTokenData.owner != player)
            {
                revert TokenNotOwnedByAccount(
                    player, asset, tokenId);
            }

            // Check if token is in ship
            if (nonFungibleTokenData.inventory != Inventory.Ship)
            {
                revert InventoryItemNotFound(
                    player, inventory, asset, tokenId);
            }

            // Deduct from ship
            inventorySpace.weight -= INVENTORY_SLOT_SIZE;
            delete nonFungibleTokenDatas[asset][tokenId];

            uint tokenIndex = nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex[tokenIndex] = nonFungibleInventory.tokensIndex[nonFungibleInventory.tokensIndex.length - 1];
            nonFungibleInventory.tokens[nonFungibleInventory.tokensIndex[tokenIndex]] = tokenIndex;

            delete nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex.pop();
        }
        else 
        {
            InventorySpaceData storage inventorySpace = playerInventories[player];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventorySpaceData storage nonFungibleInventory = inventorySpace.nonFungible[asset];

            // Check if token is owned by player
            if (nonFungibleTokenData.owner != player)
            {
                revert TokenNotOwnedByAccount(
                    player, asset, tokenId);
            }

            // Check if token is in backpack
            if (nonFungibleTokenData.inventory != Inventory.Backpack)
            {
                revert InventoryItemNotFound(
                    player, inventory, asset, tokenId);
            }

            // Deduct from backpack
            inventorySpace.weight -= INVENTORY_SLOT_SIZE;
            delete nonFungibleTokenDatas[asset][tokenId];
            
            uint tokenIndex = nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex[tokenIndex] = nonFungibleInventory.tokensIndex[nonFungibleInventory.tokensIndex.length - 1];
            nonFungibleInventory.tokens[nonFungibleInventory.tokensIndex[tokenIndex]] = tokenIndex;

            delete nonFungibleInventory.tokens[tokenId];
            nonFungibleInventory.tokensIndex.pop();
        }

        // Send to treasury
        if (sendToTreasury)
        {
            try IERC721(asset).transferFrom(address(this), treasury, tokenId) {}
            catch 
            {
                revert InventoryWithdrawFailed(
                    treasury, inventory, asset, 1, tokenId);
            }
        }
        
        // Emit
        emit InventoryDeduct(player, inventory, asset, 1, tokenId);
    }


    /// @dev Ensures that the inventory does not exceed the maximum weight
    /// @notice If the inventory exceeds the maximum weight an {Type}InventoryTooHeavy error is raised 
    ///         and if the inventory is not supported an InventoryUnsupported error is raised
    /// @param player The player to check
    /// @param inventory The inventory to check
    function _ensureInventoryWithinLimit(address player, Inventory inventory)
        internal view
    {
        if (inventory == Inventory.Backpack)
        {
            _ensurePlayerInventoryWithinLimit(player);
        }
        else if (inventory == Inventory.Ship)
        {
            _ensureShipInventoryWithinLimit(playerToShip[player]);
        }
        else 
        {
            revert InventoryUnsupported(inventory);
        }
    }


    /// @dev Ensures that the player's inventory does not exceed the maximum weight
    /// @notice If the player's inventory exceeds the maximum weight a PlayerInventoryTooHeavy error is raised
    /// @param player The player to check
    function _ensurePlayerInventoryWithinLimit(address player)
        internal view
    {
        if (playerInventories[player].weight > playerInventories[player].maxWeight)
        {
            revert PlayerInventoryTooHeavy(player);
        }
    }


    /// @dev Ensures that the ship's inventory does not exceed the maximum weight
    /// @notice If the ship's inventory exceeds the maximum weight a ShipInventoryTooHeavy error is raised
    /// @param ship The tokenId of the ship to check
    function _ensureShipInventoryWithinLimit(uint ship)
        internal view
    {
        if (shipInventories[ship].weight > shipInventories[ship].maxWeight)
        {
            revert ShipInventoryTooHeavy(ship);
        }
    }
}