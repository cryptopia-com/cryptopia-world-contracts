// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../../source/tokens/ERC721/concrete/tools/CryptopiaToolToken.sol";

/// @title Cryptopia Tool Token
/// @notice This contract handles the creation, management, and utilization of tools within Cryptopia.
/// It provides functionalities to craft tools, use them for minting resources, and manage their durability.
/// Tools in this contract are ERC721 tokens, allowing each tool to have unique properties and state.
/// @dev Inherits from CryptopiaERC721, implements ITools, ICraftable, and INonFungibleQuestReward interfaces.
/// The contract stores tool data, manages tool instances, and interfaces with other game contracts like inventories and players.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentToolToken is CryptopiaToolToken {

    // Implement clean function
}