import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { SYSTEM_ROLE } from "./settings/roles";   
import { Resource, Terrain, Biome, Faction, SubFaction } from "../scripts/types/enums";
import { Asset, Map } from "../scripts/types/input";

import { 
    CryptopiaAccount,
    CryptopiaMaps,
    CryptopiaShipToken,
    CryptopiaTitleDeedToken,
    CryptopiaPlayerRegister,
    CryptopiaInventories,
    CryptopiaToolToken,
    CryptopiaQuests
} from "../typechain-types";
import { ZERO_ADDRESS } from "./settings/constants";

/**
 * Quest tests
 */
describe("Quests Contract", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let account1: string;
    let account2: string;
    let account3: string;
    let account4: string;
    let treasury: string;

    // Instances
    let mapInstance: CryptopiaMaps;
    let shipTokenInstance: CryptopiaShipToken;
    let titleDeedTokenInstance: CryptopiaTitleDeedToken;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let toolTokenInstance: CryptopiaToolToken;
    let questsInstance: CryptopiaQuests;

    // Mock Data
    const assets: Asset[] = [
        {
            symbol: "MEAT",
            name: "Meat",
            resource: Resource.Meat,
            weight: 50, // 0.5kg
            contractAddress: "",
            contractInstance: null
        },
        {
            symbol: "WOOD",
            name: "Wood",
            resource: Resource.Wood,
            weight: 50, // 0.5kg
            contractAddress: "",
            contractInstance: null
        },
        {
            symbol: "STONE",
            name: "Stone",
            resource: Resource.Stone,
            weight: 100, // 1kg
            contractAddress: "",
            contractInstance: null
        },
        {
            symbol: "FUEL",
            name: "Fuel",
            resource: Resource.Fuel,
            weight: 200, // 2kg
            contractAddress: "",
            contractInstance: null
        },
        {
            symbol: "FE26",
            name: "Iron",
            resource: Resource.Iron,
            weight: 100, // 1kg
            contractAddress: "",
            contractInstance: null
        },
        {
            symbol: "AU29",
            name: "Gold",
            resource: Resource.Gold,
            weight: 200, // 2kg
            contractAddress: "",
            contractInstance: null
        }
    ];

    const tools = [
        {
            name: "Stone Axe",
            rarity: 1,
            level: 1,
            stats: {
                durability: 90, 
                multiplier_cooldown: 100, 
                multiplier_xp: 100, 
                multiplier_effectiveness: 100, 
                value1: 10, 
                value2: 20, 
                value3: 30
            },
            minting: [
                { 
                    resource: Resource.Meat,
                    amount: ["1.0", "ether"] 
                }, 
                { 
                    resource: Resource.Wood,
                    amount: ["1.0", "ether"] 
                }
            ],
            recipe: {
                level: 1,
                learnable: false,
                craftingTime: 300, // 5 min
                ingredients: [
                    {
                        resource: Resource.Wood,
                        amount:["2.0", "ether"]
                    },
                    {
                        resource: Resource.Stone,
                        amount: ["1.0", "ether"]
                    }
                ]
            }
        }
    ];

    /** 
     * (Hex) Grid:      Height:         Naviagation:          Legend:
     *  W W W W W        W W W W W       20 21 22 23 24       - Water (5)
     *   W I I R W        W 5 5 W W       15 16 17 18 19      - Island
     *  R I M I W        W 5 8 5 W       10 11 12 13 14       - Mountain
     *   W I I I W        W 7 5 5 W       05 06 07 08 09      - Reef
     *  W W W W W        W W W W W       00 01 02 03 04
     */
    const map: Map = {
        name: "Map 1".toBytes32(),
        sizeX: 5,
        sizeZ: 5,
        tiles: [
            
            // Bottom row
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            
            // Second row
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 7, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: true, resource1_type: Resource.Iron, resource1_amount: "10000".toWei(), resource2_type: Resource.Gold, resource2_amount: "500".toWei(), resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            
            // Third row
            { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Water, elevation: 4, waterLevel: 5, vegitationLevel: 2, rockLevel: 0, wildlifeLevel: 2, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Mountains, elevation: 8, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: Resource.Gold, resource1_amount: "1000".toWei(), resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },

            // Fourth row
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 1, riverFlags: 0, hasRoad: true, hasLake: false, resource1_type: Resource.Iron, resource1_amount: "20000".toWei(), resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Water, elevation: 4, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 3, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },

            // Top row
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
        ]
    };
    
    /**
     * Deploy Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, account1, account2, account3, account4, treasury] = (
            await ethers.getSigners()).map(s => s.address);

        // Signers
        const systemSigner = await ethers.provider.getSigner(system);

        // Factories
        const WhitelistFactory = await ethers.getContractFactory("Whitelist");
        const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
        const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
        const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
        const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
        const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
        const ToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
        const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
        const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
        const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
        const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
        const QuestsFactory = await ethers.getContractFactory("CryptopiaQuests");
        
        // Deploy Inventories
        const inventoriesProxy = await (
            await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ])
        ).waitForDeployment();

        const inventoriesAddress = await inventoriesProxy.getAddress();
        inventoriesInstance = await ethers.getContractAt("CryptopiaInventories", inventoriesAddress);

        // Grant roles
        await inventoriesInstance.grantRole(SYSTEM_ROLE, system);


        // Deploy Whitelist
        const whitelistProxy = await (
            await upgrades.deployProxy(
                WhitelistFactory, 
                [
                    [
                        inventoriesAddress
                    ]
                ])
        ).waitForDeployment();

        const whitelistAddress = await whitelistProxy.getAddress();


        // Deploy Account register
        const accountRegisterProxy = await (
            await upgrades.deployProxy(AccountRegisterFactory)
        ).waitForDeployment();

        const accountRegisterAddress = await accountRegisterProxy.getAddress();


        // Deploy Asset Register
        const assetRegisterProxy = await (
            await upgrades.deployProxy(
                AssetRegisterFactory, [])
            ).waitForDeployment();

        const assetRegisterAddress = await assetRegisterProxy.getAddress();
        const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);

        // Grant roles
        await assetRegisterInstance.grantRole(SYSTEM_ROLE, system);


        // Deploy Ships
        const shipTokenProxy = await (
            await upgrades.deployProxy(
                ShipTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
                ])
        ).waitForDeployment();

        const shipTokenAddress = await shipTokenProxy.getAddress();
        shipTokenInstance = await ethers.getContractAt("CryptopiaShipToken", shipTokenAddress);


        // Deploy Crafting
        const craftingProxy = await (
            await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ])
        ).waitForDeployment();

        const craftingAddress = await craftingProxy.getAddress();
        const craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);

        // Grant roles
        await craftingInstance.grantRole(SYSTEM_ROLE, system);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);
        

        // Deploy Player Register
        const playerRegisterProxy = await (await upgrades.deployProxy(
            PlayerRegisterFactory, 
            [
                accountRegisterAddress, 
                inventoriesAddress, 
                craftingAddress, 
                shipTokenAddress, 
                [
                    deployer
                ]
            ])).waitForDeployment();

        const playerRegisterAddress = await playerRegisterProxy.getAddress();
        playerRegisterInstance = await ethers.getContractAt("CryptopiaPlayerRegister", playerRegisterAddress);

        // Grant roles
        await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await craftingInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


        // Deploy title deed token
        const titleDeedTokenProxy = await (
            await upgrades.deployProxy(
                TitleDeedTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
                ])
        ).waitForDeployment();

        const titleDeedTokenAddress = await titleDeedTokenProxy.getAddress();
        titleDeedTokenInstance = await ethers.getContractAt("CryptopiaTitleDeedToken", titleDeedTokenAddress);


        // Deploy Maps
        const mapsProxy = await (
            await upgrades.deployProxy(
                MapsFactory, 
                [
                    playerRegisterAddress,
                    assetRegisterAddress,
                    titleDeedTokenAddress,
                    shipTokenAddress
                ])
        ).waitForDeployment();

        const mapsAddress = await mapsProxy.getAddress();
        mapInstance = await ethers.getContractAt("CryptopiaMaps", mapsAddress);

        // Grant roles
        await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);


        // Deploy Tools
        const toolTokenProxy = await (await upgrades.deployProxy(
            ToolTokenFactory, 
            [
                whitelistAddress, 
                "", 
                "",
                playerRegisterAddress,
                inventoriesAddress
            ])).waitForDeployment();

        const toolTokenAddress = await toolTokenProxy.getAddress();
        toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);


        // Deploy Quests
        const questsProxy = await (
            await upgrades.deployProxy(
                QuestsFactory, 
                [
                    playerRegisterAddress,
                    inventoriesAddress,
                    mapsAddress
                ])
        ).waitForDeployment();

        const questsAddress = await questsProxy.getAddress();
        questsInstance = await ethers.getContractAt("CryptopiaQuests", questsAddress);

        // Grant roles
        
        
        // Deploy assets
        for (let asset of assets)
        {
            const assetTokenProxy = await (
                await upgrades.deployProxy(
                    AssetTokenFactory, 
                    [
                        asset.name, 
                        asset.symbol
                    ])
                ).waitForDeployment();

            asset.contractAddress = await assetTokenProxy.getAddress();
            asset.contractInstance = await ethers
                .getContractAt("CryptopiaAssetToken", asset.contractAddress);

            await asset.contractInstance
                .grantRole(SYSTEM_ROLE, system);
            
            await assetRegisterInstance
                .connect(systemSigner)
                .__registerAsset(asset.contractAddress, true, asset.resource);

            await inventoriesInstance
                .setFungibleAsset(asset.contractAddress, asset.weight);
        }


        // Setup Tools
        await inventoriesInstance.setNonFungibleAsset(
            await toolTokenProxy.getAddress(), true);

        // Add tools
        await toolTokenInstance.setTools(
            tools.map((tool: any) => tool.name.toBytes32()),
            tools.map((tool: any) => tool.rarity),
            tools.map((tool: any) => tool.level),
            tools.map((tool: any) => [
                tool.stats.durability, 
                tool.stats.multiplier_cooldown, 
                tool.stats.multiplier_xp, 
                tool.stats.multiplier_effectiveness, 
                tool.stats.value1, 
                tool.stats.value2, 
                tool.stats.value3
            ]),
            tools.map((tool: any) => tool.minting.map((item: any) => item.resource)),
            tools.map((tool: any) => tool.minting.map((item: any) => ethers.parseUnits(item.amount[0], item.amount[1]))));


        // Create map 
        await mapInstance.createMap(
            map.name, map.sizeX, map.sizeZ);

        await mapInstance.setTiles(
            map.tiles.map((_, index) => index), 
            map.tiles.map(tile => ({
                initialized: true, 
                mapIndex: 0,
                group: tile.group,
                safety: tile.safety,
                biome: tile.biome,
                terrain: tile.terrain,
                elevation: tile.elevation,
                waterLevel: tile.waterLevel,
                vegitationLevel: tile.vegitationLevel,
                rockLevel: tile.rockLevel,
                wildlifeLevel: tile.wildlifeLevel,
                riverFlags: tile.riverFlags,
                hasRoad: tile.hasRoad,
                hasLake: tile.hasLake
            })), 
            map.tiles.map(tile => tile.resource1_type), 
            map.tiles.map(tile => tile.resource2_type), 
            map.tiles.map(tile => tile.resource3_type), 
            map.tiles.map(tile => tile.resource1_amount), 
            map.tiles.map(tile => tile.resource2_amount), 
            map.tiles.map(tile => tile.resource3_amount));
        
        await mapInstance.finalizeMap();
    });

    /**
     * Test adding quests
     */
    describe("Admin", function () {

        /**
         * Deploy players
         */
        before(async () => {

            
        });
        
        it ("Should allow system to add a quest", async function () {

            // Setup
            const toolTokenAddress = await toolTokenInstance.getAddress();
            const quest: CryptopiaQuests.QuestStruct = {
                name: "Investigate the Ancient Ruins".toBytes32(),
                hasLevelConstraint: false,
                level: 0,
                hasFactionConstraint: false,
                faction: 0, 
                hasSubFactionConstraint: false,
                subFaction: 0, 
                hasRecurrenceConstraint: true,
                maxRecurrences: 1,
                hasCooldownConstraint: false,
                cooldown: 0,
                hasTimeConstraint: false,
                maxDuration: 0,
                steps: [
                    {
                        name: "Find Scientist".toBytes32(),
                        hasMapConstraint: false,
                        map: "".toBytes32(),
                        hasTileConstraint: true,
                        tile: 6,
                        takeFungible: [],
                        takeNonFungible: [],
                        giveFungible: [],
                        giveNonFungible: []
                    }
                ],
                rewards: [
                    {
                        name: "Resque".toBytes32(),
                        xp: 100,
                        karma: 5,
                        fungible: [],
                        nonFungible: [
                            {
                                asset: toolTokenAddress, 
                                item: "Stone Axe".toBytes32(),
                                allowWallet: false
                            }
                        ]
                    },
                    {
                        name: "Steal".toBytes32(),
                        xp: 100,
                        karma: -5,
                        fungible: [
                            {
                                asset: getAssetByResource(Resource.Wood).contractAddress,
                                amount: "5".toWei(),
                                allowWallet: false
                            }
                        ],
                        nonFungible: [
                            {
                                asset: toolTokenAddress, 
                                item: "Stone Axe".toBytes32(),
                                allowWallet: false
                            }
                        ]
                    }
                ],
            };

            // Act
            await questsInstance.addQuest(quest);

            

            // Assert
            const questCount = await questsInstance.getQuestCount(); 
            expect(questCount).to.equal(1);
        }); 
    });

    /**
     * Helper functions
     */
    const getAssetByResource = (resource: Resource) : Asset => {
        const asset =  assets.find(
            asset => asset.resource === resource);

        if (!asset)
        {
            throw new Error(`No asset found for resource ${resource}`);
        }
            
        return asset;
    };
});