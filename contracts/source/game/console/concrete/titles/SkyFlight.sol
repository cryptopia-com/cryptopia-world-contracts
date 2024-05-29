// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../IGameConsoleTitle.sol";
import "../../types/GameConsoleDataTypes.sol";

/// @title Console game logic interface
/// @dev Contains the logic to interact with console games
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract SkyFlight is Initializable, AccessControlUpgradeable, IGameConsoleTitle {

    /**
     * Storage
     */
    uint32 constant private MIN_SCORE = 10_000;
    uint32 constant private MAX_SCORE = 1_000_000;
    uint32 constant private SCORE_PER_XP = 1_000;

    uint8 constant private REWARD_FIRST_RUN = 0;
    uint8 constant private REWARD_PERSONAL_HIGHSCORE = 1;
    uint8 constant private REWARD_GLOBAL_HIGHSCORE = 2;
    uint8 constant private REWARD_COUNT = 3;


    /**
     * Rewards
     * 
     * 0) First run
     * 1) Personal highscore
     * 2) Global highscore
     */
    GameConsoleReward[] public rewards;


    /**
     * Events
     */
    /// @dev Emitted when the rewards are updated
    event GameConsoleRewardsUpdate();


    /// @dev Initialize
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
    /// @dev Set the rewards (expecting REWARD_COUNT rewards)
    /// @param _rewards The rewards to set
    function setRewards(GameConsoleReward[] memory _rewards) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        assert(_rewards.length == REWARD_COUNT);
        
        // Copy rewards
        for (uint i = 0; i < _rewards.length; i++) 
        {
            rewards[i].xp = _rewards[i].xp;

            delete rewards[i].fungible;
            for (uint j = 0; j < _rewards[i].fungible.length; j++) 
            {
                rewards[i].fungible.push(_rewards[i].fungible[j]);
            }

            delete rewards[i].nonFungible;
            for (uint j = 0; j < _rewards[i].nonFungible.length; j++) 
            {
                rewards[i].nonFungible.push(_rewards[i].nonFungible[j]);
            }
        }

        // Emit event
        emit GameConsoleRewardsUpdate();
    }


    /**
     * Public functions
     */
    /// @dev Determine if the session is valid and calculate the reward
    /// @param session The session
    /// @param sessionData Additional data used to verify the session
    /// @param sessionCount The number of times the game has been run by the player
    /// @param isPersonalHighscore True if the session is the personal highscore
    /// @param isGlobalHighscore True if the session is the global highscore
    /// @return isValid True if the score is valid
    /// @return reward The reward for the session
    function run(GameConsoleSession memory session, bytes32 sessionData, uint sessionCount, bool isPersonalHighscore, bool isGlobalHighscore) 
        public override view
        returns (bool isValid, GameConsoleReward memory reward)
    {
        isValid = session.score >= MIN_SCORE 
            && session.score <= MAX_SCORE 
            && sessionData == bytes32(0);

        if (!isValid) 
        {
            return (false, reward);
        }

        // Base xp 
        reward.xp = uint24(session.score / SCORE_PER_XP / sessionCount);

        // Global highscore reward
        if (isGlobalHighscore) 
        {
            reward.xp += rewards[REWARD_GLOBAL_HIGHSCORE].xp;
            reward.fungible = rewards[REWARD_GLOBAL_HIGHSCORE].fungible;
            reward.nonFungible = rewards[REWARD_GLOBAL_HIGHSCORE].nonFungible;
        }

        // First run reward
        else if (sessionCount == 1) 
        {
            reward.xp += rewards[REWARD_FIRST_RUN].xp;
            reward.fungible = rewards[REWARD_FIRST_RUN].fungible;
            reward.nonFungible = rewards[REWARD_FIRST_RUN].nonFungible;
        }

        // Personal highscore reward
        else if (isPersonalHighscore) 
        {
            reward.xp += rewards[REWARD_PERSONAL_HIGHSCORE].xp;
            reward.fungible = rewards[REWARD_PERSONAL_HIGHSCORE].fungible;
            reward.nonFungible = rewards[REWARD_PERSONAL_HIGHSCORE].nonFungible;
        }
    }
}