import { Resource } from "../../types/enums";

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