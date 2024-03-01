// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../errors/ArgumentErrors.sol";
import "../../errors/FactionErrors.sol";
import "../../players/IPlayerRegister.sol";
import "../../players/types/PlayerDataTypes.sol";
import "../../players/errors/PlayerErrors.sol";
import "../../inventories/types/InventoryDataTypes.sol";
import "../../inventories/IInventories.sol";
import "../../maps/errors/MapErrors.sol";
import "../../maps/IMaps.sol";
import "../items/IFungibleQuestItem.sol";
import "../items/INonFungibleQuestItem.sol";
import "../rewards/IFungibleQuestReward.sol";
import "../rewards/INonFungibleQuestReward.sol";
import "../IQuests.sol";

/// @title Cryptopia Quests Contract
/// @notice Handles the functionality of quests within Cryptopia. 
/// It orchestrates the quest life cycle, including starting quests, completing quest steps, 
/// and claiming rewards. The contract allows players to engage in diverse quests with multiple steps, 
/// providing a dynamic and interactive gameplay experience. It integrates various aspects of the game, 
/// such as player data, inventories, and maps, to offer quests that are not only challenging but also deeply 
/// integrated with the game's lore and mechanics.
/// @dev Inherits from Initializable and AccessControlUpgradeable and implements the IQuests interface. 
/// It manages a comprehensive set of quest-related data and provides a robust system for quest management, 
/// including constraints, steps, and rewards. The contract is designed to be upgradable, ensuring future flexibility 
/// and adaptability for the evolving needs of the game.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaQuests is Initializable, AccessControlUpgradeable, IQuests
{
    /// @dev Quest within Cryptopia
    /// @notice Quests come with constraints (like level or faction requirements) that players must meet to start them
    /// @notice Quests include a series of ordered steps for completion and offer multiple rewards for players to choose from upon completion
    struct QuestData {

        /// @dev Index in the questsIndex array
        uint index;

        /// @dev Indicates if a level constraint is applied to start the quest
        bool hasLevelConstraint;
        /// @dev Minimum player level required to start the quest, effective if hasLevelConstraint is true
        uint8 level;

        /// @dev Indicates if a faction constraint is applied to start the quest
        bool hasFactionConstraint;
        /// @dev Specific faction required to start the quest, effective if hasFactionConstraint is true
        Faction faction;

        /// @dev Indicates if a sub-faction constraint is applied to start the quest
        bool hasSubFactionConstraint;
        /// @dev Specific sub-faction required to start the quest, effective if hasSubFactionConstraint is true
        SubFaction subFaction;

        /// @dev Indicates if there's a limit on how many times the quest can be completed
        bool hasCompletionConstraint;
        /// @dev Maximum number of times the quest can be repeated, effective if hasCompletionConstraint is true
        uint maxCompletions;

        /// @dev Indicates if there's a cooldown period between quest repetitions
        bool hasCooldownConstraint;
        /// @dev Cooldown duration in seconds before the quest can be started again, effective if hasCooldownConstraint is true
        uint cooldown;

        /// @dev Indicates if there's a time limit to complete the quest
        bool hasTimeConstraint;
        /// @dev Maximum duration in seconds to complete the quest, effective if hasTimeConstraint is true
        uint maxDuration;

        /// @dev Array of steps that need to be completed in order to finish the quest
        QuestStep[] steps;

        /// @dev Array of rewards available upon quest completion
        /// @notice Players can choose only one reward per quest completion
        QuestReward[] rewards;
    }

    /// @dev Individual player's progress and interactions with a specific quest
    struct QuestPlayerData 
    {
        /// @dev Total number of times the player has completed the quest
        uint16 completedCount;

        /// @dev Count of steps completed in the current iteration of the quest
        uint8 stepsCompletedCount;

        /// @dev Bitmask representing the steps completed in the current iteration
        /// @notice Each bit corresponds to a step in the quest, where a set bit indicates completion
        bytes8 stepsCompleted;

        /// @dev Timestamp marking when the player started the current iteration of the quest
        uint64 timestampStarted;

        /// @dev Timestamp marking when the player completed the quest in the current iteration
        /// This is set when all required steps of the quest are completed
        uint64 timestampCompleted;

        /// @dev Timestamp marking when the player claimed their reward for the quest
        /// @notice This is set when the player claims one of the available rewards upon completing the quest
        uint64 timestampClaimed;
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

    /// @dev Details of each quest, mapped by a unique quest identifier
    mapping (bytes32 => QuestData) public quests;
    bytes32[] internal questsIndex;

    /// @dev Tracks player-specific data for each quest, including progress and completion status
    mapping(address => mapping(bytes32 => QuestPlayerData)) public playerQuestData;

    // Refs
    address public playerRegisterContract;
    address public intentoriesContract;
    address public mapsContract;
    

    /**
     * Events
     */
    /// @dev Emitted when `player` starts `quest`
    /// @param player The player that started the quest
    /// @param quest The quest id that was started
    event QuestStart(address indexed player, bytes32 indexed quest);

    /// @dev Emitted when `player` completes `quest`
    /// @param player The player that completed the quest
    /// @param quest The quest id that was completed
    event QuestComplete(address indexed player, bytes32 indexed quest);

    /// @dev Emitted when `player` completes `stepIndex` of `quest`
    /// @param player The player that completed the step
    /// @param quest The quest id that was completed
    event QuestStepComplete(address indexed player, bytes32 indexed quest, uint8 indexed stepIndex);

    /// @dev Emitted when `player` claims `rewardIndex` of `quest`
    /// @param player The player that claimed the reward
    /// @param quest The quest id that was claimed
    /// @param rewardIndex The reward index that was claimed
    /// @param asset The asset that was claimed
    /// @param amount The amount that was claimed
    /// @param tokenId The token id that was claimed
    event QuestRewardClaim(address indexed player, bytes32 indexed quest, uint8 indexed rewardIndex, address asset, uint amount, uint tokenId);


    /**
     * Errors
     */
    /// @dev Emitted when `quest` is not found
    /// @param quest The quest id that was not found
    error QuestNotFound(bytes32 quest);

    /// @dev Emitted when `player` tries to complete a step when the quest is not started
    /// @param player The player that did not start the quest
    /// @param quest The quest that was not started
    error QuestNotStarted(address player, bytes32 quest);

    /// @dev Emitted when `player` already started `quest`
    /// @param player The player that already started the quest
    /// @param quest The quest that was already started
    error QuestAlreadyStarted(address player, bytes32 quest);

    /// @dev Emitted when `player` did not complete `quest` yet
    /// @param player The player that did not complete the quest
    /// @param quest The quest that was not completed
    error QuestNotCompleted(address player, bytes32 quest);

    /// @dev Emitted when `player` tries to start a quest more than `maxCompletions` times
    /// @param player The player that exceeded the max completions
    /// @param quest The quest that was exceeded
    /// @param maxCompletions The max completions that was exceeded
    error QuestCompletionExceeded(address player, bytes32 quest, uint maxCompletions);

    /// @dev Emitted when the cooldown of `player` for `quest` has not expired 
    /// @param player The player that has a cooldown
    /// @param quest The quest id that has a cooldown
    /// @param cooldown The cooldown that has not expired
    error QuestCooldownNotExpired(address player, bytes32 quest, uint cooldown);

    /// @dev Emitted when the time for `player` to complete `quest` has exceeded 
    /// @param player The player that exceeded the time
    /// @param quest The quest id that exceeded the time
    /// @param maxDuration The max duration that was exceeded
    error QuestTimeExceeded(address player, bytes32 quest, uint maxDuration);

    /// @dev Emitted when `quest` does not have a step at `index` 
    /// @param quest The quest id 
    /// @param index The step index that was not found
    error QuestStepNotFound(bytes32 quest, uint index);

    /// @dev Emitted when `player` tries to complete a step that was already completed 
    /// @param player The player that already completed the step
    /// @param quest The quest id that was already completed
    /// @param index The step index that was already completed
    error QuestStepAlreadyCompleted(address player, bytes32 quest, uint index);

    /// @dev Emitted when `player` tries to claim a reward that does not exist 
    /// @param quest The quest id that was not found
    /// @param index The reward index that was not found
    error QuestRewardNotFound(bytes32 quest, uint index);

    /// @dev Emitted when `player` tries to claim a reward that was already claimed
    /// @param player The player that already claimed the reward
    /// @param quest The quest id that was already claimed
    error QuestRewardAlreadyClaimed(address player, bytes32 quest);


    /// @dev Construct
    /// @param _playerRegisterContract Player register contract
    /// @param _intentoriesContract Inventories contract
    /// @param _mapsContract Maps contract
    function initialize(
        address _playerRegisterContract,
        address _intentoriesContract,
        address _mapsContract) 
        public virtual initializer 
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
    /// @dev Set quest
    /// @param quest Quest to add
    function setQuest(Quest memory quest) 
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setQuest(quest);
    }


    /// @dev Set multiple quests
    /// @param quests_ Quests to add
    function setQuests(Quest[] memory quests_) 
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        for (uint i = 0; i < quests_.length; i++) 
        {
            _setQuest(quests_[i]);
        }
    }


    /** 
     * Public functions
     */
    /// @dev Get quest count
    /// @return count number of quests
    function getQuestCount() 
        public override view 
        returns (uint count) 
    {
        count = questsIndex.length;
    }


    /// @dev Get quest at index
    /// @param index Quest index
    /// @return quest at index
    function getQuestAt(uint index) 
        public override view 
        returns (Quest memory quest) 
    {
        quest = _getQuest(questsIndex[index]);
    }


    /// @dev Get quests with pagination
    /// @param skip Number of quests to skip
    /// @param take Number of quests to take
    /// @return quests_ range of quests
    function getQuests(uint skip, uint take) 
        public view 
        returns (Quest[] memory quests_) 
    {
        uint length = take;
        if (questsIndex.length < skip + take)  
        {
            length = questsIndex.length - skip;
        }

        quests_ = new Quest[](length);
        for (uint i = 0; i < length; i++) 
        {

            quests_[i] = _getQuest(questsIndex[skip + i]);
        }

        return quests_;
    }


    /// @dev Start quest with `quest` and directly complete `stepIndices` if any
    /// @param quest Quest id to start
    /// @param stepIndices Steps to complete in the same transaction
    /// @param giveInventories Inventory to which a quest item is given
    /// @param takeInventories Inventory from which a quest item is taken
    /// @param takeTokenIds Non-fungible token id to take
    function startQuest(
        bytes32 quest, 
        uint8[] memory stepIndices,
        Inventory[][] memory giveInventories, 
        Inventory[][] memory takeInventories, 
        uint[][] memory takeTokenIds)
        public 
    {
        _startQuest(quest);

        // Complete steps in the same transaction (if any)
        for (uint i = 0; i < stepIndices.length; i++) 
        {
            _completeStep(
                quest, 
                stepIndices[i], 
                giveInventories[i], 
                takeInventories[i], 
                takeTokenIds[i]);
        }
    }


    /// @dev Complete step `index` of quest `quest`
    /// @param quest Quest id to which the step belongs
    /// @param stepIndex Step index to complete
    /// @param giveInventories Inventory to which a quest item is given
    /// @param takeInventories Inventory from which a quest item is taken
    /// @param takeTokenIds Non-fungible token id to take
    function completeStep(
        bytes32 quest, 
        uint8 stepIndex,
        Inventory[] memory giveInventories, 
        Inventory[] memory takeInventories, 
        uint[] memory takeTokenIds) 
        public 
    {
        // Check quest started
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][quest];
        if (questPlayerData.timestampStarted <= questPlayerData.timestampCompleted)
        {
            revert QuestNotStarted(msg.sender, quest);
        }

        _completeStep(
            quest, 
            stepIndex, 
            giveInventories, 
            takeInventories, 
            takeTokenIds);
    }


    /// @dev Complete multiple steps `indices` of quest `quest`
    /// @param quest Quest id to which the steps belong
    /// @param stepIndices Step indices to complete
    /// @param giveInventories Inventory to which a quest item is given
    /// @param takeInventories Inventory from which a quest item is taken
    /// @param takeTokenIds Non-fungible token id to take
    function completeSteps(
        bytes32 quest, 
        uint8[] memory stepIndices,
        Inventory[][] memory giveInventories, 
        Inventory[][] memory takeInventories, 
        uint[][] memory takeTokenIds) 
        public 
    {
        // Check quest started
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][quest];
        if (questPlayerData.timestampStarted <= questPlayerData.timestampCompleted)
        {
            revert QuestNotStarted(msg.sender, quest);
        }

        for (uint i = 0; i < stepIndices.length; i++) 
        {
            _completeStep(
                quest, 
                stepIndices[i], 
                giveInventories[i], 
                takeInventories[i], 
                takeTokenIds[i]);
        }
    }


    /// @dev Complete step `index` of quest `quest`  and claim reward `rewardIndex` to `inventory`
    /// @param quest Quest to which the step belongs
    /// @param stepIndex Step index to complete
    /// @param giveInventories Inventory to which a quest item is given
    /// @param takeInventories Inventory from which a quest item is taken
    /// @param takeTokenIds Non-fungible token id to take
    /// @param rewardIndex Reward index to claim
    /// @param rewardInventory Inventory to which the reward is assigned
    function completeStepAndClaimReward(
        bytes32 quest, 
        uint8 stepIndex, 
        Inventory[] memory giveInventories, 
        Inventory[] memory takeInventories, 
        uint[] memory takeTokenIds, 
        uint8 rewardIndex, 
        Inventory rewardInventory) 
        public 
    {
        // Check quest started
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][quest];
        if (questPlayerData.timestampStarted <= questPlayerData.timestampCompleted)
        {
            revert QuestNotStarted(msg.sender, quest);
        }

        _completeStep(
            quest, 
            stepIndex, 
            giveInventories, 
            takeInventories, 
            takeTokenIds); 

        // Check quest completed
        if (questPlayerData.stepsCompletedCount != quests[quest].steps.length) 
        {
            revert QuestNotCompleted(msg.sender, quest);
        }

        _claimReward(
            quest, rewardIndex, rewardInventory);
    }


    /// @dev Complete multiple steps `indices` of quest `quest` and claim reward `rewardIndex` to `inventory`
    /// @param quest Quest id to which the steps belong
    /// @param stepIndices Step indices to complete
    /// @param giveInventories Inventory to which a quest item is given
    /// @param takeInventories Inventory from which a quest item is taken
    /// @param takeTokenIds Non-fungible token id to take
    /// @param rewardIndex Reward index to claim
    /// @param rewardInventory Inventory to which the reward is assigned
    function completeStepsAndClaimReward(
        bytes32 quest, 
        uint8[] memory stepIndices, 
        Inventory[][] memory giveInventories, 
        Inventory[][] memory takeInventories, 
        uint[][] memory takeTokenIds, 
        uint8 rewardIndex, 
        Inventory rewardInventory) 
        public 
    {
        // Check quest started
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][quest];
        if (questPlayerData.timestampStarted <= questPlayerData.timestampCompleted)
        {
            revert QuestNotStarted(msg.sender, quest);
        }

        for (uint i = 0; i < stepIndices.length; i++) 
        {
            _completeStep(
                quest, 
                stepIndices[i], 
                giveInventories[i], 
                takeInventories[i], 
                takeTokenIds[i]);
        }

        // Check quest completed
        if (questPlayerData.stepsCompletedCount != quests[quest].steps.length) 
        {
            revert QuestNotCompleted(msg.sender, quest);
        }

        _claimReward(
            quest, rewardIndex, rewardInventory);
    }


    /// @dev Claim reward `rewardIndex` of quest `quest` to `inventory`
    /// @param quest Quest id to which the reward belongs
    /// @param rewardIndex Reward index to claim
    /// @param inventory Inventory to which the reward is assigned
    function claimReward(bytes32 quest, uint8 rewardIndex, Inventory inventory) 
        public 
    {
        // Check quest started
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][quest];
        if (questPlayerData.timestampStarted <= questPlayerData.timestampCompleted)
        {
            revert QuestNotStarted(msg.sender, quest);
        }

        // Check quest completed
        if (questPlayerData.stepsCompletedCount < quests[quest].steps.length)
        {
            revert QuestNotCompleted(msg.sender, quest);
        }

        // Check reward not claimed
        if (questPlayerData.timestampClaimed >= questPlayerData.timestampCompleted)
        {
            revert QuestRewardAlreadyClaimed(msg.sender, quest);
        }

        // Claim reward
        _claimReward(quest, rewardIndex, inventory); 
    }


    /// @dev Start quest with `quest`, directly complete all steps and claim `rewardIndex` 
    /// @param quest Quest id to start
    /// @param giveInventories Inventory to which a quest item is given
    /// @param takeInventories Inventory from which a quest item is taken
    /// @param takeTokenIds Non-fungible token id to take
    /// @param rewardIndex Reward to claim in the same transaction
    /// @param rewardInventory Inventory to which the reward is assigned
    function completeQuest(
        bytes32 quest, 
        Inventory[][] memory giveInventories, 
        Inventory[][] memory takeInventories, 
        uint[][] memory takeTokenIds, 
        uint8 rewardIndex, 
        Inventory rewardInventory)
        public 
    {
        _startQuest(quest);

        // Complete steps 
        for (uint8 i = 0; i < quests[quest].steps.length; i++) 
        {
            _completeStep(
                quest, i, 
                giveInventories[i], 
                takeInventories[i], 
                takeTokenIds[i]);
        }

        _claimReward(
            quest, rewardIndex, rewardInventory);
    }

    
    /**
     * Internal functions
     */
    function _questExists(bytes32 quest) 
        internal view 
        returns (bool) 
    {
        return questsIndex.length > 0 && questsIndex[quests[quest].index] == quest;
    }


    /// @dev Add quest
    /// @param quest Quest to add
    function _setQuest(Quest memory quest) 
        internal
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

        QuestData storage data = quests[quest.name];
        if (!_questExists(quest.name)) 
        {
            // Add quest
            quests[quest.name].index = questsIndex.length;
            questsIndex.push(quest.name);
        }
        else 
        {
            // Update quest
            delete data.steps;
            delete data.rewards;
        }

        // Set quest data
        data.hasLevelConstraint = quest.hasLevelConstraint;
        data.level = quest.level;
        data.hasFactionConstraint = quest.hasFactionConstraint;
        data.faction = quest.faction;
        data.hasSubFactionConstraint = quest.hasSubFactionConstraint;
        data.subFaction = quest.subFaction;
        data.hasCompletionConstraint = quest.hasCompletionConstraint;
        data.maxCompletions = quest.maxCompletions;
        data.hasCooldownConstraint = quest.hasCooldownConstraint;
        data.cooldown = quest.cooldown;
        data.hasTimeConstraint = quest.hasTimeConstraint;
        data.maxDuration = quest.maxDuration;

        // Set steps
        for (uint i = 0; i < quest.steps.length; i++) 
        {
            data.steps.push();
            data.steps[i].name = quest.steps[i].name;
            data.steps[i].hasTileConstraint = quest.steps[i].hasTileConstraint;
            data.steps[i].tile = quest.steps[i].tile;
        
            // Take fungible 
            for (uint j = 0; j < quest.steps[i].takeFungible.length; j++) 
            {
                data.steps[i].takeFungible.push();
                data.steps[i].takeFungible[j].asset = quest.steps[i].takeFungible[j].asset;
                data.steps[i].takeFungible[j].amount = quest.steps[i].takeFungible[j].amount;
                data.steps[i].takeFungible[j].allowWallet = quest.steps[i].takeFungible[j].allowWallet;
            }

            // Take non-fungible
            for (uint j = 0; j < quest.steps[i].takeNonFungible.length; j++) 
            {
                data.steps[i].takeNonFungible.push();
                data.steps[i].takeNonFungible[j].asset = quest.steps[i].takeNonFungible[j].asset;
                data.steps[i].takeNonFungible[j].item = quest.steps[i].takeNonFungible[j].item;
                data.steps[i].takeNonFungible[j].allowWallet = quest.steps[i].takeNonFungible[j].allowWallet;
            }

            // Give fungible
            for (uint j = 0; j < quest.steps[i].giveFungible.length; j++) 
            {
                data.steps[i].giveFungible.push();
                data.steps[i].giveFungible[j].asset = quest.steps[i].giveFungible[j].asset;
                data.steps[i].giveFungible[j].amount = quest.steps[i].giveFungible[j].amount;
                data.steps[i].giveFungible[j].allowWallet = quest.steps[i].giveFungible[j].allowWallet;
            }

            // Give non-fungible
            for (uint j = 0; j < quest.steps[i].giveNonFungible.length; j++) 
            {
                data.steps[i].giveNonFungible.push();
                data.steps[i].giveNonFungible[j].asset = quest.steps[i].giveNonFungible[j].asset;
                data.steps[i].giveNonFungible[j].item = quest.steps[i].giveNonFungible[j].item;
                data.steps[i].giveNonFungible[j].allowWallet = quest.steps[i].giveNonFungible[j].allowWallet;
            }
        }

        // Set rewards
        for (uint i = 0; i < quest.rewards.length; i++) 
        {
            data.rewards.push();
            data.rewards[i].name = quest.rewards[i].name;
            data.rewards[i].karma = quest.rewards[i].karma;
            data.rewards[i].xp = quest.rewards[i].xp;

            // Fungible 
            for (uint j = 0; j < quest.rewards[i].fungible.length; j++) 
            {
                data.rewards[i].fungible.push();
                data.rewards[i].fungible[j].asset = quest.rewards[i].fungible[j].asset;
                data.rewards[i].fungible[j].amount = quest.rewards[i].fungible[j].amount;
                data.rewards[i].fungible[j].allowWallet = quest.rewards[i].fungible[j].allowWallet;
            }

            // Non-fungible
            for (uint j = 0; j < quest.rewards[i].nonFungible.length; j++) 
            {
                data.rewards[i].nonFungible.push();
                data.rewards[i].nonFungible[j].asset = quest.rewards[i].nonFungible[j].asset;
                data.rewards[i].nonFungible[j].item = quest.rewards[i].nonFungible[j].item;
                data.rewards[i].nonFungible[j].allowWallet = quest.rewards[i].nonFungible[j].allowWallet;
            }
        }
    }


    /// @dev Get quest by name
    /// @param name Quest name
    /// @return quest The quest data
    function _getQuest(bytes32 name) 
        internal view 
        returns (Quest memory quest) 
    {
        QuestData storage data = quests[name];
        quest = Quest({
            name: name,
            hasLevelConstraint: data.hasLevelConstraint,
            level: data.level,
            hasFactionConstraint: data.hasFactionConstraint,
            faction: data.faction,
            hasSubFactionConstraint: data.hasSubFactionConstraint,
            subFaction: data.subFaction,
            hasCompletionConstraint: data.hasCompletionConstraint,
            maxCompletions: data.maxCompletions,
            hasCooldownConstraint: data.hasCooldownConstraint,
            cooldown: data.cooldown,
            hasTimeConstraint: data.hasTimeConstraint,
            maxDuration: data.maxDuration,
            steps: data.steps,
            rewards: data.rewards
        });
    }

    
    /// @dev Start quest with `quest` and directly complete `stepIndices` if any
    /// @param name Quest id to start
    function _startQuest(bytes32 name)
        internal 
    {
         // Get quest data  
        QuestData storage quest = quests[name]; 
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][name];

        // Get player data
        PlayerData memory playerData = IPlayerRegister(playerRegisterContract)
            .getPlayerData(msg.sender);

        // Check player is registred
        if (playerData.level == 0) 
        {
            revert PlayerNotRegistered(msg.sender);
        }

        // Check quest already started
        if (questPlayerData.timestampStarted > questPlayerData.timestampCompleted)
        {
            revert QuestAlreadyStarted(msg.sender, name);
        }

        // Check quest completion
        if (questPlayerData.stepsCompletedCount > 0)
        {
            // Quest in progress
            if (questPlayerData.stepsCompletedCount < quest.steps.length)
            {
                revert QuestAlreadyStarted(msg.sender, name);
            }

            // Quest completed
            else if (quest.hasCompletionConstraint)
            {
                // Max completions reached
                if (questPlayerData.completedCount >= quest.maxCompletions)
                {
                    revert QuestCompletionExceeded(msg.sender, name, quest.maxCompletions);
                }

                // Reset quest
                else 
                {
                    questPlayerData.stepsCompletedCount = 0;
                    questPlayerData.stepsCompleted = bytes8(0);
                }
            }
        }

        // Check level constraint
        if (quest.hasLevelConstraint) 
        {
            // Check level
            if (playerData.level < quest.level) 
            {
                revert PlayerLevelInsufficient(msg.sender, quest.level, playerData.level);
            }
        }

        // Check faction constraint
        if (quest.hasFactionConstraint) 
        {
            // Check faction
            if (playerData.faction != quest.faction) 
            {
                revert UnexpectedFaction(quest.faction, playerData.faction);
            }
        }

        // Check sub faction constraint
        if (quest.hasSubFactionConstraint) 
        {
            // Check sub faction
            if (playerData.subFaction != quest.subFaction) 
            {
                revert UnexpectedSubFaction(quest.subFaction, playerData.subFaction);
            }
        }

        // Check cooldown constraint
        if (quest.hasCooldownConstraint) 
        {
            // Check cooldown
            if (questPlayerData.timestampCompleted + quest.cooldown > block.timestamp) 
            {
                revert QuestCooldownNotExpired(msg.sender, name, quest.cooldown);
            }
        }


        // Start quest
        questPlayerData.stepsCompletedCount = 0;
        questPlayerData.stepsCompleted = bytes8(0);
        questPlayerData.timestampStarted = uint64(block.timestamp);

        // Emit event
        emit QuestStart(msg.sender, name);
    }


    /// @dev Complete step `index` of quest 
    /// @param questName Quest to which the step belongs
    /// @param stepIndex Step index to complete
    /// @param giveInventories Inventory to which a quest item is given
    /// @param takeInventories Inventory from which a quest item is taken
    /// @param takeTokenIds Non-fungible token ids to take
    function _completeStep(
        bytes32 questName, 
        uint8 stepIndex, 
        Inventory[] memory giveInventories, 
        Inventory[] memory takeInventories, 
        uint[] memory takeTokenIds) 
        internal 
    {
        // Get quest 
        QuestData storage quest = quests[questName];
        QuestStep storage questStep = quest.steps[stepIndex];
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][questName];

        // Check step index
        if (stepIndex >= quest.steps.length) 
        {
            revert QuestStepNotFound(questName, stepIndex);
        }

        // Check step not already completed
        if (questPlayerData.stepsCompleted & bytes8(uint64(1) << stepIndex) != 0) 
        {
            revert QuestStepAlreadyCompleted(msg.sender, questName, stepIndex);
        }

        // Check time constraint
        if (quest.hasTimeConstraint) 
        {
            // Check time
            if (questPlayerData.timestampStarted + quest.maxDuration < block.timestamp) 
            {
                revert QuestTimeExceeded(msg.sender, questName, quest.maxDuration); // TODO: Allow to cancel quest
            }
        }

        // Get Player location data
        (
            uint16 playerTile, 
            bool playerCanInteract
        ) = IMaps(mapsContract).getPlayerLocationData(msg.sender);

        // Check location constraint
        if (questStep.hasTileConstraint) 
        {
            if (questStep.tile != playerTile)
            {
                revert UnexpectedTile(questStep.tile, playerTile);
            }
        }
 
        // Check if player can interact
        if (!playerCanInteract) 
        {
            revert PlayerCannotInteract(msg.sender);
        }


        // Record progress
        questPlayerData.stepsCompletedCount++;
        questPlayerData.stepsCompleted |= bytes8(uint64(1) << stepIndex);


        // Give fungible quest items
        for (uint i = 0; i < questStep.giveFungible.length; i++) 
        {   
            FungibleTransactionData memory questItem = questStep.giveFungible[i];
            if (giveInventories[i] == Inventory.Wallet && !questItem.allowWallet)
            {
                revert ArgumentInvalid();
            }

            // Mint quest item
            IFungibleQuestItem(questItem.asset)
                .__mintQuestItem(questItem.amount, msg.sender, giveInventories[i]);
        }

        // Give non-fungible quest items
        if (questStep.giveNonFungible.length > 0)
        { 
            for (uint i = 0; i < questStep.giveNonFungible.length; i++) 
            {   
                NonFungibleTransactionData memory questItem = questStep.giveNonFungible[i];
                if (giveInventories[i] == Inventory.Wallet && !questItem.allowWallet)
                {
                    revert ArgumentInvalid();
                }

                // Mint quest item
                INonFungibleQuestItem(questItem.asset)
                    .__mintQuestItem(questItem.item, msg.sender, giveInventories[i]);
            }
        }
        

        // Take quest items
        for (uint i = 0; i < questStep.takeFungible.length; i++) 
        {   
            FungibleTransactionData memory questItem = questStep.takeFungible[i];
            if (takeInventories[i] == Inventory.Wallet && !questItem.allowWallet)
            {
                revert ArgumentInvalid();
            }

            // Burn quest item
            IFungibleQuestItem(questItem.asset)
                .__burnQuestItem(questItem.amount, msg.sender, takeInventories[i]);
        }

        // Take non-fungible quest items
        for (uint i = 0; i < questStep.takeNonFungible.length; i++) 
        {   
            NonFungibleTransactionData memory questItem = questStep.takeNonFungible[i];
            if (takeInventories[i] == Inventory.Wallet && !questItem.allowWallet)
            {
                revert ArgumentInvalid();
            }

            // Burn quest item
            INonFungibleQuestItem(questItem.asset)
                .__burnQuestItem(questItem.item, takeTokenIds[i], msg.sender, takeInventories[i]); 
        }

        // Emit event
        emit QuestStepComplete(msg.sender, questName, stepIndex);


        // Check if quest completed
        if (questPlayerData.stepsCompletedCount == quest.steps.length) 
        {
            // Complete quest
            questPlayerData.timestampCompleted = uint64(block.timestamp);
            questPlayerData.completedCount++;

            // Emit event
            emit QuestComplete(msg.sender, questName);
        }
    }


    /// @dev Claim reward `rewardIndex` of quest to `inventory`
    /// @param questName Quest to which the reward belongs
    /// @param rewardIndex Reward index to claim
    /// @param inventory Inventory to which the reward is assigned
    function _claimReward(bytes32 questName, uint8 rewardIndex, Inventory inventory) 
        internal 
    {
        // Get quest
        QuestData storage quest = quests[questName];
        QuestPlayerData storage questPlayerData = playerQuestData[msg.sender][questName];

        // Check reward index
        if (rewardIndex >= quest.rewards.length) 
        {
            revert QuestRewardNotFound(questName, rewardIndex); 
        }

        // Mark reward claimed
        questPlayerData.timestampClaimed = uint64(block.timestamp);

        // Fungible rewards
        for (uint i = 0; i < quest.rewards[rewardIndex].fungible.length; i++) 
        {   
            FungibleTransactionData memory reward = quest.rewards[rewardIndex].fungible[i];
            if (inventory == Inventory.Wallet && !reward.allowWallet)
            {
                revert ArgumentInvalid();
            }

            // Reward player
            IFungibleQuestReward(reward.asset)
                .__mintQuestReward(msg.sender, inventory, reward.amount); 

            // Emit event
            emit QuestRewardClaim(msg.sender, questName, rewardIndex, reward.asset, reward.amount, 0);
        }

        // Non-fungible rewards
        for (uint i = 0; i < quest.rewards[rewardIndex].nonFungible.length; i++) 
        {   
            NonFungibleTransactionData memory reward = quest.rewards[rewardIndex].nonFungible[i];
            if (inventory == Inventory.Wallet && !reward.allowWallet)
            {
                revert ArgumentInvalid();
            }

            // Reward player
            uint tokenId = INonFungibleQuestReward(reward.asset)
                .__mintQuestReward(msg.sender, inventory, reward.item);

            // Emit event
            emit QuestRewardClaim(msg.sender, questName, rewardIndex, reward.asset, 1, tokenId); 
        }

        // Award xp and karma
        IPlayerRegister(playerRegisterContract)
            .__award(msg.sender, 
                quest.rewards[rewardIndex].xp, 
                quest.rewards[rewardIndex].karma);
    }
}