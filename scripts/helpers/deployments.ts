import fs from 'fs';
import path from 'path';

/**
 * Interface for deployment information.
 */
interface DeploymentInfo {
    address: string; // The address at which the contract is deployed.
}

/**
 * Class for managing smart contract deployments.
 */
export class DeploymentManager 
{
    private networkName: string; // Name of the blockchain network.
    private deploymentFilePath: string; // File path for the deployment JSON.

    /**
     * Constructor: Initializes the DeploymentManager with a specific network name.
     * @param networkName - The name of the network (e.g., 'rinkeby', 'mainnet').
     */
    constructor(networkName: string) 
    {
        this.networkName = networkName;
        this.deploymentFilePath = path.join(__dirname, '../../data/.deployments', `${networkName}.json`);
    }

    /**
     * Reads deployment information from the file system.
     * @returns An object mapping contract names to their deployment information.
     */
    private readDeployments(): { [contractName: string]: DeploymentInfo } 
    {
        if (fs.existsSync(this.deploymentFilePath)) {
            return JSON.parse(fs.readFileSync(this.deploymentFilePath, 'utf8'));
        }
        return {};
    }

    /**
     * Writes deployment information to the file system.
     * @param deployments - An object mapping contract names to their deployment information.
     */
    private writeDeployments(deployments: { [contractName: string]: DeploymentInfo }): void 
    {
        const dirPath = path.dirname(this.deploymentFilePath);
        if (!fs.existsSync(dirPath)) 
        {
            fs.mkdirSync(dirPath, { recursive: true });
        }

        fs.writeFileSync(this.deploymentFilePath, JSON.stringify(deployments, null, 2));
    }

    /**
     * Saves a deployment to the deployment file.
     * @param contractName - The name of the contract.
     * @param contractAddress - The address where the contract is deployed.
     */
    public saveDeployment(contractName: string, contractAddress: string): void 
    {
        const deployments = this.readDeployments();
        deployments[contractName] = { address: contractAddress };
        this.writeDeployments(deployments);
    }

    /**
     * Retrieves a specific deployment's information.
     * @param contractName - The name of the contract to retrieve.
     * @returns DeploymentInfo if the contract is found, null otherwise.
     */
    public getDeployment(contractName: string): DeploymentInfo 
    {
        const deployments = this.readDeployments();
        if (deployments[contractName]) {
            return deployments[contractName];
        }
        
        throw `No deployment found for ${contractName} on ${this.networkName}`;
    }
}
