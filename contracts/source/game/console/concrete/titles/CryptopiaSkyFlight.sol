// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../types/FactionEnums.sol";
import "../../../players/IPlayerRegister.sol";
import "../../types/GameConsoleDataTypes.sol";
import "../../IGameConsoleTitle.sol";

/// @title Console game logic interface
/// @dev Contains the logic to interact with console games
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaSkyFlight is Initializable, AccessControlUpgradeable, IGameConsoleTitle {

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
    /// @dev Faction => index => reward
    mapping (Faction => mapping (uint => GameConsoleReward)) public rewards;

    /// @dev Refs
    address public playerRegisterContract;


    /**
     * Events
     */
    /// @dev Emitted when the rewards are updated
    event GameConsoleRewardsUpdate();


    /// @dev Initialize
    /// @param _playerRegisterContract The address of the player register contract
    function initialize(
        address _playerRegisterContract)
        public initializer 
    {
        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Set refs
        playerRegisterContract = _playerRegisterContract;
    }


    /**
     * Admin functions
     */
    /// @dev Set the rewards (expecting REWARD_COUNT rewards)
    /// @param _rewards The rewards to set
    function setRewards(GameConsoleReward[][] memory _rewards) 
        public 
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _setRewards(_rewards);

        // Emit event
        emit GameConsoleRewardsUpdate();
    }


    /**
     * Public functions
     */
    /// @dev Get the name of the game
    /// @return name The name of the game
    function getName() 
        public override pure 
        returns (bytes32 name)
    {
        return "Sky Flight";
    }

    
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

        // Global highscore reward
        if (isGlobalHighscore) 
        {
            Faction faction = IPlayerRegister(playerRegisterContract)
                .getFaction(session.player);
            reward = rewards[faction][REWARD_GLOBAL_HIGHSCORE];
        }

        // First run reward
        else if (sessionCount == 1) 
        {
            Faction faction = IPlayerRegister(playerRegisterContract)
                .getFaction(session.player);
            reward = rewards[faction][REWARD_FIRST_RUN];
        }

        // Personal highscore reward
        else if (isPersonalHighscore) 
        {
            Faction faction = IPlayerRegister(playerRegisterContract)
                .getFaction(session.player);
            reward = rewards[faction][REWARD_PERSONAL_HIGHSCORE];
        }

        // Base xp 
        reward.xp += uint24(session.score / SCORE_PER_XP / sessionCount);
    }


    /**
     * Internal functions
     */
    /// @dev Set the rewards (expecting rewards for each faction)
    /// @param _rewards The rewards to set
    function _setRewards(GameConsoleReward[][] memory _rewards)
        internal 
    {
        assert(_rewards.length == uint(Faction.Count)); // Faction count
        
        // Copy rewards
        for (uint i = 0; i < _rewards.length; i++) 
        {
            _setFactionRewards(Faction(i), _rewards[i]);
        }
    }

    /// @dev Set the rewards for a specific faction
    /// @param faction The faction to set the rewards for
    /// @param _rewards The rewards to set (expecting REWARD_COUNT rewards)
    function _setFactionRewards(Faction faction, GameConsoleReward[] memory _rewards)
        internal 
    {
        assert(_rewards.length == REWARD_COUNT);
        
        // Copy rewards
        for (uint i = 0; i < _rewards.length; i++) 
        {
            rewards[faction][i].xp = _rewards[i].xp;

            delete rewards[faction][i].fungible;
            for (uint j = 0; j < _rewards[i].fungible.length; j++) 
            {
                rewards[faction][i].fungible.push(
                    _rewards[i].fungible[j]);
            }

            delete rewards[faction][i].nonFungible;
            for (uint j = 0; j < _rewards[i].nonFungible.length; j++) 
            {
                rewards[faction][i].nonFungible.push(
                    _rewards[i].nonFungible[j]);
            }
        }
    }
}