// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.20;

/**
 * Call proxy used to abstract low level calls used for testing purposes 
 * 
 * Based on: http://truffleframework.com/tutorials/testing-for-throws-in-solidity-tests
 *
 * #created 10/7/2020
 * #author HFB
 */
contract CallProxy {

    // Target contract
    address private target;

    // Calldata
    bytes private data;


    /**
     * Constuct for target contract
     *
     * @param _target The contact that is being tested
     */
    constructor(address _target) {
        target = _target;
    }
    
   /**
    * Capture call data
    * 
    * This works because the called method does not exist
    * and the receive function is called instead
    */
    receive () external payable {
        _receive();
    }

    /**
     * Workaround
     */
    function _receive() private  
    {
        data = msg.data;
    }

   /**
    * Capture call data
    * 
    * This works because the called method does not exist
    * and the fallback function is called instead
    */
    fallback () external payable {
        data = msg.data;
    }


    /**
     * Test if `target` would have thrown when calling the 
     * target method
     *
     * @return Wheter the call resulted in an exception or not
     */
    function throws() public returns (bool) {
        (bool result,) = target.call(data);
        return result;
    }
}