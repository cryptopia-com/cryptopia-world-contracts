const config : AppConfig = {
    networks: {
        development: {
            CryptopiaTreasury: {
                address: "0x37eEf262526Fc4895A632b44d6e430918c67a58A"
            },
            CryptopiaAccount: {
                outputBytecode: true,
            },
            ERC721: {
                CryptopiaTitleDeedToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeedToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeedToken/'
                },
                CryptopiaShipToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/ShipToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/ShipToken/'
                },
                CryptopiaToolToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/ToolToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/ToolToken/',
                    tools : [
                        {
                            name : "Axe",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 1: ['1', 'ether'] }, // Meat
                                { 3: ['1', 'ether'] } // Wood
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        },
                        {
                            name : "Pickaxe",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 1: ['1', 'ether'] }, // Meat
                                { 4: ['1', 'ether'] } // Stone
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        },
                        {
                            name : "Fishing rod",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 0: ['1', 'ether'] } // Fish
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        },
                        {
                            name : "Shovel",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 5: ['1', 'ether'] } // Sand
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        }
                    ]
                }
            },
            ERC20: {
                CryptopiaAssetToken: {
                    assets: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: 0,
                            weight: 50, // 0.5kg
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: 1,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: 2,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: 3,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: 4,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: 5,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "FE26ORE",
                            name: "IronOre",
                            resource: 6,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "FE26",
                            name: "Iron",
                            resource: 7,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "CU29ORE",
                            name: "CopperOre",
                            resource: 8,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "CU29",
                            name: "Copper",
                            resource: 9,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "AU79ORE",
                            name: "GoldOre",
                            resource: 10,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "AU79",
                            name: "Gold",
                            resource: 11,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "C6",
                            name: "Carbon",
                            resource: 12,
                            weight: 50, // 0.5kg
                        },
                        {
                            symbol: "OIL",
                            name: "Oil",
                            resource: 13,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "GLASS",
                            name: "Glass",
                            resource: 14,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "STEEL",
                            name: "Steel",
                            resource: 15,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "FUEL",
                            name: "Fuel",
                            resource: 16,
                            weight: 200, // 2kg
                        }
                    ]
                }
            }
        }, 
        mumbai: {
            CryptopiaTreasury: {
                account: ""
            },
            CryptopiaAccount: {
                outputBytecode: true,
            },
            ERC721: {
                CryptopiaTitleDeedToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeedToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeedToken/'
                },
                CryptopiaShipToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/ShipToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/ShipToken/'
                },
                CryptopiaToolToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/ToolToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/ToolToken/',
                    beneficiary: '0x6D0855974622aeB3eE1Ce0655B766c0aC99c0C19',
                    tools : [
                        {
                            name : "Axe",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 1: ['1', 'ether'] }, // Meat
                                { 3: ['1', 'ether'] } // Wood
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        },
                        {
                            name : "Pickaxe",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 1: ['1', 'ether'] }, // Meat
                                { 4: ['1', 'ether'] } // Stone
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        },
                        {
                            name : "Fishing rod",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 0: ['1', 'ether'] } // Fish
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        },
                        {
                            name : "Shovel",
                            rarity: 0, // Common
                            level: 1,
                            stats: {
                                durability: 100, 
                                multiplier_cooldown: 100, 
                                multiplier_xp: 100, 
                                multiplier_effectiveness: 100, 
                                value1: 0, 
                                value2: 0, 
                                value3: 0
                            },
                            minting: [
                                { 5: ['1', 'ether'] } // Sand
                            ],
                            recipe: {
                                level: 1,
                                learnable: false,
                                craftingTime: 0, // Seconds
                                ingredients: []
                            }
                        }
                    ]
                }
            },
            ERC20: {
                CryptopiaAssetToken: {
                    assets: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: 0,
                            weight: 50, // 0.5kg
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: 1,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: 2,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: 3,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: 4,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: 5,
                            minters: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "FE26ORE",
                            name: "IronOre",
                            resource: 6,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "FE26",
                            name: "Iron",
                            resource: 7,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "CU29ORE",
                            name: "CopperOre",
                            resource: 8,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "CU29",
                            name: "Copper",
                            resource: 9,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "AU79ORE",
                            name: "GoldOre",
                            resource: 10,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "AU79",
                            name: "Gold",
                            resource: 11,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "C6",
                            name: "Carbon",
                            resource: 12,
                            weight: 50, // 0.5kg
                        },
                        {
                            symbol: "OIL",
                            name: "Oil",
                            resource: 13,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "GLASS",
                            name: "Glass",
                            resource: 14,
                            weight: 100, // 1kg
                        },
                        {
                            symbol: "STEEL",
                            name: "Steel",
                            resource: 15,
                            weight: 200, // 2kg
                        },
                        {
                            symbol: "FUEL",
                            name: "Fuel",
                            resource: 16,
                            weight: 200, // 2kg
                        }
                    ]
                }
            }
        }
    }
};

export default config;

interface AppConfig {
    networks: {
        [key: string]: any;
    };
}