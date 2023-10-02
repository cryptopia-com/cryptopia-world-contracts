import hre, { 
    ethers, 
    upgrades
} from "hardhat";

import {
    time,
    loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";

import { 
    expect 
} from "chai";

import {
    getParamFromEvent
} from '../scripts/helpers/events';

import appConfig from "../config";

/**
 * Crafting tests
 * 
 */
describe("Crafting Contract", function () {

    // Settings
    const REVERT_MODE = false;

    // Config
    const config = appConfig.networks[hre.network.name];

    // Roles
    const SYSTEM_ROLE = ethers.keccak256(ethers.toUtf8Bytes("SYSTEM_ROLE"));

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
                        amount: ethers.parseEther("2.0")
                    },
                    {
                        asset: "FE26",
                        amount: ethers.parseEther("1.0")
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
                        amount: ethers.parseEther("3.0")
                    }
                ]
            }
        }
    ];

    /**
     * Deploy Crafting fixture
     */
    async function deployCraftingFixture() 
    {
        const [deployer, system, account1, other, treasury] = (
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
            await upgrades.deployProxy(CryptopiaAccountRegisterFactory)
        ).waitForDeployment();

        const accountRegisterAddress = await accountRegisterProxy.getAddress();
        const accountRegisterInstance = await ethers.getContractAt("CryptopiaAccountRegister", accountRegisterAddress);

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
        const shipTokenInstance = await ethers.getContractAt("CryptopiaShipToken", shipTokenAddress);

        // Deploy Crafting
        const craftingProxy = await (
            await upgrades.deployProxy(
                CryptopiaCraftingFactory, 
                [
                    inventoriesAddress
                ])
        ).waitForDeployment();

        const craftingAddress = await craftingProxy.getAddress();
        const craftingInstance = await ethers.getContractAt("CryptopiaCrafting", craftingAddress);

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
        const playerRegisterInstance = await ethers.getContractAt("CryptopiaPlayerRegister", playerRegisterAddress);

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
        const toolTokenInstance = await ethers.getContractAt("CryptopiaToolToken", toolTokenAddress);

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
        const registeredAccountInstance = await ethers.getContractAt("CryptopiaAccount", registeredAccount);

        // Create unregistered account
        const createUnregisteredAccountResponse = await accountRegisterInstance.create(
            [other], 1, 0, "Unregistered_Username".toBytes32(), 0);
            const createUnregisteredAccountReceipt = await createUnregisteredAccountResponse.wait();
        const unregisteredAccount = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
        const unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccount);

        return { 
            craftingInstance, 
            toolTokenInstance, 
            registeredAccountInstance, 
            unregisteredAccountInstance, 
            account1, 
            other 
        };
    }

    /**
     * Test crafting recipes 
     */
    describe("Recipes", function () {

        it("Player should not be able to craft with an invalid recipe", async () => {
        
            // Load fixture
            const { 
                craftingInstance, 
                toolTokenInstance, 
                registeredAccountInstance, 
                unregisteredAccountInstance, 
                account1, 
                other 
            } = await loadFixture(deployCraftingFixture);

            // Setup
            const slot = 2;
            const inventory = 1; // Backpack
            const invalidRecipe = "invalidRecipe".toBytes32();

            const callData = craftingInstance.interface.encodeFunctionData(
                "craft", [await toolTokenInstance.getAddress(), invalidRecipe, slot, inventory]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const operation = registeredAccountInstance.connect(signer).submitTransaction(
                await craftingInstance.getAddress(), 0, callData);

            // Assert
            if (REVERT_MODE) {
                await expect(operation).to.be.revertedWith(
                    "CryptopiaCrafting: Invalid recipe");
            } else {
                await expect(operation).to.emit(
                    registeredAccountInstance, "ExecutionFailure");
            }
        });
    });
});