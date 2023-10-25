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
 * Map tests
 */
describe("Maps Contract", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let account2: string;
    let account3: string;
    let account4: string;
    let account5: string;
    let other: string;
    let treasury: string;

    // Instances
    let accountRegisterInstance: CryptopiaAccountRegister;
    let mapInstance: CryptopiaMaps;
    let shipTokenInstance: CryptopiaShipToken;
    let titleDeedTokenInstance: CryptopiaTitleDeedToken;
    let playerRegisterInstance: CryptopiaPlayerRegister;

    let registeredAccountInstance: CryptopiaAccount;
    let unregisteredAccountInstance: CryptopiaAccount;

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
     * Deploy Map Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, account2, account3, account4, account5, other, treasury] = (
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

        // Create registered account
        const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Registered_Username".toBytes32(), 0, 0);
        const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
        const registeredAccount = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
        registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccount);

        // Create unregistered account
        const createUnregisteredAccountTransaction = await accountRegisterInstance.create([other], 1, 0, "Unregistered_Username".toBytes32(), 0);
        const createUnregisteredAccountReceipt = await createUnregisteredAccountTransaction.wait();
        const unregisteredAccount = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
        unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccount);
    });

    /**
     * Test Creating a map
     */
    describe("Create Map", function () {

        it("Should not contain any maps", async function () {

            // Setup 
            const mapCount = await mapInstance.getMapCount();

            // Assert 
            expect(mapCount).to.equal(0);
        });

        it ("Should not be able to create a map if not admin", async function () {

            // Act
            const signer = await ethers.provider.getSigner(other);
            const operation = mapInstance
                .connect(signer)
                .createMap(map.name, map.sizeX, map.sizeZ);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not be able to finalize a map if there is no map under construction", async function () {
            
            // Act
            const operation = mapInstance
                .finalizeMap();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapInstance, "MapUnderConstructionNotFound");
        });

        it ("Should be able to create a map if admin", async function () {

            // Act
            await mapInstance.createMap(
                map.name, map.sizeX, map.sizeZ);

            // Assert
            const actualMap = await mapInstance.getMapAt(0);
            expect(actualMap.initialized).to.equal(true); 
            expect(actualMap.finalized).to.equal(false);
            expect(actualMap.sizeX).to.equal(map.sizeX);
            expect(actualMap.sizeZ).to.equal(map.sizeZ);
            expect(actualMap.tileStartIndex).to.equal(0);
            expect(actualMap.name).to.equal(map.name);
        });

        it ("Should not be able to create a map when the map name is already in use", async function () {

            // Act
            const operation = mapInstance
                .createMap(map.name, map.sizeX, map.sizeZ);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapInstance, "MapNameAlreadyUsed");
        });

        it ("Should not be able to finalzie a map before all tiles are added", async function () {

            // Act 
            const operation = mapInstance
                .finalizeMap();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapInstance, "MapUnderConstructionIncomplete");
        });

        it ("Should not be able to finalize a map that is under construction when not admin", async function () {

            // Setup
            await mapInstance.setTiles(
                map.tiles.map((_, index) => index), 
                map.tiles.map(tile => ({
                    initialized: true, 
                    mapIndex: 0,
                    ...tile
                })), 
                map.tiles.map(tile => tile.resources), 
                map.tiles.map(tile => tile.resources_amounts));
            
            // Act
            const signer = await ethers.provider.getSigner(other);
            const operation = mapInstance
                .connect(signer)
                .finalizeMap();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should be able to finalize a map that is under construction and complete when admin", async function () {

            // Act
            await mapInstance.finalizeMap();

            // Assert
            const actualMap = await mapInstance.getMapAt(0);
            expect(actualMap.initialized).to.equal(true); 
            expect(actualMap.finalized).to.equal(true);
            expect(actualMap.sizeX).to.equal(map.sizeX);
            expect(actualMap.sizeZ).to.equal(map.sizeZ);
            expect(actualMap.tileStartIndex).to.equal(0);
            expect(actualMap.name).to.equal(map.name);
        });
    });

    /**
     * Test players entering a map
     */
    describe("Player Enter", function () {

        it ("Should not allow a non-player to enter a map", async function () {

            // Setup
            const calldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            // Act
            const signer = await ethers.provider.getSigner(other);
            const operation = unregisteredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PlayerNotRegistered")
                    .withArgs(await unregisteredAccountInstance.getAddress());
            } else 
            {
                await expect(operation).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should allow a player to enter a map", async function () {

            // Setup
            const expectedTileIndex = 0;

            const calldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const receipt = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const expectedArrivalTime = await time.latest();
            await expect(receipt).to
                .emit(mapInstance, "PlayerEnterMap")
                .withArgs(await registeredAccountInstance.getAddress(), map.name, expectedTileIndex, expectedArrivalTime);
        });

        it ("Should not allow a player to enter a map if they are already in a map", async function () {

            // Setup
            const calldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PlayerAlreadyEnteredMap")
                    .withArgs(await registeredAccountInstance.getAddress());
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });
    });

    /**
     * Test players moving in a map
     */
    describe("Player Move", function () {

        it ("Should not accept an empty path", async function () {

            // Setup
            const invalidPath: any[] = [];
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [invalidPath]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PathInvalid");
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not accept a path that doesn't have an origin and destination", async function () {
            
            // Setup
            const invalidPath = [0];
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [invalidPath]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PathInvalid");
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not accept a path with an origin other than the player's location", async function () {
            
            // Setup
            const invalidPath = [1, 2, 3];
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [invalidPath]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PathInvalid");
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not accept a broken path", async function () {

            // Setup
            const brokenPath = [0, 1, 3];
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [brokenPath]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PathInvalid");
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not accept a path that disembarks at an invalid location", async function () {

            // Setup
            const invalidPath = [0, 1, 6];
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [invalidPath]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PathInvalid");
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not accept a path that travels over a cliff", async function () {

            // Setup
            const invalidPath = [0, 1, 2, 7, 12];
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [invalidPath]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PathInvalid");
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not allow a non-player to move in a map", async function () {

            // Setup
            const path = [0, 1, 2, 3];
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            // Act
            const signer = await ethers.provider.getSigner(other);
            const operation = unregisteredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(mapInstance, "PlayerNotEnteredMap")
                    .withArgs(await unregisteredAccountInstance.getAddress());
            } else 
            {
                await expect(operation).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should allow a player to move in a map", async function () {

            // Setup
            const expectedTurns = 29;
            const path = [
                0, 1, 2, 7, 13, 14, 13, 7, 2, 1,
                0, 1, 2, 7, 13, 14, 13, 7, 2, 1,
                0, 1, 2, 7, 13, 14, 13, 7, 2, 1, 
                0, 1, 2, 7, 13, 14, 13, 7, 2, 1, 
                0, 1, 2]; 

            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const receipt = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const expectedArrivalTime = await time.latest() + (expectedTurns * MOVEMENT_TURN_DURATION);
            await time.increaseTo(expectedArrivalTime);

            await expect(receipt).to
                .emit(mapInstance, "PlayerMove")
                .withArgs(await registeredAccountInstance.getAddress(), path[0], path[path.length - 1], anyValue, expectedArrivalTime);
        });  

        it ("Should emit valid route data when traveling", async function () {

            // Setup
            const path = [
                2,  // Turn 1 (packed)
                7,  // Turn 1
                13, // Turn 2 
                14, // Turn 3 (packed)
                13, // Turn 4
                7,  // Turn 5 
                2,  // Turn 6 (packed)
                1   // Turn 7
            ];

            const expectedRoute: UnpackedRoute = {
                durationPerTurn: MOVEMENT_TURN_DURATION,
                totalTurns: 7,
                totalTilesInPath: 8,
                totalTilesPacked: 3,
                tiles: [2, 14, 2],
            };

            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);
            const receipt = await transaction.wait();

            const player = getParamFromEvent(mapInstance, receipt, "player", "PlayerMove");
            const origin = getParamFromEvent(mapInstance, receipt, "origin", "PlayerMove");
            const destination = getParamFromEvent(mapInstance, receipt, "destination", "PlayerMove");
            const route = getParamFromEvent(mapInstance, receipt, "route", "PlayerMove");
            const arrival = getParamFromEvent(mapInstance, receipt, "arrival", "PlayerMove");
            
            // Assert
            expect(player).to.equal(await registeredAccountInstance.getAddress());
            expect(origin).to.equal(path[0]);
            expect(destination).to.equal(path[path.length - 1]);

            const expectedArrivalTime = await time.latest() + (expectedRoute.totalTurns * MOVEMENT_TURN_DURATION);
            expect(arrival).to.equal(expectedArrivalTime);

            const unpackedRoute = unpackRoute(route);
            expect(unpackedRoute.durationPerTurn).to.equal(expectedRoute.durationPerTurn);
            expect(unpackedRoute.totalTurns).to.equal(expectedRoute.totalTurns);
            expect(unpackedRoute.totalTilesInPath).to.equal(expectedRoute.totalTilesInPath);
            expect(unpackedRoute.totalTilesPacked).to.equal(expectedRoute.totalTilesPacked);

            for (let i = 0; i < unpackedRoute.tiles.length; i++)
            {
                expect(unpackedRoute.tiles[i]).to.equal(expectedRoute.tiles[i]);
            }
        }); 
    });

    /**
     * Test the player chain integrity
     */
    describe("Chain Integrity", function () {

        // Accounts
        let accountInstance1: CryptopiaAccount;
        let accountInstance2: CryptopiaAccount;
        let accountInstance3: CryptopiaAccount;
        let accountInstance4: CryptopiaAccount;
        let accountInstance5: CryptopiaAccount;

        /**
         * Create players
         */
        before(async () => {

            // Create account 1
            const createAccount1Transaction = await playerRegisterInstance.create([account1], 1, 0, "Username_1".toBytes32(), 0, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            const createAccount1Address = getParamFromEvent(playerRegisterInstance, createAccount1Receipt, "account", "RegisterPlayer");
            accountInstance1 = await ethers.getContractAt("CryptopiaAccount", createAccount1Address);

            // Create account 2
            const createAccount2Transaction = await playerRegisterInstance.create([account2], 1, 0, "Username_2".toBytes32(), 0, 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            const createAccount2Address = getParamFromEvent(playerRegisterInstance, createAccount2Receipt, "account", "RegisterPlayer");
            accountInstance2 = await ethers.getContractAt("CryptopiaAccount", createAccount2Address);

            // Create account 3
            const createAccount3Transaction = await playerRegisterInstance.create([account3], 1, 0, "Username_3".toBytes32(), 0, 0);
            const createAccount3Receipt = await createAccount3Transaction.wait();
            const createAccount3Address = getParamFromEvent(playerRegisterInstance, createAccount3Receipt, "account", "RegisterPlayer");
            accountInstance3 = await ethers.getContractAt("CryptopiaAccount", createAccount3Address);

            // Create account 4
            const createAccount4Transaction = await playerRegisterInstance.create([account4], 1, 0, "Username_4".toBytes32(), 0, 0);
            const createAccount4Receipt = await createAccount4Transaction.wait();
            const createAccount4Address = getParamFromEvent(playerRegisterInstance, createAccount4Receipt, "account", "RegisterPlayer");
            accountInstance4 = await ethers.getContractAt("CryptopiaAccount", createAccount4Address);

            // Create account 5
            const createAccount5Transaction = await playerRegisterInstance.create([account5], 1, 0, "Username_5".toBytes32(), 0, 0);
            const createAccount5Receipt = await createAccount5Transaction.wait();
            const createAccount5Address = getParamFromEvent(playerRegisterInstance, createAccount5Receipt, "account", "RegisterPlayer");
            accountInstance5 = await ethers.getContractAt("CryptopiaAccount", createAccount5Address);
        });

        it ("Should not contain any players initially", async function () {
        
            // Setup
            const tileIndex = 0;

            // Act
            const data = await mapInstance.getTileDataDynamic(tileIndex, 1);

            // Assert
            expect(data.player1[0]).to.equal(ZERO_ADDRESS);
            expect(data.player2[0]).to.equal(ZERO_ADDRESS);
            expect(data.player3[0]).to.equal(ZERO_ADDRESS);
            expect(data.player4[0]).to.equal(ZERO_ADDRESS);
            expect(data.player5[0]).to.equal(ZERO_ADDRESS);
        });

        it ("Should add the first player to the head of the chain", async function () {

            // Setup
            const tileIndex = 0;
            const calldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            // Act
            const signer = await ethers.provider.getSigner(account1);
            await accountInstance1
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const data = await mapInstance.getTileDataDynamic(tileIndex, 1);
            expect(data.player1[0]).to.equal(await accountInstance1.getAddress());
            expect(data.player2[0]).to.equal(ZERO_ADDRESS);
            expect(data.player3[0]).to.equal(ZERO_ADDRESS);
            expect(data.player4[0]).to.equal(ZERO_ADDRESS);
            expect(data.player5[0]).to.equal(ZERO_ADDRESS);
        });

        it ("Should replace the first player with the second player as the head of the chain", async function () {

            // Setup
            const tileIndex = 0;
            const calldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            // Act
            const signer = await ethers.provider.getSigner(account2);
            await accountInstance2
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const data = await mapInstance.getTileDataDynamic(tileIndex, 1);
            expect(data.player1[0]).to.equal(await accountInstance2.getAddress());
            expect(data.player2[0]).to.equal(await accountInstance1.getAddress());
            expect(data.player3[0]).to.equal(ZERO_ADDRESS);
            expect(data.player4[0]).to.equal(ZERO_ADDRESS);
            expect(data.player5[0]).to.equal(ZERO_ADDRESS);
        });

        it ("Should return five players in the chain in LIFO order", async function () {

            // Setup
            const tileIndex = 0;
            const calldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            // Act
            const signer3 = await ethers.provider.getSigner(account3);
            await accountInstance3
                .connect(signer3)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            const signer4 = await ethers.provider.getSigner(account4);
            await accountInstance4
                .connect(signer4)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            const signer5 = await ethers.provider.getSigner(account5);
            await accountInstance5
                .connect(signer5)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const data = await mapInstance.getTileDataDynamic(tileIndex, 1);
            expect(data.player1[0]).to.equal(await accountInstance5.getAddress());
            expect(data.player2[0]).to.equal(await accountInstance4.getAddress());
            expect(data.player3[0]).to.equal(await accountInstance3.getAddress());
            expect(data.player4[0]).to.equal(await accountInstance2.getAddress());
            expect(data.player5[0]).to.equal(await accountInstance1.getAddress());
        });

        it ("Should remove a player from the chain head of the chain", async function () {

            // Setup
            const tileIndex = 0;
            const path = [0, 1]; 

            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            // Act
            const signer = await ethers.provider.getSigner(account5);
            await accountInstance5
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const data = await mapInstance.getTileDataDynamic(tileIndex, 1);
            expect(data.player1[0]).to.equal(await accountInstance4.getAddress());
            expect(data.player2[0]).to.equal(await accountInstance3.getAddress());
            expect(data.player3[0]).to.equal(await accountInstance2.getAddress());
            expect(data.player4[0]).to.equal(await accountInstance1.getAddress());
            expect(data.player5[0]).to.equal(ZERO_ADDRESS);
        });

        it ("Should remove a player from the middle of the chain", async function () {

            // Setup
            const tileIndex = 0;
            const path = [0, 1]; 

            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            // Act
            const signer = await ethers.provider.getSigner(account3);
            await accountInstance3
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const data = await mapInstance.getTileDataDynamic(tileIndex, 1);
            expect(data.player1[0]).to.equal(await accountInstance4.getAddress());
            expect(data.player2[0]).to.equal(await accountInstance2.getAddress());
            expect(data.player3[0]).to.equal(await accountInstance1.getAddress());
            expect(data.player4[0]).to.equal(ZERO_ADDRESS);
            expect(data.player5[0]).to.equal(ZERO_ADDRESS);
        });

        it ("Should remove a player from the end of the chain", async function () {

            // Setup
            const tileIndex = 0;
            const path = [0, 1]; 

            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            await accountInstance1
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);

            // Assert
            const data = await mapInstance.getTileDataDynamic(tileIndex, 1);
            expect(data.player1[0]).to.equal(await accountInstance4.getAddress());
            expect(data.player2[0]).to.equal(await accountInstance2.getAddress());
            expect(data.player3[0]).to.equal(ZERO_ADDRESS);
            expect(data.player4[0]).to.equal(ZERO_ADDRESS);
            expect(data.player5[0]).to.equal(ZERO_ADDRESS);
        });
    });


    /**
     * Helper functions
     */
    interface UnpackedRoute {
        durationPerTurn: number;
        totalTurns: number;
        totalTilesInPath: number;
        totalTilesPacked: number;
        tiles: number[];
    }
      
    /**
     * Unpacks a route from a bytes32
     * 
     * @param route The route to unpack
     * @returns The unpacked route
     */
    const unpackRoute = (route: any): UnpackedRoute => {
        const durationPerTurn = Number(BigInt(route) & 0xFFn);
        const totalTurns = Number((BigInt(route) >> 8n) & 0xFFn);
        const totalTilesInPath = Number((BigInt(route) >> 16n) & 0xFFn);
        const totalTilesPacked = Number((BigInt(route) >> 24n) & 0xFFn);
    
        let bitOffset = 32n; // Starting bit offset after metadata
        const tiles: number[] = [];
    
        for (let i = 0; i < totalTilesPacked; i++) {
            const tile = Number((BigInt(route) >> bitOffset) & 0xFFFFn);
            tiles.push(tile);
            bitOffset += 16n;
        }
    
        return {
            durationPerTurn,
            totalTurns,
            totalTilesInPath,
            totalTilesPacked,
            tiles,
        };
    }
});