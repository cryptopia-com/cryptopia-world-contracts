// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./MapEnums.sol";
import "../../assets/types/AssetEnums.sol";

/// @dev Map data
struct Map  
{
    /// @dev The name of the map
    bytes32 name;

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

/// @dev Static tile data
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
    /// {Flat, Hills, Mountains, Seastead}
    Terrain terrain;

    /// @dev The type of environment
    /// {Beach, Coast, Inland, CoastalWater, ShallowWater, DeepWater}
    Environment environment;

    /// @dev The elevation of the terrain (seafloor in case of sea tile)
    uint8 elevationLevel;

    /// @dev The water level of the tile 
    /// @notice Water level minus elevation equals the depth of the water
    uint8 waterLevel;

    /// @dev Indicates the presence of a lake on the tile
    /// @notice Lakes impose a movement penalty
    bool hasLake;

    /// @dev Flags that indicate the presence of a river on the tile's hex edges
    /// @notice 0 = NW, 
    uint8 riverFlags; 

    /// @dev Natural resources
    TileResourceStatic[] resources;
}

/// @dev Dynamic tile meta data
struct TileDynamic 
{
    /// @dev the owner of the title deed
    address owner;

    /// @dev Type of zone
    Zone zone;

    /// @dev Indicates the presence of a road on the tile
    /// @notice Roads remove the movement penalty for hills
    bool hasRoad;

    /// @dev The rocks that the tile contains
    bytes4 rockData;

    /// @dev The vegetation that the tile contains
    bytes8 vegetationData;

    /// @dev The wildlife that the tile contains
    bytes4 wildlifeData;

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

    /// @dev The initial size of the `resource` deposit
    uint initialAmount;
}

/// @dev Resources can be attached to tiles
struct TileResourceDynamic
{
    /// @dev The type of resource
    Resource resource;

    /// @dev The amount of `resource` that if left
    uint amount;
}

/// @dev Player navigation 
struct PlayerNavigation {

    /// @dev Player movement budget
    uint16 movement;

    /// @dev The datetime at which the player is no longer frozen
    uint64 frozenUntil;

    /// @dev The name of the map that the player is currently on
    bytes32 location_mapName;

    /// @dev Index of the map that the player is currently on
    uint16 location_mapIndex;

    /// @dev Tile that the player is currently on
    uint16 location_tileIndex;

    /// @dev When the player arrives at `tileIndex`
    uint64 location_arrival;

    /// @dev Tiles that make up the route that the player is currently traveling or last traveled
    bytes32 location_route;
}

/// @dev Constraints based on the terrain type
struct TileTerrainConstraints 
{
    bool flat;          // Allows construction on flat terrain
    bool hills;         // Allows construction on hills (with movement penalty)
    bool mountains;     // Allows construction on mountains (if ever needed)
    bool seastead;      // Allows construction on seastead tiles
}

/// @dev Constraints based on the biome type
struct TileBiomeConstraints 
{
    bool none;          // Allows construction in areas with no specific biome
    bool plains;        // Allows construction in plains
    bool grassland;     // Allows construction in grassland
    bool forest;        // Allows construction in forest
    bool rainForest;    // Allows construction in rainforest
    bool mangrove;      // Allows construction in mangrove
    bool desert;        // Allows construction in desert
    bool tundra;        // Allows construction in tundra
    bool swamp;         // Allows construction in swamp
    bool reef;          // Allows construction in reef
    bool vulcanic;      // Allows construction in vulcanic areas
}

/// @dev Constraints based on the tile's environment
struct TileEnvironmentConstraints
{
    bool beach;        // Allows construction in beach areas
    bool coast;        // Allows construction in coastal areas
    bool inland;       // Allows construction in inland areas
    bool coastalWater; // Allows construction in coastal water areas
    bool shallowWater; // Allows construction in shallow water areas
    bool deepWater;    // Allows construction in deep water areas
    bool industrial;   // Allows construction in industrial areas
    bool urban;        // Allows construction in urban areas
}

struct TileZoneConstraints
{
    bool neutral;       // Allows construction in neutral zones
    bool industrial;    // Allows construction in industrial zones
    bool ecological;    // Allows construction in ecological zones
    bool metropolitan;  // Allows construction in metropolitan zones
}