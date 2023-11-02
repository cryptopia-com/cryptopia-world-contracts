// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../../accounts/types/AccountEnums.sol";
import "../types/FactionEnums.sol";
import "./types/PlayerEnums.sol";

/// @title Cryptopia Players
/// @dev Contains player data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IPlayerRegister {

    /**
     * Public functions
     */
    /// @dev Creates an account (see CryptopiaAccountRegister.sol) and registers the account as a player
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @param faction The choosen faction (immutable)
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, Sex sex, Faction faction)
        external 
        returns (address payable account);


    /// @dev Register `account` as a player
    /// @param faction The choosen faction (immutable)
    function register(Faction faction)
        external;


    /// @dev Check if an account was created and registered 
    /// @param account Account address
    /// @return true if account is registered
    function isRegistered(address account)
        external view 
        returns (bool);


    /// @dev Returns player data for `player`
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return username Player username (fetched from account)
    /// @return faction Faction to which the player belongs
    /// @return subFaction Sub Faction none/pirate/bounty hunter 
    /// @return level Current level (zero signals not initialized)
    /// @return karma Current karma (-100 signals piracy)
    /// @return xp Experience points towards next level; XP_BASE * ((100 + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return intelligence STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return strength STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return speed STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return ship The equipted ship (token ID)
    function getPlayerData(address payable player) 
        external view 
        returns (
            bytes32 username,
            Faction faction,
            SubFaction subFaction, 
            uint8 level,
            int16 karma,
            uint24 xp,
            uint24 luck,
            uint24 charisma,
            uint24 intelligence,
            uint24 strength,
            uint24 speed,
            uint ship
        );


    /// @dev Returns player datas for `players`
    /// @param players CryptopiaAccount addresses (registered as a players)
    /// @return username Player usernames (fetched from account)
    /// @return faction Faction to which the player belongs
    /// @return subFaction Sub Faction none/pirate/bounty hunter 
    /// @return level Current level (zero signals not initialized)
    /// @return karma Current karma (zero signals piracy)
    /// @return xp experience points towards next level; XP_BASE * ((100 + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)  
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return intelligence STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return strength STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return speed STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return ship The equipted ship
    function getPlayerDatas(address payable[] memory players) 
        external view 
        returns (
            bytes32[] memory username,
            Faction[] memory faction,
            SubFaction[] memory subFaction,
            uint8[] memory level,
            int16[] memory karma,
            uint24[] memory xp,
            uint24[] memory luck,
            uint24[] memory charisma,
            uint24[] memory intelligence,
            uint24[] memory strength,
            uint24[] memory speed,
            uint[] memory ship
        );

    
    /// @dev Returns `player` level
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return level Current level (zero signals not initialized)
    function getLevel(address player) 
        external view 
        returns (uint8);


    /// @dev Returns the tokenId from the ship that's equipted by `player`
    /// @param player The player to retrieve the ship for
    /// @return uint the tokenId of the equipted ship
    function getEquiptedShip(address player) 
        external view 
        returns (uint);


    /// @dev Equipt `ship` to calling sender
    /// @param ship The tokenId of the ship to equipt
    function equiptShip(uint ship)
        external;


    /// @dev Level up by spending xp 
    /// @param stat The type of stat to increase
    function levelUp(PlayerStat stat)
        external;


    /**
     * System functions
     */
    /// @dev Award xp/ karma to the player
    /// @param player The player to award
    /// @param xp The amount of xp that's awarded
    /// @param karma The amount of karma
    function __award(address player, uint24 xp, int16 karma)
        external;
}