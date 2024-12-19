import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { DEFAULT_ADMIN_ROLE, SYSTEM_ROLE } from "./settings/roles";   
import { Permission, Profession, Rarity, Environment, Zone, Resource, Terrain, Biome, Inventory, SubFaction, BuildingType } from "../scripts/types/enums";
import { Asset, Map } from "../scripts/types/input";
import { getParamFromEvent} from '../scripts/helpers/events';
import { encodeRockData, encodeVegetationData, encodeWildlifeData } from '../scripts/maps/helpers/encoders';
import { resolveEnum } from "../scripts/helpers/enums";
import { time } from "@nomicfoundation/hardhat-network-helpers";

import { 
    CryptopiaAccount,
    DevelopmentMaps,
    DevelopmentMapsExtensions,
    DevelopmentAccountRegister,
    DevelopmentAvatarRegister,
    DevelopmentAssetRegister,
    DevelopmentPlayerRegister,
    DevelopmentBuildingRegister,
    DevelopmentInventories,
    DevelopmentCrafting,
    DevelopmentQuests,
    DevelopmentQuestToken,
    DevelopmentPirateMechanics,
    DevelopmentConstructionMechanics,
    DevelopmentToolToken,
    DevelopmentShipToken,
    DevelopmentShipSkinToken 
} from "../typechain-types";

import { 
    InventorySpaceStructOutput 
} from "../typechain-types/contracts/source/game/inventories/IInventories";
import { ZERO_ADDRESS } from "./settings/constants";


/**
 * Cleanable tests
 */
describe("Clean Contracts", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let account1: string;
    let account2: string;
    let other: string;
    let treasury: string;

    /**
     * Deploy Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, account1, account2, other, treasury] = (
            await ethers.getSigners()).map(s => s.address);
    });

    /**
     * Test cleaning of AccountRegister
     */
    describe("AccountRegister", function () {

        let account1Address: string;
        let account2Address: string;

        let accountRegisterInstance: DevelopmentAccountRegister;

        const account1username = "Username_1".toBytes32();
        const account2username = "Username_2".toBytes32();

        /**
         * Setup
         */
        before(async () => {

            // Deploy Account register
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
            const accountRegisterAddress = await accountRegisterProxy.address;
            accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);

            // SKALE workaround
            await accountRegisterInstance.initializeManually();
            
            // Create account 1
            const createAccount1Transaction = await accountRegisterInstance.create([account1], 1, 0, account1username, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(accountRegisterInstance, createAccount1Receipt, "account", "CreateAccount");

            // Create account 2
            const createAccount2Transaction = await accountRegisterInstance.create([account2], 1, 0, account2username, 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(accountRegisterInstance, createAccount2Receipt, "account", "CreateAccount");
        });

        it ("Should contain data to clean", async function () {

            // Act
            const accountDatas = await accountRegisterInstance
                .getAccountDatas([account1Address, account2Address]);

            // Assert
            expect(accountDatas.username[0]).to.equal(account1username);
            expect(accountDatas.username[1]).to.equal(account2username);
        });

        it ("Should not allow non-admin to clean", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = accountRegisterInstance
                .connect(nonAdminSigner)
                .clean([account1Address, account2Address]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(accountRegisterInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to clean", async function () {

            // Act
            await accountRegisterInstance
                .clean([account1Address, account2Address]);

            // Assert
            const accountDatas = await accountRegisterInstance
                .getAccountDatas([account1Address, account2Address]);

            expect(accountDatas.username[0]).to.equal("".toBytes32());
            expect(accountDatas.username[1]).to.equal("".toBytes32());
        }); 
    });

    /**
     * Test cleaning of AvatarRegister
     */
    describe("AvatarRegister", function () {

        let account1Address: string;
        let account2Address: string;

        let accountRegisterInstance: DevelopmentAccountRegister;
        let avatarRegisterInstance: DevelopmentAvatarRegister;

        const avatar1Data = "0x1234567890123456789012345678901234567890123456789012345678901234";
        const avatar2Data = "0x9876543210987654321098765432109876543210987654321098765432109876";

        /**
         * Setup
         */
        before(async () => {

            // Deploy Account register
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
            const accountRegisterAddress = await accountRegisterProxy.address;
            accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);

            // SKALE workaround
            await accountRegisterInstance.initializeManually();

            // Deploy Avatar register
            const AvatarRegisterFactory = await ethers.getContractFactory("DevelopmentAvatarRegister");
            const avatarRegisterProxy = await upgrades.deployProxy(AvatarRegisterFactory, [accountRegisterAddress]);
            const avatarRegisterAddress = await avatarRegisterProxy.address;
            avatarRegisterInstance = await ethers.getContractAt("DevelopmentAvatarRegister", avatarRegisterAddress);
            
            // Create account 1
            const createAccount1Transaction = await accountRegisterInstance.create([account1], 1, 0, "Username_1".toBytes32(), 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(accountRegisterInstance, createAccount1Receipt, "account", "CreateAccount");
            const account1Instance = await ethers.getContractAt("CryptopiaAccount", account1Address);

            // Create account 2
            const createAccount2Transaction = await accountRegisterInstance.create([account2], 1, 0, "Username_2".toBytes32(), 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(accountRegisterInstance, createAccount2Receipt, "account", "CreateAccount");
            const account2Instance = await ethers.getContractAt("CryptopiaAccount", account2Address);

            // Set avatar data
            const signer1 = await ethers.provider.getSigner(account1);
            const callData1 = avatarRegisterInstance.interface
                .encodeFunctionData("setAvatarData", [avatar1Data]);

            await account1Instance
                .connect(signer1)
                .submitTransaction(await avatarRegisterInstance.address, 0, callData1);


            const signer2 = await ethers.provider.getSigner(account2);
            const callData2 = avatarRegisterInstance.interface
                .encodeFunctionData("setAvatarData", [avatar2Data]);

            await account2Instance
                .connect(signer2)
                .submitTransaction(await avatarRegisterInstance.address, 0, callData2);

        });

        it ("Should contain data to clean", async function () {

            // Act
            const avatarDatas = await avatarRegisterInstance
                .getAvatarDatas([account1Address, account2Address]);

            // Assert
            expect(avatarDatas[0]).to.equal(avatar1Data);
            expect(avatarDatas[1]).to.equal(avatar2Data);
        });

        it ("Should not allow non-admin to clean", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = avatarRegisterInstance
                .connect(nonAdminSigner)
                .clean([account1Address, account2Address]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(avatarRegisterInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to clean", async function () {

            // Act
            await avatarRegisterInstance
                .clean([account1Address, account2Address]);

            // Assert
            const avatarDatas = await avatarRegisterInstance
                .getAvatarDatas([account1Address, account2Address]);

            expect(avatarDatas[0]).to.equal("".toBytes32());
            expect(avatarDatas[1]).to.equal("".toBytes32());
        }); 
    });

    /**
     * Test cleaning of PlayerRegister
     */
    describe("PlayerRegister", function () {

        const map: Map = {
            name: "Map 1".toBytes32(),
            sizeX: 2,
            sizeZ: 2,
            tiles: [
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        let account1Address: string;
        let account2Address: string;

        let playerRegisterInstance: DevelopmentPlayerRegister;

        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            const inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);


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
             const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
             const accountRegisterAddress = await accountRegisterProxy.address;
             const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);
 
             // SKALE workaround
             await accountRegisterInstance.initializeManually();
 
 
             // Deploy Asset Register
             const assetRegisterProxy = await upgrades.deployProxy(
                 AssetRegisterFactory, []);
 
             const assetRegisterAddress = await assetRegisterProxy.address;


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
            const shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            const craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);


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
            playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
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
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);


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
            const mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

            // Grant roles
            await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);
            await playerRegisterInstance.setMapsContract(mapsAddress);
            await mapsInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


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
                    environment: tile.environment,
                    zone: tile.zone,
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

            
            // Create account 1
            const createAccount1Transaction = await playerRegisterInstance.create([account1], 1, 0, "Player1".toBytes32(), 0, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(playerRegisterInstance, createAccount1Receipt, "account", "RegisterPlayer");

            // Create account 2
            const createAccount2Transaction = await playerRegisterInstance.create([account2], 1, 0, "Player2".toBytes32(), 0, 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(playerRegisterInstance, createAccount2Receipt, "account", "RegisterPlayer");
        });

        it ("Should contain data to clean", async function () {

            // Act
            const playerData1 = await playerRegisterInstance.getPlayerData(account1Address);
            const playerData2 = await playerRegisterInstance.getPlayerData(account2Address);

            // Assert
            expect(playerData1.level).to.equal(1);
            expect(playerData2.level).to.equal(1);
        });

        it ("Should not allow non-admin to clean", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = playerRegisterInstance
                .connect(nonAdminSigner)
                .clean([account1Address, account2Address]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(playerRegisterInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to clean", async function () {

            // Act
            await playerRegisterInstance
                .clean([account1Address, account2Address]);

            // Assert
            const playerData1 = await playerRegisterInstance.getPlayerData(account1Address);
            const playerData2 = await playerRegisterInstance.getPlayerData(account2Address);

            expect(playerData1.level).to.equal(0);
            expect(playerData2.level).to.equal(0);
        }); 
    });

    /**
     * Test cleaning of AssetRegister
     */
    describe("AssetRegister", function () {

        // Data
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

        let assetRegisterInstance: DevelopmentAssetRegister;

        /**
         * Setup
         */
        before(async () => {

            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("DevelopmentAssetToken");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);
    
            const inventoriesAddress = await inventoriesProxy.address;

            // Deploy Asset Register
            const assetRegisterProxy = await upgrades.deployProxy(AssetRegisterFactory);
            const assetRegisterAddress = await assetRegisterProxy.address;
            assetRegisterInstance = await ethers.getContractAt("DevelopmentAssetRegister", assetRegisterAddress);

            // Grant roles
            await assetRegisterInstance.grantRole(SYSTEM_ROLE, system);

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
                
                await assetRegisterInstance
                    .registerAsset(asset.contractAddress, true, asset.resource);
            }
        });

        it ("Should contain data to clean", async function () {

            // Act
            const assetCount = await assetRegisterInstance.getAssetCount();
            const assetDatas = await assetRegisterInstance.getAssets(0, assetCount); 

            // Assert
            expect(assetDatas.length).to.equal(assets.length);

            for (let i = 0; i < assets.length; i++)
            {
                const assetByResource = await assetRegisterInstance
                    .getAssetByResrouce(assets[i].resource);

                expect(assetDatas[i]).to.equal(assets[i].contractAddress);
                expect(assetByResource).to.equal(assets[i].contractAddress);
            }
        });

        it ("Should not allow non-admin to clean", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = assetRegisterInstance
                .connect(nonAdminSigner)
                .clean();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(assetRegisterInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to clean", async function () {

            // Act
            await assetRegisterInstance.clean();

            // Assert
            const assetCount = await assetRegisterInstance.getAssetCount();
            expect(assetCount).to.equal(0);

            for (let asset of assets)
            {
                // bytes32 key = keccak256(bytes(symbol));
                const key = ethers.utils.keccak256(ethers.utils.toUtf8Bytes(asset.symbol));
                const assetbyKey = await assetRegisterInstance.assets(key);

                const assetByResource = await assetRegisterInstance
                    .getAssetByResrouce(asset.resource);

                expect(assetByResource).to.equal(ethers.constants.AddressZero);
                expect(assetbyKey).to.equal(ethers.constants.AddressZero);
            }
        }); 
    });

    /**
     * Test cleaning of Ships
     */
    describe("Ships", function () {

        const map: Map = {
            name: "Map 1".toBytes32(),
            sizeX: 2,
            sizeZ: 2,
            tiles: [
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        let account1Address: string;
        let account2Address: string;

        let shipTokenInstance: DevelopmentShipToken;
        let shipSkinTokenInstance: DevelopmentShipSkinToken;

        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            const inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);


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
             const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
             const accountRegisterAddress = await accountRegisterProxy.address;
             const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);
 
             // SKALE workaround
             await accountRegisterInstance.initializeManually();
 
 
             // Deploy Asset Register
             const assetRegisterProxy = await upgrades.deployProxy(
                 AssetRegisterFactory, []);
 
             const assetRegisterAddress = await assetRegisterProxy.address;


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
            shipSkinTokenInstance = await ethers.getContractAt("DevelopmentShipSkinToken", shipSkinTokenAddress);


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
            shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            const craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);


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
            const playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
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
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);


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
            const mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

            // Grant roles
            await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);
            await playerRegisterInstance.setMapsContract(mapsAddress);
            await mapsInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


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
                    environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: tile.elevationLevel,
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

            
            // Create account 1
            const createAccount1Transaction = await playerRegisterInstance.create([account1], 1, 0, "Player1".toBytes32(), 0, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(playerRegisterInstance, createAccount1Receipt, "account", "RegisterPlayer");

            // Create account 2
            const createAccount2Transaction = await playerRegisterInstance.create([account2], 1, 0, "Player2".toBytes32(), 0, 1);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(playerRegisterInstance, createAccount2Receipt, "account", "RegisterPlayer");
        });

        it ("Should contain token data to clean", async function () {

            // Setup 
            const account1ShipTokenId = 1;
            const account2ShipTokenId = 2;

            // Act
            const account1ShipData = await shipTokenInstance.getShipInstance(account1ShipTokenId);
            const account2ShipData = await shipTokenInstance.getShipInstance(account2ShipTokenId);

            // Assert
            expect(account1ShipData.name).not.to.eq("".toBytes32());
            expect(account1ShipData.locked).to.eq(true);

            expect(account2ShipData.name).not.to.eq("".toBytes32());
            expect(account2ShipData.locked).to.eq(true);
        });

        it ("Should contain ship data to clean", async function () {

            // Act
            const shipCount = await shipTokenInstance.getShipCount();
            const shipDatas = await shipTokenInstance.getShips(0, shipCount);

            // Assert
            expect(shipDatas.length).to.gt(0);
            
            for (let i = 0; i < shipDatas.length; i++)
            {
                expect(shipDatas[i].modules).gt(0);
                expect(shipDatas[i].base_speed).gt(0);
                expect(shipDatas[i].base_attack).gt(0);
                expect(shipDatas[i].base_health).gt(0);
                expect(shipDatas[i].base_defence).gt(0);
                expect(shipDatas[i].base_inventory).gt(0);
                expect(shipDatas[i].base_fuelConsumption).gt(0);
            }
        });

        it ("Should not allow non-admin to clean token data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = shipTokenInstance
                .connect(nonAdminSigner)
                .cleanTokenData(0, 2);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(shipTokenInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean ship data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = shipTokenInstance
                .connect(nonAdminSigner)
                .cleanShipData();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(shipTokenInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should allow admin to clean token data", async function () {

            // Act
            await shipTokenInstance.cleanTokenData(0, 2);

            // Assert
            const account1ShipData = await shipTokenInstance.getShipInstance(1);
            const account2ShipData = await shipTokenInstance.getShipInstance(2);

            expect(account1ShipData.name).to.equal("".toBytes32());
            expect(account1ShipData.locked).to.eq(false);

            expect(account2ShipData.name).to.equal("".toBytes32());
            expect(account2ShipData.locked).to.eq(false);
        });

        it ("Should allow admin to clean ship data", async function () {

            // Act
            await shipTokenInstance.cleanShipData();

            // Assert
            const shipCount = await shipTokenInstance.getShipCount();
            expect(shipCount).to.equal(0);
        });
    });

    /**
     * Test cleaning of Maps
     */
    describe("Maps", function () {

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
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                
                // Second row
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 7, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b1010101010101010101010101010' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: true, resources: [{ resource: Resource.Iron, amount: "100000".toWei() }, { resource: Resource.Gold, amount: "500".toWei() }] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                
                // Third row
                { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 4, waterLevel: 5, vegetationData: '0b101010101010101010101010101010101010101010' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b10000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Mountains, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 8, waterLevel: 5, vegetationData: '0b111111111111111111111111111111111111111111' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [{ resource: Resource.Gold, amount: "500".toWei() }] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },

                // Fourth row
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b1010101010101010101010101010' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: true, hasLake: false, resources: [{ resource: Resource.Iron, amount: "100000".toWei() }, { resource: Resource.Copper, amount: "5000".toWei() }] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 4, waterLevel: 5, vegetationData: '0b111111111111111111111111111111111111111111' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b11000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },

                // Top row
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        let account1Address: string;
        let account2Address: string;

        let mapsInstance: DevelopmentMaps;
        let mapsExtensionsInstance: DevelopmentMapsExtensions;

        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");
            const MapsExtensionsFactory = await ethers.getContractFactory("DevelopmentMapsExtensions");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            const inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);


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
             const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
             const accountRegisterAddress = await accountRegisterProxy.address;
             const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);
 
             // SKALE workaround
             await accountRegisterInstance.initializeManually();
 
 
             // Deploy Asset Register
             const assetRegisterProxy = await upgrades.deployProxy(
                 AssetRegisterFactory, []);
 
             const assetRegisterAddress = await assetRegisterProxy.address;


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
            const shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            const craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);


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
            const playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
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
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);


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
            mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

            // Grant roles
            await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);
            await playerRegisterInstance.setMapsContract(mapsAddress);
            await mapsInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


            // Deploy Maps Extensions
            const mapsExtensionsProxy = await upgrades.deployProxy(
                MapsExtensionsFactory, 
                [
                    mapsAddress,
                    titleDeedTokenAddress
                ]);

            const mapsExtensionsAddress = await mapsExtensionsProxy.address;
            mapsExtensionsInstance = await ethers.getContractAt("DevelopmentMapsExtensions", mapsExtensionsAddress);


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
                    environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: tile.elevationLevel,
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

            
            // Create account 1
            const createAccount1Transaction = await playerRegisterInstance.create([account1], 1, 0, "Player1".toBytes32(), 0, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(playerRegisterInstance, createAccount1Receipt, "account", "RegisterPlayer");

            // Create account 2
            const createAccount2Transaction = await playerRegisterInstance.create([account2], 1, 0, "Player2".toBytes32(), 0, 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(playerRegisterInstance, createAccount2Receipt, "account", "RegisterPlayer");
            const account2Instance = await ethers.getContractAt("CryptopiaAccount", account2Address);
            const account2Signer = await ethers.provider.getSigner(account2);

            const playerMoveCalldata = mapsInstance.interface
                .encodeFunctionData("playerMove", [[0, 1]]);

            await account2Instance
                .connect(account2Signer)
                .submitTransaction(mapsAddress, 0, playerMoveCalldata);
        });

        it ("Should contain map data to clean", async function () {

            // Act
            const mapCount = await mapsInstance.getMapCount();
            const mapData = await mapsInstance.getMapAt(0);

            // Assert
            expect(mapCount).to.gt(0);
            expect(mapData.name).to.equal(map.name);
            expect(mapData.sizeX).to.gt(0);
            expect(mapData.sizeZ).to.gt(0);
            expect(mapData.initialized).to.equal(true);
            expect(mapData.finalized).to.equal(true);
        });

        it ("Should contain tile data to clean", async function () {

            // Setup
            const tileCount = map.tiles.length
            const tileWithLake = 8;
            const player1Location = 0;
            const player2Location = 1;

            // Act 
            const tileDataStatic = await mapsExtensionsInstance["getTileDataStatic(uint16,uint16)"](0, tileCount);
            const tileDataDynamic = await mapsExtensionsInstance["getTileDataDynamic(uint16,uint16)"](0, tileCount);
            const movementPenalty = await mapsInstance.movementPenaltyCache(tileWithLake);

            // Assert
            for (let i = 0; i < tileCount; i++)
            {
                const tile = map.tiles[i];
                const tileStatic = tileDataStatic[i];
                const tileDynamic = tileDataDynamic[i];

                expect(tileStatic.initialized).to.equal(true);
                expect(tileStatic.group).to.equal(tile.group);
                expect(tileStatic.safety).to.equal(tile.safety);
                expect(tileStatic.biome).to.equal(tile.biome);
                expect(tileStatic.terrain).to.equal(tile.terrain);
                expect(tileStatic.elevationLevel).to.equal(tile.elevationLevel);
                expect(tileStatic.waterLevel).to.equal(tile.waterLevel);
                expect(tileStatic.riverFlags).to.equal(tile.riverFlags);
                expect(tileStatic.resources.length).to.equal(tile.resources.length);
                expect(tileDynamic.hasRoad).to.equal(tile.hasRoad);
                expect(tileDynamic.resources.length).to.equal(tile.resources.length);

                for (let j = 0; j < tile.resources.length; j++)
                {
                    expect(tileStatic.resources[j].resource).to.equal(tile.resources[j].resource);
                    expect(tileStatic.resources[j].initialAmount).to.equal(tile.resources[j].amount);
                    expect(tileDynamic.resources[j].resource).to.equal(tile.resources[j].resource);
                    expect(tileDynamic.resources[j].amount).to.equal(tile.resources[j].amount);
                }
            }

            expect(tileDataDynamic[player1Location].lastEnteredPlayers[0]).to.equal(account1Address);
            expect(tileDataDynamic[player2Location].lastEnteredPlayers[0]).to.equal(account2Address);
            expect(movementPenalty.initialized).to.equal(true);
            expect(movementPenalty.penalty).to.gt(0);
        });

        it ("Should contain player data to clean", async function () {

            // Setup 
            const player2Location = 1;

            // Act
            const playerData = await mapsExtensionsInstance
                .getPlayerNavigationData([account2Address, account2Address]);

            // Assert
            expect(playerData.length).to.equal(2);
            expect(playerData[0].movement).to.gt(0);
            expect(playerData[0].location_mapName).to.equal(map.name);
            expect(playerData[1].location_tileIndex).to.equal(1);
            expect(playerData[1].location_arrival).to.gt(0);
            expect(playerData[1].location_route).not.equal("".toBytes32());
            expect(playerData[1].movement).to.gt(0);
            expect(playerData[1].location_mapName).to.equal(map.name);
            expect(playerData[1].location_tileIndex).to.equal(player2Location);
            expect(playerData[1].location_arrival).to.gt(0);
            expect(playerData[1].location_route).not.to.equal("".toBytes32());
        });

        it ("Should not allow non-admin to clean map data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = mapsInstance
                .connect(nonAdminSigner)
                .cleanMapData();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean tile data", async function () {

            // Setup 
            const tileCount = map.tiles.length
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = mapsInstance
                .connect(nonAdminSigner)
                .cleanTileData(0, tileCount);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean map data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = mapsInstance
                .connect(nonAdminSigner)
                .cleanPlayerData([account1Address, account2Address]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(mapsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to clean map data", async function () {

            // Act
            await mapsInstance.cleanMapData();

            // Assert
            const mapCount = await mapsInstance.getMapCount();
            
            expect(mapCount).to.equal(0);
        });

        it ("Should allow admin to clean tile data", async function () {

            // Setup
            const tileCount = map.tiles.length
            const tileWithLake = 8;
            const player1Location = 0;
            const player2Location = 1;

            // Act
            await mapsInstance.cleanTileData(0, map.tiles.length);

            // Assert
            const tileDataStatic = await mapsExtensionsInstance["getTileDataStatic(uint16,uint16)"](0, tileCount);
            const tileDataDynamic = await mapsExtensionsInstance["getTileDataDynamic(uint16,uint16)"](0, tileCount);
            const movementPenalty = await mapsInstance.movementPenaltyCache(tileWithLake);

            for (let i = 0; i < tileCount; i++)
            {
                const tileStatic = tileDataStatic[i];
                const tileDynamic = tileDataDynamic[i];

                expect(tileStatic.initialized).to.equal(false);
                expect(tileStatic.group).to.equal(0);
                expect(tileStatic.safety).to.equal(0);
                expect(tileStatic.biome).to.equal(0);
                expect(tileStatic.terrain).to.equal(0);
                expect(tileStatic.elevationLevel).to.equal(0);
                expect(tileStatic.waterLevel).to.equal(0);
                expect(tileStatic.riverFlags).to.equal(0);
                expect(tileStatic.resources.length).to.equal(0);
                expect(tileDynamic.hasRoad).to.equal(false);
                expect(tileDynamic.resources.length).to.equal(0);
            }

            expect(tileDataDynamic[player1Location].lastEnteredPlayers[0]).to.equal(ethers.constants.AddressZero);
            expect(tileDataDynamic[player2Location].lastEnteredPlayers[0]).to.equal(ethers.constants.AddressZero);
            expect(movementPenalty.initialized).to.equal(false);
            expect(movementPenalty.penalty).to.equals(0);
        });

        it ("Should allow admin to clean map data", async function () {

            // Act
            await mapsInstance.cleanPlayerData([account1Address, account2Address]);

            // Assert
            const playerData1 = await mapsInstance.playerData(account1Address);
            const playerData2 = await mapsInstance.playerData(account2Address);

            expect(playerData1.movement).to.equal(0);
            expect(playerData2.location_tileIndex).to.equal(0);
            expect(playerData2.location_arrival).to.equal(0);
            expect(playerData2.location_route).to.equal("".toBytes32());
            expect(playerData2.movement).to.equal(0);
            expect(playerData2.location_tileIndex).to.equal(0);
            expect(playerData2.location_arrival).to.equal(0);
            expect(playerData2.location_route).to.equal("".toBytes32());
        });
    });

    /**
     * Test cleaning of Crafting
     */
    describe("Crafting", function () {

        // Data
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
            },
            {
                name: "Iron Axe",
                rarity: 1,
                level: 1,
                durability: 95, 
                multiplier_xp: 110, 
                multiplier_effectiveness: 110, 
                value1: 11, 
                value2: 22, 
                value3: 33,
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
                    learnable: true,
                    craftingTime: 600, // 10 min
                    ingredients: [
                        {
                            asset: "WOOD",
                            amount: "2"
                        },
                        {
                            asset: "FE26",
                            amount: "1"
                        }
                    ]
                }
            }
        ];

        const map: Map = {
            name: "Map 1".toBytes32(),
            sizeX: 2,
            sizeZ: 2,
            tiles: [
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        let account1Address: string;
        let account2Address: string;

        let account1Instance: CryptopiaAccount;
        let account2Instance: CryptopiaAccount;

        let craftingInstance: DevelopmentCrafting;
        let toolTokenInstance: DevelopmentToolToken;

        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("DevelopmentAssetToken");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const ToolTokenFactory = await ethers.getContractFactory("DevelopmentToolToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            const inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);


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
            const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
            const accountRegisterAddress = await accountRegisterProxy.address;
            const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);

            // SKALE workaround
            await accountRegisterInstance.initializeManually();


            // Deploy Asset Register
            const assetRegisterProxy = await upgrades.deployProxy(
                AssetRegisterFactory, []);
 
            const assetRegisterAddress = await assetRegisterProxy.address;
            const assetRegisterInstance = await ethers.getContractAt("DevelopmentAssetRegister", assetRegisterAddress);

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
            const shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);

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
            const playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
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
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);


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
            const mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

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

            const toolTokenAddress = await toolTokenProxy.address;
            toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

            // Grant roles
            await toolTokenInstance.grantRole(SYSTEM_ROLE, system);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, toolTokenAddress);


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
                    .getContractAt("DevelopmentAssetToken", asset.contractAddress);
                
                await asset.contractInstance
                    .grantRole(SYSTEM_ROLE, system);

                await inventoriesInstance.grantRole(
                    SYSTEM_ROLE, asset.contractAddress)
                
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


            // Add tool recipes
            await craftingInstance.setRecipes(
                tools.map((tool: any) => {
                    return {
                        level: tool.recipe.level,
                        learnable: tool.recipe.learnable,
                        asset: toolTokenAddress,
                        item: tool.name.toBytes32(),
                        craftingTime: tool.recipe.craftingTime,
                        ingredients: tool.recipe.ingredients.map((ingredient: any) => {
                            return {
                                asset: getAssetBySymbol(ingredient.asset).contractAddress,
                                amount: ingredient.amount.toWei()
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
                    environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: tile.elevationLevel,
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

            
            // Create account 1
            const createAccount1Transaction = await playerRegisterInstance.create([account1], 1, 0, "Player1".toBytes32(), 0, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(playerRegisterInstance, createAccount1Receipt, "account", "RegisterPlayer");
            account1Instance = await ethers.getContractAt("CryptopiaAccount", account1Address);

            // Create account 2
            const createAccount2Transaction = await playerRegisterInstance.create([account2], 1, 0, "Player2".toBytes32(), 0, 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(playerRegisterInstance, createAccount2Receipt, "account", "RegisterPlayer");
            account2Instance = await ethers.getContractAt("CryptopiaAccount", account2Address);


            // Mint assets
            const systemSigner = await ethers.provider.getSigner(system);
            for (let asset of assets)
            {
                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account1Address, Inventory.Backpack, "10".toWei());

                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account1Address, Inventory.Ship, "10".toWei());

                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account2Address, Inventory.Ship, "10".toWei());

                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account2Address, Inventory.Backpack, "10".toWei());
            }

            
            const account1Signer = await ethers.provider.getSigner(account1);
            const account2Signer = await ethers.provider.getSigner(account2);
            for (let i = 0; i < tools.length; i++)
            {
                // Learn recipes
                if (tools[i].recipe.learnable)
                {
                    await craftingInstance
                        .connect(systemSigner)
                        .__learn(account1Address, toolTokenAddress, tools[i].name.toBytes32());

                    await craftingInstance
                        .connect(systemSigner)
                        .__learn(account2Address, toolTokenAddress, tools[i].name.toBytes32());
                }

                // Mint tools
                const account1Calldata = craftingInstance.interface
                    .encodeFunctionData("craft", [toolTokenAddress, tools[i].name.toBytes32(), i + 1, Inventory.Backpack]);

                await account1Instance
                    .connect(account1Signer)
                    .submitTransaction(craftingAddress, 0, account1Calldata);

                const account2Calldata = craftingInstance.interface
                    .encodeFunctionData("craft", [toolTokenAddress, tools[i].name.toBytes32(), i + 1, Inventory.Ship]);

                await account2Instance
                    .connect(account2Signer)
                    .submitTransaction(craftingAddress, 0, account2Calldata);
            }
        });

        /**
         * Helper functions
         */
        const getAssetBySymbol = (symbol: string) : any => {
            return assets.find(asset => asset.symbol === symbol);
        };

        it ("Should contain player data to clean", async function () {

            // Setup
            const expectedSlotCount = 2;
            const toolTokenAddress = await toolTokenInstance.address;
            const learnableTools = tools.filter(tool => tool.recipe.learnable);

            // Act
            const player1LearnedRecipeCount = await craftingInstance.getLearnedRecipeCount(account1Address, toolTokenAddress);
            const player2LearnedRecipeCount = await craftingInstance.getLearnedRecipeCount(account2Address, toolTokenAddress);

            const player1LearnedRecipes = await craftingInstance.getLearnedRecipes(account1Address, toolTokenAddress, 0, player1LearnedRecipeCount);
            const player2LearnedRecipes = await craftingInstance.getLearnedRecipes(account2Address, toolTokenAddress, 0, player2LearnedRecipeCount);

            const player1Slots = await craftingInstance.getSlots(account1Address);
            const player2Slots = await craftingInstance.getSlots(account2Address);

            // Assert
            expect(player1LearnedRecipeCount).to.equal(learnableTools.length);
            expect(player2LearnedRecipeCount).to.equal(learnableTools.length);
            expect(player1LearnedRecipes.length).to.equal(learnableTools.length);
            expect(player2LearnedRecipes.length).to.equal(learnableTools.length);

            for (let i = 0; i < player1LearnedRecipes.length; i++)
            {
                expect(player1LearnedRecipes[i]).not.to.equal("".toBytes32());
            }

            for (let i = 0; i < player2LearnedRecipes.length; i++)
            {
                expect(player2LearnedRecipes[i]).not.to.equal("".toBytes32());
            }

            expect(player1Slots.length).to.equal(expectedSlotCount);
            expect(player2Slots.length).to.equal(expectedSlotCount);

            for (let i = 0; i < player1Slots.length; i++)
            {
                expect(player1Slots[i].finished).to.gt(0);
                expect(player1Slots[i].asset).not.to.equal(ethers.constants.AddressZero);
                expect(player1Slots[i].recipe).not.to.equal("".toBytes32());
            }

            for (let i = 0; i < player2Slots.length; i++)
            {
                expect(player2Slots[i].finished).to.gt(0);
                expect(player2Slots[i].asset).not.to.equal(ethers.constants.AddressZero);
                expect(player2Slots[i].recipe).not.to.equal("".toBytes32());
            }
        });

        it ("Should contain recipe data to clean", async function () {

            // Setup
            const toolTokenAddress = await toolTokenInstance.address;

            // Act
            const recipeCount = await craftingInstance.getRecipeCount(toolTokenAddress);
            const recipes = await craftingInstance.getRecipes(toolTokenAddress, 0, recipeCount);

            // Assert
            expect(recipeCount).to.equal(tools.length);
            expect(recipes.length).to.equal(tools.length);

            for (let i = 0; i < recipes.length; i++)
            {
                expect(recipes[i].asset).not.to.equal(ethers.constants.AddressZero);
                expect(recipes[i].craftingTime).to.gt(0);
                expect(recipes[i].ingredients.length).to.equal(2);

                for (let j = 0; j < recipes[i].ingredients.length; j++)
                {
                    expect(recipes[i].ingredients[j].asset).not.to.equal(ethers.constants.AddressZero);
                    expect(recipes[i].ingredients[j].amount).to.gt(0);
                }
            }
        });

        it ("Should not allow non-admin to clean player data", async function () {

            // Setup 
            const toolTokenAddress = await toolTokenInstance.address;
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = craftingInstance
                .connect(nonAdminSigner)
                .cleanPlayerData([account1Address, account2Address], [toolTokenAddress]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(craftingInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean recipe data", async function () {

            // Setup 
            const toolTokenAddress = await toolTokenInstance.address;
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = craftingInstance
                .connect(nonAdminSigner)
                .cleanRecipeData([toolTokenAddress]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(craftingInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should allow admin to clean player data", async function () {

            // Setup 
            const toolTokenAddress = await toolTokenInstance.address;

            // Act
            await craftingInstance.cleanPlayerData([account1Address, account2Address], [toolTokenAddress]);

            // Assert
            const player1LearnedRecipeCount = await craftingInstance.getLearnedRecipeCount(account1Address, toolTokenAddress);
            const player2LearnedRecipeCount = await craftingInstance.getLearnedRecipeCount(account2Address, toolTokenAddress);
            const player1SlotCount = await craftingInstance.getSlotCount(account1Address);
            const player2SlotCount = await craftingInstance.getSlotCount(account2Address);

            expect(player1LearnedRecipeCount).to.equal(0);
            expect(player2LearnedRecipeCount).to.equal(0);
            expect(player1SlotCount).to.equal(0);
            expect(player2SlotCount).to.equal(0);
        });

        it ("Should allow admin to clean recipe data", async function () {

            // Setup 
            const toolTokenAddress = await toolTokenInstance.address;

            // Act
            await craftingInstance.cleanRecipeData([toolTokenAddress]);

            // Assert
            const recipeCount = await craftingInstance.getRecipeCount(toolTokenAddress);
            expect(recipeCount).to.equal(0);
        });
    });

    /**
     * Test cleaning of Inventories
     */
    describe("Inventories", function () {

        // Data
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
                symbol: "FE26",
                name: "Iron",
                resource: Resource.Iron,
                weight: 100, // 1kg
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
            },
            {
                name: "Iron Axe",
                rarity: 1,
                level: 1,
                durability: 95, 
                multiplier_xp: 110, 
                multiplier_effectiveness: 110, 
                value1: 11, 
                value2: 22, 
                value3: 33,
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
                    learnable: true,
                    craftingTime: 600, // 10 min
                    ingredients: [
                        {
                            asset: "WOOD",
                            amount: "2"
                        },
                        {
                            asset: "FE26",
                            amount: "1"
                        }
                    ]
                }
            }
        ];

        const map: Map = {
            name: "Map 1".toBytes32(),
            sizeX: 2,
            sizeZ: 2,
            tiles: [
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        let account1Address: string;
        let account2Address: string;

        let inventoriesInstance: DevelopmentInventories;
        let toolTokenInstance: DevelopmentToolToken;

        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("DevelopmentAssetToken");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const ToolTokenFactory = await ethers.getContractFactory("DevelopmentToolToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);


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
            const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
            const accountRegisterAddress = await accountRegisterProxy.address;
            const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);

            // SKALE workaround
            await accountRegisterInstance.initializeManually();


            // Deploy Asset Register
            const assetRegisterProxy = await upgrades.deployProxy(
                AssetRegisterFactory, []);
 
            const assetRegisterAddress = await assetRegisterProxy.address;
            const assetRegisterInstance = await ethers.getContractAt("DevelopmentAssetRegister", assetRegisterAddress);

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
            const shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            const craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);


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
            const playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
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
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);


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
            const mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

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

            const toolTokenAddress = await toolTokenProxy.address;
            toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

            // Grant roles
            await toolTokenInstance.grantRole(SYSTEM_ROLE, system);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, toolTokenAddress);


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
                    .getContractAt("DevelopmentAssetToken", asset.contractAddress);
                
                await asset.contractInstance
                    .grantRole(SYSTEM_ROLE, system);

                await inventoriesInstance.grantRole(
                    SYSTEM_ROLE, asset.contractAddress)
                
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
                    environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: tile.elevationLevel,
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

            
            // Create account 1
            const createAccount1Transaction = await playerRegisterInstance.create([account1], 1, 0, "Player1".toBytes32(), 0, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(playerRegisterInstance, createAccount1Receipt, "account", "RegisterPlayer");

            // Create account 2
            const createAccount2Transaction = await playerRegisterInstance.create([account2], 1, 0, "Player2".toBytes32(), 0, 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(playerRegisterInstance, createAccount2Receipt, "account", "RegisterPlayer");


            // Mint assets
            const systemSigner = await ethers.provider.getSigner(system);
            for (let asset of assets)
            {
                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account1Address, Inventory.Backpack, "1".toWei());

                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account1Address, Inventory.Ship, "1".toWei());

                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account2Address, Inventory.Ship, "2".toWei());

                await asset.contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(account2Address, Inventory.Backpack, "2".toWei());
            }

            // Mint tools
            for (let tool of tools)
            {
                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(tool.name.toBytes32(), account1Address, Inventory.Backpack);

                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(tool.name.toBytes32(), account1Address, Inventory.Ship);

                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(tool.name.toBytes32(), account2Address, Inventory.Ship);

                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(tool.name.toBytes32(), account2Address, Inventory.Backpack);
            }
        });

        it ("Should contain ship data to clean", async function () {

            // Act
            const player1ToShip = await inventoriesInstance.playerToShip(account1Address);
            const player2ToShip = await inventoriesInstance.playerToShip(account2Address);

            const player1ShipInventory = await inventoriesInstance.getShipInventory(player1ToShip);
            const player2ShipInventory = await inventoriesInstance.getShipInventory(player2ToShip);

            // Assert
            expectInventorySpaceToContainData(player1ShipInventory);
            expectInventorySpaceToContainData(player2ShipInventory);
        });

        it ("Should contain player data to clean", async function () {

            // Act
            const player1BackpackInventory = await inventoriesInstance.getPlayerInventory(account1Address);
            const player2BackpackInventory = await inventoriesInstance.getPlayerInventory(account2Address);

            // Assert
            expectInventorySpaceToContainData(player1BackpackInventory);
            expectInventorySpaceToContainData(player2BackpackInventory);
        });

        it ("Should contain asset data to clean", async function () {

            for (let asset of assets)
            {
                // Act
                const fungibleAssetData = await inventoriesInstance.fungible(asset.contractAddress);

                // Assert
                expect(fungibleAssetData.weight).to.gt(0);
            }

            // Act
            const toolAssetData = await inventoriesInstance.nonFungible(await toolTokenInstance.address);

            // Assert
            expect(toolAssetData.weight).to.gt(0);
        });

        it ("Should not allow non-admin to clean ship data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);
            const player1ToShip = await inventoriesInstance.playerToShip(account1Address);
            const player2ToShip = await inventoriesInstance.playerToShip(account2Address);

            // Act
            const operation = inventoriesInstance
                .connect(nonAdminSigner)
                .cleanShipData([player1ToShip, player2ToShip]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(inventoriesInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean player data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = inventoriesInstance
                .connect(nonAdminSigner)
                .cleanPlayerData([account1Address, account2Address]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(inventoriesInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean asset data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = inventoriesInstance
                .connect(nonAdminSigner)
                .cleanAssetData();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(inventoriesInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should allow admin to clean ship data", async function () {

            // Setup 
            const player1ToShip = await inventoriesInstance.playerToShip(account1Address);
            const player2ToShip = await inventoriesInstance.playerToShip(account2Address);

            // Act
            await inventoriesInstance.cleanShipData([player1ToShip, player2ToShip]);

            // Assert
            const player1ShipInventory = await inventoriesInstance.getShipInventory(player1ToShip);
            const player2ShipInventory = await inventoriesInstance.getShipInventory(player2ToShip);

            expectInventorySpaceToBeEmpty(player1ShipInventory);
            expectInventorySpaceToBeEmpty(player2ShipInventory);
        }); 

        it ("Should allow admin to clean player data", async function () {

            // Act
            await inventoriesInstance.cleanPlayerData([account1Address, account2Address]);

            // Assert
            const player1ToShip = await inventoriesInstance.playerToShip(account1Address);
            const player2ToShip = await inventoriesInstance.playerToShip(account2Address);
            const player1BackpackInventory = await inventoriesInstance.getPlayerInventory(account1Address);
            const player2BackpackInventory = await inventoriesInstance.getPlayerInventory(account2Address);

            expect(player1ToShip).to.equal(0);
            expect(player2ToShip).to.equal(0);

            expectInventorySpaceToBeEmpty(player1BackpackInventory);
            expectInventorySpaceToBeEmpty(player2BackpackInventory);
        });

        it ("Should allow admin to clean asset data", async function () {

            // Act
            await inventoriesInstance.cleanAssetData();

            // Assert
            for (let asset of assets)
            {
                // Act
                const fungibleAssetData = await inventoriesInstance.fungible(asset.contractAddress);

                // Assert
                expect(fungibleAssetData.weight).to.equal(0);
            }

            // Act
            const toolAssetData = await inventoriesInstance.nonFungible(await toolTokenInstance.address);

            // Assert
            expect(toolAssetData.weight).to.equal(0);
        });

        /**
         * Helper function to assert inventory space contains data
         * 
         * @param inventorySpace 
         */
        function expectInventorySpaceToContainData(inventorySpace: InventorySpaceStructOutput)
        {
            expect(inventorySpace.weight).to.gt(0);
            expect(inventorySpace.maxWeight).to.gt(0);
            expect(inventorySpace.fungible.length).to.equal(assets.length);
            expect(inventorySpace.nonFungible.length).to.gt(0);

            for (let i = 0; i < inventorySpace.fungible.length; i++)
            {
                expect(inventorySpace.fungible[i].amount).to.gt(0);
            }

            for (let i = 0; i < inventorySpace.nonFungible.length; i++)
            {
                expect(inventorySpace.nonFungible[i].tokenIds.length).to.gt(0);
            }
        }

        /**
         * Helper function to assert inventory space does not contain data
         * 
         * @param inventorySpace 
         */
        function expectInventorySpaceToBeEmpty(inventorySpace: InventorySpaceStructOutput)
        {
            expect(inventorySpace.weight).to.equal(0);
            expect(inventorySpace.maxWeight).to.equal(0);

            for (let i = 0; i < inventorySpace.fungible.length; i++)
            {
                expect(inventorySpace.fungible[i].amount).to.equal(0);
            }
            
            for (let i = 0; i < inventorySpace.nonFungible.length; i++)
            {
                expect(inventorySpace.nonFungible[i].tokenIds.length).to.equal(0);
            }
        }
    });

    /**
     * Test cleaning of PirateMechanics
     */
    describe("PirateMechanics", function () {

        // Data
        const assets: Asset[] = [
            {
                symbol: "FUEL",
                name: "Fuel",
                resource: 16,
                weight: 200, // 2kg
                contractAddress: "",
                contractInstance: null
            }
        ];

        const map: Map = {
            name: "Map 1".toBytes32(),
            sizeX: 2,
            sizeZ: 2,
            tiles: [
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        let pirateAddress: string;
        let targetAddress: string;

        let pirateMechanicsInstance: DevelopmentPirateMechanics;


        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("DevelopmentAssetToken");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");
            const NavalBattleMechanicsFactory = await ethers.getContractFactory("DevelopmentNavalBattleMechanics");
            const PirateMechanicsFactory = await ethers.getContractFactory("DevelopmentPirateMechanics");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            const inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);


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
            const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
            const accountRegisterAddress = await accountRegisterProxy.address;
            const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);

            // SKALE workaround
            await accountRegisterInstance.initializeManually();


            // Deploy Asset Register
            const assetRegisterProxy = await upgrades.deployProxy(
                AssetRegisterFactory, []);
 
            const assetRegisterAddress = await assetRegisterProxy.address;
            const assetRegisterInstance = await ethers.getContractAt("DevelopmentAssetRegister", assetRegisterAddress);

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
            const shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            const craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);


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
            const playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
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
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);


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
            const mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

            // Grant roles
            await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, mapsAddress);
            await playerRegisterInstance.setMapsContract(mapsAddress);
            await mapsInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


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
                    .getContractAt("DevelopmentAssetToken", asset.contractAddress);
                
                await asset.contractInstance
                    .grantRole(SYSTEM_ROLE, system);

                await inventoriesInstance.grantRole(
                    SYSTEM_ROLE, asset.contractAddress)
                
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
                    environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: tile.elevationLevel,
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


            // Deploy Battle Mechanics
            const navalBattleMechanicsProxy = await upgrades.deployProxy(
                NavalBattleMechanicsFactory, 
                [
                    playerRegisterAddress,
                    mapsAddress,
                    shipTokenAddress
                ]);

            const navalBattleMechanicsAddress = await navalBattleMechanicsProxy.address;
            const navalBattleMechanicsInstance = await ethers.getContractAt("DevelopmentNavalBattleMechanics", navalBattleMechanicsAddress);

            // Grant roles
            await shipTokenInstance.grantRole(SYSTEM_ROLE, navalBattleMechanicsAddress);


            // Deploy Pirate Mechanics
            const pirateMechanicsProxy = await upgrades.deployProxy(
                PirateMechanicsFactory, 
                [
                    navalBattleMechanicsAddress,
                    playerRegisterAddress,
                    assetRegisterAddress,
                    mapsAddress,
                    shipTokenAddress,
                    getAssetByResource(
                        Resource.Fuel).contractAddress,
                    inventoriesAddress
                ]);

            const pirateMechanicsAddress = await pirateMechanicsProxy.address;
            pirateMechanicsInstance = await ethers.getContractAt("DevelopmentPirateMechanics", pirateMechanicsAddress);

            // Grant roles
            await navalBattleMechanicsInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
            await playerRegisterInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
            await shipTokenInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);
            await mapsInstance.grantRole(SYSTEM_ROLE, pirateMechanicsAddress);


            // Create target
            const createTargetTransaction = await playerRegisterInstance.create([account2], 1, 0, "Target".toBytes32(), 0, 0);
            const createTargetReceipt = await createTargetTransaction.wait();
            targetAddress = getParamFromEvent(playerRegisterInstance, createTargetReceipt, "account", "RegisterPlayer");

            // Create Pirate
            const createPirateTransaction = await playerRegisterInstance.create([account1], 1, 0, "Pirate".toBytes32(), 0, 0);
            const createPirateReceipt = await createPirateTransaction.wait();
            pirateAddress = getParamFromEvent(playerRegisterInstance, createPirateReceipt, "account", "RegisterPlayer");
            const pirateAccountInstance = await ethers.getContractAt("CryptopiaAccount", pirateAddress);
            const pirateAccountSigner = await ethers.provider.getSigner(account1);

            // Intercept target
            const interceptCalldata = pirateMechanicsInstance.interface
                .encodeFunctionData("intercept", [targetAddress, 0]);

            await pirateAccountInstance
                .connect(pirateAccountSigner)
                .submitTransaction(pirateMechanicsAddress, 0, interceptCalldata);
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

        it ("Should contain data to clean", async function () {

            // Act
            const target = await pirateMechanicsInstance.targets(pirateAddress);
            const confrontation = await pirateMechanicsInstance.confrontations(targetAddress);

            // Assert
            expect(target).to.equal(targetAddress);
            expect(confrontation.attacker).to.equal(pirateAddress);
            expect(confrontation.arrival).to.gt(0);
            expect(confrontation.deadline).to.gt(0);
            expect(confrontation.expiration).to.gt(0);
        });

        it ("Should not allow non-admin to clean data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = pirateMechanicsInstance
                .connect(nonAdminSigner)
                .clean([pirateAddress, targetAddress]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(pirateMechanicsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should allow admin to clean data", async function () {

            // Act
            await pirateMechanicsInstance.clean([pirateAddress, targetAddress]);

            // Assert
            const target = await pirateMechanicsInstance.targets(pirateAddress);    
            const confrontation = await pirateMechanicsInstance.confrontations(targetAddress);

            expect(target).to.equal(ZERO_ADDRESS);
            expect(confrontation.attacker).to.equal(ZERO_ADDRESS);
            expect(confrontation.arrival).to.equal(0);
            expect(confrontation.deadline).to.equal(0);
            expect(confrontation.expiration).to.equal(0);
        }); 
    });

    /**
     * Test cleaning of Quests
     */
    describe("Quests", function () {

        // Data
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
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                
                // Second row
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 7, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b1010101010101010101010101010' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: true, resources: [{ resource: Resource.Iron, amount: "100000".toWei() }, { resource: Resource.Gold, amount: "500".toWei() }] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                
                // Third row
                { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 4, waterLevel: 5, vegetationData: '0b101010101010101010101010101010101010101010' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b10000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Mountains, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 8, waterLevel: 5, vegetationData: '0b111111111111111111111111111111111111111111' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [{ resource: Resource.Gold, amount: "500".toWei() }] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },

                // Fourth row
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b1010101010101010101010101010' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: true, hasLake: false, resources: [{ resource: Resource.Iron, amount: "100000".toWei() }, { resource: Resource.Copper, amount: "5000".toWei() }] },
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 5, waterLevel: 5, vegetationData: '0b10101010101010101010101010101010101010101' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 4, waterLevel: 5, vegetationData: '0b111111111111111111111111111111111111111111' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b11000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b01000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },

                // Top row
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        let account1Address: string;
        let account2Address: string;

        let account1Instance: CryptopiaAccount;
        let account2Instance: CryptopiaAccount;

        let questsInstance: DevelopmentQuests;
        let questTokenInstance: DevelopmentQuestToken;
        let mapsInstance: DevelopmentMaps;

        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("DevelopmentAssetToken");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const ToolTokenFactory = await ethers.getContractFactory("DevelopmentToolToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");
            const QuestsFactory = await ethers.getContractFactory("DevelopmentQuests");
            const QuestTokenFactory = await ethers.getContractFactory("DevelopmentQuestToken");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            const inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);


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
            const accountRegisterProxy = await upgrades.deployProxy(AccountRegisterFactory);
            const accountRegisterAddress = await accountRegisterProxy.address;
            const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);

            // SKALE workaround
            await accountRegisterInstance.initializeManually();


            // Deploy Asset Register
            const assetRegisterProxy = await upgrades.deployProxy(
                AssetRegisterFactory, []);
 
            const assetRegisterAddress = await assetRegisterProxy.address;
            const assetRegisterInstance = await ethers.getContractAt("DevelopmentAssetRegister", assetRegisterAddress);

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
            const shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            const craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);

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
            const playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
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
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);


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
            mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

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

            const toolTokenAddress = await toolTokenProxy.address;
            const toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

            // Grant roles
            await toolTokenInstance.grantRole(SYSTEM_ROLE, system);
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

            const questTokenAddress = await questTokenProxy.address;
            questTokenInstance = await ethers.getContractAt("DevelopmentQuestToken", questTokenAddress);

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

            const questsAddress = await questsProxy.address;
            questsInstance = await ethers.getContractAt("DevelopmentQuests", questsAddress);

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
                    .getContractAt("DevelopmentAssetToken", asset.contractAddress);
                
                await asset.contractInstance
                    .grantRole(SYSTEM_ROLE, system);

                await inventoriesInstance.grantRole(
                    SYSTEM_ROLE, asset.contractAddress)
                
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


            // Add tool recipes
            await craftingInstance.setRecipes(
                tools.map((tool: any) => {
                    return {
                        level: tool.recipe.level,
                        learnable: tool.recipe.learnable,
                        asset: toolTokenAddress,
                        item: tool.name.toBytes32(),
                        craftingTime: tool.recipe.craftingTime,
                        ingredients: tool.recipe.ingredients.map((ingredient: any) => {
                            return {
                                asset: getAssetBySymbol(ingredient.asset).contractAddress,
                                amount: ingredient.amount.toWei()
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
                    environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: tile.elevationLevel,
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

            // Deploy quests
            const quest = {
                name: "Test Quest".toBytes32(),
                level: 0,
                hasFactionConstraint: false,
                faction: 0, 
                hasSubFactionConstraint: false,
                subFaction: SubFaction.None, 
                maxCompletions: 1,
                cooldown: 0,
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

            
            // Create account 1
            const createAccount1Transaction = await playerRegisterInstance.create([account1], 1, 0, "Player1".toBytes32(), 0, 0);
            const createAccount1Receipt = await createAccount1Transaction.wait();
            account1Address = getParamFromEvent(playerRegisterInstance, createAccount1Receipt, "account", "RegisterPlayer");
            account1Instance = await ethers.getContractAt("CryptopiaAccount", account1Address);
            const account1Signer = await ethers.provider.getSigner(account1);

            // Create account 2
            const createAccount2Transaction = await playerRegisterInstance.create([account2], 1, 0, "Player2".toBytes32(), 0, 0);
            const createAccount2Receipt = await createAccount2Transaction.wait();
            account2Address = getParamFromEvent(playerRegisterInstance, createAccount2Receipt, "account", "RegisterPlayer");
            account2Instance = await ethers.getContractAt("CryptopiaAccount", account2Address);
            const account2Signer = await ethers.provider.getSigner(account2);

            // Start quest without completing it
            const startQuestCallData1 = questsInstance.interface
                .encodeFunctionData("startQuest", [
                    quest.name,
                    [0],
                    [[Inventory.Backpack]],
                    [[]],
                    [[]]
                ]);
                
            const startQuestTransaction1 = await account1Instance
                .connect(account1Signer)
                .submitTransaction(questsAddress, 0, startQuestCallData1);
            await startQuestTransaction1.wait();

            // Complete step 1
            await travelToLocation(account1Instance, account1, [0, 1, 2, 7]);
            const completeStepCallData1 = questsInstance.interface
                .encodeFunctionData("completeStep", [
                    quest.name,
                    1,
                    [Inventory.Ship],
                    [],
                    [] 
                ]);

            const completeStepTransaction1 = await account1Instance
                .connect(account1Signer)
                .submitTransaction(questsAddress, 0, completeStepCallData1);
            await completeStepTransaction1.wait();

            // Start quest and complete quest
            const startQuestCallData2 = questsInstance.interface
                .encodeFunctionData("startQuest", [
                    quest.name,
                    [0],
                    [[Inventory.Backpack]],
                    [[]],
                    [[]]
                ]);
                
            const startQuestTransaction2 = await account2Instance
                .connect(account2Signer)
                .submitTransaction(questsAddress, 0, startQuestCallData2);

            const startQuestReceipt2 = await startQuestTransaction2.wait();
            const item1TokenId = getParamFromEvent(
                inventoriesInstance, startQuestReceipt2, "tokenId", "InventoryAssign");

            // Complete step 1
            await travelToLocation(account2Instance, account2, [0, 1, 2, 7]);
            const completeStepCallData2 = questsInstance.interface
                .encodeFunctionData("completeStep", [
                    quest.name,
                    1,
                    [Inventory.Ship],
                    [],
                    [] 
                ]);

            const completeStepTransaction2 = await account2Instance
                .connect(account2Signer)
                .submitTransaction(questsAddress, 0, completeStepCallData2);

            const completeStepReceipt2 = await completeStepTransaction2.wait();
            const item2TokenId = getParamFromEvent(
                inventoriesInstance, completeStepReceipt2, "tokenId", "InventoryAssign");

            // Complete quest and claim reward
            await travelToLocation(account2Instance, account2, [7, 8]);
            const completeStepAndClaimRewardCallData2 = questsInstance.interface
                .encodeFunctionData("completeStepAndClaimReward", [
                    quest.name,
                    2,
                    [],
                    [Inventory.Backpack, Inventory.Ship],
                    [item1TokenId, item2TokenId],
                    0,
                    Inventory.Backpack
                ]);

            await account2Instance
                .connect(account2Signer)
                .submitTransaction(questsAddress, 0, completeStepAndClaimRewardCallData2);
        });

        /**
         * Helper functions
         */
        const getAssetBySymbol = (symbol: string) : any => {
            return assets.find(asset => asset.symbol === symbol);
        };

        const getAssetByResource = (resource: Resource) : Asset => {
            const asset =  assets.find(
                asset => asset.resource === resource);

            if (!asset)
            {
                throw new Error(`No asset found for resource ${resource}`);
            }
                
            return asset;
        };

        const travelToLocation = async (accountInstance: CryptopiaAccount, accountAddress: string, path: number[]) => {

            // Travel to the correct tile
            const mapsAddress = await mapsInstance.address;
            const accountSigner = await ethers.provider
                .getSigner(accountAddress);

            const playerMoveCalldata = mapsInstance.interface
                .encodeFunctionData("playerMove", [path]);
            
            const playerMoveTransaction = await accountInstance
                .connect(accountSigner)
                .submitTransaction(mapsAddress, 0, playerMoveCalldata);

            const playerMoveReceipt = await playerMoveTransaction.wait();
            const arrival = getParamFromEvent(
                mapsInstance, playerMoveReceipt, "arrival", "PlayerMove");

            await time.increaseTo(arrival);
        };

        it ("Should contain player data to clean", async function () {

            // Setup 
            const questName = "Test Quest".toBytes32();

            // Act
            const playerData1 = await questsInstance.playerQuestData(account1Address, questName);
            const playerData2 = await questsInstance.playerQuestData(account2Address, questName);

            // Assert
            expect(playerData1.stepsCompletedCount).to.equal(2);
            expect(playerData1.timestampStarted).to.gt(0);

            expect(playerData2.completedCount).to.equal(1);
            expect(playerData2.timestampCompleted).to.gt(0);
            expect(playerData2.timestampClaimed).to.gt(0);
        });

        it ("Should contain quest data to clean", async function () {

            // Setup 
            const questName = "Test Quest".toBytes32();

            // Act
            const questCount = await questsInstance.getQuestCount();
            const questData = await questsInstance.getQuestAt(0);

            // Assert
            expect(questCount).to.equal(1);
            expect(questData.name).to.eq(questName);
            expect(questData.maxCompletions).to.gt(0);
            expect(questData.steps.length).to.eq(3);
            expect(questData.rewards.length).to.eq(2);
        });

        it ("Should contain quest item data to clean", async function () {

            // Setup 
            const item1Name = "Item 1".toBytes32();
            const item2Name = "Item 2".toBytes32();

            // Act
            const itemCount = await questTokenInstance.getItemCount();
            const item1Data = await questTokenInstance.getItemAt(0);
            const item2Data = await questTokenInstance.getItemAt(1);

            // Assert
            expect(itemCount).to.equal(2);
            expect(item1Data.name).to.eq(item1Name);
            expect(item2Data.name).to.eq(item2Name);
        });

        it ("Should contain quest item instance data to clean", async function () {

            // Setup
            const item1Name = "Item 1".toBytes32();
            const item2Name = "Item 2".toBytes32();

            // Act
            const item1Instance = await questTokenInstance.itemInstances(1);
            const item2Instance = await questTokenInstance.itemInstances(2);

            // Assert
            expect(item1Instance).to.eq(item1Name);
            expect(item2Instance).to.eq(item2Name);
        });

        it ("Should not allow non-admin to clean player data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = questsInstance
                .connect(nonAdminSigner)
                .cleanPlayerData([account1Address, account2Address]);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(questsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean quest data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = questsInstance
                .connect(nonAdminSigner)
                .cleanQuestData();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(questsInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean quest item data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = questTokenInstance
                .connect(nonAdminSigner)
                .cleanItemData();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(questTokenInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should not allow non-admin to clean quest item instance data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = questTokenInstance
                .connect(nonAdminSigner)
                .cleanTokenData(0, 2);

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(questTokenInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });

        it ("Should allow admin to clean player data", async function () {

            // Setup 
            const questName = "Test Quest".toBytes32();

            // Act
            await questsInstance.cleanPlayerData([account1Address, account2Address]);

            // Assert
            const playerData1 = await questsInstance.playerQuestData(account1Address, questName);
            const playerData2 = await questsInstance.playerQuestData(account2Address, questName);

            expect(playerData1.stepsCompletedCount).to.equal(0);
            expect(playerData1.timestampStarted).to.equal(0);

            expect(playerData2.completedCount).to.equal(0);
            expect(playerData2.timestampCompleted).to.equal(0);
            expect(playerData2.timestampClaimed).to.equal(0);
        });

        it ("Should allow admin to clean quest data", async function () {

            // Setup 
            const questName = "Test Quest".toBytes32();

            // Act
            await questsInstance.cleanQuestData();

            // Assert
            const questCount = await questsInstance.getQuestCount();
            const questData = await questsInstance.quests(questName)

            expect(questCount).to.equal(0);
            expect(questData.maxCompletions).to.eq(0);
        });

        it ("Should allow admin to clean quest item data", async function () {

            // Setup 
            const questItem1 = "Item 1".toBytes32();
            const questItem2 = "Item 2".toBytes32();

            // Act
            await questTokenInstance.cleanItemData();

            // Assert
            const itemCount = await questTokenInstance.getItemCount();
            const item1Data = await questTokenInstance.items(questItem1);
            const item2Data = await questTokenInstance.items(questItem2);

            expect(itemCount).to.equal(0);
            expect(item1Data).to.equal(0);
            expect(item2Data).to.equal(0);
        });

        it ("Should allow admin to clean quest item instance data", async function () {

            // Act
            await questTokenInstance.cleanTokenData(0, 2);

            // Assert
            const item1Instance = await questTokenInstance.itemInstances(1);
            const item2Instance = await questTokenInstance.itemInstances(2);

            expect(item1Instance).to.equal("".toBytes32());
            expect(item2Instance).to.equal("".toBytes32());
        });
    });

    /**
     * Test cleaning of BuildingRegister
     */
    describe("BuildingRegister", function () {

        // Data
        const assets: any[] = [
            {
                symbol: "WOOD",
                name: "Wood",
                resource: Resource.Wood,
                weight: 50, // 0.5kg
                contractAddress: "",
                system: [],
                contractInstance: {}
            },
            {
                symbol: "STONE",
                name: "Stone",
                resource: Resource.Stone,
                weight: 100, // 1kg
                contractAddress: "",
                system: [],
                contractInstance: {}
            },
            {
                symbol: "FE26",
                name: "Iron",
                resource: Resource.Iron,
                weight: 100, // 1kg
                system: [],
                contractAddress: "",
                contractInstance: {}
            },
            {
                symbol: "GLASS",
                name: "Glass",
                resource: Resource.Glass,
                weight: 100, // 1kg
                system: [],
                contractAddress: "",
                contractInstance: {}
            },
        ];
    
        const map: Map = {
            name: "Map 1".toBytes32(),
            sizeX: 2,
            sizeZ: 2,
            tiles: [
                { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Hills, environment: Environment.Coast, zone: Zone.Ecological, elevationLevel: 5, waterLevel: 5, vegetationData: '0b000110110001101100011011000110110001101100' , rockData: '0b0001101100011011000110110001' , wildlifeData: '0b00011011000110110001', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 1, safety: 50, biome: Biome.Grassland, terrain: Terrain.Flat, environment: Environment.Coast, zone: Zone.Neutral, elevationLevel: 6, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: true, resources: [] },
                { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.ShallowWater, zone: Zone.Ecological, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Hills, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };
    
        const buildings = [
            {
                name: "Improvised Mine".toBytes32(),
                rarity: Rarity.Common, 
                buildingType: BuildingType.Mine,
                modules: 1,
                co2: 100,
                base_health: 250,
                base_defence: 100,
                base_inventory: "120000".toWei(),
                upgradableFrom: "".toBytes32(),
                construction: {
                    constraints: {
                        hasMaxInstanceConstraint: false,
                        maxInstances: 0,
                        lake: Permission.Allowed,
                        river: Permission.Allowed,
                        dock: Permission.Allowed,
                        terrain: {
                            flat: true,
                            hills: true,
                            mountains: false,
                            seastead: false
                        },
                        biome: {
                            none: true,
                            plains: true,
                            grassland: true,
                            forest: true,
                            rainForest:true,
                            mangrove: false,
                            desert: true,
                            tundra: true,
                            swamp: false,
                            reef: false,
                            vulcanic: true
                        },
                        environment: {
                            beach: true,
                            coast: true,
                            inland: true,
                            coastalWater: false,
                            shallowWater: false,
                            deepWater: false
                        },
                        zone: {
                            neutral: true,
                            industrial: true,
                            ecological: false,
                            metropolitan: false
                        }
                    },
                    requirements: {
                        jobs: [
                            {
                                profession: Profession.Any,
                                hasMinimumLevel: false,
                                minLevel: 0,
                                hasMaximumLevel: false,
                                maxLevel: 0,
                                slots: 5,
                                xp: 100,
                                actionValue1: 100, // Progress per job
                                actionValue2: 0,
                            },
                            {
                                profession: Profession.Builder,
                                hasMinimumLevel: false,
                                minLevel: 0,
                                hasMaximumLevel: false,
                                maxLevel: 0,
                                slots: 2,
                                xp: 150,
                                actionValue1: 150, // Progress per job
                                actionValue2: 0,
                            },
                            {
                                profession: Profession.Architect,
                                hasMinimumLevel: false,
                                minLevel: 0,
                                hasMaximumLevel: false,
                                maxLevel: 0,
                                slots: 1,
                                xp: 200,
                                actionValue1: 200, // Progress per job
                                actionValue2: 0,
                            }
                        ],
                        resources: [
                            { 
                                resource: Resource.Wood, 
                                amount: "50".toWei()
                            },
                            { 
                                resource: Resource.Stone, 
                                amount: "50".toWei()
                            },
                            { 
                                resource: Resource.Iron, 
                                amount: "20".toWei()
                            },
                            { 
                                resource: Resource.Glass, 
                                amount: "20".toWei()
                            }
                        ],
                    }
                }
            }
        ];

        let buildingRegisterInstance: DevelopmentBuildingRegister;
        let constructionMechanicsInstance: DevelopmentConstructionMechanics;
    
        let registeredAccountInstance: CryptopiaAccount;
        let registeredAccountAddress: string;

        /**
         * Setup
         */
        before(async () => {

            // Factories
            const WhitelistFactory = await ethers.getContractFactory("DevelopmentWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("DevelopmentAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("DevelopmentPlayerRegister");
            const CryptopiaTokenFactory = await ethers.getContractFactory("MockERC20Token");
            const AssetRegisterFactory = await ethers.getContractFactory("DevelopmentAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("DevelopmentAssetToken");
            const ShipTokenFactory = await ethers.getContractFactory("DevelopmentShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("DevelopmentShipSkinToken");
            const ToolTokenFactory = await ethers.getContractFactory("DevelopmentToolToken");
            const InventoriesFactory = await ethers.getContractFactory("DevelopmentInventories");
            const CraftingFactory = await ethers.getContractFactory("DevelopmentCrafting");
            const TitleDeedTokenFactory = await ethers.getContractFactory("DevelopmentTitleDeedToken");
            const MapsFactory = await ethers.getContractFactory("DevelopmentMaps");
            const BlueprintTokenFactory = await ethers.getContractFactory("DevelopmentBlueprintToken");
            const BuildingRegisterFactory = await ethers.getContractFactory("DevelopmentBuildingRegister");
            const ConstructionMechanicsFactory = await ethers.getContractFactory("DevelopmentConstructionMechanics");
            
            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;
            const inventoriesInstance = await ethers.getContractAt("DevelopmentInventories", inventoriesAddress);

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
            const accountRegisterInstance = await ethers.getContractAt("DevelopmentAccountRegister", accountRegisterAddress);

            // SKALE workaround
            await accountRegisterInstance.initializeManually();


            // Deploy Asset Register
            const assetRegisterProxy = await upgrades.deployProxy(
                AssetRegisterFactory, []);

            const assetRegisterAddress = await assetRegisterProxy.address;
            const assetRegisterInstance = await ethers.getContractAt("DevelopmentAssetRegister", assetRegisterAddress);

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
            const shipTokenInstance = await ethers.getContractAt("DevelopmentShipToken", shipTokenAddress);


            // Deploy Crafting
            const craftingProxy = await upgrades.deployProxy(
                CraftingFactory, 
                [
                    inventoriesAddress
                ]);

            const craftingAddress = await craftingProxy.address;
            const craftingInstance = await ethers.getContractAt("DevelopmentCrafting", craftingAddress);

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
            const playerRegisterInstance = await ethers.getContractAt("DevelopmentPlayerRegister", playerRegisterAddress);

            // Grant roles
            await playerRegisterInstance.grantRole(SYSTEM_ROLE, system);    
            await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
            await craftingInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);


            // Deploy Cryptopia Token
            const cryptopiaTokenProxy = await upgrades.deployProxy(
                CryptopiaTokenFactory);

            const cryptopiaTokenAddress = await cryptopiaTokenProxy.address;
            const cryptopiaTokenInstance = await ethers.getContractAt("MockERC20Token", cryptopiaTokenAddress);


            // Deploy title deed token
            const titleDeedTokenProxy = await upgrades.deployProxy(
                TitleDeedTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
                ]);

            const titleDeedTokenAddress = await titleDeedTokenProxy.address;
            const titleDeedTokenInstance = await ethers.getContractAt("DevelopmentTitleDeedToken", titleDeedTokenAddress);

            // Grant roles
            await titleDeedTokenInstance.grantRole(SYSTEM_ROLE, system);

            
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
            const mapsInstance = await ethers.getContractAt("DevelopmentMaps", mapsAddress);

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

            const toolTokenAddress = await toolTokenProxy.address;
            const toolTokenInstance = await ethers.getContractAt("DevelopmentToolToken", toolTokenAddress);

            // Grant roles
            await toolTokenInstance.grantRole(SYSTEM_ROLE, craftingAddress);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, toolTokenAddress);


            // Deploy Blueprint token
            const blueprintTokenProxy = await upgrades.deployProxy(
                BlueprintTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
                ]);

            const blueprintTokenAddress = await blueprintTokenProxy.address;
            const blueprintTokenInstance = await ethers.getContractAt("DevelopmentBlueprintToken", blueprintTokenAddress);

            // Grant roles
            await blueprintTokenInstance.grantRole(SYSTEM_ROLE, system);


            // Deploy Resource building register
            const buildingRegisterProxy = await upgrades.deployProxy(
                BuildingRegisterFactory, 
                [
                    mapsAddress
                ]);

            const buildingRegisterAddress = await buildingRegisterProxy.address;
            buildingRegisterInstance = await ethers.getContractAt("DevelopmentBuildingRegister", buildingRegisterAddress);

            // Grant roles
            await blueprintTokenInstance.grantRole(SYSTEM_ROLE, buildingRegisterAddress);
            await buildingRegisterInstance.grantRole(SYSTEM_ROLE, system);


            // Deploy Construction Mechanics
            const constructionMechanicsProxy = await upgrades.deployProxy(
                ConstructionMechanicsFactory, 
                [
                    treasury,
                    cryptopiaTokenAddress,
                    titleDeedTokenAddress,
                    blueprintTokenAddress,
                    assetRegisterAddress,
                    playerRegisterAddress,
                    buildingRegisterAddress,
                    inventoriesAddress,
                    mapsAddress
                ]);

            const constructionMechanicsAddress = await constructionMechanicsProxy.address;
            constructionMechanicsInstance = await ethers.getContractAt("DevelopmentConstructionMechanics", constructionMechanicsAddress);

            // Grant roles
            await playerRegisterInstance.grantRole(SYSTEM_ROLE, constructionMechanicsAddress);
            await buildingRegisterInstance.grantRole(SYSTEM_ROLE, constructionMechanicsAddress);
            await blueprintTokenInstance.grantRole(SYSTEM_ROLE, constructionMechanicsAddress);
            await inventoriesInstance.grantRole(SYSTEM_ROLE, constructionMechanicsAddress);


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
                    .getContractAt("DevelopmentAssetToken", asset.contractAddress);

                await asset.contractInstance.grantRole(SYSTEM_ROLE, system);
                await inventoriesInstance.grantRole(SYSTEM_ROLE, asset.contractAddress);
                
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
                    environment: tile.environment,
                    zone: tile.zone,
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

            // Add buildings
            await buildingRegisterInstance.setBuildings(buildings);

            
            // Create registered account
            const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Registered_Username".toBytes32(), 0, 0);
            const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
            registeredAccountAddress = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
            registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress);
        });

        it ("Should contain building data to clean", async function () {

            // Act
            const buildingCount = await buildingRegisterInstance.getBuildingCount();

            // Assert
            expect(buildingCount).to.equal(buildings.length);
        });

        it ("Should not allow non-admin to clean building data", async function () {

            // Setup 
            const nonAdminSigner = await ethers.provider.getSigner(other);

            // Act
            const operation = buildingRegisterInstance
                .connect(nonAdminSigner)
                .cleanBuildingData();

            // Assert
            await expect(operation).to.be
                .revertedWithCustomError(buildingRegisterInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, DEFAULT_ADMIN_ROLE);
        });
        
        it ("Should allow admin to clean", async function () {

            // Act
            await buildingRegisterInstance.cleanBuildingData();

            // Assert
            const buildingCount = await buildingRegisterInstance.getBuildingCount();
            expect(buildingCount).to.equal(0);
        }); 
    });
});