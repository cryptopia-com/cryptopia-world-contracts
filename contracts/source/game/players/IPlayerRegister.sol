// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../types/boxes/uint24/Uint24Box2.sol";
import "../../tokens/ERC721/types/ERC721DataTypes.sol";
import "../../accounts/types/AccountEnums.sol";
import "../types/boxes/faction/FactionBox2.sol";
import "../types/boxes/subfaction/SubFactionBox2.sol";
import "../types/FactionEnums.sol";
import "./types/PlayerDataTypes.sol";
import "./types/PlayerEnums.sol";

/// @title Cryptopia Players Contract
/// @notice This contract is central to managing player profiles within Cryptopia, 
/// encompassing the creation and progression of player accounts. It efficiently handles player data, 
/// including levels, stats, and inventory management. The contract integrates seamlessly with various 
/// game elements, such as ships and crafting, to provide a comprehensive player experience. 
/// It allows players to embark on their journey, level up, and evolve within the game, 
/// aligning with their chosen faction and adapting their characters to suit their play style.
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
    /// @return if account is registered
    function isRegistered(address account)
        external view 
        returns (bool);


    /// @dev Returns player data for `account`
    /// @param account CryptopiaAccount address (registered as a player)
    /// @return data Player data
    function getPlayerData(address account) 
        external view 
        returns (PlayerData memory data);


    /// @dev Returns the stats for `player`
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return stats Player stats
    function getPlayerStats(address player) 
        external view 
        returns (PlayerStats memory);

    
    /// @dev Returns true if `player` is a pirate
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return true if player is a pirate
    function isPirate(address player) 
        external view 
        returns (bool);

    
    /// @dev Returns the player's faction 
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return subFaction The player's faction
    function getFaction(address player) 
        external view 
        returns (Faction);

    
    /// @dev Returns the player's faction
    /// @param player1 CryptopiaAccount address (registered as a player)
    /// @param player2 CryptopiaAccount address (registered as a player)
    function getFactions(address player1, address player2) 
        external view 
        returns (FactionBox2 memory); 

    
    /// @dev Returns the player's sub faction {None, Pirate, BountyHunter}
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return subFaction The player's sub faction
    function getSubFaction(address player) 
        external view 
        returns (SubFaction);

    
    /// @dev Returns the player's sub faction {None, Pirate, BountyHunter}
    /// @param player1 CryptopiaAccount address (registered as a player)
    /// @param player2 CryptopiaAccount address (registered as a player)
    function getSubFactions(address player1, address player2) 
        external view 
        returns (SubFactionBox2 memory);

    
    /// @dev Returns `player` level
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return level Current level (zero signals not initialized)
    function getLevel(address player) 
        external view 
        returns (uint8);


    /// @dev Returns `player` luck
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    function getLuck(address player) 
        external view 
        returns (uint24);


    /// @dev Returns `player1` and `player2` luck
    /// @param player1 CryptopiaAccount address (registered as a player)
    /// @param player2 CryptopiaAccount address (registered as a player)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    function getLuck(address player1, address player2) 
        external view 
        returns (Uint24Box2 memory);


    /// @dev Returns `player` charisma
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    function getCharisma(address player) 
        external view 
        returns (uint24);


    /// @dev Returns the tokenId from the ship that's equipped by `player`
    /// @param player The player to retrieve the ship for
    /// @return uint the tokenId of the equipped ship
    function getEquippedShip(address player) 
        external view 
        returns (uint);

    
    /// @dev Returns the tokenId from the ship that's equipped by `player1` and `player2`
    /// @param player1 The first player to retrieve the ship for
    /// @param player2 The second player to retrieve the ship for
    /// @return TokenPair the tokenId of the equipped ship
    function getEquippedShips(address player1, address player2)
        external view 
        returns (TokenPair memory);


    /// @dev Equipt `ship` to calling sender
    /// @param ship The tokenId of the ship to equipt
    function equipShip(uint ship)
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


    /// @dev Increase `player` stat by `amount`
    /// @param player The player to increase the stat for
    /// @param stat The stat to increase
    /// @param amount The amount to increase the stat by
    /// @param xp The amount of xp that's awarded
    function __increaseStat(address player, PlayerStat stat, uint8 amount, uint24 xp)
        external;
        
    
    /// @dev Award max negative karma to the player and turn pirate instantly
    /// @param player The player to turn pirate
    function __turnPirate(address player)
        external;
}