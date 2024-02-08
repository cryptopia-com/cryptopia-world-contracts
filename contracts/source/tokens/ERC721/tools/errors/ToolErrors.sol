// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/assets/types/AssetEnums.sol";

/**
 * Global Tool Errors
 */
/// @dev Emitted when the specified tool is broken
/// @param tokenId The id of the tool that is broken
error ToolIsBroken(uint tokenId);

/// @dev Emitted when the specified tool is required for minting the provided resource
/// @param resource The resource attempted to be minted with the tool
error ToolRequiredForMinting(Resource resource);