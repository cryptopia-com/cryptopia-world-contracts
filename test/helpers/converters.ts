import { ethers } from 'hardhat';
import { assert } from 'chai';

declare global {
  interface String {
    toBytes(n: number): string;
    toBytes32(): string;
    toBytes28(): string;
    toBytes26(): string;
    toWei(): string;
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

  return ethers.hexlify(ethers.toUtf8Bytes(input)).padEnd(n * 2 + 2, '0');
};

/**
 * Convert string to bytes32 format
 */
String.prototype.toBytes32 = function() {
  return String(this).toBytes(32);
};

/**
 * Convert string to bytes28 format
 */
String.prototype.toBytes28 = function() {
  return String(this).toBytes(28);
};

/**
 * Convert string to bytes26 format
 */
String.prototype.toBytes26 = function() {
  return String(this).toBytes(26);
};

/**
 * Convert string to wei
 */
 String.prototype.toWei = function() 
 {
  let input = String(this);
  return ethers.parseEther(input).toString();
 };

/**
 * Convert number to wei
 */
 Number.prototype.toWei = function() 
 {
  let input = Number(this).toString();
  return ethers.parseEther(input).toString();
 };

export {};