// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../tokens/types/TransactionDataTypes.sol";
import "../../../errors/ArgumentErrors.sol";
import "../../errors/FactionErrors.sol";
import "../../players/IPlayerRegister.sol";
import "../../players/errors/PlayerErrors.sol";
import "../../inventories/IInventories.sol";
import "../../maps/errors/MapErrors.sol";
import "../../maps/IMaps.sol";
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

    /// @dev Quest data per player
    struct PlayerQuestData 
    {
        /// @dev Times the quest has been completed
        uint16 completedCount;

        /// @dev Number of steps completed in this iteration
        uint8 stepsCompletedCount;

        /// @dev Steps completed in this iteration
        bytes8 stepsCompleted;

        /// @dev Timestamps
        uint64 timestampStarted;
        uint64 timestampCompleted;
    }


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    // Settings
    uint8 constant private MAX_STEPS_PER_QUEST = 8;

    /// @dev Quests
    Quest[] public quests;

    /// @dev Player quest data
    mapping(address => mapping(uint => PlayerQuestData)) public playerQuestData;

    // Refs
    address public playerRegisterContract;
    address public intentoriesContract;
    address public mapsContract;
    

    /**
     * Events
     */
    /// @dev Emitted when `player` starts `questId`
    /// @param player The player that started the quest
    /// @param questId The quest id that was started
    event QuestStart(address indexed player, uint indexed questId);

    /// @dev Emitted when `player` completes `questId`
    /// @param player The player that completed the quest
    /// @param questId The quest id that was completed
    event QuestComplete(address indexed player, uint indexed questId);

    /// @dev Emitted when `player` completes `stepIndex` of `questId`
    /// @param player The player that completed the step
    /// @param questId The quest id that was completed
    event QuestStepComplete(address indexed player, uint indexed questId, uint8 indexed stepIndex);


    /**
     * Errors
     */
    /// @dev Emitted when `questId` is not found
    /// @param questId The quest id that was not found
    error QuestNotFound(uint questId);

    /// @dev Emitted when `player` tries to complete a step when the quest is not started
    /// @param player The player that did not start the quest
    /// @param questId The quest id that was not started
    error QuestNotStarted(address player, uint questId);

    /// @dev Emitted when `player` already started `questId`
    /// @param player The player that already started the quest
    /// @param questId The quest id that was already started
    error QuestAlreadyStarted(address player, uint questId);

    /// @dev Emitted when `player` tries to start a quest more than `maxRecurrences` times
    /// @param player The player that exceeded the max recurrences
    /// @param questId The quest id that was exceeded
    /// @param maxRecurrences The max recurrences that was exceeded
    error QuestRecurrenceExceeded(address player, uint questId, uint maxRecurrences);

    /// @dev Emitted when the cooldown of `player` for `questId` has not expired
    /// @param player The player that has a cooldown
    /// @param questId The quest id that has a cooldown
    /// @param cooldown The cooldown that has not expired
    error QuestCooldownNotExpired(address player, uint questId, uint cooldown);

    /// @dev Emitted when the time for `player` to complete `questId` has exceeded
    /// @param player The player that exceeded the time
    /// @param questId The quest id that exceeded the time
    /// @param maxDuration The max duration that was exceeded
    error QuestTimeExceeded(address player, uint questId, uint maxDuration);

    /// @dev Emitted when `questId` does not have a step at `index`
    /// @param questId The quest id 
    /// @param index The step index that was not found
    error QuestStepNotFound(uint questId, uint index);

    /// @dev Emitted when `player` tries to complete a step that was already completed
    /// @param player The player that already completed the step
    /// @param questId The quest id that was already completed
    /// @param index The step index that was already completed
    error QuestStepAlreadyCompleted(address player, uint questId, uint index);


    /**
     * Modifiers
     */


    /// @dev Construct
    /// @param _playerRegisterContract Player register contract
    /// @param _intentoriesContract Inventories contract
    /// @param _mapsContract Maps contract
    function initialize(
        address _playerRegisterContract,
        address _intentoriesContract,
        address _mapsContract
    ) 
        public initializer 
    {
        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Refs
        playerRegisterContract = _playerRegisterContract;
        intentoriesContract = _intentoriesContract;
        mapsContract = _mapsContract;
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

        // Steps min 1 max MAX_STEPS_PER_QUEST
        if (quest.steps.length == 0 || quest.steps.length > MAX_STEPS_PER_QUEST) 
        {
            revert ArgumentInvalid();
        }

        quests.push(quest);
    }


    /** 
     * Public functions
     */
    /// @dev Get quest count
    /// @return Quest count
    function getQuestCount() 
        public view returns (uint) 
    {
        return quests.length;
    }


    /// @dev Get quest at index
    /// @param index Quest index
    /// @return Quest at index
    function getQuestAt(uint index) 
        public view 
        returns (Quest memory) 
    {
        return quests[index];
    }


    /// @dev Get quests with pagination
    /// @param skip Number of quests to skip
    /// @param take Number of quests to take
    /// @return Quest range
    function getQuests(uint skip, uint take) 
        public view 
        returns (Quest[] memory) 
    {
        uint length = quests.length;
        uint size = take;
        if (size > length - skip) 
        {
            size = length - skip;
        }

        Quest[] memory result = new Quest[](size);
        for (uint i = 0; i < size; i++) 
        {
            result[i] = quests[skip + i];
        }

        return result;
    }


    /// @dev Start quest with `questId` and directly complete `stepIndices` if any
    /// @param questId Quest id to start
    /// @param stepIndices Steps to complete in the same transaction
    function startQuest(uint questId, uint8[] memory stepIndices)
        public 
    {
         // Get quest
        Quest storage quest = quests[questId];
        PlayerQuestData storage playerData = playerQuestData[msg.sender][questId];

        // Check quest already started
        if (playerData.timestampStarted > playerData.timestampCompleted)
        {
            revert QuestAlreadyStarted(msg.sender, questId);
        }

        // Check quest recurrence
        if (playerData.stepsCompletedCount > 0)
        {
            // Quest in progress
            if (playerData.stepsCompletedCount < quest.steps.length)
            {
                revert QuestAlreadyStarted(msg.sender, questId);
            }

            // Quest completed
            else if (quest.hasRecurrenceConstraint)
            {
                // Max recurrences reached
                if (playerData.completedCount >= quest.maxRecurrences)
                {
                    revert QuestRecurrenceExceeded(msg.sender, questId, quest.maxRecurrences);
                }

                // Reset quest
                else 
                {
                    playerData.stepsCompletedCount = 0;
                    playerData.stepsCompleted = bytes8(0);
                }
            }
        }

        // Check level constraint
        if (quest.hasLevelConstraint) 
        {
            // Get player level
            uint8 playerLevel = IPlayerRegister(playerRegisterContract)
                .getLevel(msg.sender);

            // Check level
            if (playerLevel < quest.level) 
            {
                revert PlayerLevelInsufficient(msg.sender, quest.level, playerLevel);
            }
        }

        // Check faction constraint
        if (quest.hasFactionConstraint) 
        {
            // Get player faction
            Faction playerFaction = IPlayerRegister(playerRegisterContract)
                .getFaction(msg.sender); 

            // Check faction
            if (playerFaction != quest.faction) 
            {
                revert UnexpectedFaction(quest.faction, playerFaction);
            }
        }

        // Check sub faction constraint
        if (quest.hasSubFactionConstraint) 
        {
            // Get player sub faction
            SubFaction playerSubFaction = IPlayerRegister(playerRegisterContract)
                .getSubFaction(msg.sender); 

            // Check sub faction
            if (playerSubFaction != quest.subFaction) 
            {
                revert UnexpectedSubFaction(quest.subFaction, playerSubFaction);
            }
        }

        // Check cooldown constraint
        if (quest.hasCooldownConstraint) 
        {
            // Check cooldown
            if (playerData.timestampCompleted + quest.cooldown > block.timestamp) 
            {
                revert QuestCooldownNotExpired(msg.sender, questId, quest.cooldown);
            }
        }


        // Start quest
        playerData.timestampStarted = uint64(block.timestamp);

        // Emit event
        emit QuestStart(msg.sender, questId);


        // Complete steps if any
        for (uint i = 0; i < stepIndices.length; i++) 
        {
            _completeStep(questId, stepIndices[i]);
        }
    }


    /// @dev Complete step `index` of quest `questId`
    /// @param questId Quest id to which the step belongs
    /// @param index Step index to complete
    function completeStep(uint questId, uint8 index) 
        public
    {
        // Check quest started
        PlayerQuestData storage playerData = playerQuestData[msg.sender][questId];
        if (playerData.timestampStarted <= playerData.timestampCompleted)
        {
            revert QuestNotStarted(msg.sender, questId);
        }

        _completeStep(questId, index);
    }


    /// @dev Complete multiple steps `indices` of quest `questId`
    /// @param questId Quest id to which the steps belong
    /// @param indices Step indices to complete
    function completeSteps(uint questId, uint8[] memory indices) 
        public
    {
        // Check quest started
        PlayerQuestData storage playerData = playerQuestData[msg.sender][questId];
        if (playerData.timestampStarted <= playerData.timestampCompleted)
        {
            revert QuestNotStarted(msg.sender, questId);
        }

        for (uint i = 0; i < indices.length; i++) 
        {
            _completeStep(questId, indices[i]);
        }
    }

    
    /**
     * Internal functions
     */
    /// @dev Complete step `index` of quest `questId`
    /// @param questId Quest id to which the step belongs
    /// @param index Step index to complete
    function _completeStep(uint questId, uint8 index) 
        internal 
    {
        // Get quest
        Quest storage quest = quests[questId];
        QuestStep storage step = quest.steps[index];
        PlayerQuestData storage playerData = playerQuestData[msg.sender][questId];

        // Check step index
        if (index >= quest.steps.length) 
        {
            revert QuestStepNotFound(questId, index);
        }

        // Check step not already completed
        if (playerData.stepsCompleted & bytes8(uint64(1) << index) != 0) 
        {
            revert QuestStepAlreadyCompleted(msg.sender, questId, index);
        }

        // Check time constraint
        if (quest.hasTimeConstraint) 
        {
            // Check time
            if (playerData.timestampStarted + quest.maxDuration < block.timestamp) 
            {
                revert QuestTimeExceeded(msg.sender, questId, quest.maxDuration); // TODO: Allow to cancel quest
            }
        }

        // Get Player location data
        (
            uint16 playerTile, 
            bool playerCanInteract
        ) = IMaps(mapsContract).getPlayerLocationData(msg.sender);

        // Check location constraint
        if (step.hasTileConstraint) 
        {
            if (step.tile != playerTile)
            {
                revert UnexpectedTile(step.tile, playerTile);
            }
        }
 
        // Check if player can interact
        if (!playerCanInteract) 
        {
            revert PlayerCannotInteract(msg.sender);
        }


        // Record progress
        playerData.stepsCompletedCount++;
        playerData.stepsCompleted |= bytes8(uint64(1) << index);

        // Emit event
        emit QuestStepComplete(msg.sender, questId, index);


        // Give
        

        // Take


        // Check if quest completed
        if (playerData.stepsCompletedCount == quest.steps.length) 
        {
            // Complete quest
            playerData.timestampCompleted = uint64(block.timestamp);
            playerData.completedCount++;

            // Emit event
            emit QuestComplete(msg.sender, questId);
        }
    }
}