// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./ICryptopiaMap.sol";
import "../MapEnums.sol";
import "../../assets/types/AssetEnums.sol";
import "../../players/IPlayerRegister.sol";
import "../../../tokens/ERC721/deeds/ITitleDeeds.sol";

/// @title Cryptopia Maps
/// @dev Contains world data and player positions
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaMap is ICryptopiaMap, Initializable, OwnableUpgradeable {

    /// @dev A collection of tiles
    struct Map {
        bool initialized;
        bool finalized;
        uint32 sizeX;
        uint32 sizeZ;
        uint32 tileStartIndex;
    }

    /// @dev Tile data that is used to construct the mesh in the client
    struct Tile {
        bool initialized;
        uint16 mapIndex;
        uint8 terrainPrimaryIndex; // change into terrainType (enum) Grass, Sand, GrasySand etc.
        uint8 terrainSecondaryIndex; // remove
        uint8 terrainBlendFactor; // remove
        uint8 terrainOrientation; // remove
        uint8 terrainElevation;
        uint8 elevation;
        uint8 waterLevel;
        uint8 vegitationLevel;
        uint8 rockLevel;
        // Add wildlifeLevel
        uint8 incommingRiverData; // change to riverFlags
        uint8 outgoingRiverData; // remove
        uint8 roadFlags; // change to hasRoad
        // Add landMass index
        // Add hasLake
    }

    /// @dev Tile meta data
    struct TileData 
    {
        /// @dev Player that most recently entered the tile 
        address lastEnteredPlayer;

        /// @dev Wildlife 
        WildlifeData wildlife;

        /// @dev Natural resources
        ResourceData[] resources;
    }

    /// @dev Wildlife on tile
    struct WildlifeData 
    {
        /// @dev Indicates type of wildlife
        bytes32 creature;

        /// @dev Indicates level of wildlife that remains
        uint128 level;

        /// @dev Indicates level of wildlife that initially lived on the tile
        uint128 initialLevel;
    }

    /// @dev Resources can be attached to tiles
    struct ResourceData 
    {
        /// @dev The asset (see CryptopiaAssetRegister) the resource is denoted in
        address asset;

        /// @dev The amount of `asset` that if left
        uint amount;

        /// @dev The initial size of the `asset` deposit
        uint initialAmount;
    }

    /// @dev Player data
    struct PlayerData {

        /// @dev Ordered iterating - Account that entered the tile after us (above us in the list)
        address chain_next;

        /// @dev Ordered iterating - Account that entered the tile before us (below us in the list)
        address chain_prev;

        /// @dev Tile that the player is currently on
        uint32 location_tileIndex;

        uint224 location_route;

        /// @dev When the player arrives at `tileIndex`
        uint location_arrival;

        /// @dev Player movement budget
        uint movement;
    }


    /**
     * Storage
     */
    uint32 constant PLAYER_START_POSITION = 0;
    uint constant MOVEMENT_TURN_DURATION = 60; // 1 min
    uint constant MOVEMENT_COST_LAND_FLAT = 11;
    uint constant MOVEMENT_COST_LAND_SLOPE = 19;
    uint constant MOVEMENT_COST_WATER = 5;
    uint constant MOVEMENT_COST_WATER_EMBARK_DISEMBARK = 25; 
    uint constant WILDLIFE_MAX_LEVEL = 3;
    uint constant WILDLIFE_DIFFICULTY_MULTIPLIER = 10;
    uint constant RESOURCE_UNIT = 1_000_000_000_000_000_000;

    /// @dev Refs
    address public playerRegisterContract;
    address public assetRegisterContract;
    address public titleDeedContract;
    address public tokenContract;

    /// @dev Maps
    mapping(bytes32 => Map) public maps;
    bytes32[] private mapsIndex;

    /// @dev Tiles
    mapping(uint32 => Tile) public tiles;
    mapping(uint32 => TileData) public tileData;
    uint public initializedTileCount;

    /// @dev account => PlayerData
    mapping(address => PlayerData) public playerData;
  
    /// @dev a | (b << 32) => movementCost
    mapping (uint64 => uint) public pathCache;


    /**
     * Events
     */
    /// @dev Emitted when a map is created and finalized
    event CreateMap(bytes32 indexed name, uint16 index);

    /// @dev Emitted when a player entered a map
    event PlayerEnterMap(bytes32 indexed map, uint32 indexed tile, address indexed player, uint arrival);

    /// @dev Emitted when a player entered a tile
    event PlayerMove(uint32 indexed originTile, uint32 indexed destinationTile, address indexed player, uint arrival);


    /**
     * Modifiers
     */
    /// @dev Requires that a tile exists at `tileIndex` and that it's map is finalized
    /// @param tileIndex Index of the tile
    modifier onlyExistingTile(uint32 tileIndex)
    {
        require(_tileExists(tileIndex), "CryptopiaMap: Non-existing tile");
        _;
    }


    /** 
     * Public functions
     */
    /// @param _playerRegisterContract Contract responsible for players
    /// @param _assetRegisterContract Contract responsible for assets
    /// @param _titleDeedContract Contract responsible for land ownership
    /// @param _tokenContract Cryptos token
    function initialize(
        address _playerRegisterContract, 
        address _assetRegisterContract,
        address _titleDeedContract, 
        address _tokenContract) 
        public initializer 
    {
        __Ownable_init();
        playerRegisterContract = _playerRegisterContract;
        assetRegisterContract = _assetRegisterContract;
        titleDeedContract = _titleDeedContract;
        tokenContract = _tokenContract;
    }


    /// @dev Retreives the amount of maps created.
    /// @return count Number of maps created.
    function getMapCount() 
        public virtual override view 
        returns (uint count)
    {
        count = mapsIndex.length;
    }


    /// @dev Retreives the map at `index`
    /// @param index Map index (not mapping key)
    /// @return initialized True if the map is created
    /// @return finalized True if all tiles are added and the map is immutable
    /// @return sizeX Number of tiles in the x direction
    /// @return sizeZ Number of tiles in the z direction
    /// @return tileStartIndex The index of the first tile in the map (mapping key)
    /// @return name Unique name of the map
    function getMapAt(uint index) 
        public virtual override view 
        returns (
            bool initialized, 
            bool finalized, 
            uint32 sizeX, 
            uint32 sizeZ, 
            uint32 tileStartIndex,
            bytes32 name
        )
    {
        name = mapsIndex[index];
        Map storage map = maps[name];
        initialized = map.initialized;
        finalized = map.finalized; 
        sizeX = map.sizeX;
        sizeZ = map.sizeZ;
        tileStartIndex = map.tileStartIndex;
    }


    /// @dev Create a new map. The map will be 'under construction' until all (`sizeX` * `sizeZ`) tiles have been set 
    /// and `finalizeMap()` is called. While a map is under construction no other map can be created.
    /// @param name Map name
    /// @param sizeX Amount of tiles in a row
    /// @param sizeZ Amount of tiles in a column
    function createMap(bytes32 name, uint8 sizeX, uint8 sizeZ) 
        public onlyOwner 
    {
        require(!maps[name].initialized, "CryptopiaMap: Map name must be unique");
        assert(mapsIndex.length == 0 || uint16(mapsIndex.length - 1) < uint16(mapsIndex.length));

        uint32 tileStartIndex;
        if (0 == mapsIndex.length)
        {
            tileStartIndex = 0;
        }
        else 
        {
            Map storage prevMap = maps[mapsIndex[mapsIndex.length - 1]];

            // Complete prev map first
            require(prevMap.finalized, "CryptopiaMap: Another map is under construction");

            tileStartIndex = prevMap.tileStartIndex;
            tileStartIndex += prevMap.sizeX * prevMap.sizeZ;
        }

        maps[name].initialized = true;
        maps[name].finalized = false;
        maps[name].sizeX = sizeX;
        maps[name].sizeZ = sizeZ;
        maps[name].tileStartIndex = tileStartIndex;
        mapsIndex.push(name);
    }


    /// @dev Finalizes the state of the last created map. Throws if no map is under construction
    function finalizeMap() 
        public onlyOwner 
    {
        require(mapsIndex.length > 0, "CryptopiaMap: No map found");

        // Get last created map
        uint16 index = uint16(mapsIndex.length - 1);
        Map storage map = maps[mapsIndex[index]];

        require(!map.finalized, "CryptopiaMap: No map under construction");
        require(initializedTileCount == map.sizeX * map.sizeZ, "CryptopiaMap: Incomplete tile set");

        map.finalized = true;

        // Add title deeds
        ITitleDeeds(titleDeedContract)
            .increaseMaxTokenId(initializedTileCount);
        initializedTileCount = 0;

        // Emit created event
        emit CreateMap(mapsIndex[index], index);
    }

      
    /// @dev Retrieve a tile
    /// @param tileIndex Index of hte tile to retrieve
    /// @return terrainPrimaryIndex Primary texture used to paint tile
    /// @return terrainSecondaryIndex Secondary texture used to paint tile
    /// @return terrainBlendFactor Blend factor for primary and secondary textures
    /// @return terrainOrientation Orientation in degrees for texture
    /// @return terrainElevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return elevation Tile elevation actual elevation used in navigation (underwater and >= waterlevel indicates seasteading)
    /// @return waterLevel Tile water level
    /// @return vegitationLevel Level of vegitation on tile
    /// @return rockLevel Level of rocks on tile
    /// @return incommingRiverData River data
    /// @return outgoingRiverData River data
    /// @return roadFlags Road data
    function getTile(uint32 tileIndex) 
        public virtual override view 
        returns (
            uint8 terrainPrimaryIndex,
            uint8 terrainSecondaryIndex,
            uint8 terrainBlendFactor,
            uint8 terrainOrientation,
            uint8 terrainElevation,
            uint8 elevation,
            uint8 waterLevel,
            uint8 vegitationLevel,
            uint8 rockLevel,
            uint8 incommingRiverData,
            uint8 outgoingRiverData,
            uint8 roadFlags
        )
    {
        terrainPrimaryIndex = tiles[tileIndex].terrainPrimaryIndex;
        terrainSecondaryIndex = tiles[tileIndex].terrainSecondaryIndex;
        terrainBlendFactor = tiles[tileIndex].terrainBlendFactor;
        terrainOrientation = tiles[tileIndex].terrainOrientation;
        terrainElevation = tiles[tileIndex].terrainElevation;
        elevation = tiles[tileIndex].elevation;
        waterLevel = tiles[tileIndex].waterLevel;
        vegitationLevel = tiles[tileIndex].vegitationLevel;
        rockLevel = tiles[tileIndex].rockLevel;
        incommingRiverData = tiles[tileIndex].incommingRiverData;
        outgoingRiverData = tiles[tileIndex].outgoingRiverData;
        roadFlags = tiles[tileIndex].roadFlags;
    }


    /// @dev Retrieve a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return terrainPrimaryIndex Primary texture used to paint tile
    /// @return terrainSecondaryIndex Secondary texture used to paint tile
    /// @return terrainBlendFactor Blend factor for primary and secondary textures
    /// @return terrainOrientation Orientation in degrees for texture
    /// @return terrainElevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return elevation Tile elevation actual elevation used in navigation (underwater and >= waterlevel indicates seasteading)
    /// @return waterLevel Tile water level
    /// @return vegitationLevel Level of vegitation on tile
    /// @return rockLevel Level of rocks on tile
    /// @return incommingRiverData River data
    /// @return outgoingRiverData River data
    /// @return roadFlags Road data
    function getTiles(uint32 skip, uint32 take) 
        public virtual override view  
        returns (
            uint8[] memory terrainPrimaryIndex,
            uint8[] memory terrainSecondaryIndex,
            uint8[] memory terrainBlendFactor,
            uint8[] memory terrainOrientation,
            uint8[] memory terrainElevation,
            uint8[] memory elevation,
            uint8[] memory waterLevel,
            uint8[] memory vegitationLevel,
            uint8[] memory rockLevel,
            uint8[] memory incommingRiverData,
            uint8[] memory outgoingRiverData,
            uint8[] memory roadFlags
        )
    {
        terrainPrimaryIndex = new uint8[](take);
        terrainSecondaryIndex = new uint8[](take);
        terrainBlendFactor = new uint8[](take);
        terrainOrientation = new uint8[](take);
        terrainElevation = new uint8[](take);
        elevation = new uint8[](take);
        waterLevel = new uint8[](take);
        vegitationLevel = new uint8[](take);
        rockLevel = new uint8[](take);
        incommingRiverData = new uint8[](take);
        outgoingRiverData = new uint8[](take);
        roadFlags = new uint8[](take);

        uint32 index = skip;
        for (uint32 i = 0; i < take; i++)
        {
            terrainPrimaryIndex[i] = tiles[index].terrainPrimaryIndex;
            terrainSecondaryIndex[i] = tiles[index].terrainSecondaryIndex;
            terrainBlendFactor[i] = tiles[index].terrainBlendFactor;
            terrainOrientation[i] = tiles[index].terrainOrientation;
            terrainElevation[i] = tiles[index].terrainElevation;
            elevation[i] = tiles[index].elevation;
            waterLevel[i] = tiles[index].waterLevel;
            vegitationLevel[i] = tiles[index].vegitationLevel;
            rockLevel[i] = tiles[index].rockLevel;
            incommingRiverData[i] = tiles[index].incommingRiverData;
            outgoingRiverData[i] = tiles[index].outgoingRiverData;
            roadFlags[i] = tiles[index].roadFlags;
            index++;
        }
    }

    
    /// @dev Retrieve static data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return wildlife_creature Type of wildlife that the tile contains
    /// @return wildlife_initialLevel The level of wildlife that the tile contained initially
    /// @return resource1_asset A type of asset that the tile contains
    /// @return resource2_asset A type of asset that the tile contains
    /// @return resource3_asset A type of asset that the tile contains
    /// @return resource1_initialAmount The amount of resource1_asset the tile contained initially
    /// @return resource2_initialAmount The amount of resource2_asset the tile contained initially
    /// @return resource3_initialAmount The amount of resource3_asset the tile contained initially
    function getTileDataStatic(uint32 skip, uint32 take) 
        public virtual override view 
        returns (
            bytes32[] memory wildlife_creature,
            uint128[] memory wildlife_initialLevel,
            address[] memory resource1_asset,
            address[] memory resource2_asset,
            address[] memory resource3_asset,
            uint[] memory resource1_initialAmount,
            uint[] memory resource2_initialAmount,
            uint[] memory resource3_initialAmount
        )
    {
        wildlife_creature = new bytes32[](take);
        wildlife_initialLevel = new uint128[](take);
        resource1_asset = new address[](take);
        resource2_asset = new address[](take);
        resource3_asset = new address[](take);
        resource1_initialAmount = new uint[](take);
        resource2_initialAmount = new uint[](take);
        resource3_initialAmount = new uint[](take);

        uint32 index = skip;
        for (uint32 i = 0; i < take; i++)
        {   
            wildlife_creature[i] = tileData[index].wildlife.creature;
            wildlife_initialLevel[i] = tileData[index].wildlife.initialLevel;

            if (tileData[index].resources.length > 0)
            {
                resource1_asset[i] = tileData[index].resources[0].asset;
                resource1_initialAmount[i] = tileData[index].resources[0].initialAmount;
            }

            if (tileData[index].resources.length > 1)
            {
                resource2_asset[i] = tileData[index].resources[1].asset;
                resource2_initialAmount[i] = tileData[index].resources[1].initialAmount;
            }

            if (tileData[index].resources.length > 2)
            {
                resource3_asset[i] = tileData[index].resources[2].asset;
                resource3_initialAmount[i] = tileData[index].resources[2].initialAmount;
            }

            index++;
        }
    }


    /// @dev Retrieve dynamic data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return owner Account that owns the tile
    /// @return player1 Player that last entered the tile
    /// @return player2 Player entered the tile before player1
    /// @return player3 Player entered the tile before player2
    /// @return player4 Player entered the tile before player3
    /// @return player5 Player entered the tile before player4
    /// @return wildlife_level The remaining level of wildlife that the tile contains
    /// @return resource1_amount The remaining amount of resource1_asset that the tile contains
    /// @return resource2_amount The remaining amount of resource2_asset that the tile contains
    /// @return resource3_amount The remaining amount of resource3_asset that the tile contains
    function getTileDataDynamic(uint32 skip, uint32 take) 
        public virtual override view 
        returns (
            address[] memory owner,
            address[] memory player1,
            address[] memory player2,
            address[] memory player3,
            address[] memory player4,
            address[] memory player5,
            uint128[] memory wildlife_level,
            uint[] memory resource1_amount,
            uint[] memory resource2_amount,
            uint[] memory resource3_amount
        )
    {
        owner = new address[](take);
        player1 = new address[](take);
        player2 = new address[](take);
        player3 = new address[](take);
        player4 = new address[](take);
        player5 = new address[](take);
        wildlife_level = new uint128[](take);
        resource1_amount = new uint[](take);
        resource2_amount = new uint[](take);
        resource3_amount = new uint[](take);

        uint32 index = skip;
        for (uint32 i = 0; i < take; i++)
        {
            try IERC721Upgradeable(titleDeedContract).ownerOf(index + 1) 
                returns (address ownerOfResult)
            {
                owner[i] = ownerOfResult;
            } 
            catch (bytes memory)
            {
                owner[i] = address(0);
            }

            player1[i] = tileData[index].lastEnteredPlayer;
            player2[i] = playerData[player1[i]].chain_prev;
            player3[i] = playerData[player2[i]].chain_prev;
            player4[i] = playerData[player3[i]].chain_prev;
            player5[i] = playerData[player4[i]].chain_prev;

            wildlife_level[i] = tileData[index].wildlife.level;

            if (tileData[index].resources.length > 0)
            {
                resource1_amount[i] = tileData[index].resources[0].amount;
            }

            if (tileData[index].resources.length > 1)
            {
                 resource2_amount[i] = tileData[index].resources[1].amount;
            }

            if (tileData[index].resources.length > 2)
            {
                 resource3_amount[i] = tileData[index].resources[2].amount;
            }

            index++;
        }
    }


    /// @dev Batch operation to set tiles
    /// @param indices Indices of the tiles
    /// @param values Tile values that are used to create the mesh
    /// @param wildlife_creature Wildlife (type)
    /// @param wildlife_level Wildlife (level)
    /// @param resource_assets Natural resources (asset token addresses)
    /// @param resource_amounts Natural resources (amounts)
    function setTiles(uint32[] memory indices, uint8[12][] memory values, bytes32[] memory wildlife_creature, uint64[] memory wildlife_level, address[][] memory resource_assets, uint[][] memory resource_amounts) 
        public onlyOwner 
    {
        for (uint i = 0; i < indices.length; i++)
        {
            _setTile(
                indices[i], 
                values[i], 
                wildlife_creature[i], 
                wildlife_level[i], 
                resource_assets[i], 
                resource_amounts[i]);
        }
    }


    /// @dev Retrieve players from the tile with tile
    /// @param tileIndex Retrieve players from this tile
    /// @param start Starting point in the chain
    /// @param max Max amount of players to return
    function getPlayers(uint32 tileIndex, address start, uint max)
        public virtual override view  
        returns (
            address[] memory players
        )
    {
        players = new address[](max);

        // No players
        if (start == address(0) && tileData[tileIndex].lastEnteredPlayer == address(0))
        {
            return players;
        }

        // Set first player
        players[0] = start == address(0) 
            ? tileData[tileIndex].lastEnteredPlayer : start;

        // Walk chain
        for (uint i = 1; i < max; i++)
        {
            address prev = playerData[players[i - 1]].chain_prev;
            if (prev == address(0))
            {
                return players; // Reached the end
            }

            players[i] = prev;
        }
    }


    /// @dev Retrieve data that's attached to players
    /// @param accounts The players to retreive player data for
    /// @return location_mapName The map that the player is at
    /// @return location_tileIndex The tile that the player is at
    /// @return location_arrival The datetime on wich the player arrives at `location_tileIndex`
    /// @return movement Player movement budget
    function getPlayerData(address[] memory accounts)
        public virtual override view 
        returns (
            bytes32[] memory location_mapName,
            uint32[] memory location_tileIndex,
            uint[] memory location_arrival,
            uint[] memory movement
        )
    {
        uint length = accounts.length;
        movement = new uint[](length);
        location_tileIndex = new uint32[](length);
        location_arrival = new uint[](length);
        location_mapName = new bytes32[](length);

        for (uint i = 0; i < length; i++)
        {
            movement[i] = playerData[accounts[i]].movement;
            location_tileIndex[i] = playerData[accounts[i]].location_tileIndex;
            location_arrival[i] = playerData[accounts[i]].location_arrival;
            location_mapName[i] = mapsIndex[tiles[location_tileIndex[i]].mapIndex];
        }
    }


    /// @dev Returns data about the players ability to interact with wildlife 
    /// @param account Player to retrieve data for
    /// @param creature Type of wildlife to test for
    /// @return canInteract True if `account` can interact with 'creature'
    /// @return difficulty Based of level of wildlife and activity
    function getPlayerWildlifeData(address account, bytes32 creature) 
        public virtual override view 
        returns (
            bool canInteract,
            uint difficulty 
        )
    {
        canInteract = _playerCanInteract(account) && tileData[playerData[account].location_tileIndex].wildlife.creature == creature;
        difficulty = (WILDLIFE_MAX_LEVEL - tileData[playerData[account].location_tileIndex].wildlife.level) * WILDLIFE_DIFFICULTY_MULTIPLIER;
    }


    /// @dev Returns data about the players ability to interact with resources 
    /// @param account Player to retrieve data for
    /// @param resource Type of resource to test for
    /// @return uint the amount of `resource` that can be minted
    function getPlayerResourceData(address account, ResourceType resource) 
        public virtual override view 
        returns (uint)
    {
        if (!_playerCanInteract(account))
        {
            return 0; // Traveling
        }

        // Fish
        if (resource == ResourceType.Fish)
        {
            uint32 tileIndex = playerData[account].location_tileIndex;
            return _tileIsUnderwater(tileIndex) 
                ? (tiles[tileIndex].waterLevel - tiles[tileIndex].elevation) * RESOURCE_UNIT // Deeper water = more fish
                : RESOURCE_UNIT; // Small water body
        }

        // Meat
        if (resource == ResourceType.Meat)
        {
            uint32 tileIndex = playerData[account].location_tileIndex;
            if (_tileIsUnderwater(tileIndex))
            {
                return 0;
            }

            return tileData[tileIndex].wildlife.level * RESOURCE_UNIT;
        }

        // Fruit || Wood
        if (resource == ResourceType.Fruit || resource == ResourceType.Wood)
        {
            uint32 tileIndex = playerData[account].location_tileIndex;
            if (_tileIsUnderwater(tileIndex))
            {
                return 0;
            }

            return tiles[tileIndex].vegitationLevel * RESOURCE_UNIT;
        }
        
        // Stone
        if (resource == ResourceType.Stone)
        {
            uint32 tileIndex = playerData[account].location_tileIndex;
            if (_tileIsUnderwater(tileIndex))
            {
                return 0;
            }

            return tiles[tileIndex].rockLevel * RESOURCE_UNIT;
        }

        // Sand
        if (resource == ResourceType.Sand)
        {
            if (_tileIsUnderwater(playerData[account].location_tileIndex))
            {
                return 0;
            }

            return RESOURCE_UNIT;
        }

        return 0;
    }


    /// @dev Find out if a player with `account` has entred 
    /// @param account Player to test against
    /// @return Wether `account` has entered or not
    function playerHasEntered(address account) 
        public virtual override view 
        returns (bool)
    {
        return _playerHasEntered(account);
    }


    /// @dev Player entry point that adds the player to the Genesis map
    function playerEnter()
        public virtual override 
        onlyExistingTile(PLAYER_START_POSITION)
    {
        assert(block.timestamp > 0);
        require(!_playerHasEntered(msg.sender), "CryptopiaMap: Invalid account (already entered)");
        require(IPlayerRegister(playerRegisterContract)
            .isRegistered(msg.sender), "CryptopiaMap: Invalid account (unknown player)");
        
        // TEMP - Move to ship / account
        playerData[msg.sender].movement = 25;

        _playerEnterTile(msg.sender, PLAYER_START_POSITION, block.timestamp);

        // Emit
        emit PlayerEnterMap(mapsIndex[0], PLAYER_START_POSITION, msg.sender, block.timestamp);
    }


    /// @dev Moves a player from one tile to another
    /// @param path Tiles that represent a route
    function playerMove(uint32[] memory path)
        public virtual override 
    {
        require(_playerHasEntered(msg.sender), "CryptopiaMap: Player has not entered");

        // Enforce not-traveling state
        require(playerData[msg.sender].location_arrival <= block.timestamp, "CryptopiaMap: Player is still traveling");

        (bool isValidPath, uint turns) = _traversePath(path, msg.sender);
        require(isValidPath, "CryptopiaMap: Invalid path");

        // Travel to destination
        uint arrival = block.timestamp + turns * MOVEMENT_TURN_DURATION;
        _playerMove(msg.sender, path[path.length - 1], arrival);

        // Emit
        emit PlayerMove(path[0], path[path.length - 1], msg.sender, arrival);
    }


    /// @dev Gets the cached movement costs to travel between `fromTileIndex` and `toTileIndex` or zero if no cache exists
    /// @param fromTileIndex Origin tile
    /// @param toTileIndex Destination tile
    /// @return uint Movement costs
    function getPathSegmentFromCache(uint32 fromTileIndex, uint32 toTileIndex)
        public virtual override view
        returns (uint)
    {
        return pathCache[_packPathSegment(fromTileIndex, toTileIndex)];
    }


    /*
     * Internal functions
     */
    /// @dev Returns true if an initialized tile with `index` exists in a finalized map
    /// @param index Position of the tile in the tiles array
    /// @return bool Wether a tile at `index` exists
    function _tileExists(uint32 index)
        internal view 
        returns (bool)
    {
        return tiles[index].initialized && maps[mapsIndex[tiles[index].mapIndex]].finalized;
    }


    /// @dev Returns true if tile at `index` is underwater (waterLevel > elevation)
    /// @param index Position of the tile in the tiles array
    /// @return bool Wether the tile at `index` is underwater
    function _tileIsUnderwater(uint32 index)
        internal view 
        returns (bool)
    {
        return tiles[index].waterLevel > tiles[index].elevation;
    }


    /// @dev Tests if `a` and `b` are neighbors
    /// @param a Left hand tile index
    /// @param b Right hand tile index
    /// @return bool Wether a and b are neighbors
    function _tileIsNeighbor(uint32 a, uint32 b) 
        internal view 
        returns (bool) 
    {
        Map storage map = maps[mapsIndex[tiles[a].mapIndex]];
        (uint32 x, uint32 z) = (a % map.sizeX, a / map.sizeX);

        // West
        if (x > 0 && b == a - 1)
        {
            return true;
        }

        // East
        if (x < map.sizeX - 1 && b == a + 1)
        {
            return true;
        }

        // Even
        if (z % 2 == 0)
        {
            // South
            if (z > 0)
            {
                // South-East
                if (b == a - map.sizeX)
                {
                    return true;
                }

                // South-West
                if (x > 0 && b == a - (map.sizeX + 1))
                {
                    return true;
                }
            }
            
            // North
            if (z < map.sizeZ - 1)
            {
                // North-East
                if (b == a + map.sizeX)
                {
                    return true;
                }

                // North-West
                if (x > 0 && b == a + map.sizeX - 1)
                {
                    return true;
                }
            }
        }

        // Odd
        else 
        {
            // South
            if (z > 0)
            {
                // South-West
                if (b == a - map.sizeX)
                {
                    return true;
                }

                // South-East
                if (x < map.sizeX - 1 && b == a - (map.sizeX - 1))
                {
                    return true;
                }
            }
            
            // North
            if (z < map.sizeZ - 1)
            {
                // North-West
                if (b == a + map.sizeX)
                {
                    return true;
                }

                // North-East
                if (x < map.sizeX - 1 && b == a + map.sizeX + 1)
                {
                    return true;
                }
            }
        }

        return false;
    }


    /// @dev Returns the edge type between `elevationA` and `elevationB` 
    /// @param elevationA Left hand elevation
    /// @param elevationB Right hand elevation
    /// @return EdgeType {Flat, Slope, Cliff}
    function _getEdgeType(uint8 elevationA, uint8 elevationB) 
        internal pure 
        returns (MapEnums.EdgeType) 
    {
        if (elevationA == elevationB)
        {
            return MapEnums.EdgeType.Flat;
        }

        if (elevationA == elevationB + 1 || elevationB == elevationA + 1)
        {
            return MapEnums.EdgeType.Slope;
        }

        return MapEnums.EdgeType.Cliff;
    }


    /// @dev Populate (or override) the tile at `index` with `values`. The `index` is used to determin 
    /// the map to which the tile belongs as well as it's cooridinates within that map.
    /// @param index Index of the tile
    /// @param values Tile values
    /// @param wildlife_creature Wildlife (type)
    /// @param wildlife_level Wildlife (level)
    /// @param resource_assets Natural resources (asset token addresses)
    /// @param resource_amounts Natural resources (amounts)
    function _setTile(uint32 index, uint8[12] memory values, bytes32 wildlife_creature, uint128 wildlife_level, address[] memory resource_assets, uint[] memory resource_amounts) 
        internal
    {
        Map storage map = maps[mapsIndex[mapsIndex.length - 1]];
        uint32 minIndex = map.tileStartIndex;
        uint32 maxIndex = minIndex + map.sizeX * map.sizeZ;

        require(!maps[mapsIndex[mapsIndex.length - 1]].finalized, "CryptopiaMap: No map under construction");
        require(index >= minIndex && index < maxIndex, "CryptopiaMap: Tile index out of range");

        if (!tiles[index].initialized)
        {
            initializedTileCount++;
        }

        tiles[index].initialized = true;
        tiles[index].mapIndex = uint16(mapsIndex.length - 1);
        tiles[index].terrainPrimaryIndex = values[0];
        tiles[index].terrainSecondaryIndex = values[1];
        tiles[index].terrainBlendFactor = values[2];
        tiles[index].terrainOrientation = values[3];
        tiles[index].terrainElevation = values[4];
        tiles[index].elevation = values[5];
        tiles[index].waterLevel = values[6];
        tiles[index].vegitationLevel = values[7];
        tiles[index].rockLevel = values[8];
        tiles[index].incommingRiverData = values[9];
        tiles[index].outgoingRiverData = values[10];
        tiles[index].roadFlags = values[11];

        if (wildlife_level > 0) 
        {
            tileData[index].wildlife = WildlifeData({ 
                creature: wildlife_creature,
                level: wildlife_level,
                initialLevel: wildlife_level
            });
        }

        for (uint i = 0; i < resource_assets.length; i++)
        {
            tileData[index].resources.push(
                ResourceData({ 
                    asset: resource_assets[i],
                    amount: resource_amounts[i],
                    initialAmount: resource_amounts[i]
                })
            );
        }
    }


    /// @dev Traverse the path and validate that account is allowed to travel path
    /// @param path Route of tiles to validate
    /// @param account Player to validate against
    /// @return isValid True if `account` can travel `path`
    /// @return turns The amount of turns to reach destination
    function _traversePath(uint32[] memory path, address account) 
        internal  
        returns (bool isValid, uint turns)
    {
        // Validate path length
        if (path.length < 2)
        {
            return (false, 0);
        }

        // Validate player start location
        if (path[0] != playerData[account].location_tileIndex)
        {
            return (false, 0);
        }

        // Validate segments
        uint movementCostFromOrigin; 
        for (uint i = 1; i < path.length; i++)
        {
            // Validate segment in the same map as origin
            if (tiles[path[0]].mapIndex != tiles[path[i]].mapIndex)
            {
                return (false, 0);
            }

            // Movement cost for current tile
            uint movementCost;
            (isValid, movementCost) = _traversePathSegment(
                path[i - 1], path[i]);

            if (!isValid)
            {
                return (false, 0);
            }

            movementCostFromOrigin += movementCost;

            // Next turn
            uint nextTurn = (movementCostFromOrigin - 1) / playerData[account].movement;
            if (nextTurn > turns)
            {
                movementCostFromOrigin = nextTurn * playerData[account].movement + movementCost;
                turns = nextTurn;
            }
        }

        turns += 1; // Convert to non-zero based
        isValid = true;
    }


    /// @dev Calculate and validate moving from `fromTileIndex` to `toTileIndex`
    /// @param fromTileIndex Tile that we're traveling from
    /// @param toTileIndex Tile that we're traveling to
    /// @return isValid True if `account` can travel from `fromTileIndex` to `toTileIndex`
    /// @return movementCost The amount movement it costs to travel from `fromTileIndex` to `toTileIndex`
    function _traversePathSegment(uint32 fromTileIndex, uint32 toTileIndex)
        internal  
        returns (bool isValid, uint movementCost)
    {
        // Try get from cache
        movementCost = pathCache[_packPathSegment(fromTileIndex, toTileIndex)];
        if (movementCost > 0)
        {
            return (true, movementCost);
        }

        // Validate segments are neigbors
        if (!_tileIsNeighbor(fromTileIndex, toTileIndex))
        {
            return (false, 0);
        }

        // Land 
        if (!_tileIsUnderwater(fromTileIndex) && !_tileIsUnderwater(toTileIndex))
        {
            MapEnums.EdgeType edgeType = _getEdgeType(
                tiles[fromTileIndex].elevation, tiles[toTileIndex].elevation);
            if (edgeType == MapEnums.EdgeType.Cliff)
            {
                return (false, 0); // Can't move over cliffs
            }

            // Base land movement costs
            movementCost += edgeType == MapEnums.EdgeType.Flat ? 
                MOVEMENT_COST_LAND_FLAT : MOVEMENT_COST_LAND_SLOPE;

            // Add vegitation movement penalty
            movementCost += tiles[toTileIndex].vegitationLevel + tiles[toTileIndex].rockLevel;
        }

        // Water
        else if (_tileIsUnderwater(fromTileIndex) && _tileIsUnderwater(toTileIndex))
        {
            movementCost += MOVEMENT_COST_WATER;
        }

        // Disembark
        else if (_tileIsUnderwater(fromTileIndex))
        {
            MapEnums.EdgeType edgeType = _getEdgeType(
                tiles[fromTileIndex].waterLevel, tiles[toTileIndex].elevation);
            if (edgeType == MapEnums.EdgeType.Cliff)
            {
                return (false, 0); // Can't embark from cliffs
            }

            movementCost += MOVEMENT_COST_WATER_EMBARK_DISEMBARK;
        }

        // Embark
        else 
        {
            MapEnums.EdgeType edgeType = _getEdgeType(
                tiles[fromTileIndex].elevation, tiles[toTileIndex].waterLevel);
            if (edgeType == MapEnums.EdgeType.Cliff)
            {
                return (false, 0); // Can't embark from cliffs
            }

            movementCost += MOVEMENT_COST_WATER_EMBARK_DISEMBARK;
        }

        // Cache result
        pathCache[_packPathSegment(fromTileIndex, toTileIndex)] = movementCost;
        isValid = true;
    }


    /// @dev Pack the index of `a` and `b` into a single uint64
    /// @param a Left hand tile index
    /// @param b Right hand tile index
    /// @return Packed uint64
    function _packPathSegment(uint32 a, uint32 b)
        internal pure 
        returns (uint64)
    {
        return a < b ? a | (b << 32) : b | (a << 32);
    }


    /// @dev Checks the enter and travel state
    /// @param account Player that's being checked
    /// @return bool True if the player can interact with the game
    function _playerCanInteract(address account) internal view returns (bool)
    {
        return _playerHasEntered(account) && !_playerIsTraveling(account);
    } 


    /// @dev Returns true if player is traveling
    /// @param account Player's account
    /// @return bool True if player is currently traveling
    function _playerIsTraveling(address account) 
        internal view 
        returns (bool)
    {
        return playerData[account].location_arrival > block.timestamp;
    }


    /// @dev Find out if a player with `account` has entred 
    /// @param account Player to test against
    /// @return Wether `account` has entered or not
    function _playerHasEntered(address account) 
        internal view 
        returns (bool)
    {
        return playerData[account].location_arrival > 0;
    }


    /// @dev Move `account` to `tileIndex` by exiting the previous tile and entering the next
    /// @param account Player being moved
    /// @param tileIndex Tile that the player is moved to
    /// @param arrival The time at wich the player arrives at the tile
    function _playerMove(address account, uint32 tileIndex, uint arrival)
        internal 
    {
        // Exit
        _playerExitTile(account);

        // Enter
        _playerEnterTile(account, tileIndex, arrival);
    }


    /// @dev Remove `account` from `tileIndex` 
    /// @param account Player thats exiting the tile
    function _playerExitTile(address account)
        internal 
    {
        if (playerData[account].chain_next == address(0))
        {
            // Fix chain (replace head)
            tileData[playerData[account].location_tileIndex].lastEnteredPlayer = playerData[account].chain_prev;
            playerData[playerData[account].chain_prev].chain_next = address(0); // Our prev becomes new head
            // No need for (playerData[account].chain_prev = address(0);) as long as _playerEnterTile(..) is always called after _playerExitTile(..)
        }
        else 
        {
            // Fix chain (connect prev to next)
            playerData[playerData[account].chain_next].chain_prev = playerData[account].chain_prev;
            playerData[playerData[account].chain_prev].chain_next = playerData[account].chain_next;
        }
    }


    /// @dev Add `account` to `tileIndex` without removing `account` from a previous tile (!)
    /// @param account Player thats entering the tile
    /// @param tileIndex Tile that the player is entering
    /// @param arrival Timestamp on which the player arrives at the tile
    function _playerEnterTile(address account, uint32 tileIndex, uint arrival)
        internal 
    {
        playerData[account].location_tileIndex = tileIndex;
        playerData[account].location_arrival = arrival;
        playerData[account].chain_next = address(0);
        playerData[account].chain_prev = tileData[tileIndex].lastEnteredPlayer;
        playerData[tileData[tileIndex].lastEnteredPlayer].chain_next = account; 
        tileData[tileIndex].lastEnteredPlayer = account;
    }
}