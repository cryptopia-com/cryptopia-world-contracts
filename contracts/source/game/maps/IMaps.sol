// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/MapEnums.sol";
import "../assets/types/AssetEnums.sol";

/// @title Maps
/// @dev Responsible for world data and player movement
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IMaps {

    /// @dev Retrieve a tile
    /// @param tileIndex Index of hte tile to retrieve
    /// @return landmassIndex The index of the landmass that the tile belongs to
    /// @return biome The type of biome {None, Plains, Grassland, Forest, RainForest, Desert, Tundra, Swamp, Reef}
    /// @return terrain The type of terrain {Flat, Hills, Mountains, Water, Seastead}
    /// @return elevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return waterLevel The water level of the tile
    /// @return vegitationLevel The level of vegitation that the tile contains
    /// @return rockLevel The size of rocks that the tile contains
    /// @return wildlifeLevel The amount of wildlife that the tile contains
    /// @return riverFlags Flags that indicate the presence of a river on the tile's hex edges
    /// @return hasRoad Indicates the presence of a road on the tile
    /// @return hasLake Indicates the presence of a lake on the tile
    function getTile(uint16 tileIndex) 
        external view 
        returns (
            uint16 landmassIndex,
            Biome biome,
            Terrain terrain,
            uint8 elevation,
            uint8 waterLevel,
            uint8 vegitationLevel,
            uint8 rockLevel,
            uint8 wildlifeLevel,
            uint8 riverFlags,
            bool hasRoad,
            bool hasLake);


    /// @dev True if the tile with `tileIndex` is adjacent to `adjecentTileIndex`
    /// @param tileIndex The tile to test against
    /// @param adjecentTileIndex The tile to test with
    /// @return True if the tile with `tileIndex` is adjacent to `adjecentTileIndex`
    function tileIsAdjacentTo(uint16 tileIndex, uint16 adjecentTileIndex) 
        external view 
        returns (bool);


    /// @dev Checks if a tile with `tileIndex` is along the route `route` based on the traveler's progress
    /// @param tileIndex The index of the tile to check
    /// @param route The route data to check against
    /// @param routeIndex The index of the tile in the route data (0 signals origin, setting it equal to totalTilesPacked indicates destination)
    /// @param arrival The datetime on which the traveler arrives at it's destination
    /// @param position The position of the tile relative to the traveler's progress along the route {ANY, UPCOMING, CURRENT, PASSED}
    /// @return True if the tile with `tileIndex` meets the conditions specified by `position`
    function tileIsAlongRoute(uint16 tileIndex, bytes32 route, uint routeIndex, uint16 destination, uint64 arrival, RoutePosition position) 
        external view 
        returns (bool);

    
    /// @dev Retrieve data that's attached to player
    /// @param account The account to retreive player data for
    /// @return tileIndex The tile that the player is at
    /// @return canInteract Wether the player can interact with the tile
    function getPlayerData(address account)
        external view 
        returns (
            uint16 tileIndex,
            bool canInteract);

        
    /// @dev Retrieve travel data for `account`
    /// @param account The account to retreive travel data for
    /// @return isTraveling Wether the player is traveling
    /// @return isEmbarked Wether the player is embarked
    /// @return tileIndex The tile that the player is at or traveling to
    /// @return route The route that the player is traveling
    /// @return arrival The datetime on wich the player arrives at `tileIndex`
    function getPlayerTravelData(address account)
        external view 
        returns (
            bool isTraveling,
            bool isEmbarked,
            uint16 tileIndex,
            bytes32 route,
            uint64 arrival);


    /// @dev Find out if a player with `account` has entred 
    /// @param account Player to test against
    /// @return Wether `account` has entered or not
    function playerHasEntered(address account) 
        external view 
        returns (bool);
}