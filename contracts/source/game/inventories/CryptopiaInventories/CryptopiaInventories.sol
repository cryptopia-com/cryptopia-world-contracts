// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1820RegistryUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./ICryptopiaInventories.sol";
import "../InventoryEnums.sol";
import "../../players/CryptopiaPlayerRegister/ICryptopiaPlayerRegister.sol";

/// @title Cryptopia Inventories
/// @dev Contains player and ship assets
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaInventories is ICryptopiaInventories, Initializable, AccessControlUpgradeable, IERC777RecipientUpgradeable, IERC721ReceiverUpgradeable {

    struct Asset 
    {
        uint index;

        // Unit weight
        uint weight;
    }

    struct Inventory 
    {
        // Combined weight (fungible + non-fungible)
        uint weight;

        // Maximum combined weight (including module effects etc.)
        uint maxWeight;

        // Asset => amount
        mapping (address => uint) fungible;

        // Asset => NonFungibleTokenInventory
        mapping (address => NonFungibleTokenInventory) nonFungible;
    }

    struct NonFungibleTokenInventory
    {
        // TokenId => index
        mapping (uint => uint) tokens;
        uint[] tokensIndex;
    }

    struct NonFungibleTokenData
    {
        // Allocated for owner
        address owner;

        // The inventory in which this token is stored
        InventoryEnums.Inventories inventory;
    }


    /**
     * Roles
     */
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    address constant private ERC1820_ADDRESS = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    bytes32 constant private ERC777_RECIPIENT_INTERFACE = keccak256("ERC777TokensRecipient");

    // One slot 10kg
    uint constant public INVENTORY_SLOT_SIZE = 1_000_000_000_000_000_000_000; 

    // contract => Asset
    mapping (address => Asset) fungible; 
    address[] fungibleIndex;

    // contract => Asset
    mapping (address => Asset) nonFungible; 
    address[] nonFungibleIndex;

    // Player => Equipted ship 
    mapping (address => uint) playerToShip;

    // Asset => tokenId => NonFungibleTokenData
    mapping (address => mapping (uint => NonFungibleTokenData)) nonFungibleTokenDatas;

    // Ship tokenId => Inventory
    mapping (uint => Inventory) shipInventories;

    // Player => Starter ship | Backpack => Inventory
    mapping (address => Inventory) playerInventories;

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
    /// @param asset The address of the ERC20, ERC777 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenId The token ID to send (zero indicates fungible)
    event InventoryAssign(address indexed player, InventoryEnums.Inventories inventory, address indexed asset, uint amount, uint tokenId);

    /// @dev Deduct `asset` internally from `inventory` to treasury
    /// @param player The owener of the asset
    /// @param inventory Deducted from inventory {Inventories} 
    /// @param asset The address of the ERC20, ERC777 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenId The token ID to send (zero indicates fungible)
    event InventoryDeduct(address indexed player, InventoryEnums.Inventories inventory, address indexed asset, uint amount, uint tokenId);

    /// @dev Transfer `asset` internally from 'inventory_from' to `inventory_to`
    /// @param player_from The sender (owner) of the asset
    /// @param player_to The receiver of the asset (can be the same as player_from)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20, ERC777 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenId The token ID to send (zero indicates fungible)
    event InventoryTransfer(address indexed player_from, address indexed player_to, InventoryEnums.Inventories inventory_from, InventoryEnums.Inventories inventory_to, address indexed asset, uint amount, uint tokenId);


    /**
     * Admin functions
     */
    /// @dev Construct
    /// @param _treasury token (ERC777) receiver
    function initialize(
        address _treasury) 
        public initializer 
    {
        __AccessControl_init();

        // Refs
        treasury = _treasury;

        // Register as ERC777 recipient
        IERC1820RegistryUpgradeable(ERC1820_ADDRESS).setInterfaceImplementer(
            address(this), ERC777_RECIPIENT_INTERFACE, address(this));

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @dev Set the `weight` for the fungible `asset` (zero invalidates the asset)
    /// @param asset The asset contract address
    /// @param weight The asset unit weight (kg/100)
    function setFungibleAsset(address asset, uint weight)
        public virtual override  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        fungible[asset].weight = weight;
        if (0 == fungibleIndex.length || fungibleIndex[fungible[asset].index] != asset)
        {
            fungibleIndex.push(asset);
            fungible[asset].index = fungibleIndex.length - 1;
        }
    }

    
    /// @dev Set the `weight` for the non-fungible `asset` (zero invalidates the asset)
    /// @param asset The asset contract address
    /// @param accepted If true the inventory will accept the NFT asset
    function setNonFungibleAsset(address asset, bool accepted)
        public virtual override  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        nonFungible[asset].weight = accepted ? INVENTORY_SLOT_SIZE : 0;
        if (0 == nonFungibleIndex.length || nonFungibleIndex[nonFungible[asset].index] != asset)
        {
            nonFungibleIndex.push(asset);
            nonFungible[asset].index = nonFungibleIndex.length - 1;
        }
    }


    /// @dev Update equipted ship for `player`
    /// @param player The player that equipted the `ship`
    /// @param ship The tokenId of the equipted ship
    function setPlayerShip(address player, uint ship) 
        public virtual override  
        onlyRole(SYSTEM_ROLE) 
    {
        playerToShip[player] = ship;
    }


    /// @dev Update a ships inventory max weight
    /// - Fails if the ships weight exeeds the new max weight
    /// @param ship The tokenId of the ship to update
    /// @param maxWeight The new max weight of the ship
    function setShipInventory(uint ship, uint maxWeight)
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
    {
        if (shipInventories[ship].maxWeight == maxWeight)
        {
            return;
        }

        // Update
        require(shipInventories[ship].weight <= maxWeight, "CryptopiaInventories: Ship too heavy");
        shipInventories[ship].maxWeight = maxWeight;

        // Emit 
        emit ShipInventoryChange(ship, maxWeight);
    }


    /// @dev Update a player's personal inventories 
    /// @param player The player of whom we're updateing the inventories
    /// @param maxWeight The new max weight of the player's backpack
    function setPlayerInventory(address player, uint maxWeight)
        public virtual override  
        onlyRole(SYSTEM_ROLE) 
    {
        if (playerInventories[player].maxWeight == maxWeight)
        {
            return;
        }

        // Update
        require(playerInventories[player].weight <= maxWeight, "CryptopiaInventories: Backpack too heavy");
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
    function assignFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint amount)
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
    function assignNonFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint tokenId)
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
    function assignNonFungibleTokens(address player, InventoryEnums.Inventories inventory, address asset, uint[] memory tokenIds)
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
    /// @param tokenIds The token ids from asset to assign
    function assign(address[] memory player, InventoryEnums.Inventories[] memory inventory, address[] memory asset, uint[] memory amount, uint[][] memory tokenIds)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    { 
        for (uint i = 0; i < player.length; i++)
        {
            if (0 != amount[i])
            {
                // Fungible
                _assignFungibleToken(
                    player[i], inventory[i], asset[i], amount[i]);
            }
            else 
            {
                // Non-Fungible
                for (uint j = 0; j < tokenIds[i].length; j++)
                {
                    _assignNonFungibleToken(
                        player[i], inventory[i], asset[i], tokenIds[i][j]);
                } 
            }   
        }
    }


    /// @dev Deducts `amount` of `asset` from the `inventory` of `player` 
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {Backpack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to deduct
    function deductFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint amount)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        _deductFungibleToken(player, inventory, asset, amount);
    }


    /// @dev Deducts fungible and non-fungible tokens in a single transaction
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// @param player The inventory owner to deduct the assets from
    /// @param inventory The inventory type to deduct the assets from {BackPack | Ship}
    /// @param asset The asset contract addresses 
    /// @param amount The amounts of assets to deduct
    function deduct(address player, InventoryEnums.Inventories inventory, address[] memory asset, uint[] memory amount)
        public virtual override 
        onlyRole(SYSTEM_ROLE)
    {
        for (uint i = 0; i < asset.length; i++)
        {
            _deductFungibleToken(player, inventory, asset[i], amount[i]);
        }
    }


    /**
     * Public functions
     */
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
    /// @return weight The current total weight of player's inventory
    /// @return maxWeight The maximum weight of the player's inventory
    /// @return fungible_asset Contract addresses of fungible assets
    /// @return fungible_amount Amounts of fungible tokens
    /// @return nonFungible_asset Contract addresses of non-fungible assets
    /// @return nonFungible_tokenIds Token Ids of non-fungible assets
    function getPlayerInventory(address player) 
        public virtual override view 
        returns (
            uint weight,
            uint maxWeight,
            address[] memory fungible_asset, 
            uint[] memory fungible_amount, 
            address[] memory nonFungible_asset, 
            uint[][] memory nonFungible_tokenIds)
    {
        Inventory storage inventory = playerInventories[player];
        weight = inventory.weight;
        maxWeight = inventory.maxWeight;
        fungible_amount = new uint[](fungibleIndex.length);
        nonFungible_tokenIds = new uint[][](nonFungibleIndex.length);
        
        // Fungible
        fungible_asset = fungibleIndex;
        for (uint i = 0; i < fungibleIndex.length; i++)
        {
            fungible_amount[i] = inventory.fungible[fungible_asset[i]];
        }

        // Non-fungible
        nonFungible_asset = nonFungibleIndex;
        for (uint i = 0; i < nonFungibleIndex.length; i++)
        {
            nonFungible_tokenIds[i] = inventory.nonFungible[nonFungible_asset[i]].tokensIndex;
        }
    }


    /// @dev Retrieves the amount of 'asset' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of fungible assets
    /// @return uint Amount of fungible tokens
    function getPlayerBalanceFungible(address player, address asset) 
        public virtual override view 
        returns (uint)
    {
        return playerInventories[player].fungible[asset];
    }


    /// @dev Retrieves the 'asset' 'tokenIds' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of non-fungible assets
    /// @return uint Amount of non-fungible tokens
    function getPlayerBalanceNonFungible(address player, address asset) 
        public virtual override view 
        returns (uint)
    {
        return playerInventories[player].nonFungible[asset].tokensIndex.length;
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
    /// @return weight The current total weight of ship's inventory
    /// @return maxWeight The maximum weight of the ship's inventory
    /// @return fungible_asset Contract addresses of fungible assets
    /// @return fungible_amount Amounts of fungible tokens
    /// @return nonFungible_asset Contract addresses of non-fungible assets
    /// @return nonFungible_tokenIds Token Ids of non-fungible assets
    function getShipInventory(uint ship) 
        public virtual override view 
        returns (
            uint weight,
            uint maxWeight,
            address[] memory fungible_asset, 
            uint[] memory fungible_amount, 
            address[] memory nonFungible_asset, 
            uint[][] memory nonFungible_tokenIds)
    {
        Inventory storage inventory = shipInventories[ship];
        weight = inventory.weight;
        maxWeight = inventory.maxWeight;
        fungible_amount = new uint[](fungibleIndex.length);
        nonFungible_tokenIds = new uint[][](nonFungibleIndex.length);
        
        // Fungible
        fungible_asset = fungibleIndex;
        for (uint i = 0; i < fungibleIndex.length; i++)
        {
            fungible_amount[i] = inventory.fungible[fungible_asset[i]];
        }

        // Non-fungible
        nonFungible_asset = nonFungibleIndex;
        for (uint i = 0; i < nonFungibleIndex.length; i++)
        {
            nonFungible_tokenIds[i] = inventory.nonFungible[nonFungible_asset[i]].tokensIndex;
        }
    }


    /// @dev Retrieves the amount of 'asset' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of fungible assets
    /// @return uint Amount of fungible tokens
    function getShipBalanceFungible(uint ship, address asset) 
        public virtual override view 
        returns (uint)
    {
        return shipInventories[ship].fungible[asset];
    }


    /// @dev Retrieves the 'asset' 'tokenIds' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of non-fungible assets
    /// @return uint Amount of non-fungible tokens
    function getShipBalanceNonFungible(uint ship, address asset) 
        public virtual override view 
        returns (uint)
    {
        return shipInventories[ship].nonFungible[asset].tokensIndex.length;
    }


    /// @dev Returns non-fungible token data for `tokenId` of `asset`
    /// @param asset the contract address of the non-fungible asset
    /// @param tokenId the token ID to retrieve data about
    /// @return owner the account (player) that owns the token in the inventory
    /// @return inventory {InventoryEnums.Inventories} the inventory space where the token is stored 
    function getNonFungibleTokenData(address asset, uint tokenId)
        public virtual override view 
        returns (
            address owner, 
            InventoryEnums.Inventories inventory
        )
    {
        owner = nonFungibleTokenDatas[asset][tokenId].owner;
        inventory = nonFungibleTokenDatas[asset][tokenId].inventory;
    }


    /// @dev Transfer `asset` from 'inventory_from' to `inventory_to`
    /// @param player_to The receiving player (can be _msgSender())
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20, ERC777 or ERC721 contract
    /// @param amount The amount of fungible tokens to send (zero indicates non-fungible)
    /// @param tokenIds The token ID to send (zero indicates fungible)
    function transfer(address[] memory player_to, InventoryEnums.Inventories[] memory inventory_from, InventoryEnums.Inventories[] memory inventory_to, address[] memory asset, uint[] memory amount, uint[][] memory tokenIds)
        public virtual override 
    {
        address player_from = _msgSender();
        for (uint i = 0; i < player_to.length; i++)
        {
            if (0 != amount[i])
            {
                // Fungible
                _transferFungible(
                    player_from, player_to[i], inventory_from[i], inventory_to[i], asset[i], amount[i]);
            }
            else if (0 != tokenIds[i].length)
            {
                for (uint j = 0; j < tokenIds[i].length; j++)
                {
                    // Non-Fungible
                    _transferNonFungible(
                        player_from, player_to[i], inventory_from[i], inventory_to[i], asset[i], tokenIds[i][j]);
                }
            }
            else 
            {
                // Amount and token id zero
                revert("CryptopiaInventories: Missing amount or tokenId");
            }
        }
    }


     /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) public virtual override 
    {
        // Nothing for now
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
     * Internal functions
     */
    /// @dev Transfer fungible `asset` from 'inventory_from' to `inventory_to`
    /// @param player_from Owner of the asset
    /// @param player_to The receiver of the asset (can be the same as player_from)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC777 contract
    /// @param amount The amount of fungible tokens to send 
    function _transferFungible(address player_from, address player_to, InventoryEnums.Inventories inventory_from, InventoryEnums.Inventories inventory_to, address asset, uint amount) 
        internal 
    {
        uint weight = fungible[asset].weight * amount;
        require(weight > 0, "CryptopiaInventories: Unsupported fungible asset");

        // Substract
        if (inventory_from == InventoryEnums.Inventories.Wallet)
        {
            // Deposit from wallet
            require(
                IERC20Upgradeable(asset)
                    .transferFrom(player_from, address(this), amount), 
                "CryptopiaInventories: Deposit failed (ERC20)"
            );
        }
        else if (inventory_from == InventoryEnums.Inventories.Backpack)
        {
            Inventory storage inventory = playerInventories[player_from];
            require(inventory.fungible[asset] >= amount, "CryptopiaInventories: Insufficient balance (ERC20) in backpack");

            // Deduct from backpack
            inventory.weight -= weight;
            inventory.fungible[asset] -= amount;
        }
        else if (inventory_from == InventoryEnums.Inventories.Ship)
        {
            Inventory storage inventory = shipInventories[playerToShip[player_from]];
            require(inventory.fungible[asset] >= amount, "CryptopiaInventories: Insufficient balance (ERC20) in ship");

            // Deduct from ship
            inventory.weight -= weight;
            inventory.fungible[asset] -= amount;
        }
        else 
        {
            revert("CryptopiaInventories: Unknown from inventory");
        }

        // Add
        if (inventory_to == InventoryEnums.Inventories.Wallet)
        {
            // Withdraw externally
            require(
                IERC20Upgradeable(asset)
                    .transferFrom(address(this), player_to, amount), 
                "CryptopiaInventories: Withdraw failed (ERC20)"
            );
        }
        else if (inventory_to == InventoryEnums.Inventories.Backpack) 
        {
            Inventory storage inventory = playerInventories[player_to];
            require(inventory.weight + weight <= inventory.maxWeight, "CryptopiaInventories: Backpack too heavy");

            // Add to backpack
            inventory.weight += weight;
            inventory.fungible[asset] += amount;
        }
        else if (inventory_to == InventoryEnums.Inventories.Ship)
        {
            Inventory storage inventory = shipInventories[playerToShip[player_to]];
            require(inventory.weight + weight <= inventory.maxWeight, "CryptopiaInventories: Ship too heavy");

            // Add to ship
            inventory.weight += weight;
            inventory.fungible[asset] += amount;
        }
        else 
        {
            revert("CryptopiaInventories: Unknown to inventory");
        }

        // Emit
        emit InventoryTransfer(player_from, player_to, inventory_from, inventory_to, asset, amount, 0);
    }

    /// @dev Transfer non-fungible `asset` from 'inventory_from' to `inventory_to`
    /// @param player_from Owner of the asset
    /// @param player_to The receiver of the asset (can be the same as player_from)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC777 contract
    /// @param tokenId The token to transfer
    function _transferNonFungible(address player_from, address player_to, InventoryEnums.Inventories inventory_from, InventoryEnums.Inventories inventory_to, address asset, uint tokenId) 
        internal 
    {
        // Only supported 
        require(nonFungible[asset].weight > 0, "CryptopiaInventories: Unsupported non-fungible asset");

        // Substract
        if (inventory_from == InventoryEnums.Inventories.Wallet)
        {
            // Deposit from wallet
            IERC721Upgradeable(asset).transferFrom(
                player_from, address(this), tokenId);
        }
        else if (inventory_from == InventoryEnums.Inventories.Backpack)
        {
            Inventory storage inventory = playerInventories[player_from];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventory storage nonFungibleInventory = inventory.nonFungible[asset];

            require(nonFungibleTokenData.owner == player_from, "CryptopiaInventories: Token (ERC721) does not belong to player");
            require(nonFungibleTokenData.inventory == InventoryEnums.Inventories.Backpack, "CryptopiaInventories: Token (ERC721) is not stored in backpack");

            // Deduct from backpack
            inventory.weight -= INVENTORY_SLOT_SIZE;
            nonFungibleTokenData.owner = address(0);
            nonFungibleInventory.tokensIndex[nonFungibleInventory.tokens[tokenId]] = nonFungibleInventory.tokensIndex[nonFungibleInventory.tokensIndex.length - 1];
            nonFungibleInventory.tokensIndex.pop();
        }
        else if (inventory_from == InventoryEnums.Inventories.Ship)
        {
            Inventory storage inventory = shipInventories[playerToShip[player_from]];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventory storage nonFungibleInventory = inventory.nonFungible[asset];

            require(nonFungibleTokenData.owner == player_from, "CryptopiaInventories: Token (ERC721) does not belong to player");
            require(nonFungibleTokenData.inventory == InventoryEnums.Inventories.Ship, "CryptopiaInventories: Token (ERC721) is not stored in ship");

            // Deduct from ship
            inventory.weight -= INVENTORY_SLOT_SIZE;
            nonFungibleTokenData.owner = address(0);
            nonFungibleInventory.tokensIndex[nonFungibleInventory.tokens[tokenId]] = nonFungibleInventory.tokensIndex[nonFungibleInventory.tokensIndex.length - 1];
            nonFungibleInventory.tokensIndex.pop();
        }
        else 
        {
            revert("CryptopiaInventories: Unknown from inventory");
        }

        // Add
        if (inventory_to == InventoryEnums.Inventories.Wallet)
        {
            // Withdraw externally
            IERC721Upgradeable(asset)
                .transferFrom(address(this), player_to, tokenId);
        }
        else if (inventory_to == InventoryEnums.Inventories.Backpack) 
        {
            Inventory storage inventory = playerInventories[player_from];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventory storage nonFungibleInventory = inventory.nonFungible[asset];

            require(
                inventory.weight + INVENTORY_SLOT_SIZE <= inventory.maxWeight, 
                "CryptopiaInventories: Backpack too heavy"
            );

            // Add to backpack
            inventory.weight += INVENTORY_SLOT_SIZE;
            nonFungibleTokenData.owner = player_to;
            nonFungibleTokenData.inventory = InventoryEnums.Inventories.Backpack;
            nonFungibleInventory.tokensIndex.push(tokenId);
            nonFungibleInventory.tokens[tokenId] = nonFungibleInventory.tokensIndex.length - 1;
        }
        else if (inventory_to == InventoryEnums.Inventories.Ship)
        {
            Inventory storage inventory = shipInventories[playerToShip[player_to]];
            NonFungibleTokenData storage nonFungibleTokenData = nonFungibleTokenDatas[asset][tokenId];
            NonFungibleTokenInventory storage nonFungibleInventory = inventory.nonFungible[asset];

            require(
                inventory.weight + INVENTORY_SLOT_SIZE <= inventory.maxWeight, 
                "CryptopiaInventories: Ship too heavy"
            );

            // Add to ship
            inventory.weight += INVENTORY_SLOT_SIZE;
            nonFungibleTokenData.owner = player_to;
            nonFungibleTokenData.inventory = InventoryEnums.Inventories.Ship;
            nonFungibleInventory.tokensIndex.push(tokenId);
            nonFungibleInventory.tokens[tokenId] = nonFungibleInventory.tokensIndex.length - 1;
        }
        else 
        {
            revert("CryptopiaInventories: Unknown to inventory");
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
    function _assignFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint amount)
        internal 
    {
        // SYSTEM caller > Assume asset exists
        uint weight = fungible[asset].weight * amount; 

        // SYSTEM caller > Assume inventory exists
        if (inventory == InventoryEnums.Inventories.Ship) 
        {
            Inventory storage shipInventory = shipInventories[playerToShip[player]];
            require(shipInventory.weight + weight <= shipInventory.maxWeight, "CryptopiaInventories: Ship too heavy");

            // Add to ship
            shipInventory.weight += weight;
            shipInventory.fungible[asset] += amount;
        }
        else 
        {
            Inventory storage backpackInventory = playerInventories[player];
            require(backpackInventory.weight + weight <= backpackInventory.maxWeight, "CryptopiaInventories: Backpack too heavy");

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
    function _assignNonFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint tokenId)
        internal 
    {
        // SYSTEM caller > Assume inventory exists
        if (inventory == InventoryEnums.Inventories.Ship) 
        {
            Inventory storage shipInventory = shipInventories[playerToShip[player]];
            require(shipInventory.weight + INVENTORY_SLOT_SIZE <= shipInventory.maxWeight, "CryptopiaInventories: Ship too heavy");

            // Add to ship
            shipInventory.weight += INVENTORY_SLOT_SIZE;
            shipInventory.nonFungible[asset].tokensIndex.push(tokenId);
            shipInventory.nonFungible[asset].tokens[tokenId] = shipInventory.nonFungible[asset].tokensIndex.length - 1;
        }
        else 
        {
            Inventory storage backpackInventory = playerInventories[player];
            require(backpackInventory.weight + INVENTORY_SLOT_SIZE <= backpackInventory.maxWeight, "CryptopiaInventories: Backpack too heavy");

            // Add to backpack
            backpackInventory.weight += INVENTORY_SLOT_SIZE;
            backpackInventory.nonFungible[asset].tokensIndex.push(tokenId);
            backpackInventory.nonFungible[asset].tokens[tokenId] = backpackInventory.nonFungible[asset].tokensIndex.length - 1;
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
    function _deductFungibleToken(address player, InventoryEnums.Inventories inventory, address asset, uint amount)
        internal 
    {
        // SYSTEM caller > Assume asset exists
        uint weight = fungible[asset].weight * amount; 

        // SYSTEM caller > Assume inventory exists
        if (inventory == InventoryEnums.Inventories.Ship) 
        {
            Inventory storage shipInventory = shipInventories[playerToShip[player]];
            require(shipInventory.fungible[asset] >= amount, "CryptopiaInventories: Insufficient asset amount");

            // Deduct from ship
            shipInventory.weight -= weight;
            shipInventory.fungible[asset] -= amount;
        }
        else 
        {
            Inventory storage backpackInventory = playerInventories[player];
            require(backpackInventory.fungible[asset] >= amount, "CryptopiaInventories: Insufficient asset amount");

            // Deduct from backpack
            backpackInventory.weight -= weight;
            backpackInventory.fungible[asset] -= amount;
        }

        // Send to treasury
        require(
            IERC20Upgradeable(asset)
                .transferFrom(address(this), treasury, amount), 
            "CryptopiaInventories: Withdraw failed (ERC20)"
        );

        // Emit
        emit InventoryDeduct(player, inventory, asset, amount, 0);
    }
}