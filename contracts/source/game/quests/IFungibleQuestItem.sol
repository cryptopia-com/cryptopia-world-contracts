// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Quest item
interface IFungibleQuestItem {

    /// @dev Give `amount` of this asset `to` address
    /// @param to Address to give to
    /// @param amount Amount to give
    function __give(address to, uint amount) external;

    /// @dev Take `amount` of this asset `from` address
    /// @param from Address to take from
    /// @param amount Amount to take
    function __take(address from, uint amount) external;
}