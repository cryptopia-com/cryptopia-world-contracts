// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

interface IConstructionMechanics {

    function startConstruction(
        uint titleDeedId, 
        uint blueprintId, 
        uint[] memory labourCompenstations, 
        uint[] memory resourceCompensations) 
        external;
}