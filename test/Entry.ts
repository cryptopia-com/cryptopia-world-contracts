import { expect } from "chai";
import { ethers, upgrades} from "hardhat";

import { 
    CryptopiaEntry
} from "../typechain-types";

/**
 * Entry tests
 * 
 * Test cases:
 * - Read version
 */
describe("Entry Contract", function () {

    // Accounts
    let deployer: string;

    // Instances
    let entryContractInstance: CryptopiaEntry;

    // Settings
    const contractVersion: CryptopiaEntry.ContractVersionStruct = {
        major: 1,
        minor: 2,
        patch: 3
    };

    /**
     * Deploy Contracts
     */
    before(async () => {

        // Accounts
        [deployer] = (await ethers.getSigners()).map(s => s.address);

        // Factories
        const EntryContractFactory = await ethers.getContractFactory("CryptopiaEntry");
        
        // Deploy Entry Contract
        const entryProxy = await upgrades.deployProxy(
            EntryContractFactory, [contractVersion]);

        const entryAddress = entryProxy.address;
        entryContractInstance = await ethers.getContractAt("CryptopiaEntry", entryAddress);
    });

    /**
     * Test Version
     */
    describe("Contract Version", function () {

        it("Should read the correct contract version", async () => {
        
            // Act
            const version = await entryContractInstance.version();

            // Assert
            expect(version.major).to.equal(contractVersion.major);
            expect(version.minor).to.equal(contractVersion.minor);
            expect(version.patch).to.equal(contractVersion.patch);
        });
    });
});