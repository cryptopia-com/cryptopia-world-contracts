// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../../../accounts/AccountEnums.sol";
import "../../../accounts/IAccountRegister.sol";
import "../../../tokens/ERC721/CryptopiaShipToken/ICryptopiaShipToken.sol";
import "../../inventories/CryptopiaInventories/ICryptopiaInventories.sol";
import "../../crafting/ICrafting.sol";
import "../../GameEnums.sol";
import "./ICryptopiaPlayerRegister.sol";

/// @title Cryptopia Players
/// @dev Contains player data
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaPlayerRegister is ICryptopiaPlayerRegister, Initializable, AccessControlUpgradeable {

    struct PlayerData
    {
        GameEnums.Faction faction; // Faction to which the player belongs
        GameEnums.SubFaction subFaction; // Sub Faction none/pirate/bounty hunter 
        uint8 level; // Current level (zero signals not initialized)
        int16 karma; // Current karma (KARMA_MIN signals piracy)
        uint24 xp; // Experience points towards next level; XP_BASE + (uint(level - 1) * XP_FACTOR)**XP_EXPONENT
        uint24 luck; // STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
        uint24 charisma; // STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
        uint24 intelligence;  // STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
        uint24 strength; // STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
        uint24 speed; // STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
        uint ship; // Equipted ship
    }


    /**
     * Roles
     */
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    uint8 public constant LEVEL_BASE = 1;
    uint8 public constant LEVEL_MAX = 100;

    int8 public constant KARMA_MIN = -100;
    int8 public constant KARMA_MAX = 100;

    uint public constant XP_BASE = 1000;
    uint public constant XP_FACTOR = 5;
    uint public constant XP_EXPONENT = 2;

    uint24 public constant STATS_LUCK_BASE = 1;
    uint24 public constant STATS_CHARISMA_BASE = 1;
    uint24 public constant STATS_INTELLIGENCE_BASE = 1;
    uint24 public constant STATS_STRENGTH_BASE = 1;
    uint24 public constant STATS_SPEED_BASE = 10; // Min movement for slopes and embarking/disembarking

    uint public constant INVENTORY_MAX_WEIGHT_BASE = 8_000_000_000_000_000_000_000; // 8 slots 80kg
    uint public constant INVENTORY_STRENGTH_MULTIPLIER = 200_000_000_000_000_000_000; // 2kg per strength level

    uint public constant CRAFTING_SLOTS_BASE = 2;

    // Refs
    address public accountRegisterContract;
    address public inventoriesContract;
    address public craftingContract;
    address public shipTokenContract;

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
    event RegisterPlayer(address indexed sender, address indexed account, bytes32 indexed username, GameEnums.Faction faction, AccountEnums.Sex sex);

    /// @dev Emitted when `player` equipts a 'ship'
    /// @param player The address of the account (contract)
    /// @param ship The tokenId of the equipted ship
    event PlayerEquiptShip(address indexed player, uint indexed ship);

    /// @dev Emitted when `player` is awarded xp and/or karma
    /// @param player The address of the account (contract)
    /// @param xp The xp that was awarded
    /// @param karma The karma that was awarded
    event PlayerAward(address indexed player, uint24 xp, int16 karma);

    /// @dev Emitted when `player` levels up
    /// @param player The address of the account (contract)
    /// @param level The player's level after leveling up
    /// @param stat The stat that was increased 
    event PlayerLevelUp(address indexed player, uint8 level, PlayerEnums.Stats stat);

    /// @dev Emitted when 'player' becomes a pirate
    /// @param player The address of the account (contract)
    event PlayerTurnPirate(address indexed player);


    /**
     * Modifiers
     */
    /// @dev Only allow if `account` is registered
    /// @param account The account to check
    modifier onlyRegistered(address account) {
        if(!_isRegistered(account)) 
        {
            revert (
                string(
                    abi.encodePacked(
                        "CryptopiaPlayerRegister: account ",
                        StringsUpgradeable.toHexString(account),
                        " is not registered as a player"
                    )
                )
            );
        }
        _;
    }


    /**
     * Public functions
     */
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


    /// @dev Creates an account (see CryptopiaAccountRegister.sol) and registers the account as a player
    /// @param owners List of initial owners
    /// @param required Number of required confirmations
    /// @param dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis
    /// @param username Unique username
    /// @param sex {Undefined, Male, Female}
    /// @param faction The choosen faction (immutable)
    /// @return account Returns wallet address
    function create(address[] memory owners, uint required, uint dailyLimit, bytes32 username, AccountEnums.Sex sex, GameEnums.Faction faction)
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
    function register(GameEnums.Faction faction)
        public virtual override 
    {
        require(!_isRegistered(msg.sender), "CryptopiaPlayerRegister: Account is already registered as a player");
        require(IAccountRegister(accountRegisterContract).isRegistered(msg.sender), "CryptopiaPlayerRegister: Account is not registered with CryptopiaAccountRegister");

        // Read account data
        (bytes32 username, AccountEnums.Sex sex) = IAccountRegister(accountRegisterContract)
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
    /// @return faction Faction to which the player belongs
    /// @return subFaction Sub Faction none/pirate/bounty hunter 
    /// @return level Current level (zero signals not initialized)
    /// @return karma Current karma (zero signals piracy)
    /// @return xp experience points towards next level; XP_BASE * ((XP_DENOMINATOR + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return intelligence STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return strength STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return speed STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return ship The equipted ship
    function getPlayerData(address payable player) 
        public virtual override view 
        returns (
            bytes32 username,
            GameEnums.Faction faction,
            GameEnums.SubFaction subFaction, 
            uint8 level,
            int16 karma,
            uint24 xp,
            uint24 luck,
            uint24 charisma,
            uint24 intelligence,
            uint24 strength,
            uint24 speed,
            uint ship
        )
    {
        (username,) = IAccountRegister(accountRegisterContract)
            .getAccountData(player);
        faction = playerDatas[player].faction;
        subFaction = playerDatas[player].subFaction;
        level = playerDatas[player].level;
        karma = playerDatas[player].karma;
        xp = playerDatas[player].xp;
        luck = playerDatas[player].luck;
        charisma = playerDatas[player].charisma;
        intelligence = playerDatas[player].intelligence;
        strength = playerDatas[player].strength;
        speed = playerDatas[player].speed;
        ship = playerDatas[player].ship;
    }


    /// @dev Returns player datas for `players`
    /// @param players CryptopiaAccount addresses (registered as a players)
    /// @return username Player usernames (fetched from account)
    /// @return faction Faction to which the player belongs
    /// @return subFaction Sub Faction none/pirate/bounty hunter 
    /// @return level Current level (zero signals not initialized)
    /// @return karma Current karma (zero signals piracy)
    /// @return xp experience points towards next level; XP_BASE * ((XP_DENOMINATOR + XP_FACTOR) / XP_DENOMINATOR)**(level - 1)
    /// @return luck STATS_BASE_LUCK + (0 - MAX_LEVEL player choice when leveling up)
    /// @return charisma STATS_CHARISMA_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return intelligence STATS_INTELLIGENCE_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return strength STATS_STRENGTH_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return speed STATS_SPEED_BASE + (0 - MAX_LEVEL player choice when leveling up)
    /// @return ship The equipted ship
    function getPlayerDatas(address payable[] memory players) 
        public virtual override view 
        returns (
            bytes32[] memory username,
            GameEnums.Faction[] memory faction,
            GameEnums.SubFaction[] memory subFaction,
            uint8[] memory level,
            int16[] memory karma,
            uint24[] memory xp,
            uint24[] memory luck,
            uint24[] memory charisma,
            uint24[] memory intelligence,
            uint24[] memory strength,
            uint24[] memory speed,
            uint[] memory ship
        )
    {
        (username,) = IAccountRegister(accountRegisterContract)
            .getAccountDatas(players);
        faction = new GameEnums.Faction[](players.length);
        subFaction = new GameEnums.SubFaction[](players.length);
        level = new uint8[](players.length);
        karma = new int16[](players.length);
        xp = new uint24[](players.length);
        luck = new uint24[](players.length);
        charisma = new uint24[](players.length);
        intelligence = new uint24[](players.length);
        strength = new uint24[](players.length);
        speed = new uint24[](players.length);
        ship = new uint[](players.length);

        for (uint i = 0; i < players.length; i++)
        {
            faction[i] = playerDatas[players[i]].faction;
            subFaction[i] = playerDatas[players[i]].subFaction;
            level[i] = playerDatas[players[i]].level;
            karma[i] = playerDatas[players[i]].karma;
            xp[i] = playerDatas[players[i]].xp;
            luck[i] = playerDatas[players[i]].luck;
            charisma[i] = playerDatas[players[i]].charisma;
            intelligence[i] = playerDatas[players[i]].intelligence;
            strength[i] = playerDatas[players[i]].strength;
            speed[i] = playerDatas[players[i]].speed;
            ship[i] = playerDatas[players[i]].ship;
        }
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


    /// @dev Returns the tokenId from the ship that's equipted by `player`
    /// @param player The player to retrieve the ship for
    /// @return uint the tokenId of the equipted ship
    function getEquiptedShip(address player) 
        public override view 
        returns (uint)
    {
        return playerDatas[player].ship;
    }


    /// @dev Equipt `ship` to calling sender
    /// @param ship The tokenId of the ship to equipt
    function equiptShip(uint ship)
        public override 
        onlyRegistered(_msgSender())
    {
        address player = _msgSender();
        (bool locked, bool generic, 
        GameEnums.Faction faction, GameEnums.SubFaction subFaction, 
        uint inventory) = ICryptopiaShipToken(shipTokenContract)
            .getShipEquiptData(ship);

        // Validate
        require(!locked, "CryptopiaPlayerRegister: Ship is already locked");
        require(generic || faction == playerDatas[player].faction, "CryptopiaPlayerRegister: Faction mismatch");
        require(IERC721Upgradeable(shipTokenContract).ownerOf(ship) == player, "CryptopiaPlayerRegister: Not ship owner");

        // Release prev and lock next ship
        ICryptopiaShipToken(shipTokenContract)
            .lock(playerDatas[player].ship, ship);

        // Update ship
        playerDatas[player].ship = ship;

        // Update inventory
        ICryptopiaInventories(inventoriesContract)
            .setPlayerShip(player, ship);
        
        ICryptopiaInventories(inventoriesContract)
            .setShipInventory(ship, inventory);

        // Pirate?
        if (subFaction == GameEnums.SubFaction.Pirate && playerDatas[player].subFaction != GameEnums.SubFaction.Pirate)
        {
            // Mark as pirate (for life)
            _turnPirate(player);
        }

        // Emit
        emit PlayerEquiptShip(player, ship);
    }


    /// @dev Award xp and/or karma to player 
    /// @param player The player to award
    /// @param xp The amount of xp that's awarded
    /// @param karma The amount of karma
    function award(address player, uint24 xp, int16 karma)
       public virtual override 
       onlyRole(SYSTEM_ROLE)
       onlyRegistered(player)
    {
        playerDatas[player].xp += xp;
        if (0 != karma)
        {
            if (KARMA_MIN != playerDatas[player].karma) // Cannot come back from KARMA_MIN karma (once a pirate, always a pirate)
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


    /// @dev Level up by spending xp 
    /// @param stat The type of stat to increase
    function levelUp(PlayerEnums.Stats stat)
        public virtual override 
        onlyRegistered(_msgSender())
    {
        address player = _msgSender();
        PlayerData storage playerData = playerDatas[player];
        
        // Require max level not reached
        require(playerData.level < LEVEL_MAX, "CryptopiaPlayerRegister: Max level reached");

        // Require sufficient xp
        uint24 xpToLevelUp = uint24(XP_BASE + (uint(playerData.level - 1) * XP_FACTOR)**XP_EXPONENT);
        require(playerData.xp >= xpToLevelUp, "CryptopiaPlayerRegister: Insufficient xp to level up");

        // Spend xp to level up
        playerData.xp -= xpToLevelUp;
        playerData.level++;

        // Increase stat
        if (stat == PlayerEnums.Stats.Luck)
        {
            playerData.luck++;
        }
        else if (stat == PlayerEnums.Stats.Charisma)
        {
            playerData.charisma++;
        }
        else if (stat == PlayerEnums.Stats.Intelligence)
        {
            playerData.intelligence++;
        }
        else if (stat == PlayerEnums.Stats.Strength)
        {
            ICryptopiaInventories(inventoriesContract)
                .setPlayerInventory(player, INVENTORY_MAX_WEIGHT_BASE + playerData.strength * INVENTORY_STRENGTH_MULTIPLIER);

            playerData.strength++;
        }
        else if (stat == PlayerEnums.Stats.Speed)
        {
            playerData.speed++;
        }
        else 
        {
            revert("CryptopiaPlayerRegister: Unknown stat");
        }

        // Emit
        emit PlayerLevelUp(msg.sender, playerData.level, stat);
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
    function _register(address account, bytes32 username, GameEnums.Faction faction,  AccountEnums.Sex sex)
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
        (uint ship, uint inventory) = ICryptopiaShipToken(shipTokenContract)
            .mintStarterShip(account, faction, true);

        // Assign ship
        playerData.ship = ship;

        // Create inventory
        ICryptopiaInventories(inventoriesContract)
            .setPlayerInventory(account, INVENTORY_MAX_WEIGHT_BASE);

        ICryptopiaInventories(inventoriesContract)
            .setPlayerShip(account, playerData.ship);
        
        ICryptopiaInventories(inventoriesContract)
            .setShipInventory(playerData.ship, inventory);

        // Setup crafting
        ICrafting(craftingContract)
            .setCraftingSlots(account, CRAFTING_SLOTS_BASE);

        // Emit
        emit RegisterPlayer(tx.origin, account, username, faction, sex);
        emit PlayerEquiptShip(account, playerData.ship);
    }


    /// @dev Mark `player` as pirate
    /// @param player the account that becomes a pirate
    function _turnPirate(address player)
        internal 
    {
        playerDatas[player].karma = KARMA_MIN;
        playerDatas[player].subFaction = GameEnums.SubFaction.Pirate;

        // Emit 
        emit PlayerTurnPirate(player);
    }
}