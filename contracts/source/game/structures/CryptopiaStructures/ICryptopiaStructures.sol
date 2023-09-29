// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Cryptopia Structures
/// @dev Contains construction and structure data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaStructures {

    function startConstruction(
        uint blueprint, 
        uint titleDeed, 
        uint pricePerTransportUnit, 
        uint[] memory pricesPerWorkUnit) 
        external;
}