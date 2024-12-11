// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../inventories/types/InventoryEnums.sol";
import "../../../assets/types/AssetDataTypes.sol";
import "../../types/LabourDataTypes.sol";

/// @dev Contract for construction mechanics
struct ConstructionContract
{
    /// @dev Expiration time 
    /// @notice The time when the construction expires and the contract is cancelled
    uint64 expiration;

    /// @dev Labour progress
    /// @notice Labour part of the contract is considered complete when this equals labour.length
    uint8 labourProgress;

    /// @dev Resource progress
    /// @notice Resource part of the contract is considered complete when this equals resources.length
    uint8 resourceProgress;

    /// @dev The labour requirements for construction
    LabourContract[] labour;

    /// @dev The resources required for construction
    ResourceContract[] resources;
}