export interface TileJsonData {
    group: number;
    safety: number;
    biome: string;
    terrain: string;
    environment: string;
    zone: string;
    elevationLevel: number;
    waterLevel: number;
    riverFlags: number;
    hasRoad: boolean;
    hasLake: boolean;
    vegetationData: string;
    rockData: string;
    wildlifeData: string;
    resources: Array<{ resource: string, amount: string }>;
}

export interface MapJsonData {
    name: string;
    sizeX: number;
    sizeZ: number;
    tiles: TileJsonData[];
}
