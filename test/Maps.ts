import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { BytesLike } from "ethers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { getParamFromEvent} from '../scripts/helpers/events';
import { REVERT_MODE, MapsSettings } from "./settings/config";
import { DEFAULT_ADMIN_ROLE, SYSTEM_ROLE } from "./settings/roles";   
import { ZERO_ADDRESS } from "./settings/constants";
import { HexDirection, Resource, Terrain, Biome, RoutePosition } from '../scripts/types/enums';
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
 * 
 * Test cases:
 * - Create Map
 * - Add Players
 * - Traveling
 * - Route Integrity
 * - Chain Integrity
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
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.Reef, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            
            // Second row
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 7, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: true, resources: [Resource.Iron, Resource.Gold], resources_amounts: ["10000".toWei(), "500".toWei()] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            
            // Third row
            { group: 0, biome: Biome.Reef, terrain: Terrain.Water, elevation: 4, waterLevel: 5, vegitationLevel: 2, rockLevel: 0, wildlifeLevel: 2, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Mountains, elevation: 8, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [Resource.Gold], resources_amounts: ["1000".toWei()] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },

            // Fourth row
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 1, riverFlags: 0, hasRoad: true, hasLake: false, resources: [Resource.Iron], resources_amounts: ["20000".toWei()] },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.Reef, terrain: Terrain.Water, elevation: 4, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 3, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },

            // Top row
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resources: [], resources_amounts: [] },
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
                .grantRole(SYSTEM_ROLE, minter);
            
            await assetRegisterInstance
                .connect(systemSigner)
                .__registerAsset(asset.contractAddress, true, asset.resource);

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
    describe("Add Players", function () {

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
    describe("Traveling", function () {

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
            const expectedArrivalTime = await time.latest() + (expectedTurns * MapsSettings.MOVEMENT_TURN_DURATION);
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
                durationPerTurn: MapsSettings.MOVEMENT_TURN_DURATION,
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
            
            const expectedArrivalTime = await time.latest() + (expectedRoute.totalTurns * MapsSettings.MOVEMENT_TURN_DURATION);
            await time.increaseTo(arrival);

            // Assert
            expect(player).to.equal(await registeredAccountInstance.getAddress());
            expect(origin).to.equal(path[0]);
            expect(destination).to.equal(path[path.length - 1]);
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
     * Test the route integrity
     */
    describe("Route Integrity", function () {

        // Path data
        const turns = 9;
        const path = [
            1,  // Turn 1 (packed)
            2,  // Turn 1 
            7,  // Turn 2
            13, // Turn 3 (packed)
            14, // Turn 4 
            19, // Turn 5
            18, // Turn 6 (packed)
            17, // Turn 7
            22, // Turn 8
            21, // Turn 8 (packed)
            16  // Turn 9
        ];
        
        // Travel data
        let player: string;
        let origin: bigint;
        let destination: bigint;
        let route: BytesLike;
        let arrival: bigint;

        /**
         * Travel
         */
        before(async () => {
            
            const calldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(await mapInstance.getAddress(), 0, calldata);
            const receipt = await transaction.wait();

            player = getParamFromEvent(mapInstance, receipt, "player", "PlayerMove");
            origin = getParamFromEvent(mapInstance, receipt, "origin", "PlayerMove");
            destination = getParamFromEvent(mapInstance, receipt, "destination", "PlayerMove");
            route = getParamFromEvent(mapInstance, receipt, "route", "PlayerMove");
            arrival = getParamFromEvent(mapInstance, receipt, "arrival", "PlayerMove");
        });

        it ("Should be in traveling state", async function () {

            // Act
            const traveldata = await mapInstance.getPlayerTravelData(player);

            // Assert
            expect(traveldata.isTraveling).to.equal(true);
            expect(traveldata.tileIndex).to.equal(destination);
            expect(traveldata.arrival).to.equal(arrival);
            expect(traveldata.route).to.equal(route);
        });

        it ("Should indicate that the origin tile is along the route", async function () {
                
            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Any);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("Should indicate that the neighbors of the origin tile are along the route", async function () {

            // Setup
            const neighborsOfOrigin = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighborsOfOrigin)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Any);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("Should indicate that an intermediate tile is along the route", async function () {
                
            // Setup
            const tileIndex = 19;
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Any);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("Should indicate that the neighbors of an intermediate tile are along the route", async function () {
                
            // Setup
            const tileIndex = 19;
            const routeIndex = 2; // Where the tile is packed in the route
            const neighborsOfTile = getNeighbors(tileIndex, map.sizeX, map.sizeZ);

            // Act
            for (let neighbor of neighborsOfTile)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Any);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("Should indicate that the destination tile is along the route", async function () {
                
            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Any);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("Should indicate that the neighbors of the destination tile are along the route", async function () {

            // Setup
            const neighborsOfDestination = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            for (let neighbor of neighborsOfDestination)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Any);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("Should not indicate that a tile is along the route if it is not", async function () {

            // Setup
            const tileIndex = 4;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Any);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("Should not indicate that a tile is along the route when it is but the route index is incorrect", async function () {
            
            // Setup
            const tileIndex = 19;
            const routeIndex = 1; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Any);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        // Check route progress

        it ("[progress:origin][target:origin] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:origin][target:origin] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:origin][target:origin] Should indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:origin][target:origin] Should indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:origin][target:origin] Should not indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:origin][target:origin] Should not indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:origin][target:halfway] Should indicate that target is at an upcoming position along the route", async function () {
            
            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:origin][target:halfway] Should indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:origin][target:halfway] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:origin][target:halfway] Should not indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:origin][target:halfway] Should not indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:origin][target:halfway] Should not indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:origin][target:destination] Should indicate that target is at an upcoming position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:origin][target:destination] Should indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:origin][target:destination] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:origin][target:destination] Should not indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:origin][target:destination] Should not indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex, 
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:origin][target:destination] Should not indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex, 
                    route, 
                    routeIndex, 
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        /**
         * Advance time to halfway through the route
         */
        it ("Should advance time to halfway through the route", async function () {

            // Setup
            const timeToHalfway = arrival - BigInt(turns * MapsSettings.MOVEMENT_TURN_DURATION / 2);

            // Act
            await time.increaseTo(timeToHalfway);

            // Assert
            expect(await time.latest()).to.equal(timeToHalfway);
        });

        it ("[progress:halfway][target:origin] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex, 
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:halfway][target:origin] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:halfway][target:origin] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:halfway][target:origin] Should not indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:halfway][target:origin] Should indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:halfway][target:origin] Should indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:halfway][target:halfway] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:halfway][target:halfway] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:halfway][target:halfway] Should indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:halfway][target:halfway] Should indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:halfway][target:halfway] Should not indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:halfway][target:halfway] Should not indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:halfway][target:destination] Should indicate that target is at an upcoming position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:halfway][target:destination] Should indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:halfway][target:destination] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:halfway][target:destination] Should not indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:halfway][target:destination] Should not indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:halfway][target:destination] Should not indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile
            
            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        /**
         * Advance time to the end of the route
         */
        it ("Should advance time to the end of the route", async function () {

            // Act
            await time.increaseTo(arrival);

            // Assert
            expect(await time.latest()).to.equal(arrival);
        });

        it ("[progress:destination][target:origin] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:destination][target:origin] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:destination][target:origin] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:destination][target:origin] Should not indicate that target neighbors are at the current position along the route", async function () {
            
            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:destination][target:origin] Should indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:destination][target:origin] Should indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:destination][target:halfway] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:destination][target:halfway] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:destination][target:halfway] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:destination][target:halfway] Should not indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:destination][target:halfway] Should indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:destination][target:halfway] Should indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:destination][target:destination] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:destination][target:destination] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route,
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:destination][target:destination] Should indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route,
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:destination][target:destination] Should indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route,
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:destination][target:destination] Should not indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route,
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:destination][target:destination] Should not indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route,
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        /**
         * Advance time to after the end of the route
         */
        it ("Should advance time to after the end of the route", async function () {

            // Setup
            const timeAfterArrival = arrival + BigInt(MapsSettings.MOVEMENT_TURN_DURATION);

            // Act
            await time.increaseTo(timeAfterArrival);

            // Assert
            expect(await time.latest()).to.equal(timeAfterArrival);
        });

        it ("[progress:beyond][target:origin] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:beyond][target:origin] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:beyond][target:origin] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:beyond][target:origin] Should not indicate that target neighbors are at the current position along the route", async function () {
            
            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:beyond][target:origin] Should indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = origin;
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:beyond][target:origin] Should indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(origin, map.sizeX, map.sizeZ);
            const routeIndex = 0; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:beyond][target:halfway] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:beyond][target:halfway] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:beyond][target:halfway] Should not indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:beyond][target:halfway] Should not indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:beyond][target:halfway] Should indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = 19; // Halfway
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:beyond][target:halfway] Should indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(19, map.sizeX, map.sizeZ);
            const routeIndex = 2; // Where the tile is packed in the route

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route, 
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:beyond][target:destination] Should not indicate that target is at an upcoming position along the route", async function () {
            
            // Setup 
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route, 
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Upcoming);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:beyond][target:destination] Should not indicate that target neighbors are at an upcoming position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route,
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Upcoming);

                // Assert
                expect(isAlongRoute).to.equal(false);
            }
        });

        it ("[progress:beyond][target:destination] Should indicate that target is at the current position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route,
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Current);

            // Assert
            expect(isAlongRoute).to.equal(true);
        });

        it ("[progress:beyond][target:destination] Should indicate that target neighbors are at the current position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route,
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Current);

                // Assert
                expect(isAlongRoute).to.equal(true);
            }
        });

        it ("[progress:beyond][target:destination] Should not indicate that target is at a passed position along the route", async function () {

            // Setup
            const tileIndex = destination;
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            const isAlongRoute = await mapInstance.tileIsAlongRoute(
                tileIndex,
                route,
                routeIndex,
                destination, 
                arrival,
                RoutePosition.Passed);

            // Assert
            expect(isAlongRoute).to.equal(false);
        });

        it ("[progress:beyond][target:destination] Should not indicate that target neighbors are at a passed position along the route", async function () {

            // Setup
            const neighbors = getNeighbors(destination, map.sizeX, map.sizeZ);
            const routeIndex = 4; // Setting it to the total amount of packed tiles indicates the destination tile

            // Act
            for (let neighbor of neighbors)
            {
                const isAlongRoute = await mapInstance.tileIsAlongRoute(
                    neighbor.tileIndex,
                    route,
                    routeIndex,
                    destination, 
                    arrival,
                    RoutePosition.Passed);

                // Assert
                expect(isAlongRoute).to.equal(false);
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

    interface Neighbor {
        tileIndex: bigint;
        direction: HexDirection;
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

    /**
     * Gets the neighbors of a tile
     * 
     * @param tileIndex Index of the tile to get the neighbors of
     * @param sizeX Map size in the X direction
     * @param sizeZ Map size in the Z direction
     * @returns The neighbors of the tile
     */
    const getNeighbors = (tileIndex: bigint | number, sizeX: number, sizeZ: number): Neighbor[] => {
        const neighbors: Neighbor[] = [];
        const bigTileIndex = BigInt(tileIndex);
        const x = bigTileIndex % BigInt(sizeX);
        const z = bigTileIndex / BigInt(sizeX);
        const isEvenRow = z % BigInt(2) === BigInt(0);
    
        // NorthEast
        if (z < BigInt(sizeZ) - BigInt(1) && (isEvenRow || x < BigInt(sizeX) - BigInt(1))) {
            neighbors.push({ tileIndex: bigTileIndex + BigInt(sizeX) + (isEvenRow ? BigInt(0) : BigInt(1)), direction: HexDirection.NE });
        }
    
        // East
        if (x < BigInt(sizeX) - BigInt(1)) {
            neighbors.push({ tileIndex: bigTileIndex + BigInt(1), direction: HexDirection.E });
        }
    
        // SouthEast
        if (z > BigInt(0) && (isEvenRow || x < BigInt(sizeX) - BigInt(1))) {
            neighbors.push({ tileIndex: bigTileIndex - BigInt(sizeX) + (isEvenRow ? BigInt(0) : BigInt(1)), direction: HexDirection.SE });
        }
    
        // SouthWest
        if (z > BigInt(0) && (!isEvenRow || x > BigInt(0))) {
            neighbors.push({ tileIndex: bigTileIndex - BigInt(sizeX) - (isEvenRow ? BigInt(1) : BigInt(0)), direction: HexDirection.SW });
        }
    
        // West
        if (x > BigInt(0)) {
            neighbors.push({ tileIndex: bigTileIndex - BigInt(1), direction: HexDirection.W });
        }
    
        // NorthWest
        if (z < BigInt(sizeZ) - BigInt(1) && (!isEvenRow || x > BigInt(0))) {
            neighbors.push({ tileIndex: bigTileIndex + BigInt(sizeX) - (isEvenRow ? BigInt(1) : BigInt(0)), direction: HexDirection.NW });
        }

        return neighbors;
    }
});