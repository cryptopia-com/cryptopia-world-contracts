import "../scripts/helpers/converters.ts";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { getParamFromEvent} from '../scripts/helpers/events';
import { encodeRockData, encodeVegetationData, encodeWildlifeData } from '../scripts/maps/helpers/encoders';
import { REVERT_MODE } from "./settings/config";
import { resolveEnum } from "../scripts/helpers/enums";
import { Terrain, Biome, Inventory, Faction } from '../scripts/types/enums';
import { Map } from "../scripts/types/input";
import { DEFAULT_ADMIN_ROLE, SYSTEM_ROLE } from "./settings/roles";   

import { 
    CryptopiaAccount,
    CryptopiaAccountRegister,
    CryptopiaPlayerRegister,
    CryptopiaInventories,
    CryptopiaShipToken,
    CryptopiaShipSkinToken,
    CryptopiaToolToken,
    CryptopiaCrafting,
    CryptopiaGameConsole,
    CryptopiaSkyFlight
} from "../typechain-types";

import { 
    ShipSkinStruct 
} from "../typechain-types/contracts/source/tokens/ERC721/ships/IShipSkins";

import { 
    GameConsoleRewardStructOutput 
} from "../typechain-types/contracts/source/game/console/concrete/titles/CryptopiaSkyFlight";


/**
 * GameConsole tests
 */
describe("GameConsole Contracts", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let other: string;
    let treasury: string;

    // Instances
    let accountRegisterInstance: CryptopiaAccountRegister;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let shipTokenInstance: CryptopiaShipToken;
    let shipSkinTokenInstance: CryptopiaShipSkinToken;
    let craftingInstance: CryptopiaCrafting;
    let gameConsoleInstance: CryptopiaGameConsole;
    let skyFlightInstance: CryptopiaSkyFlight;

    let registeredAccountInstance: CryptopiaAccount;
    let unregisteredAccountInstance: CryptopiaAccount;

    let registeredAccountAddress: string;
    let unregisteredAccountAddress: string;

    // Mock Data
    const assets: any[] = [
        {
            symbol: "FISH",
            name: "Fish",
            resource: 0,
            weight: 50, // 0.5kg
            system: [
                "CryptopiaGameConsole"
            ],
            contractAddress: "",
            contractInstance: {}
        },
        {
            symbol: "MEAT",
            name: "Meat",
            resource: 1,
            weight: 50, // 0.5kg
            system: [
                "CryptopiaGameConsole"
            ],
            contractAddress: "",
            contractInstance: {}
        },
        {
            symbol: "FRUIT",
            name: "Fruit",
            resource: 2,
            weight: 50, // 0.5kg
            contractAddress: "",
            system: [
                "CryptopiaGameConsole"
            ],
            contractInstance: {}
        },
        {
            symbol: "WOOD",
            name: "Wood",
            resource: 3,
            weight: 50, // 0.5kg
            contractAddress: "",
            system: [
                "CryptopiaGameConsole"
            ],
            contractInstance: {}
        },
        {
            symbol: "STONE",
            name: "Stone",
            resource: 4,
            weight: 100, // 1kg
            contractAddress: "",
            system: [
                "CryptopiaGameConsole"
            ],
            contractInstance: {}
        },
        {
            symbol: "SAND",
            name: "Sand",
            resource: 5,
            weight: 100, // 1kg
            contractAddress: "",
            system: [
                "CryptopiaGameConsole"
            ],
            contractInstance: {}
        }
    ];

    const map: Map = {
        name: "Map 1".toBytes32(),
        sizeX: 2,
        sizeZ: 2,
        tiles: [
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Water, elevationLevel: 5, waterLevel: 5, vegetationData: '0b000110110001101100011011000110110001101100' , rockData: '0b0001101100011011000110110001' , wildlifeData: '0b00011011000110110001', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 6, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
        ]
    };

    const skins : ShipSkinStruct[] = [
        {
            name: "Blazing Sun Skin".toBytes32(),
            ship: "Whitewake".toBytes32()
        },
        {
            name: "Frozen Moon Skin".toBytes32(),
            ship: "Polaris".toBytes32()
        },
        {
            name: "Thunderstorm Skin".toBytes32(),
            ship: "Socrates".toBytes32()
        },
        {
            name: "Golden Dawn Skin".toBytes32(),
            ship: "Kingfisher".toBytes32()
        },
        {
            name: "Blazing Sun Skin+".toBytes32(),
            ship: "Whitewake".toBytes32()
        },
        {
            name: "Frozen Moon Skin+".toBytes32(),
            ship: "Polaris".toBytes32()
        },
        {
            name: "Thunderstorm Skin+".toBytes32(),
            ship: "Socrates".toBytes32()
        },
        {
            name: "Golden Dawn Skin+".toBytes32(),
            ship: "Kingfisher".toBytes32()
        }
    ];

    let titles = {
        "Sky Flight": {
            logic: "CryptopiaSkyFlight",
            rewards: [
                [
                    {
                        xp: 100,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Blazing Sun Skin".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    },
                    {
                        xp: 25,
                        fungible: [],
                        nonFungible: []
                    },
                    {
                        xp: 250,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Blazing Sun Skin+".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    }
                ],
                [
                    {
                        xp: 100,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Frozen Moon Skin".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    },
                    {
                        xp: 25,
                        fungible: [],
                        nonFungible: []
                    },
                    {
                        xp: 250,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Frozen Moon Skin+".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    }
                ],
                [
                    {
                        xp: 100,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Thunderstorm Skin".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    },
                    {
                        xp: 25,
                        fungible: [],
                        nonFungible: []
                    },
                    {
                        xp: 250,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Thunderstorm Skin+".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    }
                ],
                [
                    {
                        xp: 100,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Golden Dawn Skin".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    },
                    {
                        xp: 25,
                        fungible: [],
                        nonFungible: []
                    },
                    {
                        xp: 250,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: "CryptopiaShipSkinToken",
                                item: "Golden Dawn Skin+".toBytes32(),
                                allowWallet: true
                            }
                        ]
                    }
                ]
            ]
        }
    };


    /**s
     * Deploy Crafting Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, other, treasury] = (
            await ethers.getSigners()).map(s => s.address);

        // Signers
        const systemSigner = await ethers.provider.getSigner(system);

        // Factories
        const WhitelistFactory = await ethers.getContractFactory("CryptopiaWhitelist");
        const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
        const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
        const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
        const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
        const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
        const ShipSkinTokenFactory = await ethers.getContractFactory("CryptopiaShipSkinToken");
        const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
        const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
        const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
        const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
        const GameConsoleFactory = await ethers.getContractFactory("CryptopiaGameConsole");
        const SkyFlightFactory = await ethers.getContractFactory("CryptopiaSkyFlight");
        
        // Deploy Inventories
        const inventoriesProxy = await upgrades.deployProxy(
            InventoriesFactory, 
            [
                treasury
            ]);

        const inventoriesAddress = await inventoriesProxy.address;
        inventoriesInstance = await ethers.getContractAt("CryptopiaInventories", inventoriesAddress);

        // Grant roles
        await inventoriesInstance.grantRole(SYSTEM_ROLE, system);


        // Deploy Whitelist
        const whitelistProxy = await upgrades.deployProxy(
            WhitelistFactory, 
            [
                [
                    inventoriesAddress
                ]
            ]);

        const whitelistAddress = await whitelistProxy.address;


        // Deploy AccountRegister 
        const accountRegisterProxy = await upgrades.deployProxy(
            AccountRegisterFactory);

        const accountRegisterAddress = await accountRegisterProxy.address;
        accountRegisterInstance = await ethers.getContractAt("CryptopiaAccountRegister", accountRegisterAddress);

        // SKALE workaround
        await accountRegisterInstance.initializeManually();


        // Deploy Asset Register
        const assetRegisterProxy = await upgrades.deployProxy(
            AssetRegisterFactory, []);

        const assetRegisterAddress = await assetRegisterProxy.address;
        const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);

        // Grant roles
        await assetRegisterInstance.grantRole(SYSTEM_ROLE, system);


        // Deploy skins
        const shipSkinTokenProxy = await upgrades.deployProxy(
            ShipSkinTokenFactory, 
            [
                whitelistAddress,
                "", 
                "",
                inventoriesAddress
            ]);

        const shipSkinTokenAddress = await shipSkinTokenProxy.address;
        shipSkinTokenInstance = await ethers.getContractAt("CryptopiaShipSkinToken", shipSkinTokenAddress);


        // Setup Skins
        await shipSkinTokenInstance.setSkins(skins);


        // Deploy Ships
        const shipTokenProxy = await upgrades.deployProxy(
            ShipTokenFactory, 
            [
                whitelistAddress,
                "", 
                "",
                shipSkinTokenAddress
            ]);

        const shipTokenAddress = await shipTokenProxy.address;
        shipTokenInstance = await ethers.getContractAt("CryptopiaShipToken", shipTokenAddress);


        // Deploy Crafting
        const craftingProxy = await upgrades.deployProxy(
            CraftingFactory, 
            [
                inventoriesAddress
            ]);

        const craftingAddress = await craftingProxy.address;
        craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);

        // Grant roles
        await craftingInstance.grantRole(SYSTEM_ROLE, system);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);


        // Deploy Player Register
        const playerRegisterProxy = await upgrades.deployProxy(
            PlayerRegisterFactory, 
            [
                accountRegisterAddress, 
                inventoriesAddress, 
                craftingAddress, 
                shipTokenAddress, 
                [
                    deployer
                ]
            ]);

        const playerRegisterAddress = await playerRegisterProxy.address;
        playerRegisterInstance = await ethers.getContractAt("CryptopiaPlayerRegister", playerRegisterAddress);

        // Grant roles
        await playerRegisterInstance.grantRole(SYSTEM_ROLE, system);    
        await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await craftingInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


        // Deploy title deed token
        const titleDeedTokenProxy = await upgrades.deployProxy(
            TitleDeedTokenFactory, 
            [
                whitelistAddress,
                "", 
                ""
            ]);

        const titleDeedTokenAddress = await titleDeedTokenProxy.address;
        const titleDeedTokenInstance = await ethers.getContractAt("CryptopiaTitleDeedToken", titleDeedTokenAddress);

        
        // Deploy Maps
        const mapsProxy = await upgrades.deployProxy(
            MapsFactory, 
            [
                playerRegisterAddress,
                assetRegisterAddress,
                titleDeedTokenAddress,
                shipTokenAddress
            ]);

        const mapsAddress = await mapsProxy.address;
        const mapsInstance = await ethers.getContractAt("CryptopiaMaps", mapsAddress);

        // Grant roles
        await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);
        await playerRegisterInstance.setMapsContract(mapsAddress);
        await mapsInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


        // Deploy GameConsole
        const gameConsoleProxy = await upgrades.deployProxy(
            GameConsoleFactory, 
            [
                playerRegisterAddress
            ]);

        const gameConsoleAddress = await gameConsoleProxy.address;
        gameConsoleInstance = await ethers.getContractAt("CryptopiaGameConsole", gameConsoleAddress);

        // Grant roles
        await shipSkinTokenInstance.grantRole(SYSTEM_ROLE, gameConsoleAddress);  
        await playerRegisterInstance.grantRole(SYSTEM_ROLE, gameConsoleAddress);


        // Deploy SkyFlight
        const skyFlightProxy = await upgrades.deployProxy(
            SkyFlightFactory, 
            [
                playerRegisterAddress,
                parseRewards(titles["Sky Flight"].rewards)
            ]);

        const skyFlightAddress = await skyFlightProxy.address;
        skyFlightInstance = await ethers.getContractAt("CryptopiaSkyFlight", skyFlightAddress);
        titles["Sky Flight"].logic = skyFlightAddress;


        // Deploy assets
        for (let asset of assets)
        {
            const assetTokenProxy = await upgrades.deployProxy(
                AssetTokenFactory, 
                [
                    asset.name, 
                    asset.symbol,
                    inventoriesAddress
                ]);

            asset.contractAddress = await assetTokenProxy.address;
            asset.contractInstance = await ethers
                .getContractAt("CryptopiaAssetToken", asset.contractAddress);

            await asset.contractInstance.grantRole(SYSTEM_ROLE, minter);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, asset.contractAddress);
            
            if (asset.system.includes("CryptopiaGameConsole"))
            {
                await asset.contractInstance.grantRole(
                    SYSTEM_ROLE, gameConsoleAddress);
            }
            
            await assetRegisterInstance
                .registerAsset(asset.contractAddress, true, asset.resource);

            await inventoriesInstance
                .setFungibleAsset(asset.contractAddress, asset.weight);
        }


        // Create map 
        await mapsInstance.createMap(
            map.name, map.sizeX, map.sizeZ);

        await mapsInstance.setTiles(
            map.tiles.map((_, index) => index), 
            map.tiles.map(tile => ({
                initialized: true, 
                mapIndex: 0,
                group: tile.group,
                safety: tile.safety,
                biome: tile.biome,
                terrain: tile.terrain,
                elevationLevel: tile.elevationLevel,
                waterLevel: tile.waterLevel,
                hasRoad: tile.hasRoad,
                hasLake: tile.hasLake,
                riverFlags: tile.riverFlags,
                rockData: encodeRockData(tile.rockData),
                vegetationData: encodeVegetationData(tile.vegetationData),
                wildlifeData: encodeWildlifeData(tile.wildlifeData),
                resources: tile.resources.map(resource => ({    
                    resource: resource.resource,
                    initialAmount: resource.amount
                }))
            })));
        
        await mapsInstance.finalizeMap();

            
        // Create registered account
        const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Registered_Username".toBytes32(), 0, 0);
        const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
        registeredAccountAddress = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
        registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress);

        // Create unregistered account
        const createUnregisteredAccountTransaction = await accountRegisterInstance.create([other], 1, 0, "Unregistered_Username".toBytes32(), 0);
        const createUnregisteredAccountReceipt = await createUnregisteredAccountTransaction.wait();
        unregisteredAccountAddress = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
        unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccountAddress);
    });

    /**
     * Test Console
     */
    describe("Console", function () {

        it ("Contains no titles initially", async () => {

            // Setup 
            const expectedTilteCount = 0; 

            // Act
            const actualTitleCount = await gameConsoleInstance.getTitleCount();

            // Assert
            expect(actualTitleCount).to.equal(expectedTilteCount);
        });  

        it ("Non-admin cannot add titles", async () => {
                
            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = gameConsoleInstance
                .connect(nonAdminSigner)
                .setTitles(Object.values(titles).map(title => title.logic));

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(playerRegisterInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Admin can add titles", async () => {
            
            // Act
            await gameConsoleInstance.setTitles(Object.values(titles).map(title => title.logic));

            // Assert
            const actualTitleCount = await gameConsoleInstance.getTitleCount();
            expect(actualTitleCount).to.equal(Object.keys(titles).length);
        });

        describe("Titles", function () {

            describe("Sky Flight", function () {

                const title = "Sky Flight";

                const MIN_SCORE = 10_000;
                const MAX_SCORE = 1_000_000;
                const SCORE_PER_XP = 1_000;

                const REWARD_FIRST_RUN = 0;
                const REWARD_PERSONAL_HIGHSCORE = 1;
                const REWARD_GLOBAL_HIGHSCORE = 2;
                const REWARD_COUNT = 3;

                it ("No highscore initially", async () => {

                    // Act
                    const titleData = await gameConsoleInstance
                        .getTitle(title.toBytes32()); 

                    // Assert
                    expect(titleData.highscore.score).to.equal(0);
                });  

                it ("Empty leaderboard initially", async () => {

                    // Act
                    const titleData = await gameConsoleInstance
                        .getTitle(title.toBytes32()); 

                    // Assert
                    expect(titleData.leaderboard.length).to.equal(0);
                });  

                it ("Player cannot submit score lower than the min-score", async () => {

                    // Setup
                    const calldata = gameConsoleInstance.interface
                        .encodeFunctionData("submit", [
                            title.toBytes32(), 
                            MIN_SCORE - 1, 
                            "".toBytes32(), 
                            Inventory.Wallet]);

                    // Act
                    const signer = await ethers.provider.getSigner(account1);
                    const operation = registeredAccountInstance
                        .connect(signer)
                        .submitTransaction(await gameConsoleInstance.address, 0, calldata);

                    // Assert
                    if (REVERT_MODE)
                    {
                        await expect(operation).to.be
                            .revertedWithCustomError(gameConsoleInstance, "InvalidSession");
                    } else 
                    {
                        await expect(operation).to
                            .emit(unregisteredAccountInstance, "ExecutionFailure");
                    }
                });  

                it ("Player cannot submit score higher than the max-score", async () => {

                    // Setup
                    const calldata = gameConsoleInstance.interface
                        .encodeFunctionData("submit", [
                            title.toBytes32(), 
                            MAX_SCORE + 1, 
                            "".toBytes32(), 
                            Inventory.Wallet]);

                    // Act
                    const signer = await ethers.provider.getSigner(account1);
                    const operation = registeredAccountInstance
                        .connect(signer)
                        .submitTransaction(await gameConsoleInstance.address, 0, calldata);

                    // Assert
                    if (REVERT_MODE)
                    {
                        await expect(operation).to.be
                            .revertedWithCustomError(gameConsoleInstance, "InvalidSession");
                    } else 
                    {
                        await expect(operation).to
                            .emit(unregisteredAccountInstance, "ExecutionFailure");
                    }
                });  

                it ("Player can submit score", async () => {

                    // Setup
                    const isPersonalHighscore = true;
                    const isGlobalHighscore = true;
                    const calldata = gameConsoleInstance.interface
                        .encodeFunctionData("submit", [
                            title.toBytes32(), 
                            MIN_SCORE, 
                            "".toBytes32(), 
                            Inventory.Wallet]);

                    // Act
                    const signer = await ethers.provider.getSigner(account1);
                    const transaction = await registeredAccountInstance
                        .connect(signer)
                        .submitTransaction(await gameConsoleInstance.address, 0, calldata);

                    // Assert
                    expect(transaction).to
                        .emit(gameConsoleInstance, "GameConsoleSessionSubmit")
                        .withArgs(registeredAccountAddress, title.toBytes32(), MIN_SCORE, isPersonalHighscore, isGlobalHighscore);
                });  

                it ("Player receives xp", async () => {

                    // Setup
                    const expectedXP = MIN_SCORE / SCORE_PER_XP + titles[title].rewards[0][REWARD_FIRST_RUN].xp;

                    // Act
                    const playerData = await playerRegisterInstance.getPlayerData(registeredAccountAddress);

                    // Assert
                    expect(playerData.xp).to.equal(expectedXP);
                });

                it ("Player receives reward", async () => {

                    // Setup
                    const rewardTokenId = 1;
                    const expectedSkin = titles[title].rewards[0][REWARD_FIRST_RUN].nonFungible[0].item;

                    // Act
                    const skinInstance = await shipSkinTokenInstance.getSkinInstance(rewardTokenId);
                    const owner = await shipSkinTokenInstance.ownerOf(rewardTokenId);

                    // Assert
                    expect(skinInstance.name).to.equal(expectedSkin);
                    expect(owner).to.equal(registeredAccountAddress);
                });
            });
        });
    });

    /**
     * Helper functions
     */
    const parseRewards = (rewards: any[][]) => {
        return rewards.map(reward => {
            return reward.map(reward => {
                return {
                    xp: reward.xp,
                    fungible: reward.fungible.map((item: { asset: string; amount: string; allowWallet: boolean }) => ({
                        asset: resolveAsset(item.asset),
                        amount: item.amount.toWei(),
                        allowWallet: item.allowWallet
                    })),
                    nonFungible: reward.nonFungible.map((item: { asset: string; item: string; allowWallet: boolean }) => ({
                        asset: resolveAsset(item.asset),
                        item: item.item,
                        allowWallet: item.allowWallet
                    }))
                };
            });
        });
    };

    const resolveAsset = (asset: string) => {
        switch (asset)
        {
            case "CryptopiaShipSkinToken": return shipSkinTokenInstance.address;
            default: return asset;
        }
    };
});