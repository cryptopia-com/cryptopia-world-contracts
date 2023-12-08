// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./types/MapEnums.sol";
import "./types/MapDataTypes.sol";
import "../assets/types/AssetEnums.sol";

/// @title Maps
/// @dev Responsible for world data and player movement
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IMaps {

    /**
     * Public functions
     */
    /// @dev Retrieve static data for the tile with `tileIndex`
    /// @param tileIndex Index of hte tile to retrieve
    /// @return tileData Static tile data
    function getTileDataStatic(uint16 tileIndex) 
        external view 
        returns (TileStatic memory tileData);

    
    /// @dev Retrieve tile data
    /// @param tileIndex Index of the tile to retrieve data for
    /// @return tileData Dynamic tile data
    function getTileDataDynamic(uint16 tileIndex)
        external view 
        returns (TileDynamic memory tileData);


    /// @dev Retrieve tile safety score (0-100)
    /// @param tileIndex Index of the tile to retrieve safety multiplier for
    function getTileSafety(uint16 tileIndex)
        external view 
        returns (uint8);


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

    
    /// @dev Retrieve player data for `account`
    /// @param account The account to retreive player data for
    /// @return PlayerData data
    function getPlayerData(address account)
        external view 
        returns (PlayerNavigationData memory); 

    
    /// @dev Retrieve data that's attached to player
    /// @param account The account to retreive player data for
    /// @return tileIndex The tile that the player is at
    /// @return canInteract Wether the player can interact with the tile
    function getPlayerLocationData(address account)
        external view 
        returns (
            uint16 tileIndex,
            bool canInteract);

        
    /// @dev Retrieve travel data for `account`
    /// @param account The account to retreive travel data for
    /// @return isIdle Wether the player is idle
    /// @return isTraveling Wether the player is traveling
    /// @return isEmbarked Wether the player is embarked
    /// @return tileIndex The tile that the player is at or traveling to
    /// @return route The route that the player is traveling
    /// @return arrival The datetime on wich the player arrives at `tileIndex`
    function getPlayerTravelData(address account)
        external view 
        returns (
            bool isIdle,
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