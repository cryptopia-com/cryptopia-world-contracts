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
    vegitationLevel: BigNumberish;
    rockLevel: BigNumberish;
    wildlifeLevel: BigNumberish;
    riverFlags: BigNumberish;
    hasRoad: boolean;
    hasLake: boolean;
    resource1_type: Resource;
    resource1_amount: string;
    resource2_type: Resource;
    resource2_amount: string;
    resource3_type: Resource;
    resource3_amount: string;
}