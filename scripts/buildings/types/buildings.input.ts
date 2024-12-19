
export interface TerrainConstraintsJsonData 
{
    flat: boolean;
    hills: boolean;
    mountains: boolean;
    seastead: boolean;
};

export interface BiomeConstraintsJsonData 
{
    none: boolean;
    plains: boolean;
    grassland: boolean;
    forest: boolean;
    rainForest: boolean;
    mangrove: boolean;
    desert: boolean;
    tundra: boolean;
    swamp: boolean;
    reef: boolean;
    vulcanic: boolean;
};

export interface EnvironmentConstraintsJsonData 
{
    beach: boolean;
    coast: boolean;
    inland: boolean;
    coastalWater: boolean;
    shallowWater: boolean;
    deepWater: boolean;
};

export interface ZoneConstraintsJsonData 
{
    neutral: boolean;
    industrial: boolean;
    ecological: boolean;
    metropolitan: boolean;
};

export interface ConstructionConstraintsJsonData
{
    hasMaxInstanceConstraint: boolean;
    maxInstances: number;
    lake: string;
    river: string;
    dock: string;
    terrain: TerrainConstraintsJsonData;
    biome: BiomeConstraintsJsonData;
    environment: EnvironmentConstraintsJsonData;
    zone: ZoneConstraintsJsonData;
}

export interface JobJsonData 
{
    profession: string;
    hasMinimumLevel: boolean;
    minLevel: number;
    hasMaximumLevel: boolean;
    maxLevel: number;
    slots: number;
    xp: number;
    actionValue1: number;
    actionValue2: number;
};

export interface ResourceJsonData
{
    resource: string;
    amount: string;
};

export interface ConstructionRequirementsJsonData
{
    jobs: JobJsonData[];
    resources: ResourceJsonData[];
}

export interface ConstructionJsonData 
{
    constraints: ConstructionConstraintsJsonData;
    requirements: ConstructionRequirementsJsonData;
}

export interface BuildingJsonData {
    name: string;
    rarity: string; 
    buildingType: string;
    modules: number;
    co2: number;
    base_health: number;
    base_defence: number;
    base_inventory: string;
    upgradableFrom: string;
    construction: ConstructionJsonData;
}