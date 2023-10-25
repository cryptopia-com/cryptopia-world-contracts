import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { getParamFromEvent} from '../scripts/helpers/events';
import { REVERT_MODE, MOVEMENT_TURN_DURATION } from "./settings/config";
import { DEFAULT_ADMIN_ROLE, SYSTEM_ROLE, MINTER_ROLE } from "./settings/roles";   
import { ZERO_ADDRESS } from "./settings/constants";
import { ResourceType, TerrainType, BiomeType } from '../scripts/types/enums';
import { Asset, Map } from "../scripts/types/input";

import { 
    CryptopiaAccount,
    CryptopiaAccountRegister,
    CryptopiaMaps,
    CryptopiaShipToken,
    CryptopiaTitleDeedToken,
    CryptopiaPlayerRegister
} from "../typechain-types";

/**
 * Pirate Mechanics tests
 */
describe("PirateMechanics Contract", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let account2: string;
    let other: string;
    let treasury: string;

    // Instances
    let accountRegisterInstance: CryptopiaAccountRegister;
    let mapInstance: CryptopiaMaps;
    let shipTokenInstance: CryptopiaShipToken;
    let titleDeedTokenInstance: CryptopiaTitleDeedToken;
    let playerRegisterInstance: CryptopiaPlayerRegister;

    let pirateAccountInstance: CryptopiaAccount;
    let targetAccountInstance: CryptopiaAccount;

    // Mock Data
    const assets: Asset[] = [
        {
            symbol: "FE26",
            name: "Iron",
            resource: 7,
            weight: 100, // 1kg
            contractAddress: "",
            contractInstance: null
        },
        {
            symbol: "AU29",
            name: "Gold",
            resource: 11,
            weight: 200, // 2kg
            contractAddress: "",
            contractInstance: null
        }
    ];

    /** 
     * (Hex) Grid:      Navigation:     Legend:
     *  W W W W W        W W W W W       W - Water (5)
     *   W I I R W        W 5 5 W W      I - Island
     *  R I M I W        W 5 8 5 W       M - Mountain
     *   W I I I W        W 7 5 5 W      R - Reef
     *  W W W W W        W W W W W
     */
     const map: Map = {
        name: "Map 1".toBytes32(),
        sizeX: 5,
        sizeZ: 5,
        tiles: [
            
            // Bottom row
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.Reef, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            
            // Second row
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Flat, elevation: 7, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: true, resources: [ResourceType.Iron, ResourceType.Gold], resources_amounts: ["10000".toWei(), "500".toWei()] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            
            // Third row
            { group: 0, biome: BiomeType.Reef, terrain: TerrainType.Water, elevation: 4, waterLevel: 5, vegitationLevel: 2, rockLevel: 0, wildlifeLevel: 2, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Mountains, elevation: 8, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [ResourceType.Gold], resources_amounts: ["1000".toWei()] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },

            // Fourth row
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 1, riverFlags: 0, hasRoad: true, hasLake: false, resources: [ResourceType.Iron], resources_amounts: ["20000".toWei()] },
            { group: 1, biome: BiomeType.RainForest, terrain: TerrainType.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.Reef, terrain: TerrainType.Water, elevation: 4, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 3, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },

            // Top row
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: BiomeType.None, terrain: TerrainType.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
        ]
    };
    
    /**
     * Deploy Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, account2, treasury] = (
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
        const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
        const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
        const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
        const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
        
        // Deploy Inventories
        const inventoriesProxy = await (
            await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ])
        ).waitForDeployment();

        const inventoriesAddress = await inventoriesProxy.getAddress();
        const inventoriesInstance = await ethers.getContractAt("CryptopiaInventories", inventoriesAddress);

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
        await assetRegisterInstance.grantRole(SYSTEM_ROLE, system);
        await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, system);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);
        await craftingInstance.grantRole(SYSTEM_ROLE, system);
        await craftingInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        

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
                .grantRole(MINTER_ROLE, minter);
            
            await assetRegisterInstance
                .connect(systemSigner)
                .registerAsset(asset.contractAddress, true, asset.resource);

            await inventoriesInstance
                .setFungibleAsset(asset.contractAddress, asset.weight);
        }

        // Create map 
        await mapInstance.setTiles(
            map.tiles.map((_, index) => index), 
            map.tiles.map(tile => ({
                initialized: true, 
                mapIndex: 0,
                ...tile
            })), 
            map.tiles.map(tile => tile.resources), 
            map.tiles.map(tile => tile.resources_amounts));
        
        await mapInstance.finalizeMap();

        // Create pirate account
        const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Pirate".toBytes32(), 0, 0);
        const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
        const pirateAccount = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
        pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccount);

        // Create target account
        const createTargetAccountTransaction = await accountRegisterInstance.create([account2], 1, 0, "Target".toBytes32(), 0);
        const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
        const targetAccount = getParamFromEvent(accountRegisterInstance, createTargetAccountReceipt, "account", "CreateAccount");
        targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccount);
    });

    /**
     * Test Pirate Mechanics
     */
    describe("Intercept", function () {
        
    });
});