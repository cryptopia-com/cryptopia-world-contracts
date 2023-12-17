import { ethers } from 'hardhat';
import { assert } from 'chai';

declare global {
  interface String {
    toBytes(n: number): string;
    toBytes32(): string;
    toWei(): string;
    toKeccak256(): string;
  }

  interface Number {
    toWei(): string;
  }
}

/**
 * Convert string to bytesN format
 */
String.prototype.toBytes = function(n: number) {
  let input = String(this);
  assert.isAtMost(input.length, n * 2, `Input string is larger than ${n} bytes`);
  return ethers.utils.hexlify(ethers.utils.toUtf8Bytes(input)).padEnd(n * 2 + 2, '0');
};

/**
 * Convert string to bytes32 format
 */
String.prototype.toBytes32 = function() {
  return String(this).toBytes(32);
};

/**
 * Convert string to wei
 */
 String.prototype.toWei = function() 
 {
  let input = String(this);
  return ethers.utils.parseEther(input).toString();
 };

/**
 * Convert number to wei
 */
 Number.prototype.toWei = function() 
 {
  let input = Number(this).toString();
  return ethers.utils.parseEther(input).toString();
 };

/**
 * Convert string to keccak256
 */
String.prototype.toKeccak256 = function() {
  return ethers.utils.keccak256(ethers.utils.toUtf8Bytes(String(this)));
};

export {};