// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

/**
 * Global Ship Skin Errors
 */
/// @dev Emitted when `skin` is not owned by `account`
/// @param tokenId The token that is not owned
/// @param account The account that does not own the ship
error ShipSkinNotOwned(uint tokenId, address account);

/// @dev Emitted when `skin` is not applicable to `ship`
/// @param skinTokenId The token that is not applicable
/// @param skin The skin that is not applicable
/// @param shipTokenId The token that the skin is not applicable to
/// @param ship The ship that the skin is not applicable to
error ShipSkinNotApplicable(uint skinTokenId, bytes32 skin, uint shipTokenId, bytes32 ship);