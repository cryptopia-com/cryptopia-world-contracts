// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/InventoryEnums.sol";

/// @title Cryptopia Inventories
/// @dev Contains player and ship assets
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IInventories {

    /**
     * Public functions
     */
    /// @dev Retrieves info about 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @return weight The current total weight of player's inventory
    /// @return maxWeight The maximum weight of the player's inventory
    function getPlayerInventoryInfo(address player) 
        external view
        returns (uint weight, uint maxWeight);


    /// @dev Retrieves the contents from 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @return weight The current total weight of player's inventory
    /// @return maxWeight The maximum weight of the player's inventory
    /// @return fungible_asset Contract addresses of fungible assets
    /// @return fungible_amount Amounts of fungible tokens
    /// @return nonFungible_asset Contract addresses of non-fungible assets
    /// @return nonFungible_tokenIds Token Ids of non-fungible assets
    function getPlayerInventory(address player) 
        external view 
        returns (
            uint weight,
            uint maxWeight,
            address[] memory fungible_asset, 
            uint[] memory fungible_amount, 
            address[] memory nonFungible_asset, 
            uint[][] memory nonFungible_tokenIds);

    
    /// @dev Retrieves the amount of 'asset' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of fungible assets
    /// @return uint Amount of fungible tokens
    function getPlayerBalanceFungible(address player, address asset) 
        external view 
        returns (uint);


    /// @dev Retrieves the amount of 'asset' 'tokenIds' in 'player' inventory 
    /// @param player The account of the player to retrieve the info for
    /// @param asset Contract addres of non-fungible assets
    /// @return uint Amount of non-fungible tokens
    function getPlayerBalanceNonFungible(address player, address asset) 
        external view 
        returns (uint);


    /// @dev Retrieves info about 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @return weight The current total weight of ship's inventory
    /// @return maxWeight The maximum weight of the ship's inventory
    function getShipInventoryInfo(uint ship) 
        external view 
        returns (uint weight, uint maxWeight);


    /// @dev Retrieves the contents from 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @return weight The current total weight of ship's inventory
    /// @return maxWeight The maximum weight of the ship's inventory
    /// @return fungible_asset Contract addresses of fungible assets
    /// @return fungible_amount Amounts of fungible tokens
    /// @return nonFungible_asset Contract addresses of non-fungible assets
    /// @return nonFungible_tokenIds Token Ids of non-fungible assets
    function getShipInventory(uint ship) 
        external view 
        returns (
            uint weight,
            uint maxWeight,
            address[] memory fungible_asset, 
            uint[] memory fungible_amount, 
            address[] memory nonFungible_asset, 
            uint[][] memory nonFungible_tokenIds);


    /// @dev Retrieves the amount of 'asset' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of fungible assets
    /// @return uint Amount of fungible tokens
    function getShipBalanceFungible(uint ship, address asset) 
        external view 
        returns (uint);


    /// @dev Retrieves the 'asset' 'tokenIds' in 'ship' inventory 
    /// @param ship The tokenId of the ship 
    /// @param asset Contract addres of non-fungible assets
    /// @return uint Amount of non-fungible tokens
    function getShipBalanceNonFungible(uint ship, address asset) 
        external view 
        returns (uint);


    /// @dev Returns non-fungible token data for `tokenId` of `asset`
    /// @param asset the contract address of the non-fungible asset
    /// @param tokenId the token ID to retrieve data about
    /// @return owner the account (player) that owns the token in the inventory
    /// @return inventory {Inventory} the inventory space where the token is stored 
    function getNonFungibleTokenData(address asset, uint tokenId)
        external view 
        returns (
            address owner, 
            Inventory inventory);


    /// @dev Transfer `asset` from 'inventory_from' to `inventory_to`
    /// @param player_to The receiving player (can be msg.sender)
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to transfer (zero indicates non-fungible)
    /// @param tokenIds The token ID to transfer (zero indicates fungible)
    function transfer(address[] memory player_to, Inventory[] memory inventory_from, Inventory[] memory inventory_to, address[] memory asset, uint[] memory amount, uint[][] memory tokenIds)
        external;

    
    /**
     * System functions
     */
    /// @dev Update equipted ship for `player`
    /// @param player The player that equipted the `ship`
    /// @param ship The tokenId of the equipted ship
    function __setPlayerShip(address player, uint ship) 
        external;


    /// @dev Update a ships inventory max weight
    /// - Fails if the ships weight exeeds the new max weight
    /// @param ship The tokenId of the ship to update
    /// @param maxWeight The new max weight of the ship
    function __setShipInventory(uint ship, uint maxWeight)
        external;


    /// @dev Update a player's personal inventories 
    /// @param player The player of whom we're updateing the inventories
    /// @param maxWeight_backpack The new max weight of the player's backpack
    function __setPlayerInventory(address player, uint maxWeight_backpack)
        external;


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
        external;

    
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
        external;


    /// @dev Assigns `tokenIds` from `asset` to the `inventory` of `player`
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
        external;

    
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
    /// @param amount The amounts of assets to assign
    /// @param tokenId The token ids from asset to assign
    function __assign(address player, Inventory[] memory inventory, address[] memory asset, uint[] memory amount, uint[] memory tokenId)
        external;


    /// @dev Deducts `amount` of `asset` from the `inventory` of `player` 
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// - Assumes amount of asset is allocated to player
    /// @param player The inventory owner to deduct the asset from
    /// @param inventory The inventory type to deduct the asset from {BackPack | Ship}
    /// @param asset The asset contract address 
    /// @param amount The amount of asset to deduct
    function __deductFungibleToken(address player, Inventory inventory, address asset, uint amount)
        external;


    /// @dev Deducts fungible and non-fungible tokens in a single transaction
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// @param player The inventory owner to deduct the assets from
    /// @param inventory The inventory type to deduct the assets from {BackPack | Ship}
    /// @param asset The asset contract addresses 
    /// @param amount The amounts of assets to deduct
    function __deduct(address player, Inventory inventory, address[] memory asset, uint[] memory amount)
        external;


    /// @dev Transfers `asset` from `player_from` to `player_to`
    /// SYSTEM caller is trusted so checks can be omitted
    /// - Assumes inventory exists
    /// - Assumes asset exists
    /// @param player_from The sending player
    /// @param player_to The receiving player
    /// @param inventory_from Origin {Inventories}
    /// @param inventory_to Destination {Inventories} 
    /// @param asset The address of the ERC20 or ERC721 contract
    /// @param amount The amount of fungible tokens to transfer (zero indicates non-fungible)
    /// @param tokenId The token ID to transfer (zero indicates fungible)
    function __transfer(address player_from, address player_to, Inventory[] memory inventory_from, Inventory[] memory inventory_to, address[] memory asset, uint[] memory amount, uint[] memory tokenId)
        external;
}