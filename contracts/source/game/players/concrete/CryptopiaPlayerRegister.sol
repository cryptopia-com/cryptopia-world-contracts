// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../accounts/IAccountRegister.sol";
import "../../../accounts/errors/AccountErrors.sol";
import "../../../tokens/ERC721/ships/IShips.sol";
import "../../../tokens/ERC721/ships/types/ShipDataTypes.sol";
import "../../../tokens/ERC721/ships/errors/ShipErrors.sol";
import "../../inventories/IInventories.sol";
import "../../crafting/ICrafting.sol";
import "../../types/GameEnums.sol";
import "../../errors/FactionErrors.sol";
import "../errors/PlayerErrors.sol";
import "../IPlayerRegister.sol";

/// @title Cryptopia Players
/// @dev Contains player data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaPlayerRegister is Initializable, AccessControlUpgradeable, IPlayerRegister {

    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    uint8 constant private LEVEL_BASE = 1;
    uint8 constant private LEVEL_MAX = 100;

    int8 constant private KARMA_MIN = -100;
    int8 constant private KARMA_MAX = 100;

    uint constant private XP_BASE = 1000;
    uint constant private XP_FACTOR = 5;
    uint constant private XP_EXPONENT = 2;

    uint24 constant private STATS_LUCK_BASE = 1;
    uint24 constant private STATS_CHARISMA_BASE = 1;
    uint24 constant private STATS_INTELLIGENCE_BASE = 1;
    uint24 constant private STATS_STRENGTH_BASE = 1;
    uint24 constant private STATS_SPEED_BASE = 10; // Min movement for slopes and embarking/disembarking

    uint constant private INVENTORY_MAX_WEIGHT_BASE = 8_000_000_000_000_000_000_000; // 8 slots 80kg
    uint constant private INVENTORY_STRENGTH_MULTIPLIER = 200_000_000_000_000_000_000; // 2kg per strength level

    uint constant private CRAFTING_SLOTS_BASE = 2;

    // Refs
    address public accountRegisterContract;
    address public inventoriesContract;
    address public craftingContract;
    address public shipTokenContract;

    // Global stats
    uint public totalPlayerCount;
    uint public totalPlayerProgression;

    // Player => PlayerData
    mapping (address => PlayerData) private playerDatas;


    /**
     * Events
     */
    /// @dev Emitted when an account is registered as a player
    /// @param sender The addres that created the account (tx.origin)
    /// @param account The address of the account (contract)
    /// @param username The player's unique username 
    /// @param faction The player's faction
    /// @param sex {Undefined, Male, Female}
    event RegisterPlayer(address indexed sender, address indexed account, bytes32 indexed username, Faction faction, Sex sex);

    /// @dev Emitted when `player` equips a 'ship'
    /// @param player The address of the account (contract)
    /// @param ship The tokenId of the equipped ship
    event PlayerEquipShip(address indexed player, uint indexed ship);

    /// @dev Emitted when `player` is awarded xp and/or karma
    /// @param player The address of the account (contract)
    /// @param xp The xp that was awarded
    /// @param karma The karma that was awarded
    event PlayerAward(address indexed player, uint24 xp, int16 karma);

    /// @dev Emitted when `player` levels up
    /// @param player The address of the account (contract)
    /// @param level The player's level after leveling up
    /// @param stat The stat that was increased 
    event PlayerLevelUp(address indexed player, uint8 level, PlayerStat stat);

    /// @dev Emitted when 'player' becomes a pirate
    /// @param player The address of the account (contract)
    event PlayerTurnPirate(address indexed player);


    /**
     * Errors
     */
    /// @dev Emitted when `account` is already a player
    /// @param account The account that is already a player
    error PlayerAlreadyRegistered(address account);

    /// @dev Emitted when `stat` is invalid
    /// @param stat The invalid stat
    error PlayerInvalidStat(PlayerStat stat);

    /// @dev Emitted when `player` does not have enough experience points
    /// @param player The player that does not have enough experience points
    /// @param required The amount of experience points required
    /// @param actual The amount of experience points that the player has
    error PlayerInsufficientXp(address player, uint24 required, uint24 actual);

    /// @dev Emitted when `player` has already reached the maximum level
    /// @param player The player that has already reached the maximum level
    /// @param level The maximum level
    error PlayerMaxLevelReached(address player, uint8 level);


    /**
     * Modifiers
     */
    /// @dev Only allow if `account` is registered
    /// @param account The account to check
    modifier onlyRegistered(address account) {
        if(!_isRegistered(account)) 
        {
            revert PlayerNotRegistered(account);
        }
        _;
    }


    /// @param _accountRegisterContract Contract responsible for accounts
    /// @param _inventoriesContract Contract responsible for inventories
    /// @param _craftingContract Contract responsible for crafting
    /// @param _shipTokenContract Contract responsible for ships
    /// @param _systemContracts Contracts that are granted the system role
    function initialize(
        address _accountRegisterContract, 
        address _inventoriesContract,
        address _craftingContract,
        address _shipTokenContract,
        address[] memory _systemContracts) 
        public initializer 
    {
        __AccessControl_init();

        // Assign refs
        accountRegisterContract = _accountRegisterContract;
        inventoriesContract = _inventoriesContract;
        craftingContract = _craftingContract;
        shipTokenContract = _shipTokenContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Grant system roles
        for (uint i = 0; i < _systemContracts.length; i++)
        {
            _grantRole(SYSTEM_ROLE, _systemContracts[i]);
        }
    }


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
        returns (address payable account)
    {
        account = IAccountRegister(accountRegisterContract)
            .create(owners, required, dailyLimit, username, sex);

        // Emits RegisterAccount
        _register(account, username, faction, sex);
    }


    /// @dev Register `account` as a player
    /// @param faction The choosen faction (immutable)
    function register(Faction faction)
        public virtual override 
    {
        // Check if account is registered already as a player
        if (_isRegistered(msg.sender)) 
        {
            revert PlayerAlreadyRegistered(msg.sender);
        }

        // Check if account is registered with account register
        if (!IAccountRegister(accountRegisterContract).isRegistered(msg.sender)) 
        {
            revert AccountNotRegistered(msg.sender);
        }

        // Read account data
        (bytes32 username, Sex sex) = IAccountRegister(accountRegisterContract)
            .getAccountData(msg.sender);

        // Emits RegisterAccount
        _register(msg.sender, username, faction, sex);
    }


    /// @dev Check if an account was created and registered 
    /// @param account Account address
    /// @return true if account is registered
    function isRegistered(address account)
        public virtual override view 
        returns (bool)
    {
        return _isRegistered(account);
    }


    /// @dev Returns player data for `player`
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return username Player username (fetched from account)
    /// @return data Player data
    function getPlayerData(address payable player) 
        public virtual override view 
        returns (
            bytes32 username,
            PlayerData memory data
        )
    {
        (username,) = IAccountRegister(accountRegisterContract)
            .getAccountData(player);
        data = playerDatas[player];
    }


    /// @dev Returns player datas for `players`
    /// @param players CryptopiaAccount addresses (registered as a players)
    /// @return usernames Player usernames (fetched from account)
    /// @return data Player datas
    function getPlayerDatas(address payable[] memory players) 
        public virtual override view 
        returns (
            bytes32[] memory usernames,
            PlayerData[] memory data
        )
    {
        usernames = new bytes32[](players.length);
        data = new PlayerData[](players.length);

        for (uint i = 0; i < players.length; i++)
        {
            (usernames[i], data[i]) = getPlayerData(players[i]);
        }
    }


    /// @dev Returns true if `player` is a pirate
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return true if player is a pirate
    function isPirate(address player) 
        public virtual override view 
        returns (bool)
    {
        return _isPirate(player);
    }


    /// @dev Returns the player's faction 
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return subFaction The player's faction
    function getFaction(address player) 
        external view 
        returns (Faction)
    {
        return playerDatas[player].faction;
    }

    
    /// @dev Returns the player's faction
    /// @param player1 CryptopiaAccount address (registered as a player)
    /// @param player2 CryptopiaAccount address (registered as a player)
    function getFactions(address player1, address player2) 
        external view 
        returns (FactionBox2 memory)
    {
        return FactionBox2(
            playerDatas[player1].faction, 
            playerDatas[player2].faction);
    }


    /// @dev Returns the player's sub faction {None, Pirate, BountyHunter}
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return subFaction The player's sub faction
    function getSubFaction(address player) 
        public virtual override view 
        returns (SubFaction)
    {
        return playerDatas[player].subFaction;
    }

    
    /// @dev Returns the player's sub faction {None, Pirate, BountyHunter}
    /// @param player1 CryptopiaAccount address (registered as a player)
    /// @param player2 CryptopiaAccount address (registered as a player)
    function getSubFactions(address player1, address player2) 
        public virtual override view 
        returns (SubFactionBox2 memory)
    {
        return SubFactionBox2(
            playerDatas[player1].subFaction, 
            playerDatas[player2].subFaction);
    }


    /// @dev Returns `player` level
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return level Current level (zero signals not initialized)
    function getLevel(address player) 
        public virtual override view 
        returns (uint8)
    {
        return playerDatas[player].level;
    }


    /// @dev Returns `player` luck
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    function getLuck(address player) 
        public virtual override view 
        returns (uint24)
    {
        return playerDatas[player].luck;
    } 


    /// @dev Returns `player1` and `player2` luck
    /// @param player1 CryptopiaAccount address (registered as a player)
    /// @param player2 CryptopiaAccount address (registered as a player)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    function getLuck(address player1, address player2) 
        public virtual override view 
        returns (Uint24Box2 memory)
    {
        return Uint24Box2(
            playerDatas[player1].luck, 
            playerDatas[player2].luck);
    }


    /// @dev Returns `player` charisma
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    function getCharisma(address player) 
        public virtual override view 
        returns (uint24)
    {
        return playerDatas[player].charisma;
    }


    /// @dev Returns the tokenId from the ship that's equipped by `player`
    /// @param player The player to retrieve the ship for
    /// @return uint the tokenId of the equipped ship
    function getEquippedShip(address player) 
        public virtual override view 
        returns (uint)
    {
        return playerDatas[player].ship;
    }


    /// @dev Returns the tokenId from the ship that's equipped by `player1` and `player2`
    /// @param player1 The first player to retrieve the ship for
    /// @param player2 The second player to retrieve the ship for
    /// @return TokenPair the tokenId of the equipped ship
    function getEquippedShips(address player1, address player2)
        public virtual override view 
        returns (TokenPair memory)
    {
        return TokenPair({
            tokenId1: playerDatas[player1].ship,
            tokenId2: playerDatas[player2].ship
        });
    }


    /// @dev Equip `ship` to calling sender
    /// @param ship The tokenId of the ship to equip
    function equipShip(uint ship)
        public override 
        onlyRegistered(_msgSender())
    {
        address player = _msgSender();
        ShipEquipData memory shipData = IShips(shipTokenContract)
            .getShipEquipData(ship);

        // Locked?
        if (shipData.locked) 
        {
            revert ShipLocked(ship);
        }

        // Generic? or faction specific?
        if (!shipData.generic && shipData.faction != playerDatas[player].faction)
        {
            revert UnexpectedFaction(shipData.faction, playerDatas[player].faction);
        }

        // Owned?
        if (IERC721(shipTokenContract).ownerOf(ship) != player)
        {
            revert ShipNotOwned(ship, player);
        }

        // Release prev and lock next ship
        IShips(shipTokenContract)
            .__lock(playerDatas[player].ship, ship);

        // Update ship
        playerDatas[player].ship = ship;

        // Update inventory
        IInventories(inventoriesContract)
            .__setPlayerShip(player, ship, shipData.inventory);

        // Pirate?
        if (shipData.subFaction == SubFaction.Pirate && !_isPirate(player))
        {
            // Mark as pirate (for life)
            _turnPirate(player);
        }

        // Emit
        emit PlayerEquipShip(player, ship);
    }


    /// @dev Level up by spending xp 
    /// @param stat The type of stat to increase
    function levelUp(PlayerStat stat)
        public virtual override 
        onlyRegistered(_msgSender())
    {
        address player = _msgSender();
        PlayerData storage playerData = playerDatas[player];
        
        // Require max level not reached
        if (playerData.level >= LEVEL_MAX)
        {
            revert PlayerMaxLevelReached(player, LEVEL_MAX);
        }

        // Require sufficient xp
        uint24 xpToLevelUp = uint24(XP_BASE + (uint(playerData.level - 1) * XP_FACTOR)**XP_EXPONENT);
        if (playerData.xp < xpToLevelUp)
        {
            revert PlayerInsufficientXp(player, playerData.xp, xpToLevelUp);
        }

        // Spend xp to level up
        playerData.xp -= xpToLevelUp;
        playerData.level++;

        // Increase stat
        if (stat == PlayerStat.Luck)
        {
            playerData.luck++;
        }
        else if (stat == PlayerStat.Charisma)
        {
            playerData.charisma++;
        }
        else if (stat == PlayerStat.Intelligence)
        {
            playerData.intelligence++;
        }
        else if (stat == PlayerStat.Strength)
        {
            IInventories(inventoriesContract)
                .__setPlayerInventory(player, INVENTORY_MAX_WEIGHT_BASE + playerData.strength * INVENTORY_STRENGTH_MULTIPLIER);

            playerData.strength++;
        }
        else if (stat == PlayerStat.Speed)
        {
            playerData.speed++;
        }
        else 
        {
            revert PlayerInvalidStat(stat);
        }

        // Add to global stats
        totalPlayerProgression++;

        // Emit
        emit PlayerLevelUp(msg.sender, playerData.level, stat);
    }


    /**
     * System functions
     */
    /// @dev Award xp and/or karma to player 
    /// @param player The player to award
    /// @param xp The amount of xp that's awarded
    /// @param karma The amount of karma
    function __award(address player, uint24 xp, int16 karma)
       public virtual override 
       onlyRole(SYSTEM_ROLE)
       onlyRegistered(player)
    {
        playerDatas[player].xp += xp;
        if (0 != karma)
        {
            if (!_isPirate(player)) // Cannot come back from KARMA_MIN karma (once a pirate, always a pirate)
            {
                if (playerDatas[player].karma + karma > KARMA_MAX)
                {
                    // Reached max positive karma
                    karma = KARMA_MAX - playerDatas[player].karma;
                    playerDatas[player].karma = KARMA_MAX;
                }
                else if (playerDatas[player].karma + karma < KARMA_MIN)
                {
                    // Reached max negative karma
                    karma = KARMA_MIN - playerDatas[player].karma;

                    // Mark as pirate (for life)
                    _turnPirate(player);
                }
                else 
                {
                    // Add karma
                    playerDatas[player].karma = playerDatas[player].karma + karma;
                }
            }
            else 
            {
                karma = 0;
            }
        }

        // Emit
        emit PlayerAward(player, xp, karma);
    }


    /// @dev Award max negative karma to the player and turn pirate instantly
    /// @param player The player to turn pirate
    function __turnPirate(address player)
        public virtual override 
       onlyRole(SYSTEM_ROLE)
    {
        if (!_isPirate(player))
        {
            _turnPirate(player);
        }
    }


    /**
     * Internal functions
     */
    /// @dev Check if `account` is registered
    /// @param account The account to check
    /// @return bool True if  `account` is a registered account
    function _isRegistered(address account) 
        internal view 
        returns (bool)
    {
        return playerDatas[account].level > 0;
    }


    /// @dev Register `account` as a player
    /// @param account The CryptopiaAccount contract address to register as a player
    /// @param username The unique username
    /// @param faction The choosen faction (immutable)
    /// @param sex {Undefined, Male, Female}
    function _register(address account, bytes32 username, Faction faction,  Sex sex)
        internal  
    {
        // Create player
        PlayerData storage playerData = playerDatas[account];
        playerData.faction = faction;
        playerData.level = LEVEL_BASE;
        playerData.luck = STATS_LUCK_BASE;
        playerData.charisma = STATS_CHARISMA_BASE;
        playerData.intelligence = STATS_INTELLIGENCE_BASE;
        playerData.strength = STATS_STRENGTH_BASE;
        playerData.speed = STATS_SPEED_BASE;

        // Create ship
        (uint ship, uint shipInventory) = IShips(shipTokenContract)
            .__mintStarterShip(account, faction, true);

        // Assign ship
        playerData.ship = ship;

        // Create inventory
        IInventories(inventoriesContract)
            .__create(account, playerData.ship, INVENTORY_MAX_WEIGHT_BASE, shipInventory);

        // Setup crafting
        ICrafting(craftingContract)
            .__setCraftingSlots(account, CRAFTING_SLOTS_BASE);

        // Add to global stats
        totalPlayerCount++;

        // Emit
        emit RegisterPlayer(tx.origin, account, username, faction, sex);
        emit PlayerEquipShip(account, playerData.ship);
    }


    /// @dev Returns true if `player` is a pirate
    /// @param player CryptopiaAccount address (registered as a player)
    /// @return true if player is a pirate
    function _isPirate(address player) 
        internal view 
        returns (bool)
    {
        return playerDatas[player].subFaction == SubFaction.Pirate;
    }


    /// @dev Mark `player` as pirate
    /// @param player the account that becomes a pirate
    function _turnPirate(address player)
        internal 
    {
        playerDatas[player].karma = KARMA_MIN;
        playerDatas[player].subFaction = SubFaction.Pirate;

        // Update ship to pirate version
        IShips(shipTokenContract).__turnPirate(
            playerDatas[player].ship);
            
        // Emit 
        emit PlayerTurnPirate(player);
    }
}