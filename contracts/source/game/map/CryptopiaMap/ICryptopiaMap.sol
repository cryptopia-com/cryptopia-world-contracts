// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../assets/AssetEnums.sol";

/// @title Cryptopia Maps
/// @dev Responsible for world data and player movement
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaMap {

    /// @dev Retreives the amount of maps created
    /// @return count Number of maps created
    function getMapCount() 
        external view 
        returns (uint count);


    /// @dev Retreives the map at `index`
    /// @param index Map index (not mapping key)
    /// @return initialized True if the map is created
    /// @return finalized True if all tiles are added and the map is immutable
    /// @return sizeX Number of tiles in the x direction
    /// @return sizeZ Number of tiles in the z direction
    /// @return tileStartIndex The index of the first tile in the map (mapping key)
    /// @return name Unique name of the map
    function getMapAt(uint256 index) 
        external view 
        returns (
            bool initialized, 
            bool finalized, 
            uint32 sizeX, 
            uint32 sizeZ, 
            uint32 tileStartIndex,
            bytes32 name
        );

    
    /// @dev Retrieve a tile
    /// @param tileIndex Index of hte tile to retrieve
    /// @return terrainPrimaryIndex Primary texture used to paint tile
    /// @return terrainSecondaryIndex Secondary texture used to paint tile
    /// @return terrainBlendFactor Blend factor for primary and secondary textures
    /// @return terrainOrientation Orientation in degrees for texture
    /// @return terrainElevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return elevation Tile elevation actual elevation used in navigation (underwater and >= waterlevel indicates seasteading)
    /// @return waterLevel Tile water level
    /// @return vegitationLevel Level of vegitation on tile
    /// @return rockLevel Level of rocks on tile
    /// @return incommingRiverData River data
    /// @return outgoingRiverData River data
    /// @return roadFlags Road data
    function getTile(uint32 tileIndex) 
        external view 
        returns (
            uint8 terrainPrimaryIndex,
            uint8 terrainSecondaryIndex,
            uint8 terrainBlendFactor,
            uint8 terrainOrientation,
            uint8 terrainElevation,
            uint8 elevation,
            uint8 waterLevel,
            uint8 vegitationLevel,
            uint8 rockLevel,
            uint8 incommingRiverData,
            uint8 outgoingRiverData,
            uint8 roadFlags
        );


    /// @dev Retrieve a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return terrainPrimaryIndex Primary texture used to paint tile
    /// @return terrainSecondaryIndex Secondary texture used to paint tile
    /// @return terrainBlendFactor Blend factor for primary and secondary textures
    /// @return terrainOrientation Orientation in degrees for texture
    /// @return terrainElevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return elevation Tile elevation actual elevation used in navigation (underwater and >= waterlevel indicates seasteading)
    /// @return waterLevel Tile water level
    /// @return vegitationLevel Level of vegitation on tile
    /// @return rockLevel Level of rocks on tile
    /// @return incommingRiverData River data
    /// @return outgoingRiverData River data
    /// @return roadFlags Road data
    function getTiles(uint32 skip, uint32 take) 
        external view 
        returns (
            uint8[] memory terrainPrimaryIndex,
            uint8[] memory terrainSecondaryIndex,
            uint8[] memory terrainBlendFactor,
            uint8[] memory terrainOrientation,
            uint8[] memory terrainElevation,
            uint8[] memory elevation,
            uint8[] memory waterLevel,
            uint8[] memory vegitationLevel,
            uint8[] memory rockLevel,
            uint8[] memory incommingRiverData,
            uint8[] memory outgoingRiverData,
            uint8[] memory roadFlags
        );

    
    /// @dev Retrieve static data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return wildlife_creature Type of wildlife that the tile contains
    /// @return wildlife_initialLevel The level of wildlife that the tile contained initially
    /// @return resource1_asset A type of asset that the tile contains
    /// @return resource2_asset A type of asset that the tile contains
    /// @return resource3_asset A type of asset that the tile contains
    /// @return resource1_initialAmount The amount of resource1_asset the tile contains
    /// @return resource2_initialAmount The amount of resource2_asset the tile contains
    /// @return resource3_initialAmount The amount of resource3_asset the tile contains
    function getTileDataStatic(uint32 skip, uint32 take) 
        external view 
        returns (
            bytes32[] memory wildlife_creature,
            uint128[] memory wildlife_initialLevel,
            address[] memory resource1_asset,
            address[] memory resource2_asset,
            address[] memory resource3_asset,
            uint[] memory resource1_initialAmount,
            uint[] memory resource2_initialAmount,
            uint[] memory resource3_initialAmount
        );
    

    /// @dev Retrieve dynamic data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return owner Account that owns the tile
    /// @return player1 Player that last entered the tile
    /// @return player2 Player entered the tile before player1
    /// @return player3 Player entered the tile before player2
    /// @return player4 Player entered the tile before player3
    /// @return player5 Player entered the tile before player4
    /// @return wildlife_level The remaining level of wildlife that the tile contains
    /// @return resource1_amount The remaining amount of resource1_asset that the tile contains
    /// @return resource2_amount The remaining amount of resource2_asset that the tile contains
    /// @return resource3_amount The remaining amount of resource3_asset that the tile contains
    function getTileDataDynamic(uint32 skip, uint32 take) 
        external view 
        returns (
            address[] memory owner,
            address[] memory player1,
            address[] memory player2,
            address[] memory player3,
            address[] memory player4,
            address[] memory player5,
            uint128[] memory wildlife_level,
            uint[] memory resource1_amount,
            uint[] memory resource2_amount,
            uint[] memory resource3_amount
        );


    /// @dev Retrieve players from the tile with tile
    /// @param tileIndex Retrieve players from this tile
    /// @param start Starting point in the chain
    /// @param max Max amount of players to return
    function getPlayers(uint32 tileIndex, address start, uint max)
        external view 
        returns (
            address[] memory players
        );

    
    /// @dev Retrieve data that's attached to players
    /// @param accounts The players to retreive player data for
    /// @return location_mapName The map that the player is at
    /// @return location_tileIndex The tile that the player is at
    /// @return location_arrival The datetime on wich the player arrives at `location_tileIndex`
    /// @return movement Player movement budget
    function getPlayerData(address[] memory accounts)
        external view 
        returns (
            bytes32[] memory location_mapName,
            uint32[] memory location_tileIndex,
            uint[] memory location_arrival,
            uint[] memory movement
        );

    
    /// @dev Returns data about the players ability to interact with wildlife 
    /// @param account Player to retrieve data for
    /// @param creature Type of wildlife to test for
    /// @return canInteract True if `account` can interact with 'creature'
    /// @return difficulty Based of level of wildlife and activity
    function getPlayerWildlifeData(address account, bytes32 creature) 
        external view 
        returns (
            bool canInteract,
            uint difficulty 
        );


    /// @dev Returns data about the players ability to interact with resources 
    /// @param account Player to retrieve data for
    /// @param resource Type of resource to test for
    /// @return resourceLevel the amount of `resource` on the tile where `account` is located
    function getPlayerResourceData(address account, AssetEnums.Resource resource) 
        external view 
        returns (uint resourceLevel);


    /// @dev Find out if a player with `account` has entred 
    /// @param account Player to test against
    /// @return Wether `account` has entered or not
    function playerHasEntered(address account) 
        external view 
        returns (bool);


    /// @dev Player entry point that adds the player to the Genesis map
    function playerEnter()
        external;

    
    /// @dev Moves a player from one tile to another
    /// @param path Tiles that represent a route
    function playerMove(uint32[] memory path)
        external;


    /// @dev Gets the cached movement costs to travel between `fromTileIndex` and `toTileIndex` or zero if no cache exists
    /// @param fromTileIndex Origin tile
    /// @param toTileIndex Destination tile
    /// @return uint Movement costs
    function getPathSegmentFromCache(uint32 fromTileIndex, uint32 toTileIndex)
        external view 
        returns (uint);
}