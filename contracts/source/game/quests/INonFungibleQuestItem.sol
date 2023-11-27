// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Quest item
interface INonFungibleQuestItem {

    /// @dev Give `item` `to` address
    /// @param to Address to give to
    /// @param item Item to give
    function __give(address to, bytes32 item) external;

    /// @dev Take `item` `from` address
    /// @param from Address to take from
    /// @param item Item to take
    function __take(address from, bytes32 item) external;
}