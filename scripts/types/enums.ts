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

export enum Permission 
{
    NotAllowed,
    Allowed,
    Required
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

/// Specifies the position of a tile in relation to the traveler's progress along the route
export enum RoutePosition {
    Any,        // The tile's position relative to the traveler is not considered
    Upcoming,   // The traveler has not yet reached the tile
    Current,    // The tile is the current tile of the traveler
    Passed      // The traveler has already passed the tile
}

/// Connection between tiles
export enum EdgeType
{
    Flat,
    Slope,
    Cliff
} 

/// Terrain of a tile (static)
export enum Terrain
{
    Flat,
    Hills, // Penalty for movement
    Mountains, // Impassable
    Water,
    Seastead
}

/// Biome of a tile
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

/// Environment of a tile (static context of the terrain)
export enum Environment
{
    Beach, // Coastal land tile with at least one neighboring water tile with a depth of 1 (shallow water)
    Coast, // Coastal land tile with at least one neighboring water tile with a depth of 2 (deep water)
    Inland, // Land tile with no neighboring water tiles
    CoastalWater, // Water tile with at least one neighboring land tile
    ShallowWater, // Water tile with a depth of 1
    DeepWater // Water tile with a depth of 2 or more
}

/// Zone of a tile (dynamic)
export enum Zone 
{
    Neutral,       // Preferd by traditional faction (default)
    Industrial,    // Preferd by industrial faction
    Ecological,    // Preferd by eco faction      
    Metropolitan   // Prefered by tech faction
}


/**
 * Resources
 */
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


/**
 * Inventories
 */
export enum Inventory
{
    Wallet,
    Backpack,
    Ship
}


/**
 * Relationship
 */
export enum Relationship
{
    None,
    Friend,
    Family,
    Spouse
}

/**
 * Professions
 */
export enum Profession 
{
    Any,
    Builder,
    Architect,
    Engineer,
    Miner
}

/**
 * Buildings
 */
export enum BuildingType
{
    System,
    Dock,
    Mine,
    Factory
}