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
    hasLevelConstraint: boolean;
    level: number;
    hasFactionConstraint: boolean;
    faction: string;
    hasSubFactionConstraint: boolean;
    subFaction: string;
    hasCompletionConstraint: boolean;
    maxCompletions: number;
    hasCooldownConstraint: boolean;
    cooldown: number;
    hasTimeConstraint: boolean;
    maxDuration: number;
    steps: StepJsonData[];
    rewards: RewardJsonData[];
}