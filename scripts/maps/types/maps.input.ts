export interface TileJsonData {
    group: number;
    safety: number;
    biome: string;
    terrain: string;
    elevation: number;
    waterLevel: number;
    vegetationLevel: number;
    rockLevel: number;
    wildlifeLevel: number;
    riverFlags: number;
    hasRoad: boolean;
    hasLake: boolean;
    resources: Array<{ resource: string, amount: string }>;
}

export interface MapJsonData {
    name: string;
    sizeX: number;
    sizeZ: number;
    tiles: TileJsonData[];
}
