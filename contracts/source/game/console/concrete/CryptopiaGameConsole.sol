// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../errors/ArgumentErrors.sol";
import "../../inventories/types/InventoryEnums.sol";
import "../../inventories/IInventories.sol";
import "../../players/IPlayerRegister.sol";
import "../../players/errors/PlayerErrors.sol";
import "../rewards/IFungibleGameConsoleReward.sol";
import "../rewards/INonFungibleGameConsoleReward.sol";
import "../types/GameConsoleDataTypes.sol";
import "../IGameConsoleTitle.sol";
import "../IGameConsole.sol";

/// @title GameConsole 
/// @dev The game console contains a collection of game titles and records highscores, sessions and leaderboards. The game console 
///      runs on-chain sessions that are submitted by players. The game console is not tamper-proof and should be used for casual 
///      games only. There are no guarantees that the highscores are accurate or that they have not been tampered with. This system
///      is not suitable for high-stakes games or games that require high security. 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaGameConsole is Initializable, AccessControlUpgradeable, IGameConsole {

    /// @dev Data structure for a console game
    struct GameConsoleTitleData
    {
        uint index;

        /// @dev Location of the logic contract
        address logic;

        /// @dev The highscore
        GameConsoleSession highscore;

        /// @dev The leaderboard
        GameConsoleSession[] leaderboard;

        /// @dev Player data
        mapping (address => GameConsolePlayerData) playerData;
    }

    /// @dev Data structure for a console game session
    struct GameConsolePlayerData
    {
        /// @dev Personal highscore
        GameConsoleSession highscore;

        /// @dev Player sessions (chronological)
        GameConsoleSession[] sessions;
    }


    /**
     * Storage
     */
    uint constant public MAX_LEADERBOARD_SIZE = 10;

    /// @dev Game data
    mapping (bytes32 => GameConsoleTitleData) private titles;
    bytes32[] public titlesIndex;

    /// @dev Refs
    address public playerRegisterContract;


    /**
     * Events
     */
    /// @dev Emitted when a new console title is added
    /// @param name The name of the title
    event GameConsoleTitleAdd(bytes32 indexed name);

    /// @dev Emitted when a new console game session is added
    /// @param player The player that submitted the score
    /// @param title The title of the game
    /// @param score The score that was submitted
    /// @param isPersonalHighscore Indicates if the session is a personal highscore
    /// @param isGlobalHighscore Indicates if the session is a global highscore
    /// @param timestamp The timestamp of the session
    event GameConsoleSessionSubmit(address indexed player, bytes32 indexed title, uint32 score, bool isPersonalHighscore, bool isGlobalHighscore, uint64 timestamp);

    /// @dev Emitted when a new personal highscore is set
    /// @param player The player that set the highscore
    /// @param title The title of the game
    /// @param score The highscore that was set
    /// @param timestamp The timestamp of the highscore
    event GameConsoleNewPersonalHighscore(address indexed player, bytes32 indexed title, uint32 score, uint64 timestamp);

    /// @dev Emitted when a new global highscore is set
    /// @param player The player that set the highscore
    /// @param title The title of the game
    /// @param score The highscore that was set
    /// @param timestamp The timestamp of the highscore
    event GameConsoleNewGlobalHighscore(address indexed player, bytes32 indexed title, uint32 score, uint64 timestamp);

    /// @dev Emitted when the leaderboard changes
    /// @param title The title of the game
    /// @param index The index of the item in the leaderboard that changed
    /// @param player The player that submitted the score
    /// @param score The score that was submitted
    /// @param timestamp The timestamp of the session
    event GameConsoleLeaderboardChange(bytes32 indexed title, uint index, address player, uint32 score, uint64 timestamp);


    /**
     * Errors
     */
    /// @dev Emitted when the title is not found
    /// @param name The name of the title
    error TitleNotFound(bytes32 name);

    /// @dev Emitted when a session is made by a player that is invalid
    error InvalidSession();


    /**
     * Modifiers
     */
    /// @dev Enforce that the title exists
    /// @param title The title of the game
    modifier onlyExistingTitle(bytes32 title) 
    {
        if (!_titleExists(title))
        {
            revert TitleNotFound(title);
        }
        _;
    }


    /// @dev Initialize
    /// @param _playerRegisterContract Contract responsible for players
    function initialize(
        address _playerRegisterContract) 
        public initializer 
    {
        __AccessControl_init();

        // Set refs
        playerRegisterContract = _playerRegisterContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Batch operation to set titles
    /// @param titles_ The titles to set
    function setTitles(GameConsoleTitle[] memory titles_) 
        onlyRole(DEFAULT_ADMIN_ROLE) 
        public virtual 
    {
        for (uint i = 0; i < titles_.length; i++) 
        {
            GameConsoleTitle memory title = titles_[i];
            GameConsoleTitleData storage titleData = titles[title.name];

            assert(title.name != bytes32(0));
            assert(title.logic != address(0));

            // Add title if it doesn't exist
            if (titleData.index == 0) 
            {
                titlesIndex.push(title.name);
                titleData.index = titlesIndex.length;

                // Emit event
                emit GameConsoleTitleAdd(title.name);
            }

            // Update title
            titleData.logic = title.logic;
        }
    }


    /** 
     * Public functions
     */
    /// @dev Get the amount of titles
    /// @return count The amount of titles
    function getTitleCount() 
        public virtual override view 
        returns (uint count)
    {
        return titlesIndex.length;
    }
        

    /// @dev Get all console titles
    /// @param skip The amount of titles to skip
    /// @param take The amount of titles to take
    /// @return titles_ Titles and global leaderboard
    function getTitles(uint skip, uint take) 
        public virtual override view 
        returns (GameConsoleTitle[] memory titles_)
    {
        uint length = take;
        if (skip + take > titlesIndex.length) 
        {
            length = titlesIndex.length - skip;
        }

        titles_ = new GameConsoleTitle[](length);
        for (uint i = skip; i < length; i++) 
        {
            GameConsoleTitleData storage titleData = titles[titlesIndex[i]];
            titles_[i] = GameConsoleTitle(
                titlesIndex[i], 
                titleData.logic,
                titleData.highscore, 
                titleData.leaderboard);
        }
    }


    /// @dev Get all console titles and personal highscores for a specific player
    /// @param player The player to get the highscores for
    /// @param skip The amount of titles to skip
    /// @param take The amount of titles to take
    /// @return titles_ Titles and global leaderboards
    /// @return highscores Personal highscores
    function getTitlesAndHighscores(address player, uint skip, uint take) 
        public virtual override view 
        returns (GameConsoleTitle[] memory titles_, GameConsoleSession[] memory highscores)
    {
        uint length = take;
        if (skip + take > titlesIndex.length) 
        {
            length = titlesIndex.length - skip;
        }

        titles_ = new GameConsoleTitle[](length);
        highscores = new GameConsoleSession[](length);
        for (uint i = skip; i < length; i++) 
        {
            GameConsoleTitleData storage titleData = titles[titlesIndex[i]];
            titles_[i] = GameConsoleTitle(
                titlesIndex[i], 
                titleData.logic,
                titleData.highscore, 
                titleData.leaderboard);

            highscores[i] = titleData.playerData[player].highscore;
        }
    }


    /// @dev Submit a new game session
    /// @param title The title of the game
    /// @param score The session score 
    /// @param data Additional data used to verify the score (no guerantees are made about the data's integrity)
    /// @param inventory The inventory to store the rewards in
    function submit(bytes32 title, uint32 score, bytes32 data, Inventory inventory) 
        public virtual override 
        onlyExistingTitle(title)
    {
        // Check if player is registered
        if (!IPlayerRegister(playerRegisterContract).isRegistered(msg.sender))
        {
            revert PlayerNotRegistered(msg.sender);
        }

        GameConsoleTitleData storage titleData = titles[title];
        GameConsolePlayerData storage playerData = titleData.playerData[msg.sender];

        // Create session
        GameConsoleSession memory session = GameConsoleSession(
            msg.sender, 
            uint64(block.timestamp), 
            score);

        playerData.sessions.push(session);

        bool isPersonalHighscore = playerData.highscore.score < score;
        //bool isGlobalHighscore = titleData.highscore.score < score;

        // Run game logic
        (
            bool isValid, 
            GameConsoleReward memory reward
        ) = IGameConsoleTitle(titleData.logic).run(
            session, 
            data, 
            playerData.sessions.length, 
            isPersonalHighscore, 
            isPersonalHighscore);

        if (!isValid)
        {
            revert InvalidSession();
        }

        // Personal highscore?
        if (isPersonalHighscore) 
        {
            playerData.highscore = session;

            // Emit event
            emit GameConsoleNewPersonalHighscore(
                msg.sender, 
                title, 
                score, 
                session.timestamp);
        }

        // Global highscore?
        if (isPersonalHighscore) 
        {
            titleData.highscore = session;

            // Emit event
            emit GameConsoleNewGlobalHighscore(
                msg.sender, 
                title, 
                score, 
                session.timestamp);
        }

        // Add to leaderboard?
        if (titleData.leaderboard.length < MAX_LEADERBOARD_SIZE) 
        {
            titleData.leaderboard.push(session);

            // Emit 
            emit GameConsoleLeaderboardChange(
                title, 
                titleData.leaderboard.length - 1, 
                msg.sender, 
                score, 
                session.timestamp);
        } 
        else 
        {
            // Find lowest score
            uint32 lowestScore = titleData.leaderboard[0].score;
            uint lowestIndex = 0;
            for (uint i = 1; i < titleData.leaderboard.length; i++) 
            {
                if (titleData.leaderboard[i].score < lowestScore) 
                {
                    lowestScore = titleData.leaderboard[i].score;
                    lowestIndex = i;
                }
            }

            // Replace lowest score if session is higher
            if (session.score > lowestScore) 
            {
                titleData.leaderboard[lowestIndex] = session;

                // Emit
                emit GameConsoleLeaderboardChange(
                    title, 
                    lowestIndex, 
                    msg.sender, 
                    score, 
                    session.timestamp);
            }
        }

        // Fungible rewards
        for (uint i = 0; i < reward.fungible.length; i++) 
        {   
            FungibleTransactionData memory fungible = reward.fungible[i];
            if (inventory == Inventory.Wallet && !fungible.allowWallet)
            {
                revert ArgumentInvalid();
            }

            // Reward player
            IFungibleGameConsoleReward(fungible.asset)
                .__mintGameConsoleReward(msg.sender, inventory, fungible.amount); 
        }

        // Non-fungible rewards
        for (uint i = 0; i < reward.nonFungible.length; i++) 
        {   
            NonFungibleTransactionData memory nonFungible = reward.nonFungible[i];
            if (inventory == Inventory.Wallet && !nonFungible.allowWallet)
            {
                revert ArgumentInvalid();
            }

            // Reward player
            INonFungibleGameConsoleReward(nonFungible.asset)
                .__mintGameConsoleReward(msg.sender, inventory, nonFungible.item);
        }

        // Award xp 
        IPlayerRegister(playerRegisterContract)
            .__award(msg.sender, reward.xp, 0);

        // Emit event
        emit GameConsoleSessionSubmit(
            msg.sender, 
            title, 
            score, 
            isPersonalHighscore, 
            isPersonalHighscore, 
            session.timestamp);
    }


    /**
     * Private functions
     */
    /// @dev True if a title exists
    /// @param name The name of the game
    function _titleExists(bytes32 name) internal view returns (bool) 
    {
        return titlesIndex.length > 0 && titlesIndex[titles[name].index] == name;
    }
}