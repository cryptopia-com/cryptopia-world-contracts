export interface ToolMintingJsonData 
{
    resource: string;
    amount: string; 
}

export interface ToolJsonData {
    name: string;
    rarity: string; 
    level: number;
    durability: number;
    multiplier_xp: number;
    multiplier_effectiveness: number;
    value1: number;
    value2: number;
    value3: number;
    minting: ToolMintingJsonData[];
}