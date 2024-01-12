import { Resource } from "./scripts/types/enums";

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
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeeds/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeeds/'
                },
                CryptopiaShipToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/Ships/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/Ships/'
                },
                CryptopiaToolToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/Tools/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/Tools/'
                },
                CryptopiaQuestToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/Quests/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/Quests/'
                }
            },
            ERC20: {
                CryptopiaAssetToken: {
                    resources: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: Resource.Fish,
                            weight: 50, // 0.5kg
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: Resource.Meat,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: Resource.Fruit,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: Resource.Wood,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: Resource.Stone,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: Resource.Sand,
                            system: [
                                "CryptopiaResourceGathering"
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
        polygonMumbai: {
            confirmations: 2,
            pollingInterval: 5000,
            pollingTimeout: 300000,
            CryptopiaTreasury: {
                address: "0xee27be821e9b6ec58f0ec73feb0723124181a676"
            },
            CryptopiaAccount: {
                outputBytecode: false,
            },
            ERC721: {
                CryptopiaTitleDeedToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeeds/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/TitleDeeds/'
                },
                CryptopiaShipToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/Ships/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/Ships/'
                },
                CryptopiaToolToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/Tools/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/Tools/'
                },
                CryptopiaQuestToken: {
                    contractURI: 'https://mumbai-api.cryptopia.com/ERC721/Quests/',
                    baseTokenURI: 'https://mumbai-api.cryptopia.com/ERC721/Quests/'
                }
            },
            ERC20: {
                CryptopiaAssetToken: {
                    resources: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: Resource.Fish,
                            weight: 50, // 0.5kg
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: Resource.Meat,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: Resource.Fruit,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: Resource.Wood,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: Resource.Stone,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: Resource.Sand,
                            system: [
                                "CryptopiaResourceGathering"
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
        skaleChaos: {
            confirmations: 2,
            pollingInterval: 5000,
            pollingTimeout: 300000,
            CryptopiaTreasury: {
                address: "0xee27be821e9b6ec58f0ec73feb0723124181a676"
            },
            CryptopiaAccount: {
                outputBytecode: true,
            },
            ERC721: {
                CryptopiaTitleDeedToken: {
                    contractURI: 'https://chaos-api.cryptopia.com/ERC721/TitleDeeds/',
                    baseTokenURI: 'https://chaos-api.cryptopia.com/ERC721/TitleDeeds/'
                },
                CryptopiaShipToken: {
                    contractURI: 'https://chaos-api.cryptopia.com/ERC721/Ships/',
                    baseTokenURI: 'https://chaos-api.cryptopia.com/ERC721/Ships/'
                },
                CryptopiaToolToken: {
                    contractURI: 'https://chaos-api.cryptopia.com/ERC721/Tools/',
                    baseTokenURI: 'https://chaos-api.cryptopia.com/ERC721/Tools/'
                },
                CryptopiaQuestToken: {
                    contractURI: 'https://chaos-api.cryptopia.com/ERC721/Quests/',
                    baseTokenURI: 'https://chaos-api.cryptopia.com/ERC721/Quests/'
                }
            },
            ERC20: {
                CryptopiaAssetToken: {
                    resources: [
                        {
                            symbol: "FISH",
                            name: "Fish",
                            resource: Resource.Fish,
                            weight: 50, // 0.5kg
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "MEAT",
                            name: "Meat",
                            weight: 50, // 0.5kg
                            resource: Resource.Meat,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "FRUIT",
                            name: "Fruit",
                            weight: 50, // 0.5kg
                            resource: Resource.Fruit,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "WOOD",
                            name: "Wood",
                            weight: 50, // 0.5kg
                            resource: Resource.Wood,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "STONE",
                            name: "Stone",
                            weight: 100, // 1kg
                            resource: Resource.Stone,
                            system: [
                                "CryptopiaResourceGathering"
                            ]
                        },
                        {
                            symbol: "SAND",
                            name: "Sand",
                            weight: 50, // 0.5kg
                            resource: Resource.Sand,
                            system: [
                                "CryptopiaResourceGathering"
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

interface CryptopiaTreasury {
    address: string;
}

interface CryptopiaAccount {
    outputBytecode: boolean;
}

interface ERC721TokenConfig {
    contractURI: string;
    baseTokenURI: string;
}

interface ERC721Config {
    CryptopiaTitleDeedToken: ERC721TokenConfig;
    CryptopiaShipToken: ERC721TokenConfig;
    CryptopiaToolToken: ERC721TokenConfig;
    CryptopiaQuestToken: ERC721TokenConfig;
}

interface ResourceConfig {
    symbol: string;
    name: string;
    resource: Resource;
    weight: number;
    system: string[];
}

interface ERC20Config {
    CryptopiaAssetToken: {
        resources: ResourceConfig[];
    };
}

export interface NetworkConfig {
    confirmations?: number;
    pollingInterval?: number;
    pollingTimeout?: number;
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