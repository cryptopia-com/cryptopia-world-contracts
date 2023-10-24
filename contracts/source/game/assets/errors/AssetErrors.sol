// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

/// @dev Emitted when `asset` is not a supported asset
/// @param asset The asset that is not supported
error UnsupportedAsset(address asset);

/// @dev Emmited when a token is not owned by the account
/// @param account The account that was tested for ownership
/// @param asset The asset that was tested for ownership
/// @param tokenId The token id that was tested for ownership
error TokenNotOwnedByAccount(address account, address asset, uint tokenId);