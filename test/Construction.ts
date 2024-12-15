import "../scripts/helpers/converters.ts";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { getParamFromEvent} from '../scripts/helpers/events';
import { encodeRockData, encodeVegetationData, encodeWildlifeData } from '../scripts/maps/helpers/encoders';
import { resolveEnum } from "../scripts/helpers/enums";
import { Permission, Rarity, Resource, Profession, Terrain, Biome, Environment, Zone, BuildingType, Inventory } from '../scripts/types/enums';
import { Map } from "../scripts/types/input";
import { SYSTEM_ROLE } from "./settings/roles";   
import { BuildingConfig } from "./settings/config";   

import { 
    MockERC20Token,
    CryptopiaAccount,
    CryptopiaAccountRegister,
    CryptopiaPlayerRegister,
    CryptopiaInventories,
    CryptopiaShipToken,
    CryptopiaToolToken,
    CryptopiaCrafting,
    CryptopiaBlueprintToken,
    CryptopiaTitleDeedToken,
    CryptopiaAssetRegister,
    CryptopiaBuildingRegister,
    CryptopiaConstructionMechanics,
    CryptopiaMaps
} from "../typechain-types";
import { BuildingStruct } from "../typechain-types/contracts/source/game/buildings/IBuildingRegister.js";
import { ResourceContractDepositStruct } from "../typechain-types/contracts/source/game/mechanics/construction/IConstructionMechanics.js";

import { BigNumber, ContractTransaction } from "ethers";


/**
 * Construction tests
 * 
 * Test cases:
 * - Start construction
 */
describe("Construction Contracts", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let account1: string;
    let account2: string;
    let other: string;
    let treasury: string;

    // Instances
    let accountRegisterInstance: CryptopiaAccountRegister;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let cryptopiaTokenInstance: MockERC20Token;
    let shipTokenInstance: CryptopiaShipToken;
    let toolTokenInstance: CryptopiaToolToken;
    let craftingInstance: CryptopiaCrafting;
    let blueprintTokenInstance: CryptopiaBlueprintToken;
    let titleDeedTokenInstance: CryptopiaTitleDeedToken;
    let assetRegisterInstance: CryptopiaAssetRegister;
    let buildingRegisterInstance: CryptopiaBuildingRegister;
    let constructionMechanicsInstance: CryptopiaConstructionMechanics;
    let mapsInstance: CryptopiaMaps;

    let registeredAccountInstance: CryptopiaAccount;
    let unregisteredAccountInstance: CryptopiaAccount;

    let registeredAccountAddress: string;
    let unregisteredAccountAddress: string;

    // Mock Data
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
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Hills, environment: Environment.Coast, zone: Zone.Ecological, elevationLevel: 5, waterLevel: 5, vegetationData: '0b000110110001101100011011000110110001101100' , rockData: '0b0001101100011011000110110001' , wildlifeData: '0b00011011000110110001', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.Grassland, terrain: Terrain.Flat, environment: Environment.Coast, zone: Zone.Neutral, elevationLevel: 6, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: true, resources: [] },
            { group: 0, safety: 50, biome: Biome.Reef, terrain: Terrain.Flat, environment: Environment.ShallowWater, zone: Zone.Ecological, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Hills, environment: Environment.DeepWater, zone: Zone.Neutral, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
        ]
    };

    const buildings: BuildingStruct[] = [
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

    /**s
     * Deploy Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, account1, account2, other, treasury] = (
            await ethers.getSigners()).map(s => s.address);

        // Factories
        const WhitelistFactory = await ethers.getContractFactory("CryptopiaWhitelist");
        const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
        const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
        const CryptopiaTokenFactory = await ethers.getContractFactory("MockERC20Token");
        const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
        const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
        const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
        const ShipSkinTokenFactory = await ethers.getContractFactory("CryptopiaShipSkinToken");
        const ToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
        const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
        const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
        const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
        const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
        const BlueprintTokenFactory = await ethers.getContractFactory("CryptopiaBlueprintToken");
        const BuildingRegisterFactory = await ethers.getContractFactory("CryptopiaBuildingRegister");
        const ConstructionMechanicsFactory = await ethers.getContractFactory("CryptopiaConstructionMechanics");
        
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
        assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);

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


        // Deploy Cryptopia Token
        const cryptopiaTokenProxy = await upgrades.deployProxy(
            CryptopiaTokenFactory);

        const cryptopiaTokenAddress = await cryptopiaTokenProxy.address;
        cryptopiaTokenInstance = await ethers.getContractAt("MockERC20Token", cryptopiaTokenAddress);


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

        const toolTokenAddress = await toolTokenProxy.address;
        toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

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
        blueprintTokenInstance = await ethers.getContractAt("CryptopiaBlueprintToken", blueprintTokenAddress);

        // Grant roles
        await blueprintTokenInstance.grantRole(SYSTEM_ROLE, system);


        // Deploy Resource building register
        const buildingRegisterProxy = await upgrades.deployProxy(
            BuildingRegisterFactory, 
            [
                mapsAddress
            ]);

        const buildingRegisterAddress = await buildingRegisterProxy.address;
        buildingRegisterInstance = await ethers.getContractAt("CryptopiaBuildingRegister", buildingRegisterAddress);

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
        constructionMechanicsInstance = await ethers.getContractAt("CryptopiaConstructionMechanics", constructionMechanicsAddress);

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
                .getContractAt("CryptopiaAssetToken", asset.contractAddress);

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

            
        // Create registered account
        const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Registered_Username".toBytes32(), 0, 0);
        const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
        registeredAccountAddress = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
        registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress);

        // Create unregistered account
        const createUnregisteredAccountTransaction = await accountRegisterInstance.create([account2], 1, 0, "Unregistered_Username".toBytes32(), 0);
        const createUnregisteredAccountReceipt = await createUnregisteredAccountTransaction.wait();
        unregisteredAccountAddress = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
        unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccountAddress);
    });

    /**
     * Test Building Register
     */
    describe("Buildings (admin)", function () {

        it("Admin should be able to add buildings", async () => {
        
            // Act
            await buildingRegisterInstance.setBuildings(buildings);
            
            // Assert
            const buildingCount = await buildingRegisterInstance.getBuildingCount();
            expect(buildingCount).to.equal(buildings.length);
        });
    });


    /**
     * Test Construction (system)
     */
    describe("Construction (system)", function () {

        let transaction: ContractTransaction;

        it("System should be able to start construction", async () => {
        
            // Setup
            const tileIndex = 1;
            const building = "Improvised Mine".toBytes32();
            
            // Act
            const signer = await ethers.provider.getSigner(system);
            transaction = await buildingRegisterInstance
                .connect(signer)
                .__startConstruction(tileIndex, building);

            // Assert
            const buildingInstance = await buildingRegisterInstance.getBuildingInstance(tileIndex);
            expect(buildingInstance.name).to.equal(building);
            expect(buildingInstance.construction).to.equal(0);
        });

        it ("Should emit 'BuildingConstructionStart' event ", async () => {
            
            // Setup
            const tileIndex = 1;
            const building = "Improvised Mine".toBytes32();

            // Assert
            await expect(transaction).to
                .emit(buildingRegisterInstance, "BuildingConstructionStart")
                .withArgs(tileIndex, building);
        });

        it ("System should be able to progress construction", async () => {
                
            // Setup
            const tileIndex = 1;
            const progress = 500;

            // Act
            const signer = await ethers.provider.getSigner(system);
            transaction = await buildingRegisterInstance
                .connect(signer)
                .__progressConstruction(tileIndex, progress);

            // Assert
            const buildingInstance = await buildingRegisterInstance.getBuildingInstance(tileIndex);
            expect(buildingInstance.construction).to.equal(progress);
        });

        it ("Should emit 'BuildingConstructionProgress' event (intermediar)", async () => {

            // Setup
            const tileIndex = 1;
            const building = "Improvised Mine".toBytes32();
            const progress = 500;
            const completed = false;

            // Assert
            await expect(transaction).to
                .emit(buildingRegisterInstance, "BuildingConstructionProgress")
                .withArgs(tileIndex, building, progress, completed);
        });

        it ("System should be able to complete construction", async () => {

            // Setup
            const tileIndex = 1;
            const progress = BuildingConfig.CONSTRUCTION_COMPLETE; // Always enough to complete

            // Act
            const signer = await ethers.provider.getSigner(system);
            transaction = await buildingRegisterInstance
                .connect(signer)
                .__progressConstruction(tileIndex, progress);

            // Assert
            const buildingInstance = await buildingRegisterInstance.getBuildingInstance(tileIndex);
            expect(buildingInstance.construction).to.equal(BuildingConfig.CONSTRUCTION_COMPLETE);
        });

        it ("Should emit 'BuildingConstructionProgress' event (complete)", async () => {

            // Setup
            const tileIndex = 1;
            const building = "Improvised Mine".toBytes32();
            const progress = BuildingConfig.CONSTRUCTION_COMPLETE - 500;
            const completed = true;

            // Assert
            await expect(transaction).to
                .emit(buildingRegisterInstance, "BuildingConstructionProgress")
                .withArgs(tileIndex, building, progress, completed);
        });

        it ("System should be able to destroy construction", async () => {

            // Setup
            const tileIndex = 1;

            // Act
            const signer = await ethers.provider.getSigner(system);
            transaction = await buildingRegisterInstance
                .connect(signer)
                .__destroyConstruction(tileIndex);

            // Assert
            const buildingInstance = await buildingRegisterInstance.getBuildingInstance(tileIndex);
            expect(buildingInstance.name).to.equal(ethers.constants.HashZero);
        });

        it ("Should emit 'BuildingConstructionDestroy' event", async () => {

            // Setup
            const tileIndex = 1;
            const building = "Improvised Mine".toBytes32();

            // Assert
            await expect(transaction).to
                .emit(buildingRegisterInstance, "BuildingConstructionDestroy")
                .withArgs(tileIndex, building);
        });
    });


    /**
     * Test Construction (player)
     */
    describe("Construction (player)", function () {

        // Compensation per player
        const jobCompenstations = [
            "100".toWei(), // Any 
            "200".toWei(), // Builder
            "1000".toWei() // Architect
        ];

        // Compensation per resource unit
        const resourceCompensations = [
            "1", // Wood
            "1", // Stone
            "5", // Iron
            "2"  // Glass
        ];

        let transaction: ContractTransaction;

        it("Non-Player should be able to start construction", async () => {
        
            // Setup
            const building = buildings[0];
            const tileIndex = 1;
            const titleDeedId = 2; 
            const blueprintId = 1; 
            const cryptopiaTokenAddress = await cryptopiaTokenInstance.address;
            const constructionMechanicsAddress = await constructionMechanicsInstance.address;
            const systemSigner = await ethers.provider.getSigner(system);
            const nonPlayerAccountSigner = await ethers.provider.getSigner(account2);
            const nonPlayerAccountInstance = unregisteredAccountInstance;
            const nonPlayerAccountAddress = unregisteredAccountAddress;

            let totalCompensation = BigNumber.from(0);
            for (let i = 0; i < building.construction.requirements.jobs.length; i++)
            {
                const slots = building.construction.requirements.jobs[i].slots.valueOf();
                totalCompensation = totalCompensation.add(BigNumber.from(slots).mul(jobCompenstations[i]));
            }

            for (let i = 0; i < building.construction.requirements.resources.length; i++)
            {
                const amount = String(building.construction.requirements.resources[i].amount.valueOf());
                totalCompensation = totalCompensation.add(BigNumber.from(resourceCompensations[i]).mul(amount));
            }

            const totalTax = totalCompensation.mul(BuildingConfig.TAX_RATE).div(BuildingConfig.TAX_RATE_PRECISION);
            const totalCost = totalCompensation.add(totalTax);

            // Ensure sufficient funds
            await cryptopiaTokenInstance
                .__mint(nonPlayerAccountAddress, totalCost);

            // Approve spending
            const approveCallData = cryptopiaTokenInstance.interface.encodeFunctionData(
                "approve", [constructionMechanicsAddress, totalCost]);

            await nonPlayerAccountInstance
                .connect(nonPlayerAccountSigner)
                .submitTransaction(cryptopiaTokenAddress, 0, approveCallData);

            // Mint blueprint
            await blueprintTokenInstance
                .connect(systemSigner)
                .__mintTo(nonPlayerAccountAddress, building.name);

            // Mint title deed
            await titleDeedTokenInstance
                .connect(systemSigner)
                .__mintTo(nonPlayerAccountAddress, tileIndex);

            // Act
            const startConstructionCallData = constructionMechanicsInstance.interface.encodeFunctionData(
                "startConstruction", [titleDeedId, blueprintId, jobCompenstations, resourceCompensations]);

            transaction = await nonPlayerAccountInstance
                .connect(nonPlayerAccountSigner)
                .submitTransaction(constructionMechanicsAddress, 0, startConstructionCallData);

            // Assert
            const buildingInstance = await buildingRegisterInstance.getBuildingInstance(tileIndex);
            expect(buildingInstance.name).to.equal(building.name);
            expect(buildingInstance.construction).to.equal(0);
        });

        it ("Should emit 'BuildingConstructionStart' event ", async () => {
            
            // Setup
            const tileIndex = 1;
            const building = buildings[0];

            // Assert
            await expect(transaction).to
                .emit(buildingRegisterInstance, "BuildingConstructionStart")
                .withArgs(tileIndex, building.name);
        });

        it ("Player should be able to deposit resources in exchange for $TOS", async () => {

            // Setup
            const tileIndex = 1;
            const deposits = [
                { 
                    contractIndex: 0,
                    inventory: Inventory.Backpack,
                    amount: "50".toWei()
                },
                { 
                    contractIndex: 1,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                },
                { 
                    contractIndex: 2,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                },
                { 
                    contractIndex: 3,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                }
            ];

            const compensations = [
                resourceCompensations[0],
                resourceCompensations[1],
                resourceCompensations[2],
                resourceCompensations[3]
            ];

            const systemSigner = await ethers.provider.getSigner(system);
            const playerAccountSigner = await ethers.provider.getSigner(account1);
            const playerAccountInstance = registeredAccountInstance;
            const playerAccountAddress = registeredAccountAddress;

            const constructionContract = await constructionMechanicsInstance
                .getConstructionContract(tileIndex);

            // Ensure sufficient resources
            for (let i = 0; i < deposits.length; i++)
            {
                const resource = constructionContract.resources[deposits[i].contractIndex].resource;
                await getAssetByResource(resource).contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(playerAccountAddress, deposits[i].inventory, deposits[i].amount);
            }

            // Travel to the correct tile
            await travelToLocation(playerAccountInstance, playerAccountSigner, [0, tileIndex]);

            // Act
            const depositCallData = constructionMechanicsInstance.interface.encodeFunctionData(
                "depositResources", [tileIndex, deposits]);

            transaction = await playerAccountInstance
                .connect(playerAccountSigner)
                .submitTransaction(constructionMechanicsInstance.address, 0, depositCallData);

            // Assert
            const balance = await cryptopiaTokenInstance.balanceOf(playerAccountAddress);
            let expectedBalance = BigNumber.from(0);
            for (let i = 0; i < deposits.length; i++)
            {
                const amount = deposits[i].amount;
                expectedBalance = expectedBalance.add(BigNumber.from(amount).mul(compensations[i]));
            }

            expect(balance).to.equal(expectedBalance);
        });

        it ("Should emit 'ConstructionResourceDeposit' events", async () => {
                
            // Setup
            const tileIndex = 1;
            const deposits = [
                { 
                    contractIndex: 0,
                    inventory: Inventory.Backpack,
                    amount: "50".toWei()
                },
                { 
                    contractIndex: 1,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                },
                { 
                    contractIndex: 2,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                },
                { 
                    contractIndex: 3,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                }
            ];

            const playerAccountAddress = registeredAccountAddress;
            const constructionContract = await constructionMechanicsInstance
                .getConstructionContract(tileIndex);

            // Assert
            for (let i = 0; i < deposits.length; i++)
            {
                const resource = constructionContract.resources[deposits[i].contractIndex].resource;
                await expect(transaction).to
                    .emit(constructionMechanicsInstance, "ConstructionResourceDeposit")
                    .withArgs(playerAccountAddress, tileIndex, resource, deposits[i].amount);
            }
        });

        it ("Should record intermediair resource deposit progress (intermediar)", async () => {
                
            // Setup
            const tileIndex = 1;
            const currentProgress = 1;

            // Assert
            const constructionContract = await constructionMechanicsInstance
                .getConstructionContract(tileIndex); 

            expect(constructionContract.resourceProgress).to.equal(currentProgress);
        });

        it ("Players should be able to fufill all resource contracts", async () => {

            // Setup
            const tileIndex = 1;
            const deposits = [
                { 
                    contractIndex: 1,
                    inventory: Inventory.Backpack,
                    amount: "40".toWei()
                },
                { 
                    contractIndex: 2,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                },
                { 
                    contractIndex: 3,
                    inventory: Inventory.Backpack,
                    amount: "10".toWei()
                }
            ];

            const compensations = [
                resourceCompensations[1],
                resourceCompensations[2],
                resourceCompensations[3]
            ];

            const systemSigner = await ethers.provider.getSigner(system);
            const playerAccountSigner = await ethers.provider.getSigner(account1);
            const playerAccountInstance = registeredAccountInstance;
            const playerAccountAddress = registeredAccountAddress;

            const constructionContract = await constructionMechanicsInstance
                .getConstructionContract(tileIndex);

            // Ensure sufficient resources
            for (let i = 0; i < deposits.length; i++)
            {
                const resource = constructionContract.resources[deposits[i].contractIndex].resource;
                await getAssetByResource(resource).contractInstance
                    ?.connect(systemSigner)
                    .__mintToInventory(playerAccountAddress, deposits[i].inventory, deposits[i].amount);
            }

            const balanceBefore = await cryptopiaTokenInstance.balanceOf(playerAccountAddress);

            // Act
            const depositCallData = constructionMechanicsInstance.interface.encodeFunctionData(
                "depositResources", [tileIndex, deposits]);

            transaction = await playerAccountInstance
                .connect(playerAccountSigner)
                .submitTransaction(constructionMechanicsInstance.address, 0, depositCallData);

            // Assert
            const balanceAfter = await cryptopiaTokenInstance.balanceOf(playerAccountAddress);
            let expectedBalance = BigNumber.from(0);
            for (let i = 0; i < deposits.length; i++)
            {
                const amount = deposits[i].amount;
                expectedBalance = expectedBalance.add(BigNumber.from(amount).mul(compensations[i]));
            }

            expect(balanceAfter).to.equal(balanceBefore.add(expectedBalance));
        });

        it ("Should record resource deposit progress (complete)", async () => {
                
            // Setup
            const tileIndex = 1;
            const currentProgress = 4;

            // Assert
            const constructionContract = await constructionMechanicsInstance
                .getConstructionContract(tileIndex); 

            expect(constructionContract.resourceProgress).to.equal(currentProgress);
        });

        // it ("Player should be able to progress construction in exchange for $TOS", async () => {

        //     // Setup
        //     const tileIndex = 1;
        //     const progress = 500;
        //     const systemSigner = await ethers.provider.getSigner(system);
        //     const playerAccountSigner = await ethers.provider.getSigner(account1);
        //     const playerAccountInstance = registeredAccountInstance;
        //     const playerAccountAddress = registeredAccountAddress;

        //     const constructionContract = await constructionMechanicsInstance
        //         .getConstructionContract(tileIndex);

        //     const totalCost = BigNumber.from(progress).mul(BuildingConfig.CONSTRUCTION_COST);

        //     // Ensure sufficient funds
        //     await cryptopiaTokenInstance
        //         .__mint(playerAccountAddress, totalCost);

        //     // Travel to the correct tile
        //     await travelToLocation(playerAccountInstance, playerAccountSigner, [0, tileIndex]);

        //     // Act
        //     const progressCallData = constructionMechanicsInstance.interface.encodeFunctionData(
        //         "progressConstruction", [tileIndex, progress]);

        //     transaction = await playerAccountInstance
        //         .connect(playerAccountSigner)
        //         .submitTransaction(constructionMechanicsInstance.address, 0, progressCallData);

        //     // Assert
        //     const buildingInstance = await buildingRegisterInstance.getBuildingInstance(tileIndex);
        //     expect(buildingInstance.construction).to.equal(progress);
        // });
    });


    /**
     * Helper functions
     */
    const travelToLocation = async (playerInstance: CryptopiaAccount, playerSigner: any, path: number[]) => {

        // Travel to the correct tile
        const mapsAddress = await mapsInstance.address;
        const playerMoveCalldata = mapsInstance.interface
            .encodeFunctionData("playerMove", [path]);
        
        const playerMoveTransaction = await playerInstance
            .connect(playerSigner)
            .submitTransaction(mapsAddress, 0, playerMoveCalldata);

        const playerMoveReceipt = await playerMoveTransaction.wait();
        const arrival = getParamFromEvent(
            mapsInstance, playerMoveReceipt, "arrival", "PlayerMove");

        await time.increaseTo(arrival);
    };

    const getAssetByResource = (resource: Resource) => {
        const asset =  assets.find(
            asset => asset.resource === resource);

        if (!asset)
        {
            throw new Error(`No asset found for resource ${resource}`);
        }
            
        return asset;
    };

    const getAssetBySymbol = (symbol: string) => {
        return assets.find(asset => asset.symbol === symbol);
    };
});