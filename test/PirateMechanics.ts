import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { BytesLike } from "ethers";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { getParamFromEvent} from '../scripts/helpers/events';
import { REVERT_MODE, PLAYER_IDLE_TIME, MOVEMENT_TURN_DURATION, BASE_FUEL_COST } from "./settings/config";
import { DEFAULT_ADMIN_ROLE, SYSTEM_ROLE, MINTER_ROLE } from "./settings/roles";   
import { ZERO_ADDRESS } from "./settings/constants";
import { Resource, Terrain, Biome, Inventory } from '../scripts/types/enums';
import { Asset, Map } from "../scripts/types/input";

import { 
    CryptopiaAccount,
    CryptopiaMaps,
    CryptopiaAssetToken,
    CryptopiaShipToken,
    CryptopiaTitleDeedToken,
    CryptopiaPlayerRegister,
    CryptopiaInventories,
    CryptopiaPirateMechanics,
} from "../typechain-types";

/**
 * Pirate Mechanics tests
 * 
 * Test cases:
 * - Intercept
 */
describe("PirateMechanics Contract", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let account2: string;
    let account3: string;
    let account4: string;
    let treasury: string;

    // Instances
    let mapInstance: CryptopiaMaps;
    let fuelAssetInstance: CryptopiaAssetToken;
    let shipTokenInstance: CryptopiaShipToken;
    let titleDeedTokenInstance: CryptopiaTitleDeedToken;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let pirateMechanicsInstance: CryptopiaPirateMechanics;

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
        },
        {
            symbol: "FUEL",
            name: "Fuel",
            resource: 16,
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
     * Deploy Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, account2, account3, account4, treasury] = (
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
        const PirateMechanicsFactory = await ethers.getContractFactory("CryptopiaPirateMechanics");
        
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

            if (asset.resource == Resource.Fuel)
            {
                fuelAssetInstance = asset.contractInstance;
            }
        }

        // Deploy Pirate Mechanics
        const pirateMechanicsProxy = await (
            await upgrades.deployProxy(
                PirateMechanicsFactory, 
                [
                    treasury,
                    playerRegisterAddress,
                    assetRegisterAddress,
                    mapsAddress,
                    shipTokenAddress,
                    await fuelAssetInstance.getAddress(),
                    inventoriesAddress
                ])
        ).waitForDeployment();

        const pirateMechanicsAddress = await pirateMechanicsProxy.getAddress();
        pirateMechanicsInstance = await ethers.getContractAt("CryptopiaPirateMechanics", pirateMechanicsAddress);

        // Grant roles
        await inventoriesInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);


        // Create map 
        await mapInstance.createMap(
            map.name, map.sizeX, map.sizeZ);

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
    });

    /**
     * Test Pirate Mechanics
     */
    describe("Intercept", function () {

        // Players
        let pirateAccountInstance: CryptopiaAccount;
        let targetAccountInstance: CryptopiaAccount;
        let anotherPirateAccountInstance: CryptopiaAccount;
        let anotherTargetAccountInstance: CryptopiaAccount;

        /**
         * Deploy players
         */
        before(async () => {

            // Create pirate account
            const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Pirate".toBytes32(), 0, 0);
            const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
            const pirateAccount = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
            pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccount);

            // Create target account
            const createTargetAccountTransaction = await playerRegisterInstance.create([account2], 1, 0, "Target".toBytes32(), 0, 0);
            const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
            const targetAccount = getParamFromEvent(playerRegisterInstance, createTargetAccountReceipt, "account", "RegisterPlayer");
            targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccount);

            // Create another rpirate account
            const createAnotherPirateAccountTransaction = await playerRegisterInstance.create([account3], 1, 0, "Another_Pirate".toBytes32(), 0, 0);
            const createAnotherPirateAccountReceipt = await createAnotherPirateAccountTransaction.wait();
            const anotherPirateAccount = getParamFromEvent(playerRegisterInstance, createAnotherPirateAccountReceipt, "account", "RegisterPlayer");
            anotherPirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", anotherPirateAccount);

            // Create another target account
            const createAnotherTargetAccountTransaction = await playerRegisterInstance.create([account4], 1, 0, "Another_Target".toBytes32(), 0, 0);
            const createAnotherTargetAccountReceipt = await createAnotherTargetAccountTransaction.wait();
            const targetAnotherAccount = getParamFromEvent(playerRegisterInstance, createAnotherTargetAccountReceipt, "account", "RegisterPlayer");
            anotherTargetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAnotherAccount);

            // Add another pirate and target to the map
            const playerEnterCalldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            await anotherPirateAccountInstance
                .connect(await ethers.provider.getSigner(account3))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

            await anotherTargetAccountInstance
                .connect(await ethers.provider.getSigner(account4))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);
        });
        
        it ("Should not allow a pirate to intercept while entered the map", async function () {

            // Setup
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountAddress = await targetAccountInstance.getAddress();

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation =  pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(pirateMechanicsInstance, "AttackerNotInMap")
                .withArgs(pirateAccountAddress);
        }); 

        it ("Should not allow a pirate to intercept while traveling", async function () {

            // Setup 
            const turns = 1;
            const path = [
                0, // Turn 1 (packed)
                1  // Turn 1 
            ];

            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const playerEnterCalldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerEnterCalldata);

            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);

            // Act
            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation =  pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "AttackerIsTraveling")
                    .withArgs(pirateAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup
            await time.increase(turns * MOVEMENT_TURN_DURATION);
        });

        it ("Should not allow a pirate to intercept from a location that's not on the water", async function () {

            // Setup
            const path = [
                1, // Turn 1 (packed)
                2, // Turn 1 
                7  // Turn 2 (Land adjacent to water)
            ];

            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);
            
            const playerMoveTransaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);

            const playerMoveReceipt = await playerMoveTransaction.wait();
            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(arrival);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "AttackerNotEmbarked")
                    .withArgs(pirateAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup (revert to start location)
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[7, 2, 1, 0]]);
            
            const revertMoveTransaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);

            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");
                
            await time.increaseTo(revertArrival);   
        });

        it ("Should not allow a pirate to intercept a target that did not enter the map", async function () {

            // Setup
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation =  pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(pirateMechanicsInstance, "TargetNotInMap")
                .withArgs(targetAccountAddress);
        });

        it ("Should not allow a pirate to intercept a target that's not on the water", async function () {

            // Setup
            const path = [
                0, // Turn 1 (packed)
                1, // Turn 1
                2, // Turn 1 
                7  // Turn 2 (Land adjacent to water)
            ];

            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const playerEnterCalldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerEnterCalldata);

            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);
            
            const playerMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);

            const playerMoveReceipt = await playerMoveTransaction.wait();
            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(arrival);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "TargetNotEmbarked")
                    .withArgs(targetAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup (revert to start location)
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[7, 2, 1, 0]]);
            
            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);

            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");
                
            await time.increaseTo(revertArrival);   
        });

        it ("Should not allow a pirate to intercept a target at a stationary location that's not reachable", async function () {

            // Setup
            const path = [
                0, // Turn 1 (packed)
                1, // Turn 1
                2  // Turn 1 (Water tile not ajacent to pirate)
            ];

            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);
            
            const playerMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);

            const playerMoveReceipt = await playerMoveTransaction.wait();
            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(arrival);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "TargetNotReachable")
                    .withArgs(pirateAccountAddress, targetAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup (revert to start location)
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[2, 1, 0]]);
            
            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);

            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");
                
            await time.increaseTo(revertArrival);   
        });

        it ("Should not allow a pirate to intercept a target that's traveling from a location that the target has already passed", async function () {

            // Setup
            const path = [
                0,  // Turn 1 (packed)
                5,  // Turn 1
                10, // Turn 1
                15, // Turn 1 (packed)
                20, // Turn 1
                21, // Turn 2
            ];

            const turns = 2;
            const totalTilesPacked = 2;
            const totalTravelTime = turns * MOVEMENT_TURN_DURATION;
            const interceptionWindowInSeconds = totalTravelTime / totalTilesPacked / 2;

            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);
            
            const playerMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);

            const playerMoveReceipt = await playerMoveTransaction.wait();
            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");

            // Increase time to move the target out of reach of the pirate
            await time.increase(interceptionWindowInSeconds + 1);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "TargetNotReachable")
                    .withArgs(pirateAccountAddress, targetAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup (revert to start location)
            await time.increaseTo(arrival)

            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[21, 20, 15, 10, 5, 0]]);
            
            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);

            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");
                
            await time.increaseTo(revertArrival);   
        });

        it ("Should not allow a pirate to intercept a target that's traveling with insufficient fuel", async function () {

            // Setup
            const path = [
                0,  // Turn 1 (packed)
                5,  // Turn 1
                10, // Turn 1
                15, // Turn 1 (packed)
                20, // Turn 1
                21, // Turn 1
                22, // Turn 2
            ];

            const turns = 2;
            const totalTilesPacked = 2;
            const totalTravelTime = turns * MOVEMENT_TURN_DURATION;
            const interceptionWindowInSeconds = totalTravelTime / totalTilesPacked / 2;

            const mapContractAddress = await mapInstance.getAddress();
            const fuelAssetAddress = await fuelAssetInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();
            const strartingTime = await time.latest();

            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            const playerMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);
            const playerMoveReceipt = await playerMoveTransaction.wait();
            
            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");

            // Increase time but not engough to move the target out of reach of the pirate
            await time.increaseTo(strartingTime + interceptionWindowInSeconds - 1);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(inventoriesInstance, "InventoryInsufficientBalance")
                    .withArgs(pirateAccountAddress, Inventory.Ship, fuelAssetAddress, BASE_FUEL_COST);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup (revert to start location)
            await time.increaseTo(arrival);

            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[22, 21, 20, 15, 10, 5, 0]]);

            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);
                
            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(revertArrival);
        });

        it ("Should allow a pirate to intercept a target thats traveling with sufficient fuel", async function () {

            // Setup
            const path = [
                0,  // Turn 1 (packed)
                5,  // Turn 1
                10, // Turn 1
                15, // Turn 1 (packed)
                20, // Turn 1
                21, // Turn 1
                22, // Turn 2
            ];

            const turns = 2;
            const totalTilesPacked = 2;
            const totalTravelTime = turns * MOVEMENT_TURN_DURATION;
            const interceptionWindowInSeconds = totalTravelTime / totalTilesPacked / 2;

            const mapContractAddress = await mapInstance.getAddress();
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const fuelAssetAddress = await fuelAssetInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const minterSigner = await ethers.provider.getSigner(minter);
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();
            const strartingTime = await time.latest();

            // Ensure the pirate has enough fuel
            await fuelAssetInstance
                .connect(minterSigner)
                .mintTo(inventoriesAddress, BASE_FUEL_COST);

            await inventoriesInstance
                .connect(systemSigner)
                .assignFungibleToken(pirateAccountAddress, Inventory.Ship, fuelAssetAddress, BASE_FUEL_COST);

            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);

            // Increase time but not engough to move the target out of reach of the pirate
            await time.increaseTo(strartingTime + interceptionWindowInSeconds - 1);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            await expect(operation).to
                .emit(pirateMechanicsInstance, "PirateInterception")
                .withArgs(pirateAccountAddress, targetAccountAddress, 0);
        }); 

        it ("Should not allow a pirate to intercept a target that's already been intercepted", async function () {

            // Setup
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const fuelAssetAddress = await fuelAssetInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const minterSigner = await ethers.provider.getSigner(minter);
            const anotherPirateAccountSigner = await ethers.provider.getSigner(account3);
            const anotherPirateAccountAddress = await anotherPirateAccountInstance.getAddress();
            const targetAccountAddress = await targetAccountInstance.getAddress();
            
            // Ensure the pirate has enough fuel
            await fuelAssetInstance
                .connect(minterSigner)
                .mintTo(inventoriesAddress, BASE_FUEL_COST);

            await inventoriesInstance
                .connect(systemSigner)
                .assignFungibleToken(anotherPirateAccountAddress, Inventory.Ship, fuelAssetAddress, BASE_FUEL_COST);

            // Act 
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const operation = anotherPirateAccountInstance
                .connect(anotherPirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "TargetAlreadyIntercepted")
                    .withArgs(targetAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not allow a pirate to intercept another target while already intercepting a target", async function () {

            // Setup
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const anotherTargetAccountAddress = await anotherTargetAccountInstance.getAddress();
            
            // Act 
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [anotherTargetAccountAddress, 0]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "AttackerAlreadyIntercepting")
                    .withArgs(pirateAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not allow a pirate to intercept an idle target from an adjacent tile", async function () {

            // Setup
            const path = [
                0,  // Turn 1 (packed)
                5   // Turn 1 (Ajeacent to target)
            ];

            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const anotherPirateAccountSigner = await ethers.provider.getSigner(account3);
            const anotherTargetAccountAddress = await anotherTargetAccountInstance.getAddress();
    
            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            const playerMovetransaction = await anotherPirateAccountInstance
                .connect(anotherPirateAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);
            const playerMoveReceipt = await playerMovetransaction.wait();

            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");
            await time.increaseTo(arrival);

            // Ensure the target is idle
            await time.increase(PLAYER_IDLE_TIME);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [anotherTargetAccountAddress, 0]);

            const operation = anotherPirateAccountInstance
                .connect(anotherPirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "TargetIsIdle")
                    .withArgs(anotherTargetAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup (revert to start location)
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[5, 0]]);

            const revertMoveTransaction = await anotherPirateAccountInstance
                .connect(anotherPirateAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);
                
            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(revertArrival);
        });

        it ("Should allow a pirate to intercept a target statinary from an adjacent tile", async function () {

            // Setup
            const path = [
                0,  // Turn 1 (packed)
                5   // Turn 1 (Ajeacent to pirate)
            ];

            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const anotherPirateAccountSigner = await ethers.provider.getSigner(account3);
            const anotherPirateAccountAddress = await anotherPirateAccountInstance.getAddress();
            const anotherTargetAccountSigner = await ethers.provider.getSigner(account4);
            const anotherTargetAccountAddress = await anotherTargetAccountInstance.getAddress();
    
            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            const playerMovetransaction = await anotherTargetAccountInstance
                .connect(anotherTargetAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);
            const playerMoveReceipt = await playerMovetransaction.wait();

            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");
            await time.increaseTo(arrival);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [anotherTargetAccountAddress, 0]);

            const operation = anotherPirateAccountInstance
                .connect(anotherPirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            await expect(operation).to
                .emit(pirateMechanicsInstance, "PirateInterception")
                .withArgs(anotherPirateAccountAddress, anotherTargetAccountAddress, path[0]);
        });
    });
});