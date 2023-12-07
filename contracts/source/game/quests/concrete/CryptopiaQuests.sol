// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

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

/// @title Quests 
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaQuests is Initializable, AccessControlUpgradeable, IQuests
{
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
    mapping (bytes32 => Quest) private quests;
    bytes32[] private questsIndex;

    /// @dev Player quest data
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

    /// @dev Emitted when `player` tries to start a quest more than `maxRecurrences` times
    /// @param player The player that exceeded the max recurrences
    /// @param quest The quest that was exceeded
    /// @param maxRecurrences The max recurrences that was exceeded
    error QuestRecurrenceExceeded(address player, bytes32 quest, uint maxRecurrences);

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
    /// @dev Set quest
    /// @param quest Quest to add
    function setQuest(Quest calldata quest) 
        public
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setQuest(quest);
    }


    /// @dev Set multiple quests
    /// @param quests_ Quests to add
    function setQuests(Quest[] calldata quests_) 
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
        quest = quests[questsIndex[index]];
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
            quests_[i] = quests[questsIndex[skip + i]];
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
    /// @dev Add quest
    /// @param quest Quest to add
    function _setQuest(Quest calldata quest) 
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

        quests[quest.name] = quest;
        questsIndex.push(quest.name);
    }

    
    /// @dev Start quest with `quest` and directly complete `stepIndices` if any
    /// @param name Quest id to start
    function _startQuest(bytes32 name)
        internal 
    {
         // Get quest data  
        Quest storage quest = quests[name];
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

        // Check quest recurrence
        if (questPlayerData.stepsCompletedCount > 0)
        {
            // Quest in progress
            if (questPlayerData.stepsCompletedCount < quest.steps.length)
            {
                revert QuestAlreadyStarted(msg.sender, name);
            }

            // Quest completed
            else if (quest.hasRecurrenceConstraint)
            {
                // Max recurrences reached
                if (questPlayerData.completedCount >= quest.maxRecurrences)
                {
                    revert QuestRecurrenceExceeded(msg.sender, name, quest.maxRecurrences);
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
        Quest storage quest = quests[questName];
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
        Quest storage quest = quests[questName]; 
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
                .__mintQuestReward(reward.amount, msg.sender, inventory); 

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
                .__mintQuestReward(reward.item, msg.sender, inventory);

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