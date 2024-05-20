export interface StepJsonData {
    name: string;
    hasTileConstraint: boolean;
    tile: number;
    takeFungible: {
        asset: string;
        amount: string;
        allowWallet: boolean;
    }[];
    takeNonFungible: {
        asset: string;
        item: string;
        allowWallet: boolean;
    }[];
    giveFungible: {
        asset: string;
        amount: string;
        allowWallet: boolean;
    }[];
    giveNonFungible: {
        asset: string;
        item: string;
        allowWallet: boolean;
    }[];
}

export interface RewardJsonData {
    name: string;
    xp: number;
    karma: number;
    probability: number;
    probabilityModifierSpeed: number;
    probabilityModifierCharisma: number;
    probabilityModifierLuck: number;
    probabilityModifierIntelligence: number;
    probabilityModifierStrength: number;
    fungible: {
        asset: string;
        amount: string;
        allowWallet: boolean;
    }[];
    nonFungible: {
        asset: string;
        item: string;
        allowWallet: boolean;
    }[];
}

export interface QuestJsonData {
    name: string;
    level: number;
    hasFactionConstraint: boolean;
    faction: string;
    hasSubFactionConstraint: boolean;
    subFaction: string;
    maxCompletions: number;
    cooldown: number;
    maxDuration: number;
    prerequisiteQuest: string;
    steps: StepJsonData[];
    rewards: RewardJsonData[];
}