import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { REVERT_MODE } from "./settings/config";
import { DEFAULT_ADMIN_ROLE, SYSTEM_ROLE } from "./settings/roles";   
import { Resource, Terrain, Biome, Inventory, Faction, SubFaction } from "../scripts/types/enums";
import { Asset, Map } from "../scripts/types/input";
import { getParamFromEvent} from '../scripts/helpers/events';

import { 
    CryptopiaAccount,
    CryptopiaMaps,
    CryptopiaShipToken,
    CryptopiaTitleDeedToken,
    CryptopiaAccountRegister,
    CryptopiaPlayerRegister,
    CryptopiaInventories,
    CryptopiaToolToken,
    CryptopiaQuestToken,
    CryptopiaQuests
} from "../typechain-types";
import { BigNumberish } from "ethers";


/**
 * Quest tests
 */
describe("Quests Contract", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let account1: string;
    let other: string;
    let treasury: string;

    // Instances
    let mapsInstance: CryptopiaMaps;
    let shipTokenInstance: CryptopiaShipToken;
    let titleDeedTokenInstance: CryptopiaTitleDeedToken;
    let accountRegisterInstance: CryptopiaAccountRegister;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let toolTokenInstance: CryptopiaToolToken;
    let questTokenInstance: CryptopiaQuestToken;
    let questsInstance: CryptopiaQuests;

    // Addresses
    let mapsAddress: string;
    let inventoriesAddress: string;
    let toolTokenAddress: string;
    let questTokenAddress: string;
    let questsAddress: string;

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
        [deployer, system, account1, other, treasury] = (
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
        const QuestTokenFactory = await ethers.getContractFactory("CryptopiaQuestToken");
        const QuestsFactory = await ethers.getContractFactory("CryptopiaQuests");
        
        // Deploy Inventories
        const inventoriesProxy = await (
            await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ])
        ).waitForDeployment();

        inventoriesAddress = await inventoriesProxy.getAddress();
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
        accountRegisterInstance = await ethers.getContractAt("CryptopiaAccountRegister", accountRegisterAddress);


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
        await playerRegisterInstance.grantRole(SYSTEM_ROLE, system);    
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

        mapsAddress = await mapsProxy.getAddress();
        mapsInstance = await ethers.getContractAt("CryptopiaMaps", mapsAddress);

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

        toolTokenAddress = await toolTokenProxy.getAddress();
        toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

        // Grant roles
        await inventoriesInstance.grantRole(SYSTEM_ROLE, toolTokenAddress);


        // Deploy Quest Token
        const questTokenProxy = await (
            await upgrades.deployProxy(
                QuestTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    "",
                    inventoriesAddress
                ])
        ).waitForDeployment();

        questTokenAddress = await questTokenProxy.getAddress();
        questTokenInstance = await ethers.getContractAt("CryptopiaQuestToken", questTokenAddress);

        // Grant roles
        await inventoriesInstance.grantRole(SYSTEM_ROLE, questTokenAddress);


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

        questsAddress = await questsProxy.getAddress();
        questsInstance = await ethers.getContractAt("CryptopiaQuests", questsAddress);

        // Grant roles
        await toolTokenInstance.grantRole(SYSTEM_ROLE, questsAddress);
        await playerRegisterInstance.grantRole(SYSTEM_ROLE, questsAddress);
        await questTokenInstance.grantRole(SYSTEM_ROLE, questsAddress);

        
        // Deploy assets
        for (let asset of assets)
        {
            const assetTokenProxy = await (
                await upgrades.deployProxy(
                    AssetTokenFactory, 
                    [
                        asset.name, 
                        asset.symbol,
                        inventoriesAddress
                    ])
                ).waitForDeployment();

            asset.contractAddress = await assetTokenProxy.getAddress();
            asset.contractInstance = await ethers
                .getContractAt("CryptopiaAssetToken", asset.contractAddress);

            await asset.contractInstance.grantRole(SYSTEM_ROLE, system);
            await asset.contractInstance.grantRole(SYSTEM_ROLE, questsAddress);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, asset.contractAddress);
            
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
        
        await mapsInstance.finalizeMap();
    });

    /**
     * Test admin functions
     */
    describe("Admin", function () {

        let quest: CryptopiaQuests.QuestStruct;

        /**
         * Deploy players
         */
        before(async () => {
            
            quest = {
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
                        hasTileConstraint: true,
                        tile: 7,
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
        });

        it ("Should not allow non-admin to add a quest", async function () {

            // Setup 
            const nonSystemSigner = await ethers.provider.getSigner(account1);

            // Act
            const operation = questsInstance
                .connect(nonSystemSigner)
                .addQuest(quest);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(questsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(account1, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to add a quest", async function () {

            // Act
            await questsInstance.addQuest(quest);

            // Assert
            const questCount = await questsInstance.getQuestCount(); 
            expect(questCount).to.equal(1);
        }); 
    });

    /**
     * Test Ancient Ruins quests
     */
    describe("Quest: Ancient Ruins", function () {

        let quest: CryptopiaQuests.QuestStruct;

        let registeredAccountInstance: CryptopiaAccount;
        let unregisteredAccountInstance: CryptopiaAccount;

        let registeredAccountAddress: string;
        let unregisteredAccountAddress: string;

        /**
         * Deploy players
         */
        before(async () => {
            
            quest = {
                name: "Investigate the Ancient Ruins".toBytes32(),
                hasLevelConstraint: false,
                level: 0,
                hasFactionConstraint: false,
                faction: 0, 
                hasSubFactionConstraint: true,
                subFaction: SubFaction.None, 
                hasRecurrenceConstraint: true,
                maxRecurrences: 1,
                hasCooldownConstraint: false,
                cooldown: 0,
                hasTimeConstraint: false,
                maxDuration: 0,
                steps: [
                    {
                        name: "Find Scientist".toBytes32(),
                        hasTileConstraint: true,
                        tile: 7,
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

            await questsInstance.addQuest(quest);
        });

        /**
         * Create players
         */
        let createPlayersCounter = 0;
        const createPlayers = async () => {

            // Create registered account
            const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, `${createPlayersCounter}_AncientRuins_Registered`.toBytes32(), 0, 0);
            const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
            registeredAccountAddress = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
            registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress);

            // Create unregistered account
            const createUnregisteredAccountTransaction = await accountRegisterInstance.create([other], 1, 0,`${createPlayersCounter}_AncientRuins_Unregistered`.toBytes32(), 0);
            const createUnregisteredAccountReceipt = await createUnregisteredAccountTransaction.wait();
            unregisteredAccountAddress = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
            unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccountAddress);

            // Add registered player to the map
            const playerEnterCalldata = mapsInstance.interface
                .encodeFunctionData("playerEnter");

            await registeredAccountInstance
                .connect(await ethers.provider.getSigner(account1))
                .submitTransaction(mapsAddress, 0, playerEnterCalldata);

            createPlayersCounter++;
        };

        /**
         * Travel to the quest location
         */
        const travelToQuestLocation = async () => {

            // Travel to the correct tile
            const registeredPlayerSigner = await ethers.provider
                .getSigner(account1);

            const playerMoveCalldata = mapsInstance.interface
                .encodeFunctionData("playerMove", [[0, 1, 2, 7]]);
            
            const playerMoveTransaction = await registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(mapsAddress, 0, playerMoveCalldata);

            const playerMoveReceipt = await playerMoveTransaction.wait();
            const arrival = getParamFromEvent(
                mapsInstance, playerMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(arrival);
        };

        /**
         * Turn the player into a pirate
         */
        const turnPirate = async () => {
                
            // Turn pirate
            const systemSigner = await ethers.provider.getSigner(system);

            await playerRegisterInstance
                .connect(systemSigner)
                .__turnPirate(registeredAccountAddress);
        };


        it ("Should not allow a non-player to start the quest", async function () {

            // Setup
            await createPlayers();
            const questId = 1;
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const unregisteredAccountSigner = await ethers.provider.getSigner(other);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questId,
                    [[]],
                    [[]],
                    [[]],
                    rewardIndex,
                    rewardInventory
                ]);

            const operation = unregisteredAccountInstance
                .connect(unregisteredAccountSigner)
                .submitTransaction(questsAddress, 0, callData);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(questsInstance, "PlayerNotRegistered")
                    .withArgs(unregisteredAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not allow a pirate to start the quest", async function () {

            // Setup
            await turnPirate();
            const questId = 1;
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const registeredAccountSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questId,
                    [[]],
                    [[]],
                    [[]],
                    rewardIndex,
                    rewardInventory
                ]);

            const operation = registeredAccountInstance
                .connect(registeredAccountSigner)
                .submitTransaction(questsAddress, 0, callData);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(questsInstance, "UnexpectedSubFaction")
                    .withArgs(SubFaction.None, SubFaction.Pirate);
            }
            else
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not allow a player to start the quest from the wrong tile", async function () {

            // Setup
            await createPlayers();
            const questId = 1;
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const expectedTile = 7;
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questId,
                    [[]],
                    [[]],
                    [[]],
                    rewardIndex,
                    rewardInventory
                ]);

            const operation = registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(questsAddress, 0, callData);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(questsInstance, "UnexpectedTile")
                    .withArgs(expectedTile, 0);
            }
            else
            {
                await expect(operation).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should allow a player to complete the quest making the right choice", async function () {

            // Setup
            await travelToQuestLocation();
            const questId = 1;
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const rewardAsset = toolTokenAddress;
            const rewardTokenId = 1;
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questId,
                    [[]],
                    [[]],
                    [[]],
                    rewardIndex,
                    rewardInventory
                ]);

            const transaction = await registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(questsAddress, 0, callData);

            // Assert
            await expect(transaction).to
                .emit(questsInstance, "QuestStart")
                .withArgs(registeredAccountAddress, questId);

            await expect(transaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questId, 0);

            await expect(transaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, rewardAsset, 1, rewardTokenId);

            await expect(transaction).to
                .emit(questsInstance, "QuestComplete")
                .withArgs(registeredAccountAddress, questId);
        });

        it ("Should allow a player to complete the quest making the wrong choice", async function () {

            // Setup
            await createPlayers();
            await travelToQuestLocation();
            const questId = 1;
            const rewardIndex = 1;
            const rewardInventory = Inventory.Ship;
            const reward1_Asset = toolTokenAddress;
            const reward1_TokenId = 2;
            const reward2_Asset = getAssetByResource(Resource.Wood).contractAddress;
            const reward2_amount = "5".toWei();
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questId,
                    [[]],
                    [[]],
                    [[]],
                    rewardIndex,
                    rewardInventory
                ]);

            const transaction = await registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(questsAddress, 0, callData);

            // Assert
            expect(transaction).to
                .emit(questsInstance, "QuestStart")
                .withArgs(registeredAccountAddress, questId);

            expect(transaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questId, 0);

            expect(transaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, reward1_Asset, 1, reward1_TokenId);

            expect(transaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, reward2_Asset, reward2_amount, 0);

            expect(transaction).to
                .emit(questsInstance, "QuestComplete")
                .withArgs(registeredAccountAddress, questId);
        });

        it ("Should not allow a player to complete the quest twice", async function () {

            // Setup
            const questId = 1;
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const questRecrrenceLimit = 1;
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questId,
                    [[]],
                    [[]],
                    [[]],
                    rewardIndex,
                    rewardInventory
                ]);

            const operation = registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(questsAddress, 0, callData);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(questsInstance, "QuestRecurrenceExceeded")
                    .withArgs(registeredAccountAddress, questId, questRecrrenceLimit);
            }
            else
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });
    });

    /**
     * Test Complex quests
     */
    describe("Quest: Pirate", function () {

        let quest: CryptopiaQuests.QuestStruct;

        let registeredAccountInstance: CryptopiaAccount;
        let unregisteredAccountInstance: CryptopiaAccount;

        let registeredAccountAddress: string;
        let unregisteredAccountAddress: string;

        /**
         * Deploy players
         */
        before(async () => {

            quest = {
                name: "Pirate Quest".toBytes32(),
                hasLevelConstraint: false,
                level: 0,
                hasFactionConstraint: false,
                faction: 0, 
                hasSubFactionConstraint: true,
                subFaction: SubFaction.Pirate, 
                hasRecurrenceConstraint: true,
                maxRecurrences: 1,
                hasCooldownConstraint: false,
                cooldown: 0,
                hasTimeConstraint: false,
                maxDuration: 0,
                steps: [
                    {
                        name: "Step 1".toBytes32(),
                        hasTileConstraint: true,
                        tile: 0,
                        takeFungible: [],
                        takeNonFungible: [],
                        giveFungible: [],
                        giveNonFungible: [
                            {
                                asset: questTokenAddress,
                                item: "Item 1".toBytes32(),
                                allowWallet: false
                            }
                        ]
                    },
                    {
                        name: "Step 2".toBytes32(),
                        hasTileConstraint: true,
                        tile: 7,
                        takeFungible: [],
                        takeNonFungible: [],
                        giveFungible: [],
                        giveNonFungible: [
                            {
                                asset: questTokenAddress,
                                item: "Item 2".toBytes32(),
                                allowWallet: false
                            }
                        ]
                    },
                    {
                        name: "Step 3".toBytes32(),
                        hasTileConstraint: true,
                        tile: 8,
                        takeFungible: [],
                        takeNonFungible: [
                            {
                                asset: questTokenAddress,
                                item: "Item 1".toBytes32(),
                                allowWallet: false
                            },
                            {
                                asset: questTokenAddress,
                                item: "Item 2".toBytes32(),
                                allowWallet: false
                            }
                        ],
                        giveFungible: [],
                        giveNonFungible: []
                    }
                ],
                rewards: [
                    {
                        name: "Right".toBytes32(),
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
                        name: "Wrong".toBytes32(),
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

            // Add quest items
            await questTokenInstance.setItems([
                "Item 1".toBytes32(), 
                "Item 2".toBytes32()
            ]);

            // Add quest
            await questsInstance.addQuest(quest);
        });

        /**
         * Create players
         */
        let createPlayersCounter = 0;
        const createPlayers = async () => {

            // Create registered account
            const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, `${createPlayersCounter}_Pirate_Registered`.toBytes32(), 0, 0);
            const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
            registeredAccountAddress = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
            registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress);

            // Create unregistered account
            const createUnregisteredAccountTransaction = await accountRegisterInstance.create([other], 1, 0,`${createPlayersCounter}_Pirate_Unregistered`.toBytes32(), 0);
            const createUnregisteredAccountReceipt = await createUnregisteredAccountTransaction.wait();
            unregisteredAccountAddress = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
            unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccountAddress);

            // Add registered player to the map
            const playerEnterCalldata = mapsInstance.interface
                .encodeFunctionData("playerEnter");

            await registeredAccountInstance
                .connect(await ethers.provider.getSigner(account1))
                .submitTransaction(mapsAddress, 0, playerEnterCalldata);

            createPlayersCounter++;
        };

        /**
         * Travel to the quest location
         */
        const travelToLocation = async (path: number[]) => {

            // Travel to the correct tile
            const registeredPlayerSigner = await ethers.provider
                .getSigner(account1);

            const playerMoveCalldata = mapsInstance.interface
                .encodeFunctionData("playerMove", [path]);
            
            const playerMoveTransaction = await registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(mapsAddress, 0, playerMoveCalldata);

            const playerMoveReceipt = await playerMoveTransaction.wait();
            const arrival = getParamFromEvent(
                mapsInstance, playerMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(arrival);
        };

        /**
         * Turn the player into a pirate
         */
        const turnPirate = async () => {
                
            // Turn pirate
            const systemSigner = await ethers.provider.getSigner(system);

            await playerRegisterInstance
                .connect(systemSigner)
                .__turnPirate(registeredAccountAddress);
        };


        it ("Should allow a player to complete the quest making the right choice", async function () {

            // Setup
            await createPlayers();
            const questId = 2;
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const rewardAsset = toolTokenAddress;
            const rewardTokenId = 3;
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            await turnPirate();

            // Start quest and complete step 0
            const startQuestCallData = questsInstance.interface
                .encodeFunctionData("startQuest", [
                    questId,
                    [0],
                    [[Inventory.Backpack]],
                    [[]],
                    [[]]
                ]);
                
            const startQuestTransaction = await registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(questsAddress, 0, startQuestCallData);

            const startQuestReceipt = await startQuestTransaction.wait();
            const item1TokenId = getParamFromEvent(
                inventoriesInstance, startQuestReceipt, "tokenId", "InventoryAssign");

            // Complete step 1
            await travelToLocation([0, 1, 2, 7]);
            const completeStepCallData = questsInstance.interface
                .encodeFunctionData("completeStep", [
                   questId,
                    1,
                    [Inventory.Ship],
                    [],
                    [] 
                ]);

            const completeStepTransaction = await registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(questsAddress, 0, completeStepCallData);

            const completeStepReceipt = await completeStepTransaction.wait();
            const item2TokenId = getParamFromEvent(
                inventoriesInstance, completeStepReceipt, "tokenId", "InventoryAssign");

            // Complete quest and claim reward
            await travelToLocation([7, 8]);
            const completeStepAndClaimRewardCallData = questsInstance.interface
                .encodeFunctionData("completeStepAndClaimReward", [
                    questId,
                    2,
                    [],
                    [Inventory.Backpack, Inventory.Ship],
                    [item1TokenId, item2TokenId],
                    rewardIndex,
                    rewardInventory
                ]);

            const completeStepAndClaimRewardTransaction = await registeredAccountInstance
                .connect(registeredPlayerSigner)
                .submitTransaction(questsAddress, 0, completeStepAndClaimRewardCallData);


            // Assert
            await expect(startQuestTransaction).to
                .emit(questsInstance, "QuestStart")
                .withArgs(registeredAccountAddress, questId);

            await expect(startQuestTransaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questId, 0);

            await expect(completeStepTransaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questId, 1);

            await expect(completeStepAndClaimRewardTransaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, rewardAsset, 1, rewardTokenId);

            await expect(completeStepAndClaimRewardTransaction).to
                .emit(questsInstance, "QuestComplete")
                .withArgs(registeredAccountAddress, questId);
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