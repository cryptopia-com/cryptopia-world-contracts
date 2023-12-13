import { ethers } from 'hardhat';
import { TransactionReceipt } from '@ethersproject/abstract-provider';

/**
 * Wait for a transaction to be confirmed.
 *
 * @param {string} transactionHash - Hash of the transaction to wait for.
 * @param {number} confirmations - Number of confirmations to wait for.
 * @param {number} pollingInterval - Interval in milliseconds to poll for confirmations.
 * @param {number} pollingTimeout - Timeout in milliseconds to stop polling.
 * @returns {Promise<void>}
 */
export async function waitForTransaction(transactionHash: string, confirmations: number = 1, pollingInterval: number, pollingTimeout: number): Promise<TransactionReceipt | null> {
    let startTime = Date.now();
    let receipt = null;

    while (!receipt || await receipt.confirmations < confirmations) 
    {
        if (Date.now() - startTime > pollingTimeout) 
        {
            throw new Error(`Maximum wait time exceeded for transaction: ${transactionHash}`);
        }

        receipt = await ethers.provider
            .getTransactionReceipt(transactionHash);

        if (!receipt) 
        {
            await new Promise(
                resolve => setTimeout(resolve, pollingInterval)); 
        }
    }

    return receipt; 
}