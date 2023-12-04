import { Resource, Rarity } from "../../scripts/types/enums";
import { Tool } from "../../scripts/types/tools/input";

const tools: Tool[] = [
    {
        name : "Stone Axe",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 90, 
            multiplier_cooldown: 200, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Meat,
                amount: '1' 
            }, 
            { 
                resource: Resource.Wood,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: false,
            craftingTime: 300, // 5 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                }, 
                { 
                    resource: Resource.Stone,
                    amount: '1' 
                }
            ]
        }
    },
    {
        name : "Iron Axe",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 95, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Meat,
                amount: '1' 
            }, 
            { 
                resource: Resource.Wood,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: true,
            craftingTime: 600, // 10 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                }, 
                { 
                    resource: Resource.Iron,
                    amount: '1' 
                }
            ]
        }
    },
    {
        name : "Steel Axe",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 99, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Meat,
                amount: '1' 
            }, 
            { 
                resource: Resource.Wood,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: true,
            craftingTime: 1800, // 30 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                }, 
                { 
                    resource: Resource.Steel,
                    amount: '1' 
                }
            ]
        }
    },
    {
        name : "Stone Pickaxe",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 80, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Meat,
                amount: '1' 
            }, 
            { 
                resource: Resource.Wood,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: false,
            craftingTime: 300, // 5 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                }, 
                { 
                    resource: Resource.Stone,
                    amount: '1' 
                }
            ]
        }
    },
    {
        name : "Iron Pickaxe",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 90, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Meat,
                amount: '1' 
            }, 
            { 
                resource: Resource.Wood,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: true,
            craftingTime: 600, // 10 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                }, 
                { 
                    resource: Resource.Iron,
                    amount: '1' 
                }
            ]
        }
    },
    {
        name : "Steel Pickaxe",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 95, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Meat,
                amount: '1' 
            }, 
            { 
                resource: Resource.Wood,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: true,
            craftingTime: 1800, // 30 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                }, 
                { 
                    resource: Resource.Steel,
                    amount: '1' 
                }
            ]
        }
    },
    {
        name : "Wooden Rod",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 80, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Fish,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: false,
            craftingTime: 300, // 5 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                }
            ]
        }
    },
    {
        name : "Wooden Shovel",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 90, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Sand,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: false,
            craftingTime: 300, // 5 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '2' 
                }
            ]
        }
    },
    {
        name : "Iron Shovel",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 95, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Sand,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: false,
            craftingTime: 300, // 5 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                },
                { 
                    resource: Resource.Iron,
                    amount: '1' 
                }
            ]
        }
    }
    ,
    {
        name : "Steel Shovel",
        rarity: Rarity.Common, 
        level: 1,
        stats: {
            durability: 99, 
            multiplier_cooldown: 100, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 0, 
            value2: 0, 
            value3: 0
        },
        minting: [
            { 
                resource: Resource.Sand,
                amount: '1' 
            }
        ],
        recipe: {
            level: 1,
            learnable: false,
            craftingTime: 300, // 5 Minutes
            ingredients: [
                { 
                    resource: Resource.Wood,
                    amount: '1' 
                },
                { 
                    resource: Resource.Steel,
                    amount: '1' 
                }
            ]
        }
    }
];

export default tools;

