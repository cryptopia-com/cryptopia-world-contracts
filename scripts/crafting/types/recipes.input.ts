export interface IngredientJsonData {
    asset: string;
    amount: string;
}

export interface RecipeJsonData {
    level: number;
    learnable: boolean;
    asset: string,
    item: string,
    craftingTime: number;
    ingredients: IngredientJsonData[];
}