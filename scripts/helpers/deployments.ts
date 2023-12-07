import fs from 'fs';
import path from 'path';

/**
 * Interface for deployment information.
 */
interface DeploymentInfo {
    address: string; // The address at which the contract is deployed
    contractName: string; // The name of the contract
    bytecode: string; // The bytecode of the contract
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
     * @param deploymentKey - The key to use for the deployment.
     * @param contractName - The name of the contract.
     * @param contractAddress - The address where the contract is deployed.
     * @param bytecode - The bytecode of the contract.
     */
    public saveDeployment(deploymentKey: string, contractName: string, contractAddress: string, bytecode: string): void 
    {
        const deployments = this.readDeployments();
        deployments[deploymentKey] = { 
            address: contractAddress,
            contractName: contractName,
            bytecode: bytecode
        };

        this.writeDeployments(deployments);
    }

    /**
     * Checks if a deployment exists.
     * @param deploymentKey - The key to use for the deployment.
     * @returns True if the contract is deployed, false otherwise.
     */
    public isDeployed(deploymentKey: string): boolean 
    {
        const deployments = this.readDeployments();
        return !!deployments[deploymentKey];
    }

    /**
     * Retrieves a specific deployment's information.
     * @param deploymentKey - The key to use for the deployment.
     * @returns DeploymentInfo if the contract is found, null otherwise.
     */
    public getDeployment(deploymentKey: string): DeploymentInfo 
    {
        const deployments = this.readDeployments();
        if (deployments[deploymentKey]) {
            return deployments[deploymentKey];
        }
        
        throw `No deployment found for ${deploymentKey} on ${this.networkName}`;
    }
}
