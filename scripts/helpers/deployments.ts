import fs from 'fs';
import path from 'path';

/**
 * Interface for contract deployment information.
 */
interface ContractDeploymentInfo {
    address: string; // The address at which the contract is deployed
    contractName: string; // The name of the contract
    bytecode: string; // The bytecode of the contract
    verified: boolean; // Whether the contract has been verified on Etherscan
}

/**
 * Interface for map deployment information.
 */
interface MapDeploymentInfo {
    name: string;
}

/**
 * Class for managing smart contract deployments.
 */
export class DeploymentManager 
{
    private networkName: string; // Name of the blockchain network.
    private contactDeploymentFilePath: string; // File path for the deployment JSON.
    private mapDeploymentFilePath: string; // File path for the map deployment JSON.

    /**
     * Constructor: Initializes the DeploymentManager with a specific network name.
     * @param networkName - The name of the network (e.g., 'rinkeby', 'mainnet').
     */
    constructor(networkName: string) 
    {
        this.networkName = networkName;
        this.contactDeploymentFilePath = path.join(__dirname, '../../.deployments', `${networkName}.contracts.json`);
        this.mapDeploymentFilePath = path.join(__dirname, '../../.deployments', `${networkName}.maps.json`);
    }

    //////////////////////////
    // Contract Deployments //
    //////////////////////////

    /**
     * Reads deployment information from the file system.
     * @returns An object mapping contract names to their deployment information.
     */
    private readContractDeployments(): { [contractName: string]: ContractDeploymentInfo } 
    {
        if (fs.existsSync(this.contactDeploymentFilePath)) {
            return JSON.parse(fs.readFileSync(this.contactDeploymentFilePath, 'utf8'));
        }
        return {};
    }

    /**
     * Writes deployment information to the file system.
     * @param deployments - An object mapping contract names to their deployment information.
     */
    private writeContractDeployments(deployments: { [contractName: string]: ContractDeploymentInfo }): void 
    {
        const dirPath = path.dirname(this.contactDeploymentFilePath);
        if (!fs.existsSync(dirPath)) 
        {
            fs.mkdirSync(dirPath, { recursive: true });
        }

        fs.writeFileSync(this.contactDeploymentFilePath, JSON.stringify(deployments, null, 2));
    }

    /**
     * Saves a deployment to the deployment file.
     * @param deploymentKey - The key to use for the deployment.
     * @param contractName - The name of the contract.
     * @param contractAddress - The address where the contract is deployed.
     * @param bytecode - The bytecode of the contract.
     * @param verified - Whether the contract has been verified on Etherscan.
     */
    public saveContractDeployment(deploymentKey: string, contractName: string, contractAddress: string, bytecode: string, verified: boolean): void 
    {
        const deployments = this.readContractDeployments();
        deployments[deploymentKey] = { 
            address: contractAddress,
            contractName: contractName,
            bytecode: bytecode,
            verified: verified
        };

        this.writeContractDeployments(deployments);
    }

    /**
     * Sets the verification status of a deployment.
     * @param deploymentKey - The key to use for the deployment.
     * @param verified - Whether the contract has been verified on Etherscan.
     */
    public setContractVerified(deploymentKey: string, verified: boolean): void
    {
        const deployments = this.readContractDeployments();
        deployments[deploymentKey].verified = verified;
        this.writeContractDeployments(deployments);
    }

    /**
     * Checks if a deployment exists.
     * @param deploymentKey - The key to use for the deployment.
     * @returns True if the contract is deployed, false otherwise.
     */
    public isContractDeployed(deploymentKey: string): boolean 
    {
        const deployments = this.readContractDeployments();
        return !!deployments[deploymentKey];
    }

    /**
     * Retrieves a specific deployment's information.
     * @param deploymentKey - The key to use for the deployment.
     * @returns DeploymentInfo if the contract is found, null otherwise.
     */
    public getContractDeployment(deploymentKey: string): ContractDeploymentInfo 
    {
        const deployments = this.readContractDeployments();
        if (deployments[deploymentKey]) {
            return deployments[deploymentKey];
        }
        
        throw `No deployment found for ${deploymentKey} on ${this.networkName}`;
    }

    /**
     * Retrieves all deployments' information.
     * @returns An object mapping contract names to their deployment information.
     */
    public getContractDeployments(): { [contractName: string]: ContractDeploymentInfo }
    {
        return this.readContractDeployments();
    }

    /**
     * Checks if a deployment has been verified.
     * @param deploymentKey - The key to use for the deployment.
     * @returns True if the contract is verified, false otherwise.
     */
    public isContractVerified(deploymentKey: string): boolean
    {
        const deployments = this.readContractDeployments();
        if (deployments[deploymentKey]) {
            return deployments[deploymentKey].verified;
        }
        
        throw `No deployment found for ${deploymentKey} on ${this.networkName}`;
    }

    /////////////////////
    // Map Deployments //
    /////////////////////

    /**
     * Reads map deployment information from the file system.
     * @returns An object mapping map names to their deployment information.
     */
    private readMapDeployments(): { [mapName: string]: MapDeploymentInfo }
    {
        if (fs.existsSync(this.mapDeploymentFilePath)) {
            return JSON.parse(fs.readFileSync(this.mapDeploymentFilePath, 'utf8'));
        }
        return {};
    }

    /**
     * Writes map deployment information to the file system.
     * @param deployments - An object mapping map names to their deployment information.
     */
    private writeMapDeployments(deployments: { [mapName: string]: MapDeploymentInfo }): void
    {
        const dirPath = path.dirname(this.mapDeploymentFilePath);
        if (!fs.existsSync(dirPath)) 
        {
            fs.mkdirSync(dirPath, { recursive: true });
        }

        fs.writeFileSync(this.mapDeploymentFilePath, JSON.stringify(deployments, null, 2));
    }

    /**
     * Saves a map deployment to the deployment file.
     * @param mapName - The name of the map.
     */
    public saveMapDeployment(mapName: string): void
    {
        const deployments = this.readMapDeployments();
        deployments[mapName] = { name: mapName };
        this.writeMapDeployments(deployments);
    }

    /**
     * Checks if a map deployment exists.
     * @param mapName - The name of the map.
     * @returns True if the map is deployed, false otherwise.
     */
    public isMapDeployed(mapName: string): boolean
    {
        const deployments = this.readMapDeployments();
        return !!deployments[mapName];
    }

    /**
     * Retrieves a specific map deployment's information.
     * @param mapName - The name of the map.
     * @returns MapDeploymentInfo if the map is found, null otherwise.
     */
    public getMapDeployment(mapName: string): MapDeploymentInfo
    {
        const deployments = this.readMapDeployments();
        if (deployments[mapName]) {
            return deployments[mapName];
        }
        
        throw `No deployment found for ${mapName} on ${this.networkName}`;
    }

    /**
     * Retrieves all map deployments' information.
     * @returns An object mapping map names to their deployment information.
     */
    public getMapDeployments(): { [mapName: string]: MapDeploymentInfo }
    {
        return this.readMapDeployments();
    }
}
