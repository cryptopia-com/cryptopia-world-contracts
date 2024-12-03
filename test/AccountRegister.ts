import "../scripts/helpers/converters.ts";
import { expect } from "chai";
import { ethers, upgrades} from "hardhat";
import { getParamFromEvent} from '../scripts/helpers/events';
import { encodeRockData, encodeVegetationData, encodeWildlifeData } from '../scripts/maps/helpers/encoders';
import { Resource, Terrain, Biome, Relationship } from '../scripts/types/enums';
import { Map } from "../scripts/types/input";
import { SYSTEM_ROLE } from "./settings/roles";   

import { 
    CryptopiaAccount,
    CryptopiaAccountRegister,
    CryptopiaPlayerRegister,
    CryptopiaInventories,
    CryptopiaShipToken,
    CryptopiaCrafting
} from "../typechain-types";


/**
 * Account register tests
 */
describe("AccountRegister Contracts", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let account2: string;
    let other: string;
    let treasury: string;

    // Instances
    let accountRegisterInstance: CryptopiaAccountRegister;
    let playerRegisterInstance: CryptopiaPlayerRegister;
    let inventoriesInstance: CryptopiaInventories;
    let shipTokenInstance: CryptopiaShipToken;
    let craftingInstance: CryptopiaCrafting;

    let registeredAccountInstance1: CryptopiaAccount;
    let registeredAccountInstance2: CryptopiaAccount;
    let unregisteredAccountInstance: CryptopiaAccount;

    let registeredAccountAddress1: string;
    let registeredAccountAddress2: string;
    let unregisteredAccountAddress: string;

    const map: Map = {
        name: "Map 1".toBytes32(),
        sizeX: 2,
        sizeZ: 2,
        tiles: [
            { group: 1, safety: 50, biome: Biome.RainForest, terrain: Terrain.Flat, elevationLevel: 5, waterLevel: 5, vegetationData: '0b000110110001101100011011000110110001101100' , rockData: '0b0001101100011011000110110001' , wildlifeData: '0b00011011000110110001', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 1, safety: 50, biome: Biome.None, terrain: Terrain.Flat, elevationLevel: 6, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, elevationLevel: 3, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
            { group: 0, safety: 50, biome: Biome.None, terrain: Terrain.Flat, elevationLevel: 2, waterLevel: 5, vegetationData: '0b00000000000000000000000000000000000000000' , rockData: '0b0000000000000000000000000000' , wildlifeData: '0b00000000000000000000', riverFlags: 0, hasRoad: false, hasLake: false, resources: [] },
        ]
    };


    /**s
     * Deploy Crafting Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, account2, other, treasury] = (
            await ethers.getSigners()).map(s => s.address);

        // Signers
        const systemSigner = await ethers.provider.getSigner(system);

        // Factories
        const WhitelistFactory = await ethers.getContractFactory("CryptopiaWhitelist");
        const AccountRegisterFactory = await ethers.getContractFactory("CryptopiaAccountRegister");
        const PlayerRegisterFactory = await ethers.getContractFactory("CryptopiaPlayerRegister");
        const AssetRegisterFactory = await ethers.getContractFactory("CryptopiaAssetRegister");
        const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
        const ShipSkinTokenFactory = await ethers.getContractFactory("CryptopiaShipSkinToken");
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

        // Create registered accounts
        const createRegisteredAccountTransaction1 = await playerRegisterInstance.create([account1], 1, 0, "Registered_Username1".toBytes32(), 0, 0);
        const createRegisteredAccountReceipt1 = await createRegisteredAccountTransaction1.wait();
        registeredAccountAddress1 = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt1, "account", "RegisterPlayer");
        registeredAccountInstance1 = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress1);

        const createRegisteredAccountTransaction2 = await playerRegisterInstance.create([account2], 1, 0, "Registered_Username2".toBytes32(), 0, 0);
        const createRegisteredAccountReceipt2 = await createRegisteredAccountTransaction2.wait();
        registeredAccountAddress2 = getParamFromEvent(playerRegisterInstance, createRegisteredAccountReceipt2, "account", "RegisterPlayer");
        registeredAccountInstance2 = await ethers.getContractAt("CryptopiaAccount", registeredAccountAddress2);

        // Create unregistered account
        const createUnregisteredAccountTransaction = await accountRegisterInstance.create([other], 1, 0, "Unregistered_Username".toBytes32(), 0);
        const createUnregisteredAccountReceipt = await createUnregisteredAccountTransaction.wait();
        unregisteredAccountAddress = getParamFromEvent(accountRegisterInstance, createUnregisteredAccountReceipt, "account", "CreateAccount");
        unregisteredAccountInstance = await ethers.getContractAt("CryptopiaAccount", unregisteredAccountAddress);
    });

    /**
     * Test friend requests
     */
    describe ("Friend requests", function () {

        it ("Registered account should be able to send a friend request", async () => {
        
            // Setup
            const receiver = registeredAccountAddress2;
            const relationship = Relationship.Friend;

            const callData = accountRegisterInstance.interface
                .encodeFunctionData("addFriendRequest", [receiver, relationship]);

            // Act
            const signer = await ethers.provider.getSigner(account1);
            const transaction = await registeredAccountInstance1
                .connect(signer)
                .submitTransaction(await accountRegisterInstance.address, 0, callData);

            // Assert
            await expect(transaction).to
                .emit(accountRegisterInstance, "AddFriendRequest")
                .withArgs(registeredAccountAddress1, receiver, relationship);
        });

        it ("Sending account should be able to see the friend request", async () => {

            // Setup
            const sender = registeredAccountAddress1;
            const receiver = registeredAccountAddress2;
            const receiverUsername = "Registered_Username2".toBytes32();
            const relationship = Relationship.Friend;

            // Act
            const entity = await accountRegisterInstance.getFriendAt(sender, 0);

            // Assert
            expect(entity.friend_account).to.equal(receiver);
            expect(entity.friend_username).to.equal(receiverUsername);
            expect(entity.friend_relationship).to.equal(relationship);
            expect(entity.friend_accepted).to.equal(false);
        });

        it ("Receiving account should be able to see the friend request", async () => {

            // Setup
            const sender = registeredAccountAddress1;
            const senderUsername = "Registered_Username1".toBytes32();
            const receiver = registeredAccountAddress2;
            const relationship = Relationship.Friend;

            // Act
            const entity = await accountRegisterInstance.getFriendAt(receiver, 0);

            // Assert
            expect(entity.friend_account).to.equal(sender);
            expect(entity.friend_username).to.equal(senderUsername);
            expect(entity.friend_relationship).to.equal(relationship);
            expect(entity.friend_accepted).to.equal(false);
        });

        it ("Receiving account should be able to accept the friend request", async () => {

            // Setup
            const sender = registeredAccountAddress1;
            const receiver = registeredAccountAddress2;
            const relationship = Relationship.Friend;

            const callData = accountRegisterInstance.interface
                .encodeFunctionData("acceptFriendRequest", [sender]);

            // Act
            const signer = await ethers.provider.getSigner(account2);
            const transaction = await registeredAccountInstance2
                .connect(signer)
                .submitTransaction(await accountRegisterInstance.address, 0, callData);

            // Assert
            await expect(transaction).to
                .emit(accountRegisterInstance, "AcceptFriendRequest")
                .withArgs(sender, receiver, relationship);
        });

        it ("Sending account should be able to see the friendship", async () => {

            // Setup
            const sender = registeredAccountAddress1;
            const receiver = registeredAccountAddress2;
            const receiverUsername = "Registered_Username2".toBytes32();
            const relationship = Relationship.Friend;

            // Act
            const entity = await accountRegisterInstance.getFriendAt(sender, 0);

            // Assert
            expect(entity.friend_account).to.equal(receiver);
            expect(entity.friend_username).to.equal(receiverUsername);
            expect(entity.friend_relationship).to.equal(relationship);
            expect(entity.friend_accepted).to.equal(true);
        });

        it ("Receiving account should be able to see the friendship", async () => {

            // Setup
            const sender = registeredAccountAddress1;
            const senderUsername = "Registered_Username1".toBytes32();
            const receiver = registeredAccountAddress2;
            const relationship = Relationship.Friend;

            // Act
            const entity = await accountRegisterInstance.getFriendAt(receiver, 0);

            // Assert
            expect(entity.friend_account).to.equal(sender);
            expect(entity.friend_username).to.equal(senderUsername);
            expect(entity.friend_relationship).to.equal(relationship);
            expect(entity.friend_accepted).to.equal(true);
        });

        it ("Should be able to unfriend", async () => {

            // Setup
            const sender = registeredAccountAddress2;
            const friend = registeredAccountAddress1;
            const relationship = Relationship.Friend;

            const callData = accountRegisterInstance.interface
                .encodeFunctionData("unfriend", [friend]);

            // Act
            const signer = await ethers.provider.getSigner(account2);
            const transaction = await registeredAccountInstance2
                .connect(signer)
                .submitTransaction(await accountRegisterInstance.address, 0, callData);

            // Assert
            await expect(transaction).to
                .emit(accountRegisterInstance, "Unfriend")
                .withArgs(sender, friend, relationship);
        });

        it ("Friendship should be removed after unfriending", async () => {

            // Setup
            const account1 = registeredAccountAddress1;
            const account2 = registeredAccountAddress2;

            // Act
            const friendCount1 = await accountRegisterInstance.getFriendCount(account1);
            const friendCount2 = await accountRegisterInstance.getFriendCount(account2);

            // Assert
            expect(friendCount1).to.equal(0);
            expect(friendCount2).to.equal(0);
        });
    });
});