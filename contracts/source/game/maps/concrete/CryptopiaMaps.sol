// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "../IMaps.sol";
import "../types/MapEnums.sol";
import "../../assets/types/AssetEnums.sol";
import "../../players/IPlayerRegister.sol";
import "../../players/errors/PlayerErrors.sol";
import "../../../tokens/ERC721/deeds/ITitleDeeds.sol";
import "../../../tokens/ERC721/ships/IShips.sol";

/// @title Cryptopia Maps
/// @dev Contains world data and player positions
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaMaps is Initializable, AccessControlUpgradeable, IMaps {

    struct Map 
    {
        /// @dev True if the map is created
        bool initialized;

        /// @dev True if the map is final and immutable
        bool finalized;

        /// @dev Number of tiles in the x direction
        uint16 sizeX;

        /// @dev Number of tiles in the z direction
        uint16 sizeZ;

        /// @dev The index of the first tile in the map 
        /// @notice Multiple maps exist but the tiles are numbered sequentially
        uint16 tileStartIndex;
    }

    struct Tile 
    {
        /// @dev True if the tile is created
        bool initialized;

        /// @dev Index of the map that the tile belongs to
        uint16 mapIndex;

        /// @dev Landmass or island index (zero signals water tile)
        /// @notice Landmasses are global and can span multiple maps
        uint16 group;

        /// @dev The type of biome 
        /// {None, Plains, Grassland, Forest, RainForest, Desert, Tundra, Swamp, Reef}
        Biome biome;

        /// @dev The type of terrain 
        /// {Flat, Hills, Mountains, Water, Seastead}
        Terrain terrain;

        /// @dev The elevation of the terrain (seafloor in case of sea tile)
        uint8 elevation;

        /// @dev The water level of the tile 
        /// @notice Water level minus elevation equals the depth of the water
        uint8 waterLevel;

        /// @dev The level of vegitation that the tile contains
        uint8 vegitationLevel;

        /// @dev The size of rocks that the tile contains
        uint8 rockLevel;

        /// @dev The amount of wildlife that the tile contains
        uint8 wildlifeLevel;

        /// @dev Flags that indicate the presence of a river on the tile's hex edges
        /// @notice 0 = NW, 
        uint8 riverFlags; 

        /// @dev Indicates the presence of a road on the tile
        /// @notice Roads remove the movement penalty for hills
        bool hasRoad;

        /// @dev Indicates the presence of a lake on the tile
        /// @notice Lakes impose a movement penalty
        bool hasLake;
    }

    /// @dev Tile meta data
    struct TileData 
    {
        /// @dev Player that most recently entered the tile 
        address lastEnteredPlayer;

        /// @dev Natural resources
        mapping (ResourceType => ResourceData) resources;
        ResourceType[] resourcesIndex;
    }

    /// @dev Resources can be attached to tiles
    struct ResourceData 
    {
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

        /// @dev Player movement budget
        uint16 movement;

        /// @dev Tile that the player is currently on
        uint16 location_tileIndex;

        /// @dev When the player arrives at `tileIndex`
        uint64 location_arrival;

        /// @dev Tiles that make up the route that the player is currently traveling or last traveled
        bytes32 location_route;
    }


    /**
     * Roles
     */
    bytes32 public constant SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    uint16 constant private MAP_MAX_SIZE = 4800;
    uint16 constant private PATH_MAX_LENGTH = 31;
    uint16 constant private PLAYER_START_POSITION = 0;
    uint16 constant private PLAYER_START_MOVEMENT = 25;
    uint64 constant private MOVEMENT_TURN_DURATION = 60; // 1 min
    uint16 constant private MOVEMENT_COST_LAND_FLAT = 11;
    uint16 constant private MOVEMENT_COST_LAND_SLOPE = 19;
    uint16 constant private MOVEMENT_COST_WATER = 5;
    uint16 constant private MOVEMENT_COST_WATER_EMBARK_DISEMBARK = 25; 
    uint8 constant private WILDLIFE_MAX_LEVEL = 3;

    /// @dev Refs
    address public playerRegisterContract;
    address public assetRegisterContract;
    address public titleDeedContract;
    address public shipContract;
    address public tokenContract;

    /// @dev Maps
    mapping(bytes32 => Map) public maps;
    bytes32[] private mapsIndex;

    /// @dev Tiles
    mapping(uint16 => Tile) public tiles;
    mapping(uint16 => TileData) public tileData;
    uint public initializedTileCount;

    /// @dev player => PlayerData
    mapping(address => PlayerData) public playerData;
  
    /// @dev a | (b << 16) => movementCost
    mapping (uint32 => uint) public pathCache;


    /**
     * Events
     */
    /// @dev Emitted when a map is created and finalized
    /// @param name Unique name of the map
    /// @param index Index of the map (there are multiple maps)
    event CreateMap(bytes32 indexed name, uint16 index);

    /// @dev Emitted when a player entered a map
    /// @param map Map that the player entered
    /// @param tile Tile that the player entered
    /// @param player Player that entered the map
    /// @param arrival The datetime on wich the player arrives at `tile`
    event PlayerEnterMap(bytes32 indexed map, uint16 indexed tile, address indexed player, uint64 arrival);

    /// @dev Emitted when a player entered a tile
    /// @param origin Tile that the player originated from
    /// @param destination Tile that the player entered
    /// @param route The route that the player traveled
    /// @param player Player that entered the tile
    /// @param arrival The datetime on wich the player arrives at `destinationTile`
    event PlayerMove(uint16 indexed origin, uint16 indexed destination, bytes32 route, address indexed player, uint arrival);


    /**
     * Errors
     */
    /// @dev Emits if a map name is not unique during map creation
    error MapNameAlreadyUsed();

    /// @dev Emits if an attempt is made to create a map that exceeds the maximum size
    error MapSizeExceedsLimit();

    /// @dev Emits if an attempt is made to create a new map while another is still under construction
    error MapUnderConstruction();

    /// @dev Emits if there is no map under construction
    error MapUnderConstructionNotFound();

    /// @dev Emits if the tile set for the last created map is incomplete
    error MapUnderConstructionIncomplete();

    /// @dev Emits if an attempt is made to set a tile that is out of bounds of the map under construction
    error TileIndexOutOfBounds();

    /// @dev Emits if the path is invalid
    error PathInvalid();

    /// @dev Emits if the player has not entered the map
    error PlayerNotEnteredMap();

    /// @dev Emits if a player attempts to enter a map while already on a map
    error PlayerAlreadyEnteredMap();


    /** 
     * Public functions
     */
    /// @dev Initialize
    /// @param _playerRegisterContract Contract responsible for players
    /// @param _assetRegisterContract Contract responsible for assets
    /// @param _titleDeedContract Contract responsible for land ownership
    /// @param _shipContract Contract for ships
    /// @param _tokenContract CRT token
    function initialize(
        address _playerRegisterContract, 
        address _assetRegisterContract,
        address _titleDeedContract, 
        address _shipContract,
        address _tokenContract) 
        public initializer 
    {
        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

        // Set refs
        playerRegisterContract = _playerRegisterContract;
        assetRegisterContract = _assetRegisterContract;
        titleDeedContract = _titleDeedContract;
        shipContract = _shipContract;
        tokenContract = _tokenContract;
    }


    /// @dev Retreives the amount of maps created.
    /// @return count Number of maps created.
    function getMapCount() 
        public virtual view 
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
        public virtual view 
        returns (
            bool initialized, 
            bool finalized, 
            uint16 sizeX, 
            uint16 sizeZ, 
            uint16 tileStartIndex,
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
    function createMap(bytes32 name, uint16 sizeX, uint16 sizeZ) 
        public onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        // Check if map is already created
        if (maps[name].initialized)
        {
            revert MapNameAlreadyUsed();
        }

        // Check if map size exceeds limit
        if (sizeX * sizeZ > MAP_MAX_SIZE)
        {
            revert MapSizeExceedsLimit();
        }

        // Check for overflow
        assert(mapsIndex.length == 0 || mapsIndex.length < 2**16);

        uint16 tileStartIndex;
        if (mapsIndex.length > 0)
        {
            Map storage prevMap = maps[mapsIndex[mapsIndex.length - 1]];

            // Check if previous map is finalized
            if (!prevMap.finalized)
            {
                revert MapUnderConstruction();
            }

            tileStartIndex = prevMap.tileStartIndex + prevMap.sizeX * prevMap.sizeZ;
        }
        else 
        {
            tileStartIndex = 0;
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
        public onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        // Check if map is under construction
        if (mapsIndex.length == 0)
        {
            revert MapUnderConstructionNotFound();
        }

        // Get last created map
        uint16 index = uint16(mapsIndex.length - 1);
        Map storage map = maps[mapsIndex[index]];

        // Check if map is under construction
        if (map.finalized)
        {
            revert MapUnderConstructionNotFound();
        }

        // Check if all tiles are initialized
        if (initializedTileCount != map.sizeX * map.sizeZ)
        {
            revert MapUnderConstructionIncomplete();
        }

        map.finalized = true;

        // Increase title deeds limit
        ITitleDeeds(titleDeedContract)
            .increaseLimit(initializedTileCount);
        initializedTileCount = 0;

        // Emit created event
        emit CreateMap(mapsIndex[index], index);
    }

      
    /// @dev Retrieve a tile
    /// @param tileIndex Index of hte tile to retrieve
    /// @return group The index of the landmass or island that the tile belongs to
    /// @return biome The type of biome {None, Plains, Grassland, Forest, RainForest, Desert, Tundra, Swamp, Reef}
    /// @return terrain The type of terrain {Flat, Hills, Mountains, Water, Seastead}
    /// @return elevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return waterLevel The water level of the tile
    /// @return vegitationLevel The level of vegitation that the tile contains
    /// @return rockLevel The size of rocks that the tile contains
    /// @return wildlifeLevel The amount of wildlife that the tile contains
    /// @return riverFlags Flags that indicate the presence of a river on the tile's hex edges
    /// @return hasRoad Indicates the presence of a road on the tile
    /// @return hasLake Indicates the presence of a lake on the tile
    function getTile(uint16 tileIndex) 
        public virtual override view 
        returns (
            uint16 group,
            Biome biome,
            Terrain terrain,
            uint8 elevation,
            uint8 waterLevel,
            uint8 vegitationLevel,
            uint8 rockLevel,
            uint8 wildlifeLevel,
            uint8 riverFlags,
            bool hasRoad,
            bool hasLake)
    {
        group = tiles[tileIndex].group;
        biome = tiles[tileIndex].biome;
        terrain = tiles[tileIndex].terrain;
        elevation = tiles[tileIndex].elevation;
        waterLevel = tiles[tileIndex].waterLevel;
        elevation = tiles[tileIndex].elevation;
        vegitationLevel = tiles[tileIndex].vegitationLevel;
        rockLevel = tiles[tileIndex].rockLevel;
        wildlifeLevel = tiles[tileIndex].wildlifeLevel;
        riverFlags = tiles[tileIndex].riverFlags;
        hasRoad = tiles[tileIndex].hasRoad;
        hasLake = tiles[tileIndex].hasLake;
    }


    /// @dev Retrieve a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return group The index of the landmass that the tile belongs to
    /// @return biome The type of biome {None, Plains, Grassland, Forest, RainForest, Desert, Tundra, Swamp, Reef}
    /// @return terrain The type of terrain {Flat, Hills, Mountains, Water, Seastead}
    /// @return elevation The elevation of the terrain (seafloor in case of sea tile)
    /// @return waterLevel The water level of the tile
    /// @return vegitationLevel The level of vegitation that the tile contains
    /// @return rockLevel The size of rocks that the tile contains
    /// @return wildlifeLevel The amount of wildlife that the tile contains
    /// @return riverFlags Flags that indicate the presence of a river on the tile's hex edges
    /// @return hasRoad Indicates the presence of a road on the tile
    /// @return hasLake Indicates the presence of a lake on the tile
    function getTiles(uint16 skip, uint16 take) 
        public virtual view  
        returns (
            uint16[] memory group,
            Biome[] memory biome,
            Terrain[] memory terrain,
            uint8[] memory elevation,
            uint8[] memory waterLevel,
            uint8[] memory vegitationLevel,
            uint8[] memory rockLevel,
            uint8[] memory wildlifeLevel,
            uint8[] memory riverFlags,
            bool[] memory hasRoad,
            bool[] memory hasLake
        )
    {
        group = new uint16[](take);
        biome = new Biome[](take);
        terrain = new Terrain[](take);
        elevation = new uint8[](take);
        waterLevel = new uint8[](take);
        vegitationLevel = new uint8[](take);
        rockLevel = new uint8[](take);
        wildlifeLevel = new uint8[](take);
        riverFlags = new uint8[](take);
        hasRoad = new bool[](take);
        hasLake = new bool[](take);

        uint16 index = skip;
        for (uint16 i = 0; i < take; i++)
        {
            group[i] = tiles[index].group;
            biome[i] = tiles[index].biome;
            terrain[i] = tiles[index].terrain;
            elevation[i] = tiles[index].elevation;
            waterLevel[i] = tiles[index].waterLevel;
            vegitationLevel[i] = tiles[index].vegitationLevel;
            rockLevel[i] = tiles[index].rockLevel;
            wildlifeLevel[i] = tiles[index].wildlifeLevel;
            riverFlags[i] = tiles[index].riverFlags;
            hasRoad[i] = tiles[index].hasRoad;
            hasLake[i] = tiles[index].hasLake;
            index++;
        }
    }

    
    /// @dev Retrieve static data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return resource1 A type of asset that the tile contains
    /// @return resource2 A type of asset that the tile contains
    /// @return resource3 A type of asset that the tile contains
    /// @return resource1_initialAmount The amount of resource1 the tile contains
    /// @return resource2_initialAmount The amount of resource2 the tile contains
    /// @return resource3_initialAmount The amount of resource3 the tile contains
    function getTileDataStatic(uint16 skip, uint16 take) 
        public virtual view 
        returns (
            ResourceType[] memory resource1,
            ResourceType[] memory resource2,
            ResourceType[] memory resource3,
            uint[] memory resource1_initialAmount,
            uint[] memory resource2_initialAmount,
            uint[] memory resource3_initialAmount)
    {
        resource1 = new ResourceType[](take);
        resource2 = new ResourceType[](take);
        resource3 = new ResourceType[](take);
        resource1_initialAmount = new uint[](take);
        resource2_initialAmount = new uint[](take);
        resource3_initialAmount = new uint[](take);

        uint16 index = skip;
        for (uint16 i = 0; i < take; i++)
        {   
            if (tileData[index].resourcesIndex.length > 0)
            {
                resource1[i] = tileData[index].resourcesIndex[0];
                resource1_initialAmount[i] = tileData[index].resources[resource1[i]].initialAmount;
            }

            if (tileData[index].resourcesIndex.length > 1)
            {
                resource2[i] = tileData[index].resourcesIndex[1];
                resource2_initialAmount[i] = tileData[index].resources[resource2[i]].initialAmount;
            }

            if (tileData[index].resourcesIndex.length > 2)
            {
                resource3[i] = tileData[index].resourcesIndex[2];
                resource3_initialAmount[i] = tileData[index].resources[resource3[i]].initialAmount;
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
    /// @return resource1_amount The remaining amount of resource1_asset that the tile contains
    /// @return resource2_amount The remaining amount of resource2_asset that the tile contains
    /// @return resource3_amount The remaining amount of resource3_asset that the tile contains
    function getTileDataDynamic(uint16 skip, uint16 take) 
        public virtual view 
        returns (
            address[] memory owner,
            address[] memory player1,
            address[] memory player2,
            address[] memory player3,
            address[] memory player4,
            address[] memory player5,
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
        resource1_amount = new uint[](take);
        resource2_amount = new uint[](take);
        resource3_amount = new uint[](take);

        uint16 index = skip;
        for (uint16 i = 0; i < take; i++)
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

            if (tileData[index].resourcesIndex.length > 0)
            {
                resource1_amount[i] = tileData[index].resources[tileData[index].resourcesIndex[0]].amount;
            }

            if (tileData[index].resourcesIndex.length > 1)
            {
                 resource2_amount[i] = tileData[index].resources[tileData[index].resourcesIndex[1]].amount;
            }

            if (tileData[index].resourcesIndex.length > 2)
            {
                 resource3_amount[i] = tileData[index].resources[tileData[index].resourcesIndex[2]].amount;
            }

            index++;
        }
    }


    /// @dev Batch operation to set tiles
    /// @param indices Indices of the tiles
    /// @param values Tile values that are used to create the mesh
    /// @param resources Natural resources {ResourceType} that the tile contains
    /// @param resources_amounts Natural resources {ResourceType} amounts that the tile contains
    function setTiles(uint16[] memory indices, Tile[] memory values, ResourceType[][] memory resources, uint[][] memory resources_amounts) 
        public onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < indices.length; i++)
        {
            _setTile(
                indices[i], 
                values[i], 
                resources[i], 
                resources_amounts[i]);
        }
    }


    /// @dev Retrieve players from the tile with tile
    /// @param tileIndex Retrieve players from this tile
    /// @param start Starting point in the chain
    /// @param max Max amount of players to return
    function getPlayers(uint16 tileIndex, address start, uint max)
        public virtual view  
        returns (
            address[] memory players)
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
    function getPlayerDatas(address[] memory accounts)
        public virtual view 
        returns (
            bytes32[] memory location_mapName,
            uint16[] memory location_tileIndex,
            uint64[] memory location_arrival,
            uint16[] memory movement)
    {
        uint length = accounts.length;
        location_mapName = new bytes32[](length);
        location_tileIndex = new uint16[](length);
        location_arrival = new uint64[](length);
        movement = new uint16[](length);

        for (uint i = 0; i < length; i++)
        {
            movement[i] = playerData[accounts[i]].movement;
            location_tileIndex[i] = playerData[accounts[i]].location_tileIndex;
            location_arrival[i] = playerData[accounts[i]].location_arrival;
            location_mapName[i] = mapsIndex[tiles[location_tileIndex[i]].mapIndex];
        }
    }


    /// @dev Retrieve data that's attached to player
    /// @param account The account to retreive player data for
    /// @return tileIndex The tile that the player is at
    /// @return canInteract Wether the player can interact with the tile
    function getPlayerData(address  account)
        public virtual override view 
        returns (
            uint16 tileIndex,
            bool canInteract)
    {
        tileIndex = playerData[account].location_tileIndex;
        canInteract = _playerCanInteract(account);
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
        public virtual  
    {
        // Assert that the block timestamp is set
        assert(block.timestamp > 0);
        
        // Check if player has already entered
        if (_playerHasEntered(msg.sender))
        {
            revert PlayerAlreadyEnteredMap();
        }
        
        // Check if player is registered
        if (!IPlayerRegister(playerRegisterContract).isRegistered(msg.sender))
        {
            revert PlayerNotRegistered(msg.sender);
        }

        // Setup player
        playerData[msg.sender].movement = PLAYER_START_MOVEMENT;
        _playerEnterTile(msg.sender, PLAYER_START_POSITION, uint64(block.timestamp));

        // Emit
        emit PlayerEnterMap(
            mapsIndex[0], PLAYER_START_POSITION, msg.sender, uint64(block.timestamp));
    }


    /// @dev Moves a player from one tile to another
    /// @param path Tiles that represent a route
    function playerMove(uint16[] memory path)
        public virtual  
    {
        // Enforce valid path
        if (path.length == 0 || path.length > PATH_MAX_LENGTH)
        {
            revert PathInvalid();
        }

        // Enforce player in map
        if (!_playerHasEntered(msg.sender))
        {
            revert PlayerNotEnteredMap();
        }

        // Enforce player not traveling
        PlayerData memory data = playerData[msg.sender];
        if (_playerIsTraveling(msg.sender))
        {
            revert PlayerIsTraveling(msg.sender, data.location_arrival);
        }

        (bool isValidPath, uint turns) = _traversePath(
            path, msg.sender);

        // Enforce valid path
        if (!isValidPath)
        {
            revert PathInvalid();
        }

        // Compute route
        data.location_route = bytes32(0);
        uint tileCount = 0; // Count of tiles actually included in route
        uint bitOffset = 16; // Start shifting from the 16th bit to leave space for length

        for (uint i = 0; i < path.length - 1; i += 2) 
        { 
            data.location_route |= bytes32(uint(path[i])) << bitOffset;
            bitOffset += 16; // Shift by 16 bits for the next tile
            tileCount++;
        }

        // Add the correct length at the beginning of the route
        data.location_route |= bytes32(tileCount);

        // Travel to destination
        uint64 arrival = uint64(block.timestamp + turns * MOVEMENT_TURN_DURATION);
        _playerMove(msg.sender, path[path.length - 1], arrival);

        // Emit
        emit PlayerMove(path[0], path[path.length - 1], data.location_route, msg.sender, arrival);
    }


    /// @dev Gets the cached movement costs to travel between `fromTileIndex` and `toTileIndex` or zero if no cache exists
    /// @param fromTileIndex Origin tile
    /// @param toTileIndex Destination tile
    /// @return uint Movement costs
    function getPathSegmentFromCache(uint16 fromTileIndex, uint16 toTileIndex)
        public virtual view
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
    function _tileExists(uint16 index)
        internal view 
        returns (bool)
    {
        return tiles[index].initialized && maps[mapsIndex[tiles[index].mapIndex]].finalized;
    }


    /// @dev Returns true if tile at `index` is underwater (waterLevel > elevation)
    /// @param index Position of the tile in the tiles array
    /// @return bool Wether the tile at `index` is underwater
    function _tileIsUnderwater(uint16 index)
        internal view 
        returns (bool)
    {
        return tiles[index].waterLevel > tiles[index].elevation;
    }


    /// @dev Tests if `a` and `b` are neighbors
    /// @param a Left hand tile index
    /// @param b Right hand tile index
    /// @return bool Wether a and b are neighbors
    function _tileIsNeighbor(uint16 a, uint16 b) 
        internal view 
        returns (bool) 
    {
        Map storage map = maps[mapsIndex[tiles[a].mapIndex]];
        (uint16 x, uint16 z) = (a % map.sizeX, a / map.sizeX);

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
        returns (EdgeType) 
    {
        if (elevationA == elevationB)
        {
            return EdgeType.Flat;
        }

        if (elevationA == elevationB + 1 || elevationB == elevationA + 1)
        {
            return EdgeType.Slope;
        }

        return EdgeType.Cliff;
    }


    /// @dev Populate (or override) the tile at `index` with `values`. The `index` is used to determin 
    /// the map to which the tile belongs as well as it's cooridinates within that map.
    /// @param index Index of the tile
    /// @param values Tile values
    /// @param resources Natural resources {ResourceType} that the tile contains
    /// @param resources_amounts Natural resources {ResourceType} amounts that the tile contains
    function _setTile(uint16 index, Tile memory values, ResourceType[] memory resources, uint[] memory resources_amounts) 
        internal
    {
        Map storage map = maps[mapsIndex[mapsIndex.length - 1]];
        uint16 minIndex = map.tileStartIndex;
        uint16 maxIndex = minIndex + map.sizeX * map.sizeZ;

        // Check if map is under construction
        if (maps[mapsIndex[mapsIndex.length - 1]].finalized)
        {
            revert MapUnderConstructionNotFound();
        }

        // Check if tile belongs to map under construction
        if (index < minIndex || index >= maxIndex)
        {
            revert TileIndexOutOfBounds();
        }

        if (!tiles[index].initialized)
        {
            initializedTileCount++;
        }

        tiles[index].initialized = true;
        tiles[index].mapIndex = uint16(mapsIndex.length - 1);
        tiles[index].biome = values.biome;
        tiles[index].terrain = values.terrain;
        tiles[index].elevation = values.elevation;
        tiles[index].waterLevel = values.waterLevel;
        tiles[index].vegitationLevel = values.vegitationLevel;
        tiles[index].rockLevel = values.rockLevel;
        tiles[index].wildlifeLevel = values.wildlifeLevel;
        tiles[index].riverFlags = values.riverFlags;
        tiles[index].hasRoad = values.hasRoad;
        tiles[index].hasLake = values.hasLake;

        for (uint i = 0; i < resources.length; i++)
        {
            tileData[index].resourcesIndex.push(resources[i]);
            tileData[index].resources[resources[i]] = ResourceData({ 
                amount: resources_amounts[i],
                initialAmount: resources_amounts[i]
            });
        }
    }


    /// @dev Traverse the path and validate that account is allowed to travel path
    /// @param path Route of tiles to validate
    /// @param account Player to validate against
    /// @return isValid True if `account` can travel `path`
    /// @return turns The amount of turns to reach destination
    function _traversePath(uint16[] memory path, address account) 
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
    function _traversePathSegment(uint16 fromTileIndex, uint16 toTileIndex)
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
            EdgeType edgeType = _getEdgeType(
                tiles[fromTileIndex].elevation, tiles[toTileIndex].elevation);
            if (edgeType == EdgeType.Cliff)
            {
                return (false, 0); // Can't move over cliffs
            }

            // Base land movement costs
            movementCost += edgeType == EdgeType.Flat ? 
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
            EdgeType edgeType = _getEdgeType(
                tiles[fromTileIndex].waterLevel, tiles[toTileIndex].elevation);
            if (edgeType == EdgeType.Cliff)
            {
                return (false, 0); // Can't embark from cliffs
            }

            movementCost += MOVEMENT_COST_WATER_EMBARK_DISEMBARK;
        }

        // Embark
        else 
        {
            EdgeType edgeType = _getEdgeType(
                tiles[fromTileIndex].elevation, tiles[toTileIndex].waterLevel);
            if (edgeType == EdgeType.Cliff)
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
    function _packPathSegment(uint16 a, uint16 b)
        internal pure 
        returns (uint16)
    {
        return a < b ? a | (b << 16) : b | (a << 16);
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
    function _playerMove(address account, uint16 tileIndex, uint64 arrival)
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
    function _playerEnterTile(address account, uint16 tileIndex, uint64 arrival)
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