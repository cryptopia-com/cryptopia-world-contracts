import { CryptopiaAssetToken } from "../../typechain-types";
import { Resource, Terrain, Biome } from "./enums";
import { BigNumberish } from 'ethers';

export type Asset = {
    symbol: string;
    name: string;
    resource: Resource;
    weight: number;
    contractAddress: string;
    contractInstance: CryptopiaAssetToken | null; 
};

/** 
 * Maps
 */
export interface Map {
    name: string;
    sizeX: number;
    sizeZ: number;
    tiles: Tile[];
}

export interface Tile {
    group: BigNumberish,
    safety: BigNumberish,
    biome: Biome;
    terrain: Terrain;
    elevation: BigNumberish;
    waterLevel: BigNumberish;
    vegetationData: BigNumberish;
    rockData: BigNumberish;
    wildlifeData: BigNumberish;
    riverFlags: BigNumberish;
    hasRoad: boolean;
    hasLake: boolean;
    resources: TileResource[];
}

export interface TileResource {
    resource: Resource;
    amount: string;
}