// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Regions in a hex cell
enum HexSection
{
    NE, // North East
    E,  // East
    SE, // South East
    SW, // South West
    W,  // West
    NW, // North West
    C,  // center
    Count // Sentinel value
}

/// @dev Connection between tiles
enum EdgeType
{
    Flat,
    Slope,
    Cliff
}

/// @dev Terrain of a tile
enum Terrain
{
    Flat,
    Hills, // Penalty for movement
    Mountains, // Impassable
    Water,
    Seastead
}

/// @dev Biome of a tile
enum Biome 
{
    None, 
    Plains,
    Grassland,
    Forest, // Allows minting of wood
    RainForest, // Allows minting of wood
    Mangrove, // Allows minting of wood
    Desert,
    Tundra,
    Swamp,
    Reef, // Water only
    Vulcanic
}

/// @dev Specifies the position of a tile in relation to the traveler's progress along the route
enum RoutePosition {
    Any,        // The tile's position relative to the traveler is not considered
    Upcoming,   // The traveler has not yet reached the tile
    Current,    // The tile is the current tile of the traveler
    Passed      // The traveler has already passed the tile
}