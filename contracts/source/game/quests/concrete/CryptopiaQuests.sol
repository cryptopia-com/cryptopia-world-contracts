// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../tokens/types/TransactionDataTypes.sol";
import "../../../errors/ArgumentErrors.sol";
import "../IQuests.sol";

contract CryptopiaQuests is Initializable, AccessControlUpgradeable, IQuests
{
    /// @dev Quest 
    /// @notice A quest has constraints that must be met before it can be started
    /// @notice A quest consists of a number of steps that must be completed in order
    /// @notice A quest consists of a number of rewards that the player can choose from when completed
    struct Quest 
    {
        /// @dev Quest name
        bytes32 name;

        /// @dev Level constraint
        bool hasLevelConstraint;
        uint8 level;

        /// @dev Faction constraint
        bool hasFactionConstraint;
        Faction faction;

        /// @dev Sub faction constraint
        bool hasSubFactionConstraint;
        SubFaction subFaction;

        /// @dev Recurrence constraint
        bool hasRecurrenceConstraint;
        uint maxRecurrences;

        /// @dev Cooldown constraint
        bool hasCooldownConstraint;
        uint cooldown;

        /// @dev Time constraint
        bool hasTimeConstraint;
        uint maxDuration;

        /// @dev Quest steps
        QuestStep[] steps;

        /// @dev Quest rewards
        /// @notice Players can only claim one reward per quest per recurrence
        QuestReward[] rewards;
    }

    /// @dev Quest step
    /// @notice A quest step has constraints that must be met before it can be completed
    /// @notice A quest step can consist of a number of items (ERC20 or ERC721) that are taken or given
    struct QuestStep
    {
        /// @dev Step name
        bytes32 name;

        /// @dev Map constraint
        bool hasMapConstraint;
        bytes32 map;

        /// @dev Tile constraint
        bool hasTileConstraint;
        uint16 tile;

        /// @dev Fungible tokens that are taken from the inventory
        FungibleTransaction[] takeFungible;

        /// @dev Non-fungible tokens that are taken from the inventory
        NonFungibleTransaction[] takeNonFungible;

        /// @dev Fungible tokens that are given to the inventory
        FungibleTransaction[] giveFungible;

        /// @dev Non-fungible tokens that are given to the inventory
        NonFungibleTransaction[] giveNonFungible;
    }

    /// @dev Quest reward
    /// @notice A quest reward describes the xp and karma (can be negative) that are rewarded 
    /// @notice A quest reward describes the amount of tokens that are rewarded
    struct QuestReward
    {
        /// @dev Reward name
        bytes32 name;

        /// @dev The amount of xp rewarded
        uint xp;

        /// @dev The amount of karma rewarded (negative values are allowed)
        int karma;
        
        /// @dev Fungible rewards
        FungibleTransaction[] fungible;

        /// @dev Non-fungible rewards
        NonFungibleTransaction[] nonFungible;
    }

    
    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    /// @dev Quests
    Quest[] public quests;


    /**
     * Events
     */


    /**
     * Errors
     */


    /**
     * Modifiers
     */


    /// @dev Construct
    function initialize() 
        public initializer 
    {
        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    function addQuest(Quest calldata quest) 
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        // Quest name cannot be empty
        if (quest.name == bytes32(0)) 
        {
            revert ArgumentInvalid();
        }

        quests.push(quest);
    }


    /** 
     * Public functions
     */
    function getQuestCount() 
        public view returns (uint) 
    {
        return quests.length;
    }
}