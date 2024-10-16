// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../IConstructionMechanics.sol";
import "../../inventories/types/InventoryEnums.sol";

contract CryptopiaConstructionMechanics is Initializable, AccessControlUpgradeable, IConstructionMechanics 
{
    /**
     * Storage 
     */
    struct Construction 
    {
        // Location

        // Building 

        // Progress
    }


    /**
     * Events
     */


    /**
     * Errors
     */


    // Constructor
    function initialize() 
        public virtual initializer 
    {
        __AccessControl_init();
    }


    /**
     * Public functions 
     */
}