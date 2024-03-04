import "../scripts/helpers/converters.ts";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { getParamFromEvent} from '../scripts/helpers/events';
import { encodeRockData, encodeVegetationData, encodeWildlifeData } from '../scripts/maps/helpers/encoders';
import { resolveEnum } from "../scripts/helpers/enums";
import { Resource, Terrain, Biome, Inventory } from '../scripts/types/enums';
import { Map } from "../scripts/types/input";
import { REVERT_MODE } from "./settings/config";
import { SYSTEM_ROLE } from "./settings/roles";   

import { 
    CryptopiaAccount,
    CryptopiaAccountRegister,
    CryptopiaPlayerRegister,
    CryptopiaInventories,
    CryptopiaShipToken,
    CryptopiaToolToken,
    CryptopiaCrafting
} from "../typechain-types";


/**
 * Inventories Contract
 */
describe("Inventories Contract", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let treasury: string;

    /**
     * Setup accounts 
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, treasury] = (
            await ethers.getSigners()).map(s => s.address);
    });

    /**
     * Test transfer between owned inventories
     */
    describe("Transfer", function () {

        // Data
        const assets: any[] = [
            {
                symbol: "WOOD",
                name: "Wood",
                resource: 3,
                weight: 50, // 0.5kg
                contractAddress: "",
                contractInstance: {}
            },
            {
                symbol: "STONE",
                name: "Stone",
                resource: 4,
                weight: 100, // 1kg
                contractAddress: "",
                contractInstance: {}
            },
            {
                symbol: "FE26",
                name: "Iron",
                resource: 7,
                weight: 100, // 1kg
                contractAddress: "",
                contractInstance: {}
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
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        // Instances
        let accountRegisterInstance: CryptopiaAccountRegister;
        let playerRegisterInstance: CryptopiaPlayerRegister;
        let inventoriesInstance: CryptopiaInventories;
        let shipTokenInstance: CryptopiaShipToken;
        let toolTokenInstance: CryptopiaToolToken;
        let craftingInstance: CryptopiaCrafting;

        let registeredAccountInstance: CryptopiaAccount;
        let registeredAccountAddress: string;

        /**
         * Deploy Crafting Contracts
         */
        before(async () => {

            // Signers
            const systemSigner = await ethers.provider.getSigner(system);

            // Factories
            const WhitelistFactory = await ethers.getContractFactory("CryptopiaWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
            const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
            const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
            const ToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
            const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
            const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
            const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
            const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
            
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
            const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);

            // Grant roles
            await assetRegisterInstance.grantRole(SYSTEM_ROLE, system);


            // Deploy Ships
            const shipTokenProxy = await upgrades.deployProxy(
                ShipTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
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


            // Deploy title deed token
            const titleDeedTokenProxy = await upgrades.deployProxy(
                TitleDeedTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
                ]);

            const titleDeedTokenAddress = await titleDeedTokenProxy.address;
            const titleDeedTokenInstance = await ethers.getContractAt("CryptopiaTitleDeedToken", titleDeedTokenAddress);

            
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
            const mapsInstance = await ethers.getContractAt("CryptopiaMaps", mapsAddress);

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
            await toolTokenInstance.grantRole(SYSTEM_ROLE, craftingAddress);
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
                    .getContractAt("CryptopiaAssetToken", asset.contractAddress);

                await asset.contractInstance
                    .grantRole(SYSTEM_ROLE, minter);
                
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
                
            // Create registered account
            const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Registered_Username".toBytes32(), 0, 0);
            const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
            registeredAccountAddress = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
            registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress);

            // Populate inventories
            for (let tool of tools)
            {
                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(
                        tool.name.toBytes32(), 
                        registeredAccountAddress, 
                        Inventory.Backpack);
            }
        });

        it("Player should be able to transfer a non-fungible item from Backpack to Ship", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;
            const fromInventory = Inventory.Backpack;
            const toInventory = Inventory.Ship;
            const tokenIds = [1];
            
            const calldata = inventoriesInstance.interface
                .encodeFunctionData("transfer", [[registeredAccountAddress], [fromInventory], [toInventory], [assetAddress], [0], [tokenIds]]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert 
            for (let tokenId of tokenIds)
            {
                await expect(transaction).to
                    .emit(inventoriesInstance, "InventoryTransfer")
                    .withArgs(registeredAccountAddress, registeredAccountAddress, fromInventory, toInventory, assetAddress, 1, tokenId);
            }
        });

        it("Player should be able to transfer a non-fungible item from Ship to Backpack", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;
            const fromInventory = Inventory.Ship;
            const toInventory = Inventory.Backpack;
            const tokenIds = [1];
            
            const calldata = inventoriesInstance.interface
                .encodeFunctionData("transfer", [[registeredAccountAddress], [fromInventory], [toInventory], [assetAddress], [0], [tokenIds]]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert 
            for (let tokenId of tokenIds)
            {
                await expect(transaction).to
                    .emit(inventoriesInstance, "InventoryTransfer")
                    .withArgs(registeredAccountAddress, registeredAccountAddress, fromInventory, toInventory, assetAddress, 1, tokenId);
            }
        });

        it("Player should be able to transfer multiple non-fungible items from Backpack to Ship", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;
            const fromInventory = Inventory.Backpack;
            const toInventory = Inventory.Ship;
            const tokenIds = [1, 2];
            
            const calldata = inventoriesInstance.interface
                .encodeFunctionData("transfer", [[registeredAccountAddress], [fromInventory], [toInventory], [assetAddress], [0], [tokenIds]]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert 
            for (let tokenId of tokenIds)
            {
                await expect(transaction).to
                    .emit(inventoriesInstance, "InventoryTransfer")
                    .withArgs(registeredAccountAddress, registeredAccountAddress, fromInventory, toInventory, assetAddress, 1, tokenId);
            }
        });

        it("Player should be able to transfer multiple non-fungible items from Ship to Backpack", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;
            const fromInventory = Inventory.Ship;
            const toInventory = Inventory.Backpack;
            const tokenIds = [2, 1];
            
            const calldata = inventoriesInstance.interface
                .encodeFunctionData("transfer", [[registeredAccountAddress], [fromInventory], [toInventory], [assetAddress], [0], [tokenIds]]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert 
            for (let tokenId of tokenIds)
            {
                await expect(transaction).to
                    .emit(inventoriesInstance, "InventoryTransfer")
                    .withArgs(registeredAccountAddress, registeredAccountAddress, fromInventory, toInventory, assetAddress, 1, tokenId);
            }
        });

        it ("Player should be able to transfer items between full inventories", async () => {

            // Setup
            const systemSigner = await ethers.provider.getSigner(system);
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;

            // Populate inventories
            const tool = tools[0];
            const weightPerTool = await inventoriesInstance.INVENTORY_SLOT_SIZE();
            const playerShipId = await inventoriesInstance.playerToShip(registeredAccountAddress);
            const backpackInventoryInfo = await inventoriesInstance.getPlayerInventoryInfo(registeredAccountAddress);
            const shipInventoryInfo = await inventoriesInstance.getShipInventoryInfo(playerShipId);
            const itemsToCraftIntoBackpack = Number((backpackInventoryInfo.maxWeight.sub(backpackInventoryInfo.weight)).div(weightPerTool).toNumber().toFixed(0));
            const itemsToCraftIntoShip = Number((shipInventoryInfo.maxWeight.sub(shipInventoryInfo.weight)).div(weightPerTool).toNumber().toFixed(0));
            
            for (let i = 0; i < itemsToCraftIntoBackpack; i++)
            {
                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(
                        tool.name.toBytes32(), 
                        registeredAccountAddress, 
                        Inventory.Backpack);
            }
            
            for (let i = 0; i < itemsToCraftIntoShip; i++)
            {
                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(
                        tool.name.toBytes32(), 
                        registeredAccountAddress, 
                        Inventory.Ship);
            }

            const backpackInventory = await inventoriesInstance.getPlayerInventory(registeredAccountAddress);
            const shipInventory = await inventoriesInstance.getShipInventory(playerShipId);

            const tokenIdFromBackpack = backpackInventory.nonFungible[0].tokenIds[0];
            const tokenIdFromShip = shipInventory.nonFungible[0].tokenIds[0];

            const calldata = inventoriesInstance.interface
                .encodeFunctionData("transfer", [
                    [registeredAccountAddress, registeredAccountAddress], 
                    [Inventory.Backpack, Inventory.Ship], 
                    [Inventory.Ship, Inventory.Backpack], 
                    [assetAddress, assetAddress], 
                    [0, 0], 
                    [[tokenIdFromBackpack], [tokenIdFromShip]]
                ]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert 
            await expect(transaction).to
                .emit(inventoriesInstance, "InventoryTransfer")
                .withArgs(registeredAccountAddress, registeredAccountAddress, Inventory.Backpack, Inventory.Ship, assetAddress, 1, tokenIdFromBackpack);

            await expect(transaction).to
                .emit(inventoriesInstance, "InventoryTransfer")
                .withArgs(registeredAccountAddress, registeredAccountAddress, Inventory.Ship, Inventory.Backpack, assetAddress, 1, tokenIdFromShip);
        });

        it ("Player should not be able to exceed backpack inventory weight limit", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;

            const playerShipId = await inventoriesInstance.playerToShip(registeredAccountAddress);
            const backpackInventory = await inventoriesInstance.getPlayerInventory(registeredAccountAddress);
            const tokenIdFromBackpack = backpackInventory.nonFungible[0].tokenIds[0];

            const calldata = inventoriesInstance.interface
                .encodeFunctionData("transfer", [
                    [registeredAccountAddress], 
                    [Inventory.Backpack], 
                    [Inventory.Ship], 
                    [assetAddress], 
                    [0], 
                    [[tokenIdFromBackpack]]
                ]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert
            if (REVERT_MODE) 
            {
                await expect(operation).to.be
                    .revertedWithCustomError(inventoriesInstance, "ShipInventoryTooHeavy")
                    .withArgs(playerShipId);
            } else 
            {
                await expect(operation).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Player should not be able to exceed ship inventory weight limit", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;

            const playerShipId = await inventoriesInstance.playerToShip(registeredAccountAddress);
            const shipInventory = await inventoriesInstance.getShipInventory(playerShipId);
            const tokenIdFromShip = shipInventory.nonFungible[0].tokenIds[0];

            const calldata = inventoriesInstance.interface
                .encodeFunctionData("transfer", [
                    [registeredAccountAddress], 
                    [Inventory.Ship], 
                    [Inventory.Backpack], 
                    [assetAddress], 
                    [0], 
                    [[tokenIdFromShip]]
                ]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert
            if (REVERT_MODE) 
            {
                await expect(operation).to.be
                    .revertedWithCustomError(inventoriesInstance, "PlayerInventoryTooHeavy")
                    .withArgs(registeredAccountAddress);
            } else 
            {
                await expect(operation).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });
    });

    /**
     * Test Drop from inventories
     */
    describe("Drop", function () {

        // Data
        const assets: any[] = [
            {
                symbol: "WOOD",
                name: "Wood",
                resource: 3,
                weight: 50, // 0.5kg
                contractAddress: "",
                contractInstance: {}
            },
            {
                symbol: "STONE",
                name: "Stone",
                resource: 4,
                weight: 100, // 1kg
                contractAddress: "",
                contractInstance: {}
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

        const map: Map = {
            name: "Map 1".toBytes32(),
            sizeX: 2,
            sizeZ: 2,
            tiles: [
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
                { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Water, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            ]
        };

        // Instances
        let accountRegisterInstance: CryptopiaAccountRegister;
        let playerRegisterInstance: CryptopiaPlayerRegister;
        let inventoriesInstance: CryptopiaInventories;
        let shipTokenInstance: CryptopiaShipToken;
        let toolTokenInstance: CryptopiaToolToken;
        let craftingInstance: CryptopiaCrafting;

        let registeredAccountInstance: CryptopiaAccount;
        let registeredAccountAddress: string;

        /**
         * Deploy Crafting Contracts
         */
        before(async () => {

            // Signers
            const systemSigner = await ethers.provider.getSigner(system);

            // Factories
            const WhitelistFactory = await ethers.getContractFactory("CryptopiaWhitelist");
            const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
            const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
            const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
            const AssetTokenFactory = await ethers.getContractFactory("CryptopiaAssetToken");
            const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
            const ToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
            const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
            const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
            const TitleDeedTokenFactory = await ethers.getContractFactory("CryptopiaTitleDeedToken");
            const MapsFactory = await ethers.getContractFactory("CryptopiaMaps");
            
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
            const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);

            // Grant roles
            await assetRegisterInstance.grantRole(SYSTEM_ROLE, system);


            // Deploy Ships
            const shipTokenProxy = await upgrades.deployProxy(
                ShipTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
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


            // Deploy title deed token
            const titleDeedTokenProxy = await upgrades.deployProxy(
                TitleDeedTokenFactory, 
                [
                    whitelistAddress,
                    "", 
                    ""
                ]);

            const titleDeedTokenAddress = await titleDeedTokenProxy.address;
            const titleDeedTokenInstance = await ethers.getContractAt("CryptopiaTitleDeedToken", titleDeedTokenAddress);

            
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
            const mapsInstance = await ethers.getContractAt("CryptopiaMaps", mapsAddress);

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
            await toolTokenInstance.grantRole(SYSTEM_ROLE, craftingAddress);
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
                    .getContractAt("CryptopiaAssetToken", asset.contractAddress);

                await asset.contractInstance
                    .grantRole(SYSTEM_ROLE, minter);
                
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
                
            // Create registered account
            const createRegisteredAccountTransaction = await playerRegisterInstance.create([account1], 1, 0, "Registered_Username".toBytes32(), 0, 0);
            const createRegisteredAccountReceipt = await createRegisteredAccountTransaction.wait();
            registeredAccountAddress = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
            registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress);

            // Populate inventories
            for (let tool of tools)
            {
                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(
                        tool.name.toBytes32(), 
                        registeredAccountAddress, 
                        Inventory.Backpack);

                await toolTokenInstance
                    .connect(systemSigner)
                    .__craft(
                        tool.name.toBytes32(), 
                        registeredAccountAddress, 
                        Inventory.Ship);
            }
        });

        it("Player should be able to drop a non-fungible item from Backpack", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;
            const fromInventory = Inventory.Backpack;
            const tokenId = 1;
            
            const calldata = inventoriesInstance.interface
                .encodeFunctionData("drop", [fromInventory, assetAddress, 0, tokenId]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert 
            await expect(transaction).to
                .emit(inventoriesInstance, "InventoryDeduct")
                .withArgs(registeredAccountAddress, fromInventory, assetAddress, 1, tokenId);
        });

        it("Player should be able to drop a non-fungible item from Ship", async () => {

            // Setup
            const inventoriesAddress = await inventoriesInstance.address;
            const assetAddress = await toolTokenInstance.address;
            const fromInventory = Inventory.Ship;
            const tokenId = 2;
            
            const calldata = inventoriesInstance.interface
                .encodeFunctionData("drop", [fromInventory, assetAddress, 0, tokenId]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(inventoriesAddress, 0, calldata);

            // Assert 
            await expect(transaction).to
                .emit(inventoriesInstance, "InventoryDeduct")
                .withArgs(registeredAccountAddress, fromInventory, assetAddress, 1, tokenId);
        });
    });
});