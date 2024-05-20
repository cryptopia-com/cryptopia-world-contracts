import "../scripts/helpers/converters";
import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { MINTER_ROLE, SYSTEM_ROLE } from "./settings/roles";   

import { 
    CryptopiaShipToken,
    CryptopiaShipSkinToken,
} from "../typechain-types";

import { 
    ShipSkinStruct 
} from "../typechain-types/contracts/source/tokens/ERC721/ships/IShipSkins";


/**
 * Ship tests
 */
describe("Ships", function () {

    // Accounts
    let deployer: string;
    let system: string;
    let minter: string;
    let account1: string;
    let account2: string;
    let other: string;
    let treasury: string;

    /**
     * Deploy Contracts
     */
    before(async () => {

        // Accounts
        [deployer, system, minter, account1, account2, other, treasury] = (
            await ethers.getSigners()).map(s => s.address);
    });

    /**
     * Test cleaning of Ships
     */
    describe("Skins", function () {

        const skins : ShipSkinStruct[] = [
            {
                name: "Blazing Sun Skin".toBytes32(),
                ship: "Whitewake".toBytes32()
            },
            {
                name: "Frozen Moon Skin".toBytes32(),
                ship: "Polaris".toBytes32()
            },
            {
                name: "Thunderstorm Skin".toBytes32(),
                ship: "Socrates".toBytes32()
            },
            {
                name: "Golden Dawn Skin".toBytes32(),
                ship: "Kingfisher".toBytes32()
            }
        ];


        let shipTokenInstance: CryptopiaShipToken;
        let shipSkinTokenInstance: CryptopiaShipSkinToken;

        /**
         * Setup
         */
        before(async () => {

            const WhitelistFactory = await ethers.getContractFactory("CryptopiaWhitelist");
            const InventoriesFactory = await ethers.getContractFactory("CryptopiaInventories");
            const ShipTokenFactory = await ethers.getContractFactory("CryptopiaShipToken");
            const ShipSkinTokenFactory = await ethers.getContractFactory("CryptopiaShipSkinToken");

            // Deploy Inventories
            const inventoriesProxy = await upgrades.deployProxy(
                InventoriesFactory, 
                [
                    treasury
                ]);

            const inventoriesAddress = await inventoriesProxy.address;

            // Deploy Whitelist
            const whitelistProxy = await upgrades.deployProxy(
                WhitelistFactory, 
                [
                    [
                        inventoriesAddress
                    ]
                ]);

            const whitelistAddress = await whitelistProxy.address;

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
            shipSkinTokenInstance = await ethers.getContractAt("CryptopiaShipSkinToken", shipSkinTokenAddress);

            // Setup roles
            await shipSkinTokenInstance.grantRole(SYSTEM_ROLE, system);
            await shipSkinTokenInstance.grantRole(MINTER_ROLE, minter);


            // Deploy ships
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

            // Setup roles
            shipTokenInstance.grantRole(SYSTEM_ROLE, system);
            shipSkinTokenInstance.grantRole(SYSTEM_ROLE, shipTokenAddress);


            // Setup Skins
            await shipSkinTokenInstance.setSkins(skins);
            
            const minterSigner = await ethers.getSigner(minter);
            for (let i = 0; i < skins.length; i++)
            {
                await shipSkinTokenInstance
                    .connect(minterSigner)
                    .mint(skins[i].name, account1);
            }

            // Setup Ships
            const systemSigner = await ethers.getSigner(system);
            await shipTokenInstance
                .connect(systemSigner)
                .__mintTo(account1, skins[0].ship);

            await shipTokenInstance
                .connect(systemSigner)
                .__mintTo(account2, skins[0].ship);
        });

        it ("Non-minter should not be able to mint a skin", async function () {

            // Setup 
            const to = account1;
            const skin = skins[0];

            // Act
            const signer = await ethers.getSigner(other);
            const transaction = shipSkinTokenInstance
                .connect(signer)
                .mint(skin.name, to);

            // Assert
            await expect(transaction).to.be
                .revertedWithCustomError(shipSkinTokenInstance, "AccessControlUnauthorizedAccount")
                .withArgs(other, MINTER_ROLE);
        });

        it ("Should not be able to apply a skin to a non-existent ship", async function () {

            // Setup 
            const account = account1;
            const shipTokenId = skins.length + 1; // Non-existent ship
            const skinTokenId = 1; // Existing skin

            // Act
            const signer = await ethers.getSigner(account);
            const transaction = shipTokenInstance
                .connect(signer)
                .applySkin(shipTokenId, skinTokenId);

            // Assert
            await expect(transaction).to.be
                .revertedWithCustomError(shipTokenInstance, "ERC721NonexistentToken");
        });

        it ("Should not be able to apply a non-existent skin to a ship", async function () {

            // Setup 
            const account = account1;
            const shipTokenId = 1; // Existing ship
            const skinTokenId = skins.length + 1; // Non-existent skin

            // Act
            const signer = await ethers.getSigner(account);
            const transaction = shipTokenInstance
                .connect(signer)
                .applySkin(shipTokenId, skinTokenId);

            // Assert
            await expect(transaction).to.be
                .revertedWithCustomError(shipTokenInstance, "ERC721NonexistentToken");
        });

        it ("Should not be able to apply a skin to a ship that is not owned", async function () {

            // Setup 
            const account = account1;
            const shipTokenId = 2; // Existing ship
            const skinTokenId = 1; // Existing skin

            // Act
            const signer = await ethers.getSigner(account);
            const transaction = shipTokenInstance
                .connect(signer)
                .applySkin(shipTokenId, skinTokenId);

            // Assert
            await expect(transaction).to.be
                .revertedWithCustomError(shipTokenInstance, "ShipNotOwned")
                .withArgs(shipTokenId, account);
        });

        it ("Should not be able to apply a skin that is not owned", async function () {
                
            // Setup 
            const account = account2;
            const shipTokenId = 2; // Existing ship
            const skinTokenId = 1; // Existing skin

            // Act
            const signer = await ethers.getSigner(account);
            const transaction = shipTokenInstance
                .connect(signer)
                .applySkin(shipTokenId, skinTokenId);

            // Assert
            await expect(transaction).to.be
                .revertedWithCustomError(shipTokenInstance, "ShipSkinNotOwned")
                .withArgs(skinTokenId, account);
        });

        it ("Should not be able to apply an incompatible skin to a ship", async function () {

            // Setup 
            const account = account1;
            const ship = skins[0].ship;
            const skin = skins[1].name;
            const shipTokenId = 1; // Existing ship
            const skinTokenId = 2; // Incompatible skin

            // Act
            const signer = await ethers.getSigner(account);
            const transaction = shipTokenInstance
                .connect(signer)
                .applySkin(shipTokenId, skinTokenId);

            // Assert
            await expect(transaction).to.be
                .revertedWithCustomError(shipTokenInstance, "ShipSkinNotApplicable")
                .withArgs(skinTokenId, skin, shipTokenId, ship);
        });

        it ("Should apply a skin to a compatible ship", async function () {

            // Setup 
            const account = account1;
            const skin = skins[0];
            const shipTokenId = 1; // Existing ship
            const skinTokenId = 1; // Compatible skin

            // Act
            const signer = await ethers.getSigner(account);
            const transaction = shipTokenInstance
                .connect(signer)
                .applySkin(shipTokenId, skinTokenId);

            // Assert
            await expect(transaction).to
                .emit(shipTokenInstance, "ShipSkinApplied")
                .withArgs(shipTokenId, skinTokenId, 0, skin.name);
        });

        it ("Should burn a skin after being applied", async function () {

            // Setup 
            const skinTokenId = 1; // Burned skin

            // Act
            const operation = shipSkinTokenInstance.ownerOf(skinTokenId);

            // Assert
            expect(operation).to.be
                .revertedWithCustomError(shipSkinTokenInstance, "ERC721NonexistentToken")
                .withArgs(skinTokenId);
        });

        it ("Should not be able to apply a skin that has been burned", async function () {

            // Setup 
            const account = account1;
            const shipTokenId = 1; // Existing ship
            const skinTokenId = 1; // Burned skin

            // Act
            const signer = await ethers.getSigner(account);
            const transaction = shipTokenInstance
                .connect(signer)
                .applySkin(shipTokenId, skinTokenId);

            // Assert
            await expect(transaction).to.be
                .revertedWithCustomError(shipTokenInstance, "ERC721NonexistentToken")
                .withArgs(skinTokenId);
        });
    });
});