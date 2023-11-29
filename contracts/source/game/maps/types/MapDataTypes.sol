// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./MapEnums.sol";
import "../../assets/types/AssetEnums.sol";

struct Tile 
{
    /// @dev True if the tile is created
    bool initialized;

    /// @dev Index of the map that the tile belongs to
    uint16 mapIndex;

    /// @dev Landmass or island index (zero signals water tile)
    /// @notice Landmasses are global and can span multiple maps
    uint16 group;

    /// @dev Ranges from 0 to 100 and indicates the safety level of the tile 
    /// @notice 100 - safety for pirates
    uint8 safety; 

    /// @dev The type of biome 
    /// {None, Plains, Grassland, Forest, RainForest, Desert, Tundra, Swamp, Reef}
    Biome biome;

    /// @dev The type of terrain 
    /// {Flat, Hills, Mountains, Water, Seastead}
    Terrain terrain;

    /// @dev The elevation of the terrain (seafloor in case of sea tile)
    uint8 elevation;

    /// @dev The water level of the tile 
    /// @notice Water level minus elevation equals the depth of the water
    uint8 waterLevel;

    /// @dev The level of vegitation that the tile contains
    uint8 vegitationLevel;

    /// @dev The size of rocks that the tile contains
    uint8 rockLevel;

    /// @dev The amount of wildlife that the tile contains
    uint8 wildlifeLevel;

    /// @dev Flags that indicate the presence of a river on the tile's hex edges
    /// @notice 0 = NW, 
    uint8 riverFlags; 

    /// @dev Indicates the presence of a road on the tile
    /// @notice Roads remove the movement penalty for hills
    bool hasRoad;

    /// @dev Indicates the presence of a lake on the tile
    /// @notice Lakes impose a movement penalty
    bool hasLake;
}


/// @dev Tile meta data
struct TileData 
{
    /// @dev Player that most recently entered the tile 
    address lastEnteredPlayer;

    /// @dev Natural resources
    TileResourceData resource1;
    TileResourceData resource2;
    TileResourceData resource3;
}


/// @dev Resources can be attached to tiles
struct TileResourceData 
{
    /// @dev The type of resource
    Resource type_;

    /// @dev The amount of `asset` that if left
    uint amount;

    /// @dev The initial size of the `asset` deposit
    uint initialAmount;
}


/// @dev Player navigation data
struct PlayerNavigationData {

    /// @dev Ordered iterating - Account that entered the tile after us (above us in the list)
    address chain_next;

    /// @dev Ordered iterating - Account that entered the tile before us (below us in the list)
    address chain_prev;

    /// @dev Player movement budget
    uint16 movement;

    /// @dev The datetime at which the player is no longer frozen
    uint64 frozenUntil;

    /// @dev Tile that the player is currently on
    uint16 location_tileIndex;

    /// @dev When the player arrives at `tileIndex`
    uint64 location_arrival;

    /// @dev Tiles that make up the route that the player is currently traveling or last traveled
    bytes32 location_route;
}