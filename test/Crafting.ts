import "../scripts/helpers/converters.ts";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { time } from "@nomicfoundation/hardhat-network-helpers";
import { getParamFromEvent} from '../scripts/helpers/events';
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
            stats: {
                durability: 90, 
                multiplier_cooldown: 100, 
                multiplier_xp: 100, 
                multiplier_effectiveness: 100, 
                value1: 10, 
                value2: 20, 
                value3: 30
            },
            minting: [
                { 
                    asset: "MEAT",
                    amount: ['1.0', 'ether'] 
                }, 
                { 
                    asset: "WOOD",
                    amount: ['1.0', 'ether'] 
                }
            ],
            recipe: {
                level: 1,
                learnable: false,
                craftingTime: 300, // 5 min
                ingredients: [
                    {
                        asset: "WOOD",
                        amount:['2.0', 'ether']
                    },
                    {
                        asset: "STONE",
                        amount: ['1.0', 'ether']
                    }
                ]
            }
        },
        {
            name: "Iron Axe",
            rarity: 1,
            level: 1,
            stats: {
                durability: 95, 
                multiplier_cooldown: 110, 
                multiplier_xp: 110, 
                multiplier_effectiveness: 110, 
                value1: 11, 
                value2: 22, 
                value3: 33
            },
            minting: [
                { 
                    asset: "MEAT",
                    amount: ['1.0', 'ether'] 
                }, 
                { 
                    asset: "WOOD",
                    amount: ['1.0', 'ether'] 
                }
            ],
            recipe: {
                level: 1,
                learnable: true,
                craftingTime: 600, // 10 min
                ingredients: [
                    {
                        asset: "WOOD",
                        amount: ['2.0', 'ether']
                    },
                    {
                        asset: "FE26",
                        amount: ['1.0', 'ether']
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
        craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);

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

        // Deploy Tools
        const toolTokenProxy = await (await upgrades.deployProxy(
            ToolTokenFactory, 
            [
                whitelistAddress, 
                "", 
                "",
                playerRegisterAddress,
                inventoriesAddress
            ])).waitForDeployment();

        const toolTokenAddress = await toolTokenProxy.getAddress();
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

        // Setup Tools
        await inventoriesInstance.setNonFungibleAsset(
            await toolTokenProxy.getAddress(), true);

        // Add tools
        await toolTokenInstance.setTools(
            tools.map((tool: any) => tool.name.toBytes32()),
            tools.map((tool: any) => tool.rarity),
            tools.map((tool: any) => tool.level),
            tools.map((tool: any) => [
                tool.stats.durability, 
                tool.stats.multiplier_cooldown, 
                tool.stats.multiplier_xp, 
                tool.stats.multiplier_effectiveness, 
                tool.stats.value1, 
                tool.stats.value2, 
                tool.stats.value3
            ]),
            tools.map((tool: any) => tool.minting.map((item: any) => getAssetBySymbol(item.asset).resource)),
            tools.map((tool: any) => tool.minting.map((item: any) => ethers.parseUnits(item.amount[0], item.amount[1]))));
    
        // Add tool recipes
        await craftingInstance.setRecipes(
            tools.map(() => toolTokenAddress),
            tools.map((tool: any) => tool.name.toBytes32()),
            tools.map((tool: any) => tool.recipe.level),
            tools.map((tool: any) => tool.recipe.learnable),
            tools.map((tool: any) => tool.recipe.craftingTime),
            tools.map((tool: any) => tool.recipe.ingredients.map((ingredient: any) => getAssetBySymbol(ingredient.asset).contractAddress)),
            tools.map((tool: any) => tool.recipe.ingredients.map((ingredient: any) => ethers.parseUnits(ingredient.amount[0], ingredient.amount[1]))));

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
            const toolTokenAddress = await toolTokenInstance.getAddress();

            const callData = craftingInstance.interface
                .encodeFunctionData("craft", [toolTokenAddress, invalidRecipe, slot, inventory]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await craftingInstance.getAddress(), 0, callData);

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
                .submitTransaction(await craftingInstance.getAddress(), 0, callData);
    
            // Assert
            if (REVERT_MODE) 
            {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingSlotIsEmpty")
                    .withArgs(await registeredAccountInstance.getAddress(), emptySlot);
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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
    
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
                    .withArgs(await unregisteredAccountInstance.getAddress());
    
                await expect(operationClaim).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingSlotIsEmpty")
                    .withArgs(await unregisteredAccountInstance.getAddress(), slot);
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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
            const registeredAccountAddress = await registeredAccountInstance.getAddress();
            const assetAddress = getAssetBySymbol(craftable.recipe.ingredients[0].asset).contractAddress;
            const assetAmount = ethers.parseUnits(craftable.recipe.ingredients[0].amount[0], craftable.recipe.ingredients[0].amount[1]);

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
            const playerAddress = await registeredAccountInstance.getAddress();
            const minterSigner = await ethers.provider.getSigner(minter);
            const systemSigner = await ethers.provider.getSigner(system);
    
            // Ensure enough resources in inventory
            for (let ingredient of craftable.recipe.ingredients)
            {
                const asset = getAssetBySymbol(ingredient.asset);
                const amount = ethers.parseUnits(ingredient.amount[0], ingredient.amount[1]);

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
            const playerAddress = await registeredAccountInstance.getAddress();

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
            const registeredAccountAddress = await registeredAccountInstance.getAddress();

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
            const registeredAccountAddress = await registeredAccountInstance.getAddress();

            const signer = await ethers.provider.getSigner(account1);
            const callData = craftingInstance.interface
                .encodeFunctionData("learn", [registeredAccountAddress, craftableTokenAddress, recipeName]);

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const registeredAccountAddress = await registeredAccountInstance.getAddress();

            // Act
            const signer = await ethers.provider.getSigner(system);
            const operation = craftingInstance
                .connect(signer)
                .learn(registeredAccountAddress, craftableTokenAddress, recipeName)

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const inventoriesAddress = await inventoriesInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
            const playerAddress = await registeredAccountInstance.getAddress();
            const minterSigner = await ethers.provider.getSigner(minter);
            const systemSigner = await ethers.provider.getSigner(system);

            // Ensure enough resources in inventory
            for (let ingredient of craftable.recipe.ingredients)
            {
                const asset = getAssetBySymbol(ingredient.asset);
                const amount = ethers.parseUnits(ingredient.amount[0], ingredient.amount[1]);

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
            const craftableTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
            const playerAddress = await registeredAccountInstance.getAddress();

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