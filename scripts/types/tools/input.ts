import { Resource, Rarity } from "../../types/enums";

export interface Tool 
{
    name: string;
    rarity: Rarity; 
    level: number;
    durability: number;
    multiplier_cooldown: number;
    multiplier_xp: number;
    multiplier_effectiveness: number;
    value1: number;
    value2: number;
    value3: number;
}

export interface ToolMintingData 
{
    resource: string;
    amount: string; 
}

export interface JsonData {
    name: string;
    rarity: string; 
    level: number;
    durability: number;
    multiplier_cooldown: number;
    multiplier_xp: number;
    multiplier_effectiveness: number;
    value1: number;
    value2: number;
    value3: number;
    minting: ToolMintingData[];
}