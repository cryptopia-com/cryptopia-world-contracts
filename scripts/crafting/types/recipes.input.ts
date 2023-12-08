export interface Ingredient {
    asset: string;
    amount: string;
}

export interface JsonData {
    level: number;
    learnable: boolean;
    asset: string,
    item: string,
    craftingTime: number;
    ingredients: Ingredient[];
}