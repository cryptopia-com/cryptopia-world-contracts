import { Resource, Rarity } from "../../types/enums";

export interface Stats {
    durability: number;
    multiplier_cooldown: number;
    multiplier_xp: number;
    multiplier_effectiveness: number;
    value1: number;
    value2: number;
    value3: number;
}

export interface Minting {
    resource: Resource;
    amount: string; 
}

export interface Ingredient {
    resource: Resource;
    amount: string;
}

export interface Recipe {
    level: number;
    learnable: boolean;
    craftingTime: number;
    ingredients: Ingredient[];
}

export interface Tool {
    name: string;
    rarity: Rarity; 
    level: number;
    stats: Stats;
    minting: Minting[];
    recipe: Recipe;
}