// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../game/players/IPlayerRegister.sol";
import "../../../../game/inventories/IInventories.sol";
import "../../../../game/crafting/ICraftable.sol";
import "../../../../game/items/interactables/IConsumable.sol";
import "../../../../game/quests/rewards/INonFungibleQuestReward.sol";
import "../../books/types/DevelopmentBookDataTypes.sol";
import "../../books/errors/BookErrors.sol";
import "../../books/IDevelopmentBooks.sol";
import "../CryptopiaERC721.sol";

/// @title Cryptopia Players Contract
/// @notice Books that are learnable and can be used to increase the stats of a player. 
/// It provides functionalities to craft books, consume books and retrieve book data.
/// @dev Inherits from Initializable and AccessControlUpgradeable and implements the 
/// IDevelopmentBooks interface. The contract utilizes an upgradable design for scalability 
/// and future enhancements. It maintains detailed player data, enabling intricate game mechanics and interactions.
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract DevelopmentBooks is CryptopiaERC721, IDevelopmentBooks, ICraftable, IConsumable, INonFungibleQuestReward {

    /// @dev Development book in Cryptopia
    struct DevelopmentBookData
    {
        /// @dev Index within the booksIndex array
        uint index;

        /// @dev The player that authored the book (if any)
        address author;

        /// @dev The rarity of the book
        Rarity rarity;

        /// @dev The level required to use the book
        uint8 level;

        /// @dev Indicates if a faction constraint is applied to consume the book
        bool hasFactionConstraint;
        /// @dev Specific faction required to consume the book
        /// @notice Effective if hasFactionConstraint is true
        Faction faction;

        /// @dev Indicates if a sub-faction constraint is applied to consume the book
        bool hasSubFactionConstraint;
        /// @dev Specific sub-faction required to consume the book
        /// @notice Effective if hasSubFactionConstraint is true
        SubFaction subFaction;

        /// @dev The stats that this book will increase
        PlayerStat statType;

        /// @dev The amount of stats that this book will increase
        uint8 statIncrease;

        /// @dev Experience points awarded for consuming the book
        uint24 xp;
    }


    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev name => DevelopmentBookData
    mapping(bytes32 => DevelopmentBookData) public books;
    bytes32[] internal booksIndex;

    // Refs
    address public playerRegisterContract;
    address public inventoriesContract;

    /// @dev tokenId => book
    mapping (uint => bytes32) public bookInstances;

    /// @dev player => book => consumed
    mapping (address => mapping (bytes32 => bool)) public consumedBooks;


    /**
     * Events
     */
    /// @dev Emitted when a book is minted
    /// @param tokenId The id of the minted book
    /// @param book The name of the minted book
    /// @param to The player or account that received the minted book
    event DevelopmentBookMinted(uint indexed tokenId, bytes32 book, address to);

    /// @dev Emitted when a book is consumed
    /// @param tokenId The id of the consumed book
    /// @param book The name of the consumed book
    /// @param player The player that consumed the book
    event DevelopmentBookConsumed(uint indexed tokenId, bytes32 book, address indexed player);

    /// @dev Emitted when a book is burned
    /// @param tokenId The id of the burned book
    /// @param book The name of the burned book
    event DevelopmentBookBurned(uint indexed tokenId, bytes32 book);


    /**
     * Modifiers
     */
    /// @dev Requires that an item with `book` exists
    /// @param book Unique token name
    modifier onlyExisting(bytes32 book)
    {
        if (!_exists(book)) 
        {
            revert BookNotFound(book);
        }
        _;
    }


    /// @dev Contract initializer sets shared base uri
    /// @param _authenticator Whitelist
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    /// @param _playerRegisterContract Contract responsible for players
    /// @param _inventoriesContract Contract responsible for inventories
    function initialize(
        address _authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI,
        address _playerRegisterContract,
        address _inventoriesContract) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Development Books", "DEBOOK", _authenticator, initialContractURI, initialBaseTokenURI);

        // Set refs
        playerRegisterContract = _playerRegisterContract;
        inventoriesContract = _inventoriesContract;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Add or update books
    /// @param data DevelopmentBook data
    function setBooks(DevelopmentBook[] memory data) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < data.length; i++)
        {
            _setBook(data[i]);
        }
    }


    /// @dev Mint a new book
    /// @param book The name of the book
    /// @param to The address to mint the book to
    function mint(bytes32 book, address to) 
        public virtual
        onlyRole(MINTER_ROLE)
        onlyExisting(book)
        returns (uint tokenId)
    {
        // Mint
        tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();
        booksIndex[tokenId] = book;

        // Emit event
        emit DevelopmentBookMinted(tokenId, book, to);
    }


    /**
     * Public functions
     */
    /// @dev Returns the amount of different books
    /// @return count The amount of different books
    function getBookCount() 
        public virtual override view 
        returns (uint)
    {
        return booksIndex.length;
    }


    /// @dev Retreive a book by name
    /// @param _name Book name (unique)
    /// @return book a single book
    function getBook(bytes32 _name) 
        public virtual override view 
        returns (DevelopmentBook memory book) 
    {
        book = _getBook(_name);
    }


    /// @dev Retreive a book by index
    /// @param index The index of the book to retreive
    /// @return book a single book
    function getBookAt(uint index) 
        public virtual override view 
        returns (DevelopmentBook memory book)
    {
        book = _getBook(booksIndex[index]);
    }


    /// @dev Retreive a rance of books
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return books_ a range of books
    function getBooks(uint skip, uint take) 
        public virtual override view 
        returns (DevelopmentBook[] memory books_)
    {
        uint length = take;
        if (booksIndex.length < skip + take) 
        {
            length = booksIndex.length - skip;
        }

        books_ = new DevelopmentBook[](length);
        for (uint i = 0; i < length; i++)
        {
            books_[i] = _getBook(booksIndex[skip + i]);
        }
    }


    /// @dev Retreive a book by token id
    /// @param tokenId The id of the book to retreive
    /// @return instance a single book instance
    function getBookInstance(uint tokenId) 
        public virtual override view 
        returns (DevelopmentBookInstance memory instance)
    {
        instance = _getBookInstance(tokenId);
    }


    /// @dev Retreive books by token ids
    /// @param tokenIds The ids of the books to retreive
    /// @return instances a range of book instances
    function getBookInstances(uint[] memory tokenIds) 
        public virtual override view 
        returns (DevelopmentBookInstance[] memory instances)
    {
        instances = new DevelopmentBookInstance[](tokenIds.length);
        for (uint i = 0; i < tokenIds.length; i++)
        {
            instances[i] = _getBookInstance(tokenIds[i]);
        }
    }


    /// @dev Consume a book
    /// @param tokenId The id of the book to consume
    function consume(uint tokenId) 
        public virtual override 
    {
        address player = _msgSender();

        // Check if book is owned by the player
        if (ownerOf(tokenId) != player) 
        {
            revert BookNotOwned(tokenId, player);
        }

        // Check if book is already consumed
        if (consumedBooks[player][bookInstances[tokenId]]) 
        {
            revert BookAlreadyConsumed(tokenId, player);
        }

        bytes32 bookName = bookInstances[tokenId];
        DevelopmentBookData memory book = books[bookName];

        // Burn book
        _burn(tokenId);

        // Mark as consumed
        consumedBooks[player][bookName] = true;

        // Increase stat and xp
        IPlayerRegister(playerRegisterContract)
            .__increaseStat(player, book.statType, book.statIncrease, book.xp);

        // Emit event
        emit DevelopmentBookBurned(tokenId, bookName);
        emit DevelopmentBookConsumed(tokenId, bookName, player);
    }


    /// @dev getTokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param tokenId Token ID
    /// @return uri where token data can be retrieved
    function getTokenURI(uint tokenId) 
        public virtual override view 
        returns (string memory) 
    {
        return string(abi.encodePacked(getBaseTokenURI(), bookInstances[tokenId]));
    }


    /**
     * System functions
     */
    /// @dev Allows for the crafting of a development book
    /// @param book The name of the book to be crafted
    /// @param player The player to craft the book for
    /// @param inventory The inventory to mint the item into
    /// @return tokenId The token ID of the minted item
    function __craft(bytes32 book, address player, Inventory inventory) 
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(book) 
        returns (uint tokenId)
    {
        // Mint
        tokenId = _getNextTokenId();
        _mint(inventoriesContract, tokenId);
        _incrementTokenId();
        bookInstances[tokenId] = book;

        // Assign
        IInventories(inventoriesContract)
            .__assignNonFungibleToken(player, inventory, address(this), tokenId);
    }


    /// @dev Mint a quest reward
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param book The item to mint
    /// @return tokenId The token ID of the minted item
    function __mintQuestReward(address player, Inventory inventory, bytes32 book)
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        onlyExisting(book) 
        returns (uint tokenId)
    {
        // Mint
        tokenId = _getNextTokenId();
        _mint(inventoriesContract, tokenId);
        _incrementTokenId();
        bookInstances[tokenId] = book;

        // Assign
        IInventories(inventoriesContract)
            .__assignNonFungibleToken(player, inventory, address(this), tokenId);
    }


    /**
     * Private functions
     */
    /// @dev calculates the next token ID based on value of _currentTokenId
    /// @return uint for the next token ID
    function _getNextTokenId() private view returns (uint) 
    {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() private 
    {
        _currentTokenId++;
    }

    
    /// @dev True if a book with `name` exists
    /// @param book of the book
    function _exists(bytes32 book) internal view returns (bool) 
    {
        return booksIndex.length > 0 && booksIndex[books[book].index] == book;
    }


    /// @dev Add or update a book
    /// @param book Book data
    function _setBook(DevelopmentBook memory book) 
        internal 
    {
        // Add book
        if (!_exists(book.name))
        {
            books[book.name].index = booksIndex.length;
            booksIndex.push(book.name);
        }

        // Set book
        DevelopmentBookData storage data = books[book.name];
        data.author = book.author;
        data.rarity = book.rarity;
        data.level = book.level;
        data.hasFactionConstraint = book.hasFactionConstraint;
        data.faction = book.faction;
        data.hasSubFactionConstraint = book.hasSubFactionConstraint;
        data.subFaction = book.subFaction;
        data.statType = book.statType;
        data.statIncrease = book.statIncrease;
        data.xp = book.xp;
    }


    /// @dev Retreive a book by name
    /// @param _name Book name (unique)
    /// @return book a single book
    function _getBook(bytes32 _name) 
        internal virtual view 
        returns (DevelopmentBook memory book)
    {
        DevelopmentBookData memory data = books[_name];
        book = DevelopmentBook({
            name: _name,
            author: data.author,
            rarity: data.rarity,
            level: data.level,
            hasFactionConstraint: data.hasFactionConstraint,
            faction: data.faction,
            hasSubFactionConstraint: data.hasSubFactionConstraint,
            subFaction: data.subFaction,
            statType: data.statType,
            statIncrease: data.statIncrease,
            xp: data.xp
        });
    }


    /// @dev Retreive a book instance by token id
    /// @param tokenId The id of the book to retreive
    /// @return instance a single book instance
    function _getBookInstance(uint tokenId) 
        internal virtual view 
        returns (DevelopmentBookInstance memory instance)
    {
        bytes32 bookName = bookInstances[tokenId];
        DevelopmentBookData memory data = books[bookName];
        instance = DevelopmentBookInstance({
            tokenId: tokenId,
            owner: ownerOf(tokenId),
            index: uint16(data.index),
            name: bookName,
            author: data.author,
            rarity: data.rarity,
            level: data.level,
            hasFactionConstraint: data.hasFactionConstraint,
            faction: data.faction,
            hasSubFactionConstraint: data.hasSubFactionConstraint,
            subFaction: data.subFaction,
            statType: data.statType,
            statIncrease: data.statIncrease,
            xp: data.xp
        });
    }
}