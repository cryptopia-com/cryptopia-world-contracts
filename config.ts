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
                },
                CryptopiaCreatureToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/CreatureToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/CreatureToken/',
                    beneficiary: '0x6D0855974622aeB3eE1Ce0655B766c0aC99c0C19',
                    creatures: [
                        {
                            name : "cat1_common",
                            hash : "hash1_common",
                            rarity : 0, // Common
                            class : 0, // Carnivore
                            species : 2, // Cat
                            modules : 1,
                            arbitrary : 0,
                            base_xp : 1000,
                            base_luck : 20,
                            base_charisma : 0,
                            base_speed : 25,
                            base_attack : 15,
                            base_health : 20,
                            base_defence : 0
                        },
                        {
                            name : "cat1_rare",
                            hash : "hash1_rare",
                            rarity : 1, // Rare
                            class : 0, // Carnivore
                            species : 2, // Cat
                            modules : 2,
                            arbitrary : 0,
                            base_xp : 1000,
                            base_luck : 20,
                            base_charisma : 0,
                            base_speed : 30,
                            base_attack : 18,
                            base_health : 25,
                            base_defence : 0
                        },
                        {
                            name : "cat1_legendary",
                            hash : "hash1_legendary",
                            rarity : 2, // Common
                            class : 0, // Carnivore
                            species : 2, // Cat
                            modules : 3,
                            arbitrary : 0,
                            base_xp : 1000,
                            base_luck : 50,
                            base_charisma : 0,
                            base_speed : 35,
                            base_attack : 22,
                            base_health : 30,
                            base_defence : 0
                        },
                        {
                            name : "cat2_common",
                            hash : "hash2_common",
                            rarity : 0, // Common
                            class : 0, // Carnivore
                            species : 2, // Cat
                            modules : 1,
                            arbitrary : 0,
                            base_xp : 1000,
                            base_luck : 20,
                            base_charisma : 0,
                            base_speed : 20,
                            base_attack : 15,
                            base_health : 25,
                            base_defence : 0
                        },
                        {
                            name : "cat2_rare",
                            hash : "hash2_rare",
                            rarity : 1, // Rare
                            class : 0, // Carnivore
                            species : 2, // Cat
                            modules : 2,
                            arbitrary : 0,
                            base_xp : 1000,
                            base_luck : 20,
                            base_charisma : 0,
                            base_speed : 25,
                            base_attack : 18,
                            base_health : 30,
                            base_defence : 0
                        },
                        {
                            name : "cat2_legendary",
                            hash : "hash2_legendary",
                            rarity : 2, // Common
                            class : 0, // Carnivore
                            species : 2, // Cat
                            modules : 3,
                            arbitrary : 0,
                            base_xp : 1000,
                            base_luck : 50,
                            base_charisma : 0,
                            base_speed : 30,
                            base_attack : 22,
                            base_health : 35,
                            base_defence : 0
                        },
                        {
                            name : "tiger_common",
                            hash : "tiger_common",
                            rarity : 0, // Common
                            class : 0, // Carnivore
                            species : 2, // Same as cat
                            modules : 1,
                            arbitrary : 0,
                            base_xp : 2000,
                            base_luck : 0,
                            base_charisma : 0,
                            base_speed : 50,
                            base_attack : 45,
                            base_health : 100,
                            base_defence : 45
                        },
                        {
                            name : "tiger_rare",
                            hash : "tiger_rare",
                            rarity : 1, // Rare
                            class : 0, // Carnivore
                            species : 2, // Same as cat
                            modules : 2,
                            arbitrary : 0,
                            base_xp : 2000,
                            base_luck : 0,
                            base_charisma : 30,
                            base_speed : 55,
                            base_attack : 50,
                            base_health : 110,
                            base_defence : 50
                        },
                        {
                            name : "tiger_legenary",
                            hash : "tiger_legendary",
                            rarity : 3, // Legendary
                            class : 0, // Carnivore
                            species : 2, // Same as cat
                            modules : 3,
                            arbitrary : 0,
                            base_xp : 2000,
                            base_luck : 30,
                            base_charisma : 30,
                            base_speed : 70,
                            base_attack : 65,
                            base_health : 200,
                            base_defence : 60
                        }
                    ],
                    mintData : [
                        {
                            creature : "cat1_common",
                            special : false,
                            rare : "cat1_rare",
                            legendary : "cat1_legendary",
                            mintFee : ['100', 'ether'] // Matic
                        },
                        {
                            creature : "cat2_common",
                            special : false,
                            rare : "cat2_rare",
                            legendary : "cat2_legendary",
                            mintFee : ['100', 'ether'] // Matic
                        },
                        {
                            creature : "tiger_common",
                            special : true,
                            rare : "tiger_rare",
                            legendary : "tiger_legendary",
                            mintFee : ['0', 'ether'] // Matic
                        }
                    ]
                },
                CryptopiaCaptureToken: {
                    contractURI: 'https://rinkeby-api.cryptopia.com/ERC721/CaptureToken/',
                    baseTokenURI: 'https://rinkeby-api.cryptopia.com/ERC721/CaptureToken/',
                    beneficiary: '0x6D0855974622aeB3eE1Ce0655B766c0aC99c0C19',
                    items: [
                        {
                            name : "common",
                            rarity : 0, // Common
                            class : 255, // All
                            strength : 200
                        },
                        {
                            name : "common carnivore",
                            rarity : 0, // Common
                            class : 0, // Carnivore
                            strength : 400
                        },
                        {
                            name : "common herbivore",
                            rarity : 0, // Common
                            class : 1, // Herbivore
                            strength : 400
                        },
                        {
                            name : "common amphibian",
                            rarity : 0, // Common
                            class : 2, // Amphibian
                            strength : 400
                        },
                        {
                            name : "common aerial",
                            rarity : 0, // Common
                            class : 3, // Aerial
                            strength : 400
                        },
                        {
                            name : "rare",
                            rarity : 1, // Rare
                            class : 255, // All
                            strength : 100000
                        },
                        {
                            name : "rare carnivore",
                            rarity : 1, // Rare
                            class : 0, // Carnivore
                            strength : 200000
                        },
                        {
                            name : "rare herbivore",
                            rarity : 1, // Rare
                            class : 1, // Herbivore
                            strength : 200000
                        },
                        {
                            name : "rare amphibian",
                            rarity : 1, // Rare
                            class : 2, // Amphibian
                            strength : 200000
                        },
                        {
                            name : "rare aerial",
                            rarity : 1, // Rare
                            class : 3, // Aerial
                            strength : 200000
                        },
                        {
                            name : "legendary",
                            rarity : 2, // Legendary
                            class : 255, // All
                            strength : 5000000
                        },
                        {
                            name : "legendary carnivore",
                            rarity : 2, // Legendary
                            class : 0, // Carnivore
                            strength : 10000000
                        },
                        {
                            name : "legendary herbivore",
                            rarity : 2, // Legendary
                            class : 1, // Herbivore
                            strength : 10000000
                        },
                        {
                            name : "legendary amphibian",
                            rarity : 2, // Legendary
                            class : 2, // Amphibian
                            strength : 10000000
                        },
                        {
                            name : "legendary aerial",
                            rarity : 2, // Legendary
                            class : 3, // Aerial
                            strength : 10000000
                        },
                        {
                            name : "master",
                            rarity : 3, // Master
                            class : 255, // All
                            strength : 100000000
                        },
                        {
                            name : "master carnivore",
                            rarity : 3, // Master
                            class : 0, // Carnivore
                            strength : 200000000
                        },
                        {
                            name : "master herbivore",
                            rarity : 3, // Master
                            class : 1, // Herbivore
                            strength : 200000000
                        },
                        {
                            name : "master amphibian",
                            rarity : 3, // Master
                            class : 2, // Amphibian
                            strength : 200000000
                        },
                        {
                            name : "master aerial",
                            rarity : 3, // Master
                            class : 3, // Aerial
                            strength : 200000000
                        }
                    ],
                    mintData : [
                        {
                            item : "common",
                            mintFee : ['10', 'ether'] // Matic
                        },
                        {
                            item : "common carnivore",
                            mintFee : ['15', 'ether'] // Matic
                        },
                        {
                            item : "common herbivore",
                            mintFee : ['15', 'ether'] // Matic
                        },
                        {
                            item : "common amphibian",
                            mintFee : ['15', 'ether'] // Matic
                        },
                        {
                            item : "common aerial",
                            mintFee : ['15', 'ether'] // Matic
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
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: 1,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: 2,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: 3,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: 4,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: 5,
                            faucets: [
                                "CryptopiaResourceFaucet"
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
                },
                CryptopiaCreatureToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/CreatureToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/CreatureToken/',
                    beneficiary: '0x6D0855974622aeB3eE1Ce0655B766c0aC99c0C19',
                    creatures: [],
                    mintData : []
                },
                CryptopiaCaptureToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/CaptureToken/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/CaptureToken/',
                    beneficiary: '0x6D0855974622aeB3eE1Ce0655B766c0aC99c0C19',
                    items: [
                        {
                            name : "common",
                            rarity : 0, // Common
                            class : 255, // All
                            strength : 200
                        },
                        {
                            name : "common carnivore",
                            rarity : 0, // Common
                            class : 0, // Carnivore
                            strength : 400
                        },
                        {
                            name : "common herbivore",
                            rarity : 0, // Common
                            class : 1, // Herbivore
                            strength : 400
                        },
                        {
                            name : "common amphibian",
                            rarity : 0, // Common
                            class : 2, // Amphibian
                            strength : 400
                        },
                        {
                            name : "common aerial",
                            rarity : 0, // Common
                            class : 3, // Aerial
                            strength : 400
                        },
                        {
                            name : "rare",
                            rarity : 1, // Rare
                            class : 255, // All
                            strength : 100000
                        },
                        {
                            name : "rare carnivore",
                            rarity : 1, // Rare
                            class : 0, // Carnivore
                            strength : 200000
                        },
                        {
                            name : "rare herbivore",
                            rarity : 1, // Rare
                            class : 1, // Herbivore
                            strength : 200000
                        },
                        {
                            name : "rare amphibian",
                            rarity : 1, // Rare
                            class : 2, // Amphibian
                            strength : 200000
                        },
                        {
                            name : "rare aerial",
                            rarity : 1, // Rare
                            class : 3, // Aerial
                            strength : 200000
                        },
                        {
                            name : "legendary",
                            rarity : 2, // Legendary
                            class : 255, // All
                            strength : 5000000
                        },
                        {
                            name : "legendary carnivore",
                            rarity : 2, // Legendary
                            class : 0, // Carnivore
                            strength : 10000000
                        },
                        {
                            name : "legendary herbivore",
                            rarity : 2, // Legendary
                            class : 1, // Herbivore
                            strength : 10000000
                        },
                        {
                            name : "legendary amphibian",
                            rarity : 2, // Legendary
                            class : 2, // Amphibian
                            strength : 10000000
                        },
                        {
                            name : "legendary aerial",
                            rarity : 2, // Legendary
                            class : 3, // Aerial
                            strength : 10000000
                        },
                        {
                            name : "master",
                            rarity : 3, // Master
                            class : 255, // All
                            strength : 100000000
                        },
                        {
                            name : "master carnivore",
                            rarity : 3, // Master
                            class : 0, // Carnivore
                            strength : 200000000
                        },
                        {
                            name : "master herbivore",
                            rarity : 3, // Master
                            class : 1, // Herbivore
                            strength : 200000000
                        },
                        {
                            name : "master amphibian",
                            rarity : 3, // Master
                            class : 2, // Amphibian
                            strength : 200000000
                        },
                        {
                            name : "master aerial",
                            rarity : 3, // Master
                            class : 3, // Aerial
                            strength : 200000000
                        }
                    ],
                    mintData : [
                        {
                            item : "common",
                            mintFee : ['10', 'ether'] // Matic
                        },
                        {
                            item : "common carnivore",
                            mintFee : ['15', 'ether'] // Matic
                        },
                        {
                            item : "common herbivore",
                            mintFee : ['15', 'ether'] // Matic
                        },
                        {
                            item : "common amphibian",
                            mintFee : ['15', 'ether'] // Matic
                        },
                        {
                            item : "common aerial",
                            mintFee : ['15', 'ether'] // Matic
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
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: 1,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: 2,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: 3,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: 4,
                            faucets: [
                                "CryptopiaResourceFaucet"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: 5,
                            faucets: [
                                "CryptopiaResourceFaucet"
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