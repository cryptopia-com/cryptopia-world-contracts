import { Resource } from "./scripts/types/enums";

const config : AppConfig = {
    networks: {
        development: {
            version: {
                major: 1,
                minor: 2,
                patch: 0
            },
            development: true,
            CryptopiaTreasury: {
                contract: "0x37eEf262526Fc4895A632b44d6e430918c67a58A"
            },
            CryptopiaToken: {
                contract: "Token"
            },
            CryptopiaAccount: {
                outputBytecode: true,
            },
            ERC721: {
                TitleDeedToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/TitleDeeds/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/TitleDeeds/'
                },
                BlueprintToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Blueprints/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Blueprints/'
                },
                ShipToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Ships/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Ships/'
                },
                ShipSkinToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/ShipSkins/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/ShipSkins/'
                },
                ToolToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Tools/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Tools/'
                },
                QuestToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Quests/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Quests/'
                }
            },
            ERC20: {
                AssetToken: {
                    resources: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: Resource.Fish,
                            weight: 50, // 0.5kg
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: Resource.Meat,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: Resource.Fruit,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: Resource.Wood,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: Resource.Stone,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: Resource.Sand,
                            system: [
                                "ResourceGathering"
                            ]
                        },  
                        {
                            symbol: "FE26",
                            name: "Iron",
                            resource: Resource.Iron,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "CU29",
                            name: "Copper",
                            resource: Resource.Copper,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "AG47",
                            name: "Silver",
                            resource: Resource.Silver,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "AU79",
                            name: "Gold",
                            resource: Resource.Gold,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "U92",
                            name: "Uranium",
                            resource: Resource.Uranium,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "C6",
                            name: "Carbon",
                            resource: Resource.Carbon,
                            weight: 50, // 0.5kg
                            system: []
                        },
                        {
                            symbol: "DIAMOND",
                            name: "Diamond",
                            resource: Resource.Diamond,
                            weight: 50, // 0.5kg
                            system: []
                        },
                        {
                            symbol: "OIL",
                            name: "Oil",
                            resource: Resource.Oil,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "GLASS",
                            name: "Glass",
                            resource: Resource.Glass,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "STEEL",
                            name: "Steel",
                            resource: Resource.Steel,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "FUEL",
                            name: "Fuel",
                            resource: Resource.Fuel,
                            weight: 200, // 2kg
                            system: []
                        }
                    ]
                }
            }
        }, 
        skaleNebulaTestnet: {
            version: {
                major: 1,
                minor: 2,
                patch: 0
            },
            development: true,
            confirmations: 2,
            pollingInterval: 5000,
            pollingTimeout: 300000,
            defaultSystem: [
                "0x77e5ce811c764a89bf313ece7133050bf9cf8df3"
            ],
            CryptopiaTreasury: {
                contract: "0x0e1445FE302eFE9E3A5160d0DfCd041026791034"
            },
            CryptopiaToken: {
                contract: "0x4b343052753c70B075F6C43412D367BB2DCFf18B"
            },
            CryptopiaAccount: {
                outputBytecode: false,
            },
            ERC721: {
                TitleDeedToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/TitleDeeds/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/TitleDeeds/'
                },
                BlueprintToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Blueprints/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Blueprints/'
                },
                ShipToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Ships/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Ships/'
                },
                ShipSkinToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/ShipSkins/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/ShipSkins/'
                },
                ToolToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Tools/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Tools/'
                },
                QuestToken: {
                    contractURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Quests/',
                    baseTokenURI: 'https://nebula-testnet-api.cryptopia.com/ERC721/Quests/'
                }
            },
            ERC20: {
                AssetToken: {
                    resources: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: Resource.Fish,
                            weight: 50, // 0.5kg
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: Resource.Meat,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: Resource.Fruit,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: Resource.Wood,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: Resource.Stone,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: Resource.Sand,
                            system: [
                                "ResourceGathering"
                            ]
                        },  
                        {
                            symbol: "FE26",
                            name: "Iron",
                            resource: Resource.Iron,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "CU29",
                            name: "Copper",
                            resource: Resource.Copper,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "AG47",
                            name: "Silver",
                            resource: Resource.Silver,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "AU79",
                            name: "Gold",
                            resource: Resource.Gold,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "U92",
                            name: "Uranium",
                            resource: Resource.Uranium,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "C6",
                            name: "Carbon",
                            resource: Resource.Carbon,
                            weight: 50, // 0.5kg
                            system: []
                        },
                        {
                            symbol: "DIAMOND",
                            name: "Diamond",
                            resource: Resource.Diamond,
                            weight: 50, // 0.5kg
                            system: []
                        },
                        {
                            symbol: "OIL",
                            name: "Oil",
                            resource: Resource.Oil,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "GLASS",
                            name: "Glass",
                            resource: Resource.Glass,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "STEEL",
                            name: "Steel",
                            resource: Resource.Steel,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "FUEL",
                            name: "Fuel",
                            resource: Resource.Fuel,
                            weight: 200, // 2kg
                            system: []
                        }
                    ]
                }
            }
        },
        skaleNebulaMainnet: {
            version: {
                major: 1,
                minor: 2,
                patch: 0
            },
            development: false,
            confirmations: 2,
            pollingInterval: 5000,
            pollingTimeout: 300000,
            CryptopiaTreasury: {
                contract: "0x0e1445FE302eFE9E3A5160d0DfCd041026791034"
            },
            CryptopiaToken: {
                contract: "0xDEC61c699cDAAeB0965cDFA727f01c71341e8dCb"
            },
            CryptopiaAccount: {
                outputBytecode: false,
            },
            ERC721: {
                TitleDeedToken: {
                    contractURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/TitleDeeds/',
                    baseTokenURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/TitleDeeds/'
                },
                BlueprintToken: {
                    contractURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Blueprints/',
                    baseTokenURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Blueprints/'
                },
                ShipToken: {
                    contractURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Ships/',
                    baseTokenURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Ships/'
                },
                ShipSkinToken: {
                    contractURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/ShipSkins/',
                    baseTokenURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/ShipSkins/'
                },
                ToolToken: {
                    contractURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Tools/',
                    baseTokenURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Tools/'
                },
                QuestToken: {
                    contractURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Quests/',
                    baseTokenURI: 'https://nebula-mainnet-api.cryptopia.com/ERC721/Quests/'
                }
            },
            ERC20: {
                AssetToken: {
                    resources: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: Resource.Fish,
                            weight: 50, // 0.5kg
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: Resource.Meat,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: Resource.Fruit,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: Resource.Wood,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: Resource.Stone,
                            system: [
                                "ResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: Resource.Sand,
                            system: [
                                "ResourceGathering"
                            ]
                        },  
                        {
                            symbol: "FE26",
                            name: "Iron",
                            resource: Resource.Iron,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "CU29",
                            name: "Copper",
                            resource: Resource.Copper,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "AG47",
                            name: "Silver",
                            resource: Resource.Silver,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "AU79",
                            name: "Gold",
                            resource: Resource.Gold,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "U92",
                            name: "Uranium",
                            resource: Resource.Uranium,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "C6",
                            name: "Carbon",
                            resource: Resource.Carbon,
                            weight: 50, // 0.5kg
                            system: []
                        },
                        {
                            symbol: "DIAMOND",
                            name: "Diamond",
                            resource: Resource.Diamond,
                            weight: 50, // 0.5kg
                            system: []
                        },
                        {
                            symbol: "OIL",
                            name: "Oil",
                            resource: Resource.Oil,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "GLASS",
                            name: "Glass",
                            resource: Resource.Glass,
                            weight: 100, // 1kg
                            system: []
                        },
                        {
                            symbol: "STEEL",
                            name: "Steel",
                            resource: Resource.Steel,
                            weight: 200, // 2kg
                            system: []
                        },
                        {
                            symbol: "FUEL",
                            name: "Fuel",
                            resource: Resource.Fuel,
                            weight: 200, // 2kg
                            system: []
                        }
                    ]
                }
            }
        }
    }
};

export default config;

interface Version {
    major: number;
    minor: number;
    patch: number;
}

interface CryptopiaToken {
    contract: string;
}

interface CryptopiaTreasury {
    contract: string;
}

interface CryptopiaAccount {
    outputBytecode: boolean;
}

interface ERC721TokenConfig {
    contractURI: string;
    baseTokenURI: string;
}

interface ERC721Config {
    TitleDeedToken: ERC721TokenConfig;
    BlueprintToken: ERC721TokenConfig;
    ShipToken: ERC721TokenConfig;
    ShipSkinToken: ERC721TokenConfig;
    ToolToken: ERC721TokenConfig;
    QuestToken: ERC721TokenConfig;
}

interface ResourceConfig {
    symbol: string;
    name: string;
    resource: Resource;
    weight: number;
    system: string[];
}

interface ERC20Config {
    AssetToken: {
        resources: ResourceConfig[];
    };
}

export interface NetworkConfig {
    version: Version;
    development: boolean;
    confirmations?: number;
    pollingInterval?: number;
    pollingTimeout?: number;
    defaultSystem?: string[];
    CryptopiaToken: CryptopiaToken;
    CryptopiaTreasury: CryptopiaTreasury;
    CryptopiaAccount: CryptopiaAccount;
    ERC721: ERC721Config;
    ERC20: ERC20Config;
}

interface AppConfig {
    networks: {
        [key: string]: NetworkConfig;
    };
}