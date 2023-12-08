// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "./MapEnums.sol";
import "../../assets/types/AssetEnums.sol";

/// @dev Map data
struct Map  
{
    /// @dev True if the map is created
    bool initialized;

    /// @dev True if the map is final and immutable
    bool finalized;

    /// @dev Number of tiles in the x direction
    uint16 sizeX;

    /// @dev Number of tiles in the z direction
    uint16 sizeZ;

    /// @dev The index of the first tile in the map 
    /// @notice Multiple maps exist but the tiles are numbered sequentially
    uint16 tileStartIndex;
}

/// @dev Tile data
struct TileStatic
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

    /// @dev The level of vegetation that the tile contains
    uint32 vegetationLevel;

    /// @dev The size of rocks that the tile contains
    uint32 rockLevel;

    /// @dev The amount of wildlife that the tile contains
    uint32 wildlifeLevel;

    /// @dev Flags that indicate the presence of a river on the tile's hex edges
    /// @notice 0 = NW, 
    uint8 riverFlags; 

    /// @dev Indicates the presence of a road on the tile
    /// @notice Roads remove the movement penalty for hills
    bool hasRoad;

    /// @dev Indicates the presence of a lake on the tile
    /// @notice Lakes impose a movement penalty
    bool hasLake;

    /// @dev Natural resources
    TileResourceStatic[] resources;
}

/// @dev Tile meta data
struct TileDynamic 
{
    /// @dev the owner of the title deed
    address owner;

    /// @dev Up to five players that last entered the tile
    address[] lastEnteredPlayers;

    /// @dev Natural resources
    TileResourceDynamic[] resources;
}

/// @dev Resources can be attached to tiles
struct TileResourceStatic
{
    /// @dev The type of resource
    Resource resource;

    /// @dev The initial size of the `asset` deposit
    uint initialAmount;
}

/// @dev Resources can be attached to tiles
struct TileResourceDynamic
{
    /// @dev The type of resource
    Resource resource;

    /// @dev The amount of `asset` that if left
    uint amount;
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