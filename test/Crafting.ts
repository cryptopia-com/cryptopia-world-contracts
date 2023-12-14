import "../scripts/helpers/converters.ts";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { getParamFromEvent} from '../scripts/helpers/events';
import { resolveEnum } from "../scripts/helpers/enums";
import { Resource } from '../scripts/types/enums';
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
 * Crafting tests
 * 
 * Test cases:
 * - Default recipes
 * - Learnable recipes
 */
describe("Crafting Contract", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let other: string;
    let treasury: string;

    // Instances
    let accountRegisterInstance: CryptopiaAccountRegister;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let shipTokenInstance: CryptopiaShipToken;
    let toolTokenInstance: CryptopiaToolToken;
    let craftingInstance: CryptopiaCrafting;

    let registeredAccountInstance: CryptopiaAccount;
    let unregisteredAccountInstance: CryptopiaAccount;

    // Mock Data
    const assets: any[] = [
        {
            symbol: "MEAT",
            name: "Meat",
            resource: 1,
            weight: 50, // 0.5kg
            contractAddress: "",
            contractInstance: {}
        },
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
        },
        {
            symbol: "AU29",
            name: "Gold",
            resource: 11,
            weight: 200, // 2kg
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
            multiplier_cooldown: 100, 
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
            multiplier_cooldown: 110, 
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


    /**
     * Deploy Crafting Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, other, treasury] = (
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
        const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
        const CraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
        
        // Deploy Inventories
        const inventoriesProxy = await upgrades.deployProxy(
            InventoriesFactory, 
            [
                treasury
            ]);

        const inventoriesAddress = await inventoriesProxy.address;
        inventoriesInstance = await ethers.getContractAt("CryptopiaInventories", inventoriesAddress);

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

        // Deploy Asset Register
        const assetRegisterProxy = await upgrades.deployProxy(
            AssetRegisterFactory, []);

        const assetRegisterAddress = await assetRegisterProxy.address;
        const assetRegisterInstance = await ethers.getContractAt("CryptopiaAssetRegister", assetRegisterAddress);

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
        await assetRegisterInstance.grantRole(SYSTEM_ROLE, system);
        await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await toolTokenInstance.grantRole(SYSTEM_ROLE, craftingAddress);
        await craftingInstance.grantRole(SYSTEM_ROLE, system);
        await craftingInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, system);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);
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
        const registeredAccount = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
        registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccount);

        // Create unregistered account
        const createUnregisteredAccountTransaction = await accountRegisterInstance.create([other], 1, 0, "Unregistered_Username".toBytes32(), 0);
        const createUnregisteredAccountReceipt = await createUnregisteredAccountTransaction.wait();
        const unregisteredAccount = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
        unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccount);
    });

    /**
     * Test Crafting default items
     */
    describe("Default Recipes", function () {

        it("Player should not be able to craft with an invalid recipe", async () => {
        
            // Setup
            const slot = 2;
            const inventory = 1; // Backpack
            const invalidRecipe = "invalidRecipe".toBytes32();
            const toolTokenAddress = await toolTokenInstance.address;

            const callData = craftingInstance.interface
                .encodeFunctionData("craft", [toolTokenAddress, invalidRecipe, slot, inventory]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await craftingInstance.address, 0, callData);

            // Assert
            if (REVERT_MODE) 
            {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingRecipeInvalid")
                    .withArgs(toolTokenAddress, invalidRecipe);
            } else 
            {
                await expect(operation).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });

        it("Player should not be able to claim from an empty slot", async () => {
    
            // Setup
            const emptySlot = 2;
            const inventory = 1; // Backpack
    
            const callData = craftingInstance.interface.encodeFunctionData(
                "claim", [emptySlot, inventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await craftingInstance.address, 0, callData);
    
            // Assert
            if (REVERT_MODE) 
            {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingSlotIsEmpty")
                    .withArgs(await registeredAccountInstance.address, emptySlot);
            } else 
            {
                await expect(operation).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });

        it("Player should not be able to craft or claim if not registered", async () => {

            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const craftable = tools[0];
            const recipe = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const craftingAddress = await craftingInstance.address;
    
            const callDataCraft = craftingInstance.interface
                .encodeFunctionData("craft", [craftableTokenAddress, recipe, slot, inventory]);
    
            const callDataClaim = craftingInstance.interface
                .encodeFunctionData("claim", [slot, inventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(other);
            const operationCraft = unregisteredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, callDataCraft);
    
            const operationClaim = unregisteredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, callDataClaim);
    
            // Assert
            if (REVERT_MODE) 
            {
                await expect(operationCraft).to.be
                    .revertedWithCustomError(craftingInstance, "PlayerNotRegistered")
                    .withArgs(await unregisteredAccountInstance.address);
    
                await expect(operationClaim).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingSlotIsEmpty")
                    .withArgs(await unregisteredAccountInstance.address, slot);
            } else 
            {
                await expect(operationCraft).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
    
                await expect(operationClaim).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });

        it("Player should not be able to craft an item using an invalid inventory", async () => {

            // Setup
            const slot = 1;
            const invalidInventory = 0; // Wallet
            const craftable = tools[0];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const craftingAddress = await craftingInstance.address;

            const callDataCraft = craftingInstance.interface
                .encodeFunctionData("craft", [craftableTokenAddress, recipeName, slot, invalidInventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operationCraft = registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, callDataCraft);
    
            // Assert
            if (REVERT_MODE) 
            {
                await expect(operationCraft).to.be
                    .revertedWithCustomError(craftingInstance, "InventoryInvalid")
                    .withArgs(invalidInventory);
            } else 
            {
                await expect(operationCraft).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Player should not be able to craft an item with insufficient recources", async () => {

            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const craftable = tools[0];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const craftingAddress = await craftingInstance.address;
            const registeredAccountAddress = await registeredAccountInstance.address;
            const assetAddress = getAssetBySymbol(craftable.recipe.ingredients[0].asset).contractAddress;
            const assetAmount = ethers.utils.parseUnits(craftable.recipe.ingredients[0].amount[0], craftable.recipe.ingredients[0].amount[1]);

            const callDataCraft = craftingInstance.interface
                .encodeFunctionData("craft", [craftableTokenAddress, recipeName, slot, inventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operationCraft = registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, callDataCraft);

            // Assert (fail)
            if (REVERT_MODE) 
            {
                await expect(operationCraft).to.be
                    .revertedWithCustomError(inventoriesInstance, "InventoryInsufficientBalance")
                    .withArgs(registeredAccountAddress, inventory, assetAddress, assetAmount);
            } else 
            {
                await expect(operationCraft).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });

        it("Player should be able to craft an item", async () => {

            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const craftable = tools[0];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const inventoriesAddress = await inventoriesInstance.address;
            const craftingAddress = await craftingInstance.address;
            const playerAddress = await registeredAccountInstance.address;
            const minterSigner = await ethers.provider.getSigner(minter);
            const systemSigner = await ethers.provider.getSigner(system);
    
            // Ensure enough resources in inventory
            for (let ingredient of craftable.recipe.ingredients)
            {
                const asset = getAssetBySymbol(ingredient.asset);
                const amount = ethers.utils.parseUnits(ingredient.amount[0], ingredient.amount[1]);

                // Mint asset
                await asset.contractInstance
                    .connect(minterSigner)
                    .__mintTo(inventoriesAddress, amount);

                // Assign to player
                await inventoriesInstance
                    .connect(systemSigner)
                    .__assignFungibleToken(
                        playerAddress,
                        inventory,
                        asset.contractAddress,
                        amount);
            }

            const calldata = craftingInstance.interface
                .encodeFunctionData("craft", [craftableTokenAddress, recipeName, slot, inventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, calldata);

            // Assert 
            const timeStamp = await time.latest();
            const caftingFinishTime = timeStamp + craftable.recipe.craftingTime;

            expect(transaction).to
                .emit(craftingInstance, "CraftingStart")
                .withArgs(playerAddress, craftableTokenAddress, recipeName, slot, caftingFinishTime);
        });

        it("Player should be able to claim a crafted item", async () => {

            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const expectedTokenId = 1;
            const craftable = tools[0];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const craftingAddress = await craftingInstance.address;
            const playerAddress = await registeredAccountInstance.address;

            const calldata = craftingInstance.interface
                .encodeFunctionData("claim", [slot, inventory]);
    
            // Act
            await time.increase(craftable.recipe.craftingTime);
    
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, calldata);

            // Assert
            expect(transaction).to
                .emit(craftingInstance, "CraftingClaim")
                .withArgs(playerAddress, craftableTokenAddress, recipeName, slot, expectedTokenId);
        });
    });

    /**
     * Test Crafting learnable items
     */
    describe("Learnable Recipes", function () {

        it ("Player should not be able to craft an item without learning the recipe", async () => {

            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const craftable = tools[1];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const craftingAddress = await craftingInstance.address;
            const registeredAccountAddress = await registeredAccountInstance.address;

            const callData = craftingInstance.interface
                .encodeFunctionData("craft", [craftableTokenAddress, recipeName, slot, inventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, callData);

            // Assert (fail)
            if (REVERT_MODE) 
            {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingRecipeNotLearned")
                    .withArgs(registeredAccountAddress, craftableTokenAddress, recipeName);
            } else 
            {
                await expect(operation).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });

        it ("Should not allow non-system to learn a recipe", async () => {

            // Setup 
            const craftable = tools[1];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const craftingAddress = await craftingInstance.address;
            const registeredAccountAddress = await registeredAccountInstance.address;

            const signer = await ethers.provider.getSigner(account1);
            const callData = craftingInstance.interface
                .encodeFunctionData("__learn", [registeredAccountAddress, craftableTokenAddress, recipeName]);

            // Act
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, callData);

            // Assert
            if (REVERT_MODE) 
            {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "AccessControlUnauthorizedAccount")
                    .withArgs(registeredAccountAddress, SYSTEM_ROLE);
            } else 
            {
                await expect(operation).to
                    .emit(registeredAccountInstance, "ExecutionFailure");
            }
        }); 

        it ("Should allow system to learn a recipe", async () => {

            // Setup 
            const craftable = tools[1];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const registeredAccountAddress = await registeredAccountInstance.address;

            // Act
            const signer = await ethers.provider.getSigner(system);
            const operation = craftingInstance
                .connect(signer)
                .__learn(registeredAccountAddress, craftableTokenAddress, recipeName)

            // Assert
            await expect(operation).to
                .emit(craftingInstance, "CraftingRecipeLearn")
                .withArgs(registeredAccountAddress, craftableTokenAddress, recipeName);
        }); 

        it ("Player should be able to craft an item after learning the recipe", async () => {
            
            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const craftable = tools[1];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const inventoriesAddress = await inventoriesInstance.address;
            const craftingAddress = await craftingInstance.address;
            const playerAddress = await registeredAccountInstance.address;
            const minterSigner = await ethers.provider.getSigner(minter);
            const systemSigner = await ethers.provider.getSigner(system);

            // Ensure enough resources in inventory
            for (let ingredient of craftable.recipe.ingredients)
            {
                const asset = getAssetBySymbol(ingredient.asset);
                const amount = ethers.utils.parseUnits(ingredient.amount[0], ingredient.amount[1]);

                // Mint asset
                await asset.contractInstance
                    .connect(minterSigner)
                    .__mintTo(inventoriesAddress, amount);

                // Assign to player
                await inventoriesInstance
                    .connect(systemSigner)
                    .__assignFungibleToken(
                        playerAddress,
                        inventory,
                        asset.contractAddress,
                        amount);
            }

            const callData = craftingInstance.interface
                .encodeFunctionData("craft", [craftableTokenAddress, recipeName, slot, inventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, callData);

            // Assert 
            const timeStamp = await time.latest();
            const caftingFinishTime = timeStamp + craftable.recipe.craftingTime;

            expect(transaction).to
                .emit(craftingInstance, "CraftingStart")
                .withArgs(playerAddress, craftableTokenAddress, recipeName, slot, caftingFinishTime);
        });

        it("Player should be able to claim a crafted item after learning the recipe", async () => {

            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const expectedTokenId = 2;
            const craftable = tools[1];
            const recipeName = craftable.name.toBytes32();
            const craftableTokenAddress = await toolTokenInstance.address;
            const craftingAddress = await craftingInstance.address;
            const playerAddress = await registeredAccountInstance.address;

            const calldata = craftingInstance.interface
                .encodeFunctionData("claim", [slot, inventory]);
    
            // Act
            await time.increase(craftable.recipe.craftingTime);
    
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance
                .connect(signer)
                .submitTransaction(craftingAddress, 0, calldata);

            // Assert
            expect(transaction).to
                .emit(craftingInstance, "CraftingClaim")
                .withArgs(playerAddress, craftableTokenAddress, recipeName, slot, expectedTokenId);
        });
    });

    /**
     * Helper functions
     */
    const getAssetBySymbol = (symbol: string) => {
        return assets.find(asset => asset.symbol === symbol);
    };
});