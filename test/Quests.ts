import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { REVERT_MODE } from "./settings/config";
import { DEFAULT_ADMIN_ROLE, SYSTEM_ROLE } from "./settings/roles";   
import { Resource, Terrain, Biome, Inventory, SubFaction } from "../scripts/types/enums";
import { Asset, Map } from "../scripts/types/input";
import { getParamFromEvent} from '../scripts/helpers/events';
import { encodeRockData, encodeVegetationData, encodeWildlifeData } from '../scripts/maps/helpers/encoders';
import { resolveEnum } from "../scripts/helpers/enums";

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

import { 
    QuestStruct 
} from "../typechain-types/contracts/source/game/quests/IQuests";


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
            durability: 90, 
            multiplier_xp: 100, 
            multiplier_effectiveness: 100, 
            value1: 10, 
            value2: 20, 
            value3: 30,
            minting: [
                { 
                    resource: "MEAT",
                    amount: "1"
                }, 
                { 
                    resource: "WOOD",
                    amount: "1"
                }
            ],
            recipe: {
                level: 1,
                learnable: false,
                craftingTime: 300, // 5 min
                ingredients: [
                    {
                        asset: "WOOD",
                        amount: "2"
                    },
                    {
                        asset: "STONE",
                        amount: "1"
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
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            
            // Second row
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 7, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b1010101010101010101010101010' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: true, resources: [{ resource: Resource.Iron, amount: "100000".toWei() }, { resource: Resource.Gold, amount: "500".toWei() }] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            
            // Third row
            { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Water, elevationLevel: 4, waterLevel: 5, vegetationData: '0b101010101010101010101010101010101010101010' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b10000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Mountains, elevationLevel: 8, waterLevel: 5, vegetationData: '0b111111111111111111111111111111111111111111' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [{ resource: Resource.Gold, amount: "500".toWei() }] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },

            // Fourth row
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b1010101010101010101010101010' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: true, hasLake: false, resources: [{ resource: Resource.Iron, amount: "100000".toWei() }, { resource: Resource.Copper, amount: "5000".toWei() }] },
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Water, elevationLevel: 4, waterLevel: 5, vegetationData: '0b111111111111111111111111111111111111111111' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b11000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },

            // Top row
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
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
        const WhitelistFactory = await ethers.getContractFactory("CryptopiaWhitelist");
        const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
        const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
        const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
        const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
        const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
        const ShipSkinTokenFactory = await ethers.getContractFactory("CryptopiaShipSkinToken");
        const ToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
        const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
        const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
        const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
        const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
        const QuestTokenFactory = await ethers.getContractFactory("CryptopiaQuestToken");
        const QuestsFactory = await ethers.getContractFactory("CryptopiaQuests");
        
        // Deploy Inventories
        const inventoriesProxy = await upgrades.deployProxy(
            InventoriesFactory, 
            [
                treasury
            ]);

        inventoriesAddress = await inventoriesProxy.address;
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


        // Deploy Account register
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
        const craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);

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
        titleDeedTokenInstance = await ethers.getContractAt("CryptopiaTitleDeedToken", titleDeedTokenAddress);


        // Deploy Maps
        const mapsProxy = await upgrades.deployProxy(
            MapsFactory, 
            [
                playerRegisterAddress,
                assetRegisterAddress,
                titleDeedTokenAddress,
                shipTokenAddress
            ]);

        mapsAddress = await mapsProxy.address;
        mapsInstance = await ethers.getContractAt("CryptopiaMaps", mapsAddress);

        // Grant roles
        await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);
        await playerRegisterInstance.setMapsContract(mapsAddress);
        await mapsInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


        // Deploy Tools
        const toolTokenProxy = await upgrades.deployProxy(
            ToolTokenFactory, 
            [
                whitelistAddress, 
                "", 
                "",
                playerRegisterAddress,
                inventoriesAddress
            ]);

        toolTokenAddress = await toolTokenProxy.address;
        toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

        // Grant roles
        await inventoriesInstance.grantRole(SYSTEM_ROLE, toolTokenAddress);


        // Deploy Quest Token
        const questTokenProxy = await upgrades.deployProxy(
            QuestTokenFactory, 
            [
                whitelistAddress,
                "", 
                "",
                inventoriesAddress
            ]);

        questTokenAddress = await questTokenProxy.address;
        questTokenInstance = await ethers.getContractAt("CryptopiaQuestToken", questTokenAddress);

        // Grant roles
        await inventoriesInstance.grantRole(SYSTEM_ROLE, questTokenAddress);


        // Deploy Quests
        const questsProxy = await upgrades.deployProxy(
            QuestsFactory, 
            [
                playerRegisterAddress,
                inventoriesAddress,
                mapsAddress
            ]);

        questsAddress = await questsProxy.address;
        questsInstance = await ethers.getContractAt("CryptopiaQuests", questsAddress);

        // Grant roles
        await toolTokenInstance.grantRole(SYSTEM_ROLE, questsAddress);
        await playerRegisterInstance.grantRole(SYSTEM_ROLE, questsAddress);
        await questTokenInstance.grantRole(SYSTEM_ROLE, questsAddress);

        
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

            await asset.contractInstance.grantRole(SYSTEM_ROLE, system);
            await asset.contractInstance.grantRole(SYSTEM_ROLE, questsAddress);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, asset.contractAddress);
            
            await assetRegisterInstance
                .registerAsset(asset.contractAddress, true, asset.resource);

            await inventoriesInstance
                .setFungibleAsset(asset.contractAddress, asset.weight);
        }


        // Setup Tools
        await inventoriesInstance.setNonFungibleAsset(
            await toolTokenProxy.address, true);

        // Add tools
        await toolTokenInstance.setTools(
            tools.map((tool: any) => {
                return {
                    name: tool.name.toBytes32(),
                    rarity: tool.rarity,
                    level: tool.level,
                    durability: tool.durability,
                    multiplier_cooldown: tool.multiplier_cooldown,
                    multiplier_xp: tool.multiplier_xp,
                    multiplier_effectiveness: tool.multiplier_effectiveness,
                    value1: tool.value1,
                    value2: tool.value2,
                    value3: tool.value3,
                    minting: tool.minting.map((minting: any) => {
                        return {
                            resource: resolveEnum(Resource, minting.resource),
                            amount: minting.amount.toWei()
                        };
                    })
                };
            }));

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
    });

    /**
     * Test admin functions
     */
    describe("Admin", function () {

        let quest: QuestStruct;

        /**
         * Deploy Quests
         */
        before(async () => {
            
            quest = {
                name: "Investigate the Ancient Ruins".toBytes32(),
                level: 0,
                hasFactionConstraint: false,
                faction: 0, 
                hasSubFactionConstraint: false,
                subFaction: 0, 
                cooldown: 0,
                maxCompletions: 1,
                maxDuration: 0,
                prerequisiteQuest: "".toBytes32(),
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
                        probability: 10000,
                        probabilityModifierSpeed: 0,
                        probabilityModifierCharisma: 0,
                        probabilityModifierLuck: 0,
                        probabilityModifierIntelligence: 0,
                        probabilityModifierStrength: 0,
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
                        probability: 10000,
                        probabilityModifierSpeed: 0,
                        probabilityModifierCharisma: 0,
                        probabilityModifierLuck: 0,
                        probabilityModifierIntelligence: 0,
                        probabilityModifierStrength: 0,
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
                .setQuest(quest);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(questsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(account1, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to add a quest", async function () {

            // Act
            await questsInstance.setQuest(quest);

            // Assert
            const questCount = await questsInstance.getQuestCount(); 
            expect(questCount).to.equal(1);
        }); 
    });

    /**
     * Test Ancient Ruins quests
     */
    describe("Quest: Ancient Ruins", function () {

        let quest: QuestStruct;

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
                level: 0,
                hasFactionConstraint: false,
                faction: 0, 
                hasSubFactionConstraint: true,
                subFaction: SubFaction.None, 
                cooldown: 0,
                maxCompletions: 1,
                maxDuration: 0,
                prerequisiteQuest: "".toBytes32(),
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
                        probability: 10000,
                        probabilityModifierSpeed: 0,
                        probabilityModifierCharisma: 0,
                        probabilityModifierLuck: 0,
                        probabilityModifierIntelligence: 0,
                        probabilityModifierStrength: 0,
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
                        probability: 10000,
                        probabilityModifierSpeed: 0,
                        probabilityModifierCharisma: 0,
                        probabilityModifierLuck: 0,
                        probabilityModifierIntelligence: 0,
                        probabilityModifierStrength: 0,
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

            await questsInstance.setQuest(quest);
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
            const questName = "Investigate the Ancient Ruins".toBytes32()
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const unregisteredAccountSigner = await ethers.provider.getSigner(other);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questName,
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
            const questName = "Investigate the Ancient Ruins".toBytes32()
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const registeredAccountSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questName,
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
            const questName = "Investigate the Ancient Ruins".toBytes32()
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const expectedTile = 7;
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questName,
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
            const questName = "Investigate the Ancient Ruins".toBytes32();
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const rewardAsset = toolTokenAddress;
            const rewardTokenId = 1;
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questName,
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
                .withArgs(registeredAccountAddress, questName);

            await expect(transaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questName, 0);

            await expect(transaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, rewardAsset, 1, rewardTokenId);

            await expect(transaction).to
                .emit(questsInstance, "QuestComplete")
                .withArgs(registeredAccountAddress, questName);
        });

        it ("Should allow a player to complete the quest making the wrong choice", async function () {

            // Setup
            await createPlayers();
            await travelToQuestLocation();
            const questName = "Investigate the Ancient Ruins".toBytes32()
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
                    questName,
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
                .withArgs(registeredAccountAddress, questName);

            expect(transaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questName, 0);

            expect(transaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, reward1_Asset, 1, reward1_TokenId);

            expect(transaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, reward2_Asset, reward2_amount, 0);

            expect(transaction).to
                .emit(questsInstance, "QuestComplete")
                .withArgs(registeredAccountAddress, questName);
        });

        it ("Should not allow a player to complete the quest twice", async function () {

            // Setup
            const questName = "Investigate the Ancient Ruins".toBytes32()
            const rewardIndex = 0;
            const rewardInventory = Inventory.Backpack;
            const questRecrrenceLimit = 1;
            const registeredPlayerSigner = await ethers.provider.getSigner(account1);

            // Act
            const callData = questsInstance.interface
                .encodeFunctionData("completeQuest", 
                [
                    questName,
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
                    .revertedWithCustomError(questsInstance, "QuestCompletionExceeded")
                    .withArgs(registeredAccountAddress, questName, questRecrrenceLimit);
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

        let quest: QuestStruct;

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
                level: 0,
                hasFactionConstraint: false,
                faction: 0, 
                hasSubFactionConstraint: true,
                subFaction: SubFaction.Pirate, 
                cooldown: 0,
                maxCompletions: 1,
                maxDuration: 0,
                prerequisiteQuest: "".toBytes32(),
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
                        probability: 10000,
                        probabilityModifierSpeed: 0,
                        probabilityModifierCharisma: 0,
                        probabilityModifierLuck: 0,
                        probabilityModifierIntelligence: 0,
                        probabilityModifierStrength: 0,
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
                        probability: 10000,
                        probabilityModifierSpeed: 0,
                        probabilityModifierCharisma: 0,
                        probabilityModifierLuck: 0,
                        probabilityModifierIntelligence: 0,
                        probabilityModifierStrength: 0,
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
                {name: "Item 1".toBytes32()}, 
                {name: "Item 2".toBytes32()}
            ]);

            // Add quest
            await questsInstance.setQuest(quest);
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
            const questName = "Pirate Quest".toBytes32();
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
                    questName,
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
                   questName,
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
                    questName,
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
                .withArgs(registeredAccountAddress, questName);

            await expect(startQuestTransaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questName, 0);

            await expect(completeStepTransaction).to
                .emit(questsInstance, "QuestStepComplete")
                .withArgs(registeredAccountAddress, questName, 1);

            await expect(completeStepAndClaimRewardTransaction).to
                .emit(inventoriesInstance, "InventoryAssign")
                .withArgs(registeredAccountAddress, rewardInventory, rewardAsset, 1, rewardTokenId);

            await expect(completeStepAndClaimRewardTransaction).to
                .emit(questsInstance, "QuestComplete")
                .withArgs(registeredAccountAddress, questName);
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