import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { getParamFromEvent, containsEvent } from '../scripts/helpers/events';
import { getTransferProposalSignature } from "../scripts/helpers/meta";
import { TransferProposal } from "../scripts/types/meta";
import { ZERO_ADDRESS } from "./settings/constants";
import { REVERT_MODE, MapsSettings, PirateMechanicsConfig } from "./settings/config";
import { SYSTEM_ROLE } from "./settings/roles";   
import { Resource, Terrain, Biome, Inventory } from '../scripts/types/enums';
import { Asset, Map } from "../scripts/types/input";

import { 
    CryptopiaAccount,
    CryptopiaMaps,
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
 * - Negotiate
 * - Escape
 * - Quick battle
 * - Turn based battle
 */
describe("PirateMechanics Contract", function () {

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
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.Reef, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            
            // Second row
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 7, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: true, resource1_type: Resource.Iron, resource1_amount: "10000".toWei(), resource2_type: Resource.Gold, resource2_amount: "500".toWei(), resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            
            // Third row
            { group: 0, biome: Biome.Reef, terrain: Terrain.Water, elevation: 4, waterLevel: 5, vegitationLevel: 2, rockLevel: 0, wildlifeLevel: 2, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Mountains, elevation: 8, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: Resource.Gold, resource1_amount: "1000".toWei(), resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },

            // Fourth row
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 1, wildlifeLevel: 1, riverFlags: 0, hasRoad: true, hasLake: false, resource1_type: Resource.Iron, resource1_amount: "20000".toWei(), resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 1, biome: Biome.RainForest, terrain: Terrain.Flat, elevation: 5, waterLevel: 5, vegitationLevel: 1, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.Reef, terrain: Terrain.Water, elevation: 4, waterLevel: 5, vegitationLevel: 3, rockLevel: 0, wildlifeLevel: 3, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 1, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },

            // Top row
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 3, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
            { group: 0, biome: Biome.None, terrain: Terrain.Water, elevation: 2, waterLevel: 5, vegitationLevel: 0, rockLevel: 0, wildlifeLevel: 0, riverFlags: 0, hasRoad: false, hasLake: false, resource1_type: 0, resource1_amount: "0", resource2_type: 0, resource2_amount: "0", resource3_type: 0, resource3_amount: "0" },
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
                    getAssetByResource(
                        Resource.Fuel).contractAddress,
                    inventoriesAddress
                ])
        ).waitForDeployment();

        const pirateMechanicsAddress = await pirateMechanicsProxy.getAddress();
        pirateMechanicsInstance = await ethers.getContractAt("CryptopiaPirateMechanics", pirateMechanicsAddress);

        // Grant roles
        await playerRegisterInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
        await shipTokenInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
        await mapInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);

        // Create map 
        await mapInstance.createMap(
            map.name, map.sizeX, map.sizeZ);

        await mapInstance.setTiles(
            map.tiles.map((_, index) => index), 
            map.tiles.map(tile => ({
                initialized: true, 
                mapIndex: 0,
                group: tile.group,
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
     * Test intercepting a target
     */
    describe("Intercepting", function () {

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
            const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Intercepting_Pirate".toBytes32(), 0, 0);
            const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
            const pirateAccount = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
            pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccount);

            // Create target account
            const createTargetAccountTransaction = await playerRegisterInstance.create([account2], 1, 0, "Intercepted_Target".toBytes32(), 0, 0);
            const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
            const targetAccount = getParamFromEvent(playerRegisterInstance, createTargetAccountReceipt, "account", "RegisterPlayer");
            targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccount);

            // Create another rpirate account
            const createAnotherPirateAccountTransaction = await playerRegisterInstance.create([account3], 1, 0, "Another_Intercepting_Pirate".toBytes32(), 0, 0);
            const createAnotherPirateAccountReceipt = await createAnotherPirateAccountTransaction.wait();
            const anotherPirateAccount = getParamFromEvent(playerRegisterInstance, createAnotherPirateAccountReceipt, "account", "RegisterPlayer");
            anotherPirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", anotherPirateAccount);

            // Create another target account
            const createAnotherTargetAccountTransaction = await playerRegisterInstance.create([account4], 1, 0, "Another_Intercepted_Target".toBytes32(), 0, 0);
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
            await time.increase(turns * MapsSettings.MOVEMENT_TURN_DURATION);
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
            const totalTravelTime = turns * MapsSettings.MOVEMENT_TURN_DURATION;
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
            const totalTravelTime = turns * MapsSettings.MOVEMENT_TURN_DURATION;
            const interceptionWindowInSeconds = totalTravelTime / totalTilesPacked / 2;

            const fuelAsset = getAssetByResource(Resource.Fuel);
            const mapContractAddress = await mapInstance.getAddress();
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
                    .withArgs(pirateAccountAddress, Inventory.Ship, fuelAsset.contractAddress, PirateMechanicsConfig.BASE_FUEL_COST);
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
            const totalTravelTime = turns * MapsSettings.MOVEMENT_TURN_DURATION;
            const interceptionWindowInSeconds = totalTravelTime / totalTilesPacked / 2;

            const fuelAsset = getAssetByResource(Resource.Fuel);
            const mapContractAddress = await mapInstance.getAddress();
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();
            const strartingTime = await time.latest();
            
            // Ensure the pirate has enough fuel
            await fuelAsset.contractInstance
                ?.connect(systemSigner)
                 .__mintTo(inventoriesAddress, PirateMechanicsConfig.BASE_FUEL_COST);

            await inventoriesInstance
                .connect(systemSigner)
                .__assignFungibleToken(pirateAccountAddress, Inventory.Ship, fuelAsset.contractAddress, PirateMechanicsConfig.BASE_FUEL_COST);

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

            const transaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            const expectedDeadline = await time.latest() + PirateMechanicsConfig.MAX_RESPONSE_TIME;
            const expectedExpiration = expectedDeadline + PirateMechanicsConfig.MAX_RESPONSE_TIME;

            // Assert
            await expect(transaction).to
                .emit(pirateMechanicsInstance, "PirateConfrontationStart")
                .withArgs(pirateAccountAddress, targetAccountAddress, 0, expectedDeadline, expectedExpiration);
        }); 

        it ("Should not allow a pirate to intercept a target that's already been intercepted", async function () {

            // Setup
            const fuelAsset = getAssetByResource(Resource.Fuel);
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const anotherPirateAccountSigner = await ethers.provider.getSigner(account3);
            const anotherPirateAccountAddress = await anotherPirateAccountInstance.getAddress();
            const targetAccountAddress = await targetAccountInstance.getAddress();
            
            // Ensure the pirate has enough fuel
            await fuelAsset.contractInstance
                ?.connect(systemSigner)
                 .__mintTo(inventoriesAddress, PirateMechanicsConfig.BASE_FUEL_COST);

            await inventoriesInstance
                .connect(systemSigner)
                .__assignFungibleToken(anotherPirateAccountAddress, Inventory.Ship, fuelAsset.contractAddress, PirateMechanicsConfig.BASE_FUEL_COST);

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
            await time.increase(MapsSettings.PLAYER_IDLE_TIME);

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

        it("Should not mark the attakcer as pirate before intercepting a target", async function () {

            // Setup
            const anotherPirateAccountAddress = await anotherPirateAccountInstance.getAddress();

            // Act
            const isPirate = await playerRegisterInstance
                .isPirate(anotherPirateAccountAddress);

            // Assert
            expect(isPirate).to.be.false;
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

            const transaction = await anotherPirateAccountInstance
                .connect(anotherPirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            const expectedDeadline = await time.latest() + PirateMechanicsConfig.MAX_RESPONSE_TIME;
            const expectedExpiration = expectedDeadline + PirateMechanicsConfig.MAX_RESPONSE_TIME;

            // Assert
            await expect(transaction).to
                .emit(pirateMechanicsInstance, "PirateConfrontationStart")
                .withArgs(anotherPirateAccountAddress, anotherTargetAccountAddress, path[0], expectedDeadline, expectedExpiration);
        });

        it("Should freeze the target's inventories when intercepted", async function () {

            // Setup
            const anotherTargetAccountAddress = await anotherTargetAccountInstance.getAddress();

            // Act
            const isFrozen = await inventoriesInstance
                .isFrozen(anotherTargetAccountAddress);

            // Assert
            expect(isFrozen).to.be.true;
        });

        it("Should freeze the target in the map when intercepted", async function () {
            
            // Setup
            const anotherTargetAccountAddress = await anotherTargetAccountInstance.getAddress();
            
            // Act
            const mapPlayerData = await mapInstance
                .getPlayerData(anotherTargetAccountAddress);
            
            const confrontationData = await pirateMechanicsInstance
                .getConfrontation(anotherTargetAccountAddress);

            // Assert 
            expect(mapPlayerData.frozenUntil).to.equal(confrontationData.expiration);
        });

        it("Should freeze the pirate in the map when intercepted", async function () {
            
            // Setup
            const anotherPirateAccountAddress = await anotherPirateAccountInstance.getAddress();
            const anotherTargetAccountAddress = await anotherTargetAccountInstance.getAddress();
            
            // Act
            const mapPlayerData = await mapInstance
                .getPlayerData(anotherPirateAccountAddress);
            
            const confrontationData = await pirateMechanicsInstance
                .getConfrontation(anotherTargetAccountAddress);

            // Assert 
            expect(mapPlayerData.frozenUntil).to.equal(confrontationData.expiration);
        });

        it("Should mark the attakcer as pirate after intercepting a target", async function () {

            // Setup
            const anotherPirateAccountAddress = await anotherPirateAccountInstance.getAddress();

            // Act
            const isPirate = await playerRegisterInstance
                .isPirate(anotherPirateAccountAddress);

            // Assert
            expect(isPirate).to.be.true;
        });

        it ("Should not allow a pirate to intercept another pirate", async function () {

            // Setup
            const path = [
                0,  // Turn 1 (packed)
                5   // Turn 1 
            ];

            // Setup 
            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const anotherPirateAccountSigner = await ethers.provider.getSigner(account3);
            const anotherPirateAccountAddress = await anotherPirateAccountInstance.getAddress();
            const anotherTargetAccountSigner = await ethers.provider.getSigner(account4);
            const anotherTargetAccountAddress = await anotherTargetAccountInstance.getAddress();
            
            // End previous confrontation
            const confrontation = await pirateMechanicsInstance
                .getConfrontation(anotherTargetAccountAddress);

            await time.increaseTo(confrontation.expiration);

            // Ensure not idle
            const playerMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [path]);

            const playerMovetransaction = await anotherPirateAccountInstance
                .connect(anotherPirateAccountSigner)
                .submitTransaction(mapContractAddress, 0, playerMoveCalldata);
            const playerMoveReceipt = await playerMovetransaction.wait();

            const arrival = getParamFromEvent(
                mapInstance, playerMoveReceipt, "arrival", "PlayerMove");
            await time.increaseTo(arrival);

            // Act
            const calldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [anotherPirateAccountAddress, 0]);

            const operation = anotherTargetAccountInstance
                .connect(anotherTargetAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, calldata);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(pirateMechanicsInstance, "TargetIsPirate")
                .withArgs(anotherPirateAccountAddress);
        });
    });

    /**
     * Test resolving a confrontation through negotiation
     */
    describe("Negotiating", function () {

        // Players
        let pirateAccountInstance: CryptopiaAccount;
        let targetAccountInstance: CryptopiaAccount;

        /**
         * Deploy players
         */
        before(async () => {

            // Create pirate account
            const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Negotiating_Pirate".toBytes32(), 0, 0);
            const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
            const pirateAccount = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
            pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccount);

            // Create target account
            const createTargetAccountTransaction = await playerRegisterInstance.create([account2], 1, 0, "Negotiating_Target".toBytes32(), 0, 0);
            const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
            const targetAccount = getParamFromEvent(playerRegisterInstance, createTargetAccountReceipt, "account", "RegisterPlayer");
            targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccount);

            // Add another pirate and target to the map
            const playerEnterCalldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            await pirateAccountInstance
                .connect(await ethers.provider.getSigner(account1))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

            await targetAccountInstance
                .connect(await ethers.provider.getSigner(account2))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);
        });

        it ("Should not accept an offer when the target was not intercepted", async function () {

            // Setup
            const ironAsset = getAssetByResource(Resource.Iron);
            const goldAsset = getAssetByResource(Resource.Gold);
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            // Create proposal
            const proposal: TransferProposal = {
                from: targetAccountAddress,
                to: pirateAccountAddress,
                inventories: [Inventory.Ship, Inventory.Backpack],
                assets: [ironAsset.contractAddress, goldAsset.contractAddress],
                amounts: ["2".toWei(), "1".toWei()],
                tokenIds: [0, 0],
                deadline: 0
            }

            const signatures = await getTransferProposalSignature(
                targetAccountSigner, 
                pirateMechanicsAddress,
                0,
                proposal);

            // Act
            const acceptOfferCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("acceptOffer", [
                    [signatures], 
                    proposal.inventories, 
                    [Inventory.Ship, Inventory.Ship], 
                    proposal.assets, 
                    proposal.amounts, 
                    proposal.tokenIds]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, acceptOfferCalldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "ConfrontationNotFound")
                    .withArgs(pirateAccountAddress, ZERO_ADDRESS);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not accept an offer when the dealine for the target to respond expired", async function () {

            // Setup
            const ironAsset = getAssetByResource(Resource.Iron);
            const goldAsset = getAssetByResource(Resource.Gold);
            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const interceptTransaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
            const interceptReceipt = await interceptTransaction.wait();

            const deadline = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "deadline", "PirateConfrontationStart");
            const expiration = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "expiration", "PirateConfrontationStart");

            // Create proposal
            const proposal: TransferProposal = {
                from: targetAccountAddress,
                to: pirateAccountAddress,
                inventories: [Inventory.Ship, Inventory.Backpack],
                assets: [ironAsset.contractAddress, goldAsset.contractAddress],
                amounts: ["2".toWei(), "1".toWei()],
                tokenIds: [0, 0],
                deadline: deadline
            }

            const signatures = await getTransferProposalSignature(
                targetAccountSigner, 
                pirateMechanicsAddress,
                0,
                proposal);

            // Act
            await time.increaseTo(deadline + BigInt(1));

            const acceptOfferCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("acceptOffer", [
                    [signatures], 
                    proposal.inventories, 
                    [Inventory.Ship, Inventory.Ship], 
                    proposal.assets, 
                    proposal.amounts, 
                    proposal.tokenIds]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, acceptOfferCalldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "ResponseTimeExpired")
                    .withArgs(targetAccountAddress, deadline);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup
            await time.increaseTo(expiration);

            // Move target to new location
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[0, 1]]);

            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);
                
            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(revertArrival);
        });

        it ("Should not accept an offer when the target has insufficient assets", async function () {

            // Setup
            const ironAsset = getAssetByResource(Resource.Iron);
            const goldAsset = getAssetByResource(Resource.Gold);
            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const interceptTransaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
            const interceptReceipt = await interceptTransaction.wait();

            const deadline = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "deadline", "PirateConfrontationStart");
            const expiration = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "expiration", "PirateConfrontationStart");

            // Create proposal
            const proposal: TransferProposal = {
                from: targetAccountAddress,
                to: pirateAccountAddress,
                inventories: [Inventory.Ship, Inventory.Backpack],
                assets: [ironAsset.contractAddress, goldAsset.contractAddress],
                amounts: ["2".toWei(), "1".toWei()],
                tokenIds: [0, 0],
                deadline: deadline
            }

            const signatures = await getTransferProposalSignature(
                targetAccountSigner, 
                pirateMechanicsAddress,
                0,
                proposal);

            // Act
            const acceptOfferCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("acceptOffer", [
                    [signatures], 
                    proposal.inventories, 
                    [Inventory.Ship, Inventory.Ship], 
                    proposal.assets, 
                    proposal.amounts, 
                    proposal.tokenIds]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, acceptOfferCalldata);

            // Assert
            if (REVERT_MODE)
            {
                const expectedDeductedAmount = BigInt(proposal.amounts[0]) 
                    * BigInt(PirateMechanicsConfig.BASE_NEGOTIATION_DEDUCTION_FACTOR) 
                    / BigInt(PirateMechanicsConfig.BASE_NEGOTIATION_DEDUCTION_FACTOR_PRECISION);
                await expect(operation).to.be
                    .revertedWithCustomError(inventoriesInstance, "InventoryInsufficientBalance")
                    .withArgs(targetAccountAddress, proposal.inventories[0], ironAsset.contractAddress, expectedDeductedAmount);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup
            await time.increaseTo(expiration);

            // Move target to new location
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[1, 0]]);

            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);
                
            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(revertArrival);
        });

        it ("Should allow a pirate to accept an offer from the targed", async function () {

            // Setup
            const ironAsset = getAssetByResource(Resource.Iron);
            const goldAsset = getAssetByResource(Resource.Gold);
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const interceptTransaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
            const interceptReceipt = await interceptTransaction.wait();

            const deadline = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "deadline", "PirateConfrontationStart");

            // Create proposal
            const proposal: TransferProposal = {
                from: targetAccountAddress,
                to: pirateAccountAddress,
                inventories: [Inventory.Ship, Inventory.Backpack],
                assets: [ironAsset.contractAddress, goldAsset.contractAddress],
                amounts: ["2".toWei(), "1".toWei()],
                tokenIds: [0, 0],
                deadline: deadline
            }

            const signatures = await getTransferProposalSignature(
                targetAccountSigner, 
                pirateMechanicsAddress,
                0,
                proposal);

            // Ensure target has enough assets
            await ironAsset.contractInstance
                ?.connect(systemSigner)
                .__mintTo(inventoriesAddress, proposal.amounts[0]);
            
            await goldAsset.contractInstance
                ?.connect(systemSigner)
                .__mintTo(inventoriesAddress, proposal.amounts[1]);

            await inventoriesInstance
                .connect(systemSigner)
                .__assign(
                    targetAccountAddress, 
                    proposal.inventories, 
                    proposal.assets,
                    proposal.amounts,
                    proposal.tokenIds);

            // Act
            const acceptOfferCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("acceptOffer", [
                    [signatures], 
                    proposal.inventories, 
                    [Inventory.Ship, Inventory.Ship], 
                    proposal.assets, 
                    proposal.amounts, 
                    proposal.tokenIds]);

            const operation = pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, acceptOfferCalldata);

            // Assert
            await expect(operation).to
                .emit(pirateMechanicsInstance, "PirateConfrontationEnd")
                .withArgs(pirateAccountAddress, targetAccountAddress, 0);
        });

        it("Should transfer the correct amount of assets from the target to the pirate taking charisma into account", async function () {

            // Setup 
            const expectedIronBalance = "1".toWei(); // Deduct 50% for charisma
            const expectedGoldBalance = "0.5".toWei(); // Deduct 50% for charisma

            const ironAsset = getAssetByResource(Resource.Iron);
            const goldAsset = getAssetByResource(Resource.Gold);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();

            // Act
            const pirateEquipedShip = await playerRegisterInstance
                .getEquippedShip(pirateAccountAddress);

            const actualPirateIronBalance = await inventoriesInstance
                .getShipBalanceFungible(pirateEquipedShip, ironAsset.contractAddress);

            const actualPirateGoldBalance = await inventoriesInstance
                .getShipBalanceFungible(pirateEquipedShip, goldAsset.contractAddress);

            // Assert
            expect(actualPirateIronBalance).to.equal(expectedIronBalance);
            expect(actualPirateGoldBalance).to.equal(expectedGoldBalance);
        });

        it("Should unfreeze the target's inventories after accepting the offer", async function () {

            // Setup
            const targetAccountAddress = await targetAccountInstance.getAddress();

            // Act
            const isFrozen = await inventoriesInstance
                .isFrozen(targetAccountAddress);

            // Assert
            expect(isFrozen).to.be.false;
        });

        it("Should unfreeze the target in the map when intercepted", async function () {
            
            // Setup
            const targetAccountAddress = await targetAccountInstance.getAddress();
            
            // Act
            const mapPlayerData = await mapInstance
                .getPlayerData(targetAccountAddress);
 
            // Assert 
            expect(mapPlayerData.frozenUntil).to.equal(0);
        });

        it("Should freeze the pirate in the map when intercepted", async function () {
            
            // Setup
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            
            // Act
            const mapPlayerData = await mapInstance
                .getPlayerData(pirateAccountAddress);

            // Assert 
            expect(mapPlayerData.frozenUntil).to.equal(0);
        });
    });

    /**
     * Test resolving a confrontation through escaping
     */
    describe("Escaping", function () { 

        // Players
        let pirateAccountInstance: CryptopiaAccount;
        let targetAccountInstance: CryptopiaAccount;

        /**
         * Deploy players
         */
        before(async () => {

            // Create pirate account
            const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Escaping_Pirate".toBytes32(), 0, 0);
            const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
            const pirateAccount = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
            pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccount);

            // Create target account
            const createTargetAccountTransaction = await playerRegisterInstance.create([account2], 1, 0, "Escaping_Target".toBytes32(), 0, 0);
            const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
            const targetAccount = getParamFromEvent(playerRegisterInstance, createTargetAccountReceipt, "account", "RegisterPlayer");
            targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccount);

            // Add another pirate and target to the map
            const playerEnterCalldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            await pirateAccountInstance
                .connect(await ethers.provider.getSigner(account1))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

            await targetAccountInstance
                .connect(await ethers.provider.getSigner(account2))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);
        });

        it ("Should not allow a target to attempt an escape when the target was not intercepted", async function () {

            // Setup
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            // Act
            const attemptEscapeCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("attemptEscape");

            const operation = targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, attemptEscapeCalldata);
            
            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "ConfrontationNotFound")
                    .withArgs(ZERO_ADDRESS, targetAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not allow a target to attempt an escape when the dealine for the target to respond expired", async function () {

            // Setup
            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const interceptTransaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
            const interceptReceipt = await interceptTransaction.wait();

            const deadline = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "deadline", "PirateConfrontationStart");
            const expiration = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "expiration", "PirateConfrontationStart");

            // Act
            await time.increaseTo(deadline + BigInt(1));

            const attemptEscapeCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("attemptEscape");

            const operation = targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, attemptEscapeCalldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "ResponseTimeExpired")
                    .withArgs(targetAccountAddress, deadline);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup
            await time.increaseTo(expiration);

            // Move target to new location
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[0, 1]]);

            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);
                
            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(revertArrival);
        });

        it ("Should not allow a target to attempt an escape with insufficient fuel", async function () {

            // Setup
            const fuelAsset = getAssetByResource(Resource.Fuel);
            const mapContractAddress = await mapInstance.getAddress();
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            const interceptTransaction = await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
            const interceptReceipt = await interceptTransaction.wait();

            const expiration = getParamFromEvent(
                pirateMechanicsInstance, interceptReceipt, "expiration", "PirateConfrontationStart");

            // Act
            const attemptEscapeCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("attemptEscape");

            const operation = targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, attemptEscapeCalldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(inventoriesInstance, "InventoryInsufficientBalance")
                    .withArgs(targetAccountAddress, Inventory.Ship, fuelAsset.contractAddress, PirateMechanicsConfig.BASE_FUEL_COST);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }

            // Cleanup
            await time.increaseTo(expiration);

            // Move target to new location
            const revertMoveCalldata = mapInstance.interface
                .encodeFunctionData("playerMove", [[1, 0]]);

            const revertMoveTransaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(mapContractAddress, 0, revertMoveCalldata);
                
            const revertMoveReceipt = await revertMoveTransaction.wait();
            const revertArrival = getParamFromEvent(
                mapInstance, revertMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(revertArrival);
        });

        it ("Should allow a target to attempt an escape regardless of the outcome", async function () {

            // Setup
            const fuelAsset = getAssetByResource(Resource.Fuel);
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const pirateAccountAddress = await pirateAccountInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);

            // Ensure the pirate has enough fuel
            await fuelAsset.contractInstance
                ?.connect(systemSigner)
                 .__mintTo(inventoriesAddress, PirateMechanicsConfig.BASE_FUEL_COST);

            await inventoriesInstance
                .connect(systemSigner)
                .__assignFungibleToken(targetAccountAddress, Inventory.Ship, fuelAsset.contractAddress, PirateMechanicsConfig.BASE_FUEL_COST);

            // Act
            const attemptEscapeCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("attemptEscape");

            const transaction = await targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, attemptEscapeCalldata);
            const receipt = await transaction.wait();
            
            const escapeSuccess = containsEvent(
                pirateMechanicsInstance, receipt, "EscapeSuccess");

            // Assert
            if (escapeSuccess) 
            {
                await expect(transaction).to
                    .emit(pirateMechanicsInstance, "EscapeSuccess")
                    .withArgs(pirateAccountAddress, targetAccountAddress, 0);

                await expect(transaction).to
                    .emit(pirateMechanicsInstance, "PirateConfrontationEnd")
                    .withArgs(pirateAccountAddress, targetAccountAddress, 0);
            }
            else 
            {
                await expect(transaction).to
                    .emit(pirateMechanicsInstance, "EscapeFail")
                    .withArgs(pirateAccountAddress, targetAccountAddress, 0);
            }
        });

        it ("Should successfully escape a pirate and end the confrontation", async function () {

            // Setup
            const fuelAsset = getAssetByResource(Resource.Fuel);
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const targetAccountSigner = await ethers.provider.getSigner(account2);

            for (let i = 0; i < PirateMechanicsConfig.MAX_ESCAPE_ATTEMPTS; i++)
            {
                // Create pirate account
                const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, `A${i}_Escaping_Pirate`.toBytes32(), 0, 0);
                const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
                const pirateAccountAddress = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
                pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccountAddress);

                // Create target account
                const createTargetAccountTransaction = await playerRegisterInstance.create([account2], 1, 0, `A${i}_Escaping_Target`.toBytes32(), 0, 0);
                const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
                const targetAccountAddress = getParamFromEvent(playerRegisterInstance, createTargetAccountReceipt, "account", "RegisterPlayer");
                targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccountAddress);

                // Add another pirate and target to the map
                const playerEnterCalldata = mapInstance.interface
                    .encodeFunctionData("playerEnter");

                await pirateAccountInstance
                    .connect(await ethers.provider.getSigner(account1))
                    .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

                await targetAccountInstance
                    .connect(await ethers.provider.getSigner(account2))
                    .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

                const interceptCalldata = pirateMechanicsInstance.interface
                    .encodeFunctionData("intercept", [targetAccountAddress, 0]);
    
                await pirateAccountInstance
                    .connect(pirateAccountSigner)
                    .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
    
                // Ensure the pirate has enough fuel
                await fuelAsset.contractInstance
                    ?.connect(systemSigner)
                     .__mintTo(inventoriesAddress, PirateMechanicsConfig.BASE_FUEL_COST);
    
                await inventoriesInstance
                    .connect(systemSigner)
                    .__assignFungibleToken(targetAccountAddress, Inventory.Ship, fuelAsset.contractAddress, PirateMechanicsConfig.BASE_FUEL_COST);
    
                // Act
                const attemptEscapeCalldata = pirateMechanicsInstance.interface
                    .encodeFunctionData("attemptEscape");
    
                const transaction = await targetAccountInstance
                    .connect(targetAccountSigner)
                    .submitTransaction(pirateMechanicsAddress, 0, attemptEscapeCalldata);
                const receipt = await transaction.wait();
                
                const escapeSuccess = containsEvent(
                    pirateMechanicsInstance, receipt, "EscapeSuccess");

                if (!escapeSuccess)
                {
                    continue;
                }
    
                // Assert
                await expect(transaction).to
                    .emit(pirateMechanicsInstance, "EscapeSuccess")
                    .withArgs(pirateAccountAddress, targetAccountAddress, 0);

                await expect(transaction).to
                    .emit(pirateMechanicsInstance, "PirateConfrontationEnd")
                    .withArgs(pirateAccountAddress, targetAccountAddress, 0);

                break;
            }
        });

        it ("Should fail to escape a pirate and not end the confrontation", async function () {

            // Setup
            const fuelAsset = getAssetByResource(Resource.Fuel);
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const systemSigner = await ethers.provider.getSigner(system);
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const pirateAccountSigner = await ethers.provider.getSigner(account1);
            const targetAccountSigner = await ethers.provider.getSigner(account2);

            for (let i = 0; i < PirateMechanicsConfig.MAX_ESCAPE_ATTEMPTS; i++)
            {
                // Create pirate account
                const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, `B${i}_Escaping_Pirate`.toBytes32(), 0, 0);
                const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
                const pirateAccountAddress = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
                pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccountAddress);

                // Create target account
                const createTargetAccountTransaction = await playerRegisterInstance.create([account2], 1, 0, `B${i}_Escaping_Target`.toBytes32(), 0, 0);
                const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
                const targetAccountAddress = getParamFromEvent(playerRegisterInstance, createTargetAccountReceipt, "account", "RegisterPlayer");
                targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccountAddress);

                // Add another pirate and target to the map
                const playerEnterCalldata = mapInstance.interface
                    .encodeFunctionData("playerEnter");

                await pirateAccountInstance
                    .connect(await ethers.provider.getSigner(account1))
                    .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

                await targetAccountInstance
                    .connect(await ethers.provider.getSigner(account2))
                    .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

                    const interceptCalldata = pirateMechanicsInstance.interface
                    .encodeFunctionData("intercept", [targetAccountAddress, 0]);
    
                await pirateAccountInstance
                    .connect(pirateAccountSigner)
                    .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
    
                // Ensure the pirate has enough fuel
                await fuelAsset.contractInstance
                    ?.connect(systemSigner)
                     .__mintTo(inventoriesAddress, PirateMechanicsConfig.BASE_FUEL_COST);
    
                await inventoriesInstance
                    .connect(systemSigner)
                    .__assignFungibleToken(targetAccountAddress, Inventory.Ship, fuelAsset.contractAddress, PirateMechanicsConfig.BASE_FUEL_COST);
    
                // Act
                const attemptEscapeCalldata = pirateMechanicsInstance.interface
                    .encodeFunctionData("attemptEscape");
    
                const transaction = await targetAccountInstance
                    .connect(targetAccountSigner)
                    .submitTransaction(pirateMechanicsAddress, 0, attemptEscapeCalldata);
                const receipt = await transaction.wait();
                
                const escapeSuccess = containsEvent(
                    pirateMechanicsInstance, receipt, "EscapeSuccess");

                if (escapeSuccess)
                {
                    continue;
                }
    
                // Assert
                await expect(transaction).to
                    .emit(pirateMechanicsInstance, "EscapeFail")
                    .withArgs(pirateAccountAddress, targetAccountAddress, 0);

                await expect(transaction).to.not
                    .emit(pirateMechanicsInstance, "PirateConfrontationEnd");

                break;
            }
        });


        it ("Should now allow a target to attempt a second escape within the same confrontation", async function () {

            // Setup
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();

            // Act
            const attemptEscapeCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("attemptEscape");

            const operation = targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, attemptEscapeCalldata);

            // Assert
            if (REVERT_MODE)
            {
                await expect(operation).to.be
                    .revertedWithCustomError(pirateMechanicsInstance, "TargetAlreadyAttemptedEscape")
                    .withArgs(targetAccountAddress);
            }
            else
            {
                await expect(operation).to
                    .emit(pirateAccountInstance, "ExecutionFailure");
            }
        });
    });

    /**
     * Test resolving a confrontation through a quick battle
     */
    describe("Quick Battle", function () { 

        // Players
        let pirateAccountInstance: CryptopiaAccount;
        let targetAccountInstance: CryptopiaAccount;

        /**
         * Deploy players
         */
        before(async () => {

            // Create pirate account
            const createPirateAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "QuickBattle_Pirate".toBytes32(), 0, 0);
            const createPirateAccountReceipt = await createPirateAccountTransaction.wait();
            const pirateAccountAddress = getParamFromEvent(playerRegisterInstance, createPirateAccountReceipt, "account", "RegisterPlayer");
            pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAccountAddress);

            // Create target account
            const createTargetAccountTransaction = await playerRegisterInstance.create([account2], 1, 0, "QuickBattle_Target".toBytes32(), 0, 0);
            const createTargetAccountReceipt = await createTargetAccountTransaction.wait();
            const targetAccountAddress = getParamFromEvent(playerRegisterInstance, createTargetAccountReceipt, "account", "RegisterPlayer");
            targetAccountInstance = await ethers.getContractAt("CryptopiaAccount", targetAccountAddress);

            // Add another pirate and target to the map
            const playerEnterCalldata = mapInstance.interface
                .encodeFunctionData("playerEnter");

            await pirateAccountInstance
                .connect(await ethers.provider.getSigner(account1))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

            await targetAccountInstance
                .connect(await ethers.provider.getSigner(account2))
                .submitTransaction(await mapInstance.getAddress(), 0, playerEnterCalldata);

            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAccountAddress, 0]);

            await pirateAccountInstance
                .connect(await ethers.provider.getSigner(account1))
                .submitTransaction(await pirateMechanicsInstance.getAddress(), 0, interceptCalldata);
        });

        it ("Should allow a target to resolve a confrontation through a quick battle", async function () {

            // Setup
            const pirateMechanicsAddress = await pirateMechanicsInstance.getAddress();
            const targetAccountSigner = await ethers.provider.getSigner(account2);
            const targetAccountAddress = await targetAccountInstance.getAddress();
            const pirateAccountAddress = await pirateAccountInstance.getAddress();

            // Act
            const quickBattleCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("startQuickBattleAsTarget");

            const operation = targetAccountInstance
                .connect(targetAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, quickBattleCalldata);

            // Assert
            await expect(operation).to
                .emit(pirateMechanicsInstance, "PirateConfrontationEnd")
                .withArgs(pirateAccountAddress, targetAccountAddress, 0);
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