import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { getParamFromEvent} from '../scripts/helpers/events';
import appConfig from "../config";
import "../scripts/helpers/converters.ts";

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
 */
describe("Crafting Contract", function () {

    // Settings
    const REVERT_MODE = false;

    // Config
    const config = appConfig.networks.development;

    // Roles
    const SYSTEM_ROLE = "SYSTEM_ROLE".toKeccak256();

    // Accounts
    let deployer: string;
    let system: string;
    let account1: string;
    let other: string;
    let treasury: string;

    // Contracts
    let registeredAccountInstance: CryptopiaAccount;
    let unregisteredAccountInstance: CryptopiaAccount;
    
    let accountRegisterInstance: CryptopiaAccountRegister;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let shipTokenInstance: CryptopiaShipToken;
    let toolTokenInstance: CryptopiaToolToken;
    let craftingInstance: CryptopiaCrafting;

    // Mock Data
    const assets: any[] = [
        {
            symbol: "WOOD",
            name: "Wood",
            weight: 50, // 0.5kg
            contractInstance: {}
        },
        {
            symbol: "FE26",
            name: "Iron",
            weight: 100, // 1kg
            contractInstance: {}
        },
        {
            symbol: "AU29",
            name: "Gold",
            weight: 100, // 1kg
            contractInstance: {}
        }
    ];

    const craftableItems = [
        {
            name: "MockTool1",
            rarity: 1,
            level: 1,
            stats: [90, 100, 100, 100, 10, 20, 30],
            minting: [
                { 1: ['1', 'ether'] }, // Meat
                { 3: ['1', 'ether'] } // Wood
            ],
            recipe: {
                level: 1,
                learnable: false,
                craftingTime: 0,
                ingredients: []
            }
        },
        {
            name: "MockTool2",
            rarity: 1,
            level: 1,
            stats: [95, 110, 110, 120, 11, 22, 33],
            minting: [
                { 1: ['1', 'ether'] }, // Meat
                { 3: ['1', 'ether'] } // Wood
            ],
            recipe: {
                level: 1,
                learnable: true,
                craftingTime: 600, // 10 min
                ingredients: [
                    {
                        asset: "WOOD",
                        amount: "2".toWei()
                    },
                    {
                        asset: "FE26",
                        amount: "1".toWei()
                    }
                ]
            }
        },
        {
            name: "MockWearable1",
            rarity: 1,
            level: 1,
            stats: [100, 100, 100, 100, 1, 0, 0],
            minting: [],
            recipe: {
                level: 1,
                learnable: false,
                craftingTime: 0,
                ingredients: []
            }
        },
        {
            name: "MockWearable2",
            rarity: 1,
            level: 2,
            stats: [100, 100, 100, 100, 3, 1, 1],
            minting: [],
            recipe: {
                level: 2,
                learnable: true,
                craftingTime: 3600, // 60 min
                ingredients: [
                    {
                        asset: "AU29",
                        amount: "3".toWei()
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
        [deployer, system, account1, other, treasury] = (
            await ethers.getSigners()).map(s => s.address);

        // Factories
        const CryptopiaAccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister"); 
        const CryptopiaPlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister"); 
        const CryptopiaInventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
        const CryptopiaShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
        const CryptopiaToolTokenFactory = await ethers.getContractFactory("CryptopiaToolToken");
        const CryptopiaCraftingFactory = await ethers.getContractFactory("CryptopiaCrafting");
        const WhitelistFactory = await ethers.getContractFactory("Whitelist");

        // Deploy Inventories
        const inventoriesProxy = await (
            await upgrades.deployProxy(
                CryptopiaInventoriesFactory, 
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
            await upgrades.deployProxy(CryptopiaAccountRegisterFactory)
        ).waitForDeployment();

        const accountRegisterAddress = await accountRegisterProxy.getAddress();
        accountRegisterInstance = await ethers.getContractAt("CryptopiaAccountRegister", accountRegisterAddress);

        // Deploy Ships
        const shipTokenProxy = await (
            await upgrades.deployProxy(
                CryptopiaShipTokenFactory, 
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
                CryptopiaCraftingFactory, 
                [
                    inventoriesAddress
                ])
        ).waitForDeployment();

        const craftingAddress = await craftingProxy.getAddress();
        craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);

        // Deploy Player Register
        const playerRegisterProxy = await (await upgrades.deployProxy(
            CryptopiaPlayerRegisterFactory, 
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
            CryptopiaToolTokenFactory, 
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
        await inventoriesInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, craftingAddress);
        await inventoriesInstance.grantRole(SYSTEM_ROLE, toolTokenAddress);
        await shipTokenInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await craftingInstance.grantRole(SYSTEM_ROLE, playerRegisterAddress);
        await toolTokenInstance.grantRole(SYSTEM_ROLE, craftingAddress);

        // Setup Tools
        await inventoriesInstance.setNonFungibleAsset(
            await toolTokenProxy.getAddress(), true);

        // Add tools
        await toolTokenInstance.setTools(
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.name.toBytes32()),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.rarity),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.level),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => [
                tool.stats.durability, 
                tool.stats.multiplier_cooldown, 
                tool.stats.multiplier_xp, 
                tool.stats.multiplier_effectiveness, 
                tool.stats.value1, 
                tool.stats.value2, 
                tool.stats.value3
            ]),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.minting.map((item: any) => Object.keys(item)[0])),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.minting.map((item: any) => ethers.parseUnits(item[Object.keys(item)[0]][0], item[Object.keys(item)[0]][1]))));
    
        // Add tool recipes
        await craftingInstance.setRecipes(
            config.ERC721.CryptopiaToolToken.tools.map(() => toolTokenAddress),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.name.toBytes32()),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.recipe.level),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.recipe.learnable),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.recipe.craftingTime),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.recipe.ingredients.map((ingredient: any) => Object.keys(ingredient)[0])),
            config.ERC721.CryptopiaToolToken.tools.map((tool: any) => tool.recipe.ingredients.map((ingredient: any) => ethers.parseUnits(ingredient[Object.keys(ingredient)[0]][0], ingredient[Object.keys(ingredient)[0]][1]))));

        // Create registered account
        const createRegisteredAccountResponse = await playerRegisterInstance.create(
            [account1], 1, 0, "Registered_Username".toBytes32(), 0, 0);
        const createRegisteredAccountReceipt = await createRegisteredAccountResponse.wait();
        const registeredAccount = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt, "account", "RegisterPlayer");
        registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccount);

        // Create unregistered account
        const createUnregisteredAccountResponse = await accountRegisterInstance.create(
            [other], 1, 0, "Unregistered_Username".toBytes32(), 0);
            const createUnregisteredAccountReceipt = await createUnregisteredAccountResponse.wait();
        const unregisteredAccount = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
        unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccount);
    });

    /**
     * Test Crafting 
     */
    describe("Crafting", function () {

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
            if (REVERT_MODE) {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingInvalidRecipe")
                    .withArgs(toolTokenAddress, invalidRecipe);
            } else {
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
            if (REVERT_MODE) {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingSlotIsEmpty")
                    .withArgs(account1, emptySlot);
            } else {
                await expect(operation).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });

        it("Player should not be able to claim from a slot in another inventory", async () => {

            // Setup
            const slot = 1;
            const otherInventory = 2; // Other inventory
    
            const callData = craftingInstance.interface
                .encodeFunctionData("claim", [slot, otherInventory]);
    
            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance
                .connect(signer)
                .submitTransaction(await craftingInstance.getAddress(), 0, callData);
    
            // Assert
            if (REVERT_MODE) {
                await expect(operation).to.be
                    .revertedWithCustomError(craftingInstance, "CraftingInvalidInventory")
                    .withArgs(otherInventory);
            } else {
                await expect(operation).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });

        it("Player should not be able to craft or claim if not registered", async () => {

            // Setup
            const slot = 1;
            const inventory = 1; // Backpack
            const tool = config.ERC721.CryptopiaToolToken.tools[0];
            const recipe = tool.name.toBytes32();
            const toolTokenAddress = await toolTokenInstance.getAddress();
            const craftingAddress = await craftingInstance.getAddress();
    
            const callDataCraft = craftingInstance.interface
                .encodeFunctionData("craft", [toolTokenAddress, recipe, slot, inventory]);
    
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
            if (REVERT_MODE) {
                await expect(operationCraft).to.be
                    .revertedWithCustomError(accountRegisterInstance, "AccountNotRegistered")
                    .withArgs(other);
    
                await expect(operationClaim).to.be
                    .revertedWithCustomError(accountRegisterInstance, "AccountNotRegistered")
                    .withArgs(other);
            } else {
                await expect(operationCraft).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
    
                await expect(operationClaim).to
                    .emit(unregisteredAccountInstance, "ExecutionFailure");
            }
        });
    });
});