// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20 < 0.9.0;

/**
 * Accounts wrapper for unit tests
 *
 * #created 10/7/2020
 * #author HFB
 */  
contract Accounts {

    address[] private accounts;


   /**
    * Accept accounts
    * 
    * @param _accounts List of accounts to grant access to
    */  
    constructor(address[] memory _accounts) {
        accounts = _accounts;
    }


   /**
    * Returns the number of accounts
    * 
    * @return Number of accounts
    */  
    function length() public view returns (uint) {
        return accounts.length;
    }


   /**
    * Returns the account at `_index` 
    * 
    * @param _index Location of the account
    * @return address
    */ 
    function get(uint _index) public view returns (address) {
        return accounts[_index];
    }
}