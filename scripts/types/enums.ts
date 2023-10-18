/// @dev Connection between tiles
export enum EdgeType
{
    Flat,
    Slope,
    Cliff
} 

export enum TerrainType
{
    Flat,
    Hills, // Penalty for movement
    Mountains, // Impassable
    Water,
    Seastead
}

export enum BiomeType
{
    None, // Seastead only
    Plains,
    Grassland,
    Forest, // Allows minting of wood
    RainForest, // Allows minting of wood
    Desert,
    Tundra,
    Swamp,
    Reef // Water only
}

export enum ResourceType {
    Fish,
    Meat,
    Fruit,
    Wood,
    Stone,
    Sand,
    IronOre,
    Iron,
    CopperOre,
    Copper,
    GoldOre,
    Gold,
    Carbon,
    Oil,
    Glass,
    Steel
}