/**
 * Global
 */
export enum Faction
{
    Eco,
    Tech,
    Industrial,
    Traditional
}

export enum SubFaction 
{
    None,
    Pirate,
    BountyHunter
}

export enum Rarity
{
    Common,
    Rare,
    Legendary,
    Master
}


/**
 * Maps
 */
/// Direction of a tile in relation to another tile
export enum HexDirection 
{
    NE = "NorthEast",
    E = "East",
    SE = "SouthEast",
    SW = "SouthWest",
    W = "West",
    NW = "NorthWest"
}

/// Connection between tiles
export enum EdgeType
{
    Flat,
    Slope,
    Cliff
} 

export enum Terrain
{
    Flat,
    Hills, // Penalty for movement
    Mountains, // Impassable
    Water,
    Seastead
}

export enum Biome 
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

export enum Resource {
    Fish,
    Meat,
    Fruit,
    Wood,
    Stone,
    Sand,
    Uranium, 
    Iron,
    Diamond, 
    Copper,
    Silver, 
    Gold,
    Carbon,
    Oil,
    Glass,
    Steel,
    Fuel
}

/// Specifies the position of a tile in relation to the traveler's progress along the route
export enum RoutePosition {
    Any,        // The tile's position relative to the traveler is not considered
    Upcoming,   // The traveler has not yet reached the tile
    Current,    // The tile is the current tile of the traveler
    Passed      // The traveler has already passed the tile
}


/**
 * Invnetories
 */
export enum Inventory
{
    Wallet,
    Backpack,
    Ship
}