// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.12 < 0.9.0;

import "./CallProxy.sol";

/**
 * CallProxy creation
 *
 * #created 10/7/2020
 * #author HFB
 */  
contract CallProxyFactory {

    /**
     * Create a CallProxy instance
     */
    function create(address _target) public returns (address) {
        return address(new CallProxy(_target));
    }
}