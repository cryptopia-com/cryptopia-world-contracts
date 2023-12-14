import { BaseContract } from 'ethers'; 
import { Log, TransactionReceipt } from '@ethersproject/providers'; 
import { ethers } from 'hardhat';
import { assert } from 'chai';

/**
 * Function to get a parameter from an event
 * 
 * @param contract The contract instance 
 * @param receipt The transaction receipt
 * @param paramName The name of the parameter
 * @param eventName The name of the event
 * @returns The value of the parameter
 */
export function getParamFromEvent(contract: BaseContract, receipt: TransactionReceipt | null, paramName: string, eventName: string) {
  
    if (!receipt) {
        throw new Error('Transaction receipt is null');
    }

    assert.isObject(receipt);

    const eventFragment = contract.interface.getEvent(eventName);
    if (!eventFragment) {
        throw new Error(`Event ${eventName} not found in contract interface`);
    }

    const eventTopic = ethers.utils.keccak256(
        ethers.utils.toUtf8Bytes(eventFragment.format()));

    const filteredLogs = receipt.logs.filter(
        (log: Log) => log.topics && log.topics[0] === eventTopic);

    assert.notEqual(filteredLogs.length, 0, 'No logs found!');
    assert.equal(filteredLogs.length, 1, 'Too many logs found!');

    // Make a copy of the topics array to make it mutable
    const mutableTopics = [...filteredLogs[0].topics];

    const decodedLog = contract.interface
      .parseLog({ ...filteredLogs[0], topics: mutableTopics});

    if (!decodedLog) {
        throw new Error(`Could not decode log for event ${eventName}`);
    }

    return decodedLog.args[paramName];
}

/**
 * Function to check if an event was emitted
 * 
 * @param contract The contract instance 
 * @param receipt The transaction receipt
 * @param eventName The name of the event
 * @param eventArgs An array of arguments to match against the emitted event, if null, only the event name is checked
 * @returns A boolean indicating if the event was emitted
 */
export function containsEvent(contract: BaseContract, receipt: TransactionReceipt | null, eventName: string, eventArgs?: any[]) {
    if (!receipt) {
        throw new Error('Transaction receipt is null');
    }

    assert.isObject(receipt);

    const eventFragment = contract.interface.getEvent(eventName);
    if (!eventFragment) {
        throw new Error(`Event ${eventName} not found in contract interface`);
    }

    const eventTopic = ethers.utils.id(eventFragment.format());
    const filteredLogs = receipt.logs.filter(
        (log: Log) => log.topics && log.topics[0] === eventTopic);

    if (filteredLogs.length === 0) {
        return false; // No logs found for the event
    }

    // Make a copy of the topics array to make it mutable
    const mutableTopics = [...filteredLogs[0].topics];

    for (const log of filteredLogs) 
    {
        const decodedLog = contract.interface
            .parseLog({ ...filteredLogs[0], topics: mutableTopics});
        if (decodedLog && (!eventArgs || eventArgsMatch(decodedLog.args, eventArgs))) {
            return true; // Event found and arguments match
        }
    }

    return false; // Event not found or arguments did not match
}

/**
 * Helper function to match event arguments
 * 
 * @param logArgs The decoded log arguments
 * @param eventArgs The event arguments to match
 * @returns A boolean indicating if the arguments match
 */
function eventArgsMatch(logArgs: any, eventArgs: any[]) {
    return eventArgs.every((arg, index) => {
        return arg === logArgs[index];
    });
}
