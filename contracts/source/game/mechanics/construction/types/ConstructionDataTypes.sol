// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../inventories/types/InventoryEnums.sol";
import "../../../assets/types/AssetDataTypes.sol";
import "../../types/JobDataTypes.sol";

/// @dev Contract for construction mechanics
struct ConstructionContract
{
    /// @dev Expiration time 
    /// @notice The time when the construction expires and the contract is cancelled
    uint64 expiration;

    /// @dev Job progress
    /// @notice Job part of the contract is considered complete when this equals jobs.length
    uint8 jobProgress;

    /// @dev Resource progress
    /// @notice Resource part of the contract is considered complete when this equals resources.length
    uint8 resourceProgress;

    /// @dev The job requirements for construction
    JobContract[] jobs;

    /// @dev The resources required for construction
    ResourceContract[] resources;
}