import { CryptopiaAssetToken } from "../../typechain-types";
import { ResourceType, TerrainType, BiomeType } from "./enums";
import { BigNumberish } from 'ethers';

export type Asset = {
    symbol: string;
    name: string;
    resource: number;
    weight: number;
    contractAddress: string;
    contractInstance: CryptopiaAssetToken | null; 
};

export interface Map {
    name: string;
    sizeX: number;
    sizeZ: number;
    tiles: Tile[];
}

export interface Tile {
    group: BigNumberish,
    biome: BiomeType;
    terrain: TerrainType;
    elevation: BigNumberish;
    waterLevel: BigNumberish;
    vegitationLevel: BigNumberish;
    rockLevel: BigNumberish;
    wildlifeLevel: BigNumberish;
    riverFlags: BigNumberish;
    hasRoad: boolean;
    hasLake: boolean;
    resources: ResourceType[];
    resources_amounts: string[];
  }