// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../../../game/assets/types/AssetEnums.sol";

/**
 * Global Tool Errors
 */
/// @dev Emitted when the specified tool is required for minting the provided resource
/// @param resource The resource attempted to be minted with the tool
error ToolRequiredForMinting(ResourceType resource);