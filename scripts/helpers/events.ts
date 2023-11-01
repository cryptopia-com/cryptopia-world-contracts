import { BaseContract, Log, TransactionReceipt } from 'ethers';
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

    const eventTopic = ethers.keccak256(
        ethers.toUtf8Bytes(eventFragment.format()));

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