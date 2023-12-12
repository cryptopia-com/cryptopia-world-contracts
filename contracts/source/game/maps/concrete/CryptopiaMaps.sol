// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import "../IMaps.sol";
import "../types/MapEnums.sol";
import "../types/MapDataTypes.sol";
import "../../assets/types/AssetEnums.sol";
import "../../players/IPlayerRegister.sol";
import "../../players/errors/PlayerErrors.sol";
import "../../players/control/IPlayerFreezeControl.sol";
import "../../../errors/ArgumentErrors.sol";
import "../../../tokens/ERC721/deeds/ITitleDeeds.sol";
import "../../../tokens/ERC721/ships/IShips.sol";

/// @title Cryptopia Maps
/// @dev Contains world data and player positions
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaMaps is Initializable, AccessControlUpgradeable, IMaps, IPlayerFreezeControl {

    /// @dev Tile data
    struct TileStaticData
    {
        /// @dev True if the tile is created
        bool initialized;

        /// @dev Index of the map that the tile belongs to
        uint16 mapIndex;

        /// @dev Landmass or island index (zero signals water tile)
        /// @notice Landmasses are global and can span multiple maps
        uint16 group;

        /// @dev Ranges from 0 to 100 and indicates the safety level of the tile 
        /// @notice 100 - safety for pirates
        uint8 safety; 

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

        /// @dev The level of vegetation that the tile contains
        uint32 vegetationLevel;

        /// @dev The size of rocks that the tile contains
        uint32 rockLevel;

        /// @dev The amount of wildlife that the tile contains
        uint32 wildlifeLevel;

        /// @dev Flags that indicate the presence of a river on the tile's hex edges
        /// @notice 0 = NW, 
        uint8 riverFlags; 

        /// @dev Indicates the presence of a road on the tile
        /// @notice Roads remove the movement penalty for hills
        bool hasRoad;

        /// @dev Indicates the presence of a lake on the tile
        /// @notice Lakes impose a movement penalty
        bool hasLake;

        /// @dev Resource => initial amount
        mapping (Resource => uint) resources;
        Resource[] resourcesIndex;
    }

    /// @dev Tile meta data
    struct TileDynamicData
    {
        /// @dev Player that most recently entered the tile 
        address lastEnteredPlayer;

        /// @dev Resource => current amount
        mapping (Resource => uint) resources;
    }


    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */
    uint constant private BASE_INVERSE = 10_000;

    uint16 constant private MAP_MAX_SIZE = 4800;
    uint16 constant private PATH_MAX_LENGTH = 43;
    uint16 constant private PLAYER_START_POSITION = 0;
    uint16 constant private PLAYER_START_MOVEMENT = 25;
    uint64 constant private PLAYER_IDLE_TIME = 600; // 10 minutes
    uint64 constant private MOVEMENT_TURN_DURATION = 60; // 1 min (TODO: scale with ship speed and player speed)
    uint16 constant private MOVEMENT_COST_LAND_FLAT = 11;
    uint16 constant private MOVEMENT_COST_LAND_SLOPE = 19;
    uint16 constant private MOVEMENT_COST_WATER = 5; // Lower by ship speed
    uint16 constant private MOVEMENT_COST_WATER_EMBARK_DISEMBARK = 25; 

    // Route packing
    uint8 constant ROUTE_PACKING_TIME_PER_TURN_OFFSET = 0; 
    uint8 constant ROUTE_PACKING_TOTAL_TURNS_OFFSET = 8;  
    uint8 constant ROUTE_PACKING_TOTAL_TILES_OFFSET = 16;  
    uint8 constant ROUTE_PACKING_TOTAL_PACKED_TILES_OFFSET = 24;  
    uint8 constant ROUTE_PACKING_META_DATA_OFFSET = 32;  
    uint8 constant ROUTE_PACKING_TILE_BIT_LENGTH = 16;  

    /// @dev Refs
    address public playerRegisterContract;
    address public assetRegisterContract;
    address public titleDeedContract;
    address public shipContract;

    /// @dev Maps
    mapping(bytes32 => Map) public maps; 
    bytes32[] private mapsIndex;

    /// @dev Tiles
    mapping(uint16 => TileStaticData) public tileDataStatic;
    mapping(uint16 => TileDynamicData) public tileDataDynamic; 
    uint public initializedTileCount;

    /// @dev player => PlayerNavigationData
    mapping(address => PlayerNavigationData) public playerData;
  
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
    /// @param player Player that entered the map
    /// @param map Map that the player entered
    /// @param tile Tile that the player entered
    /// @param arrival The datetime on wich the player arrives at `tile`
    event PlayerEnterMap(address indexed player, bytes32 indexed map, uint16 indexed tile, uint64 arrival);

    /// @dev Emitted when a player entered a tile
    /// @param player Player that entered the tile
    /// @param origin Tile that the player originated from
    /// @param destination Tile that the player entered
    /// @param route The route that the player traveled
    /// @param arrival The datetime on wich the player arrives at `destinationTile`
    event PlayerMove(address indexed player, uint16 indexed origin, uint16 indexed destination, bytes32 route, uint64 arrival);


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
    /// @param account Player that has not entered the map
    error PlayerNotEnteredMap(address account);

    /// @dev Emits if a player attempts to enter a map while already on a map
    /// @param account Player that is already on a map
    error PlayerAlreadyEnteredMap(address account);


    /**
     * Modifiers
     */
    /// @dev Only allow if `account` has entered a map
    /// @param account The account to check
    modifier onlyEntered(address account) 
    {
        // Enforce player in map
        if (!_playerHasEntered(msg.sender))
        {
            revert PlayerNotEnteredMap(msg.sender);
        }
        _;
    }


    /// @dev Initialize
    /// @param _playerRegisterContract Contract responsible for players
    /// @param _assetRegisterContract Contract responsible for assets
    /// @param _titleDeedContract Contract responsible for land ownership
    /// @param _shipContract Contract for ships
    function initialize(
        address _playerRegisterContract, 
        address _assetRegisterContract,
        address _titleDeedContract, 
        address _shipContract) 
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
    }


    /** 
     * Admin functions
     */
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

        maps[name].name = name; 
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
            .__increaseLimit(initializedTileCount);
        initializedTileCount = 0;

        // Emit created event
        emit CreateMap(mapsIndex[index], index);
    }


    /// @dev Batch operation to set tiles 
    /// @param indices Indices of the tiles
    /// @param data Tile datas
    function setTiles(
        uint16[] memory indices, 
        TileStatic[] memory data)
        public virtual
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        for (uint i = 0; i < indices.length; i++)
        {
            _setTile(indices[i], data[i]);
        }
    }


    /** 
     * Public functions
     */
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
    /// @return map Map data
    function getMapAt(uint index) 
        public virtual view 
        returns (Map memory map)
    {
        map = maps[mapsIndex[index]];
    }

      
    /// @dev Retrieve static data for the tile with `tileIndex`
    /// @param tileIndex Index of hte tile to retrieve
    /// @return tileData Static tile data
    function getTileDataStatic(uint16 tileIndex) 
        public virtual override view 
        returns (TileStatic memory tileData)
    {
        TileStaticData storage data = tileDataStatic[tileIndex];
        tileData.initialized = data.initialized;
        tileData.mapIndex = data.mapIndex;
        tileData.group = data.group;
        tileData.safety = data.safety;
        tileData.biome = data.biome;
        tileData.terrain = data.terrain;
        tileData.elevation = data.elevation;
        tileData.waterLevel = data.waterLevel;
        tileData.vegetationLevel = data.vegetationLevel;
        tileData.rockLevel = data.rockLevel;
        tileData.wildlifeLevel = data.wildlifeLevel;
        tileData.riverFlags = data.riverFlags;
        tileData.hasRoad = data.hasRoad;
        tileData.hasLake = data.hasLake;
        tileData.resources = new TileResourceStatic[](data.resourcesIndex.length);
        for (uint i = 0; i < data.resourcesIndex.length; i++)
        {
            tileData.resources[i] = TileResourceStatic(
                data.resourcesIndex[i], 
                data.resources[data.resourcesIndex[i]]);
        }
    }

    
    /// @dev Retrieve dynamic data for the tile with `tileIndex`
    /// @param tileIndex Index of the tile to retrieve
    /// @return tileData Dynamic tile data
    function getTileDataDynamic(uint16 tileIndex)
        public virtual override view 
        returns (TileDynamic memory tileData)
    {
        TileStaticData storage staticData = tileDataStatic[tileIndex];
        TileDynamicData storage dynamicData = tileDataDynamic[tileIndex];

        // Add owener
        try IERC721(titleDeedContract).ownerOf(tileIndex) 
            returns (address owner)
        {
            tileData.owner = owner;
        } 
        catch (bytes memory)
        {
            tileData.owner = address(0);
        }

        // Add last entered players
        tileData.lastEnteredPlayers = new address[](5);
        tileData.lastEnteredPlayers[0] = dynamicData.lastEnteredPlayer;
        tileData.lastEnteredPlayers[1] = playerData[tileData.lastEnteredPlayers[0]].chain_prev;
        tileData.lastEnteredPlayers[2] = playerData[tileData.lastEnteredPlayers[1]].chain_prev;
        tileData.lastEnteredPlayers[3] = playerData[tileData.lastEnteredPlayers[2]].chain_prev;
        tileData.lastEnteredPlayers[4] = playerData[tileData.lastEnteredPlayers[3]].chain_prev;

        // Add resources
        tileData.resources = new TileResourceDynamic[](staticData.resourcesIndex.length);
        for (uint i = 0; i < tileDataStatic[tileIndex].resourcesIndex.length; i++)
        {
            tileData.resources[i] = TileResourceDynamic(
                staticData.resourcesIndex[i], 
                dynamicData.resources[staticData.resourcesIndex[i]]);
        }
    }


    /// @dev Retrieve tile safety score (0-100)
    /// @param tileIndex Index of the tile to retrieve safety multiplier for
    function getTileSafety(uint16 tileIndex)
        public virtual view 
        returns (uint8)
    {
        return tileDataStatic[tileIndex].safety;
    }


    /// @dev True if the tile with `tileIndex` is adjacent to `adjecentTileIndex`
    /// @param tileIndex The tile to test against
    /// @param adjecentTileIndex The tile to test with
    /// @return True if the tile with `tileIndex` is adjacent to `adjecentTileIndex`
    function tileIsAdjacentTo(uint16 tileIndex, uint16 adjecentTileIndex) 
        public view 
        returns (bool)
    {
        return _tileIsAdjecentTo(tileIndex, adjecentTileIndex);
    }


    /// @dev Checks if a tile with `tileIndex` is along the route `route` based on the traveler's progress
    /// @param tileIndex The index of the tile to check
    /// @param route The route data to check against
    /// @param routeIndex The index of the tile in the route data (0 signals origin, setting it equal to totalTilesPacked indicates destination)
    /// @param arrival The datetime on which the traveler arrives at it's destination
    /// @param position The position of the tile relative to the traveler's progress along the route {ANY, UPCOMING, CURRENT, PASSED}
    /// @return True if the tile with `tileIndex` meets the conditions specified by `position`
    function tileIsAlongRoute(uint16 tileIndex, bytes32 route, uint routeIndex, uint16 destination, uint64 arrival, RoutePosition position) 
        public view 
        returns (bool)
    {
        // Extract metadata 
        uint totalTilesPacked = uint(route >> 24) & 0xFF;

        // Find closest tile
        uint16 closestTileIndex;
        if (routeIndex < totalTilesPacked)
        {
            closestTileIndex = uint16(uint(route) >> (ROUTE_PACKING_META_DATA_OFFSET + routeIndex * ROUTE_PACKING_TILE_BIT_LENGTH));
        }
        else if (routeIndex == totalTilesPacked)
        {
            closestTileIndex = destination;
        }
        else 
        {
            revert ArgumentInvalid();
        }
        
        
        // Check if closestTileIndex is reachable from tileIndex
        if (closestTileIndex != tileIndex && !_tileIsAdjecentTo(closestTileIndex, tileIndex))
        {
            return false;
        }

        // Return true if we don't care about where the traveler is in the route
        if (position == RoutePosition.Any)
        {
            return true;
        }

        // Extract more metadata
        uint timePerTurn = uint(route) & 0xFF;
        uint totalTravelTime = (uint(route >> 8) & 0xFF) * timePerTurn; // totalTurns * timePerTurn
        uint closestTileProgressPercentage = routeIndex * BASE_INVERSE / totalTilesPacked; // Packed tile index * BASE_INVERSE / totalTilesPacked
        uint routeProgressPercentage = block.timestamp < arrival 
            ? (totalTravelTime - (arrival - block.timestamp)) * BASE_INVERSE / totalTravelTime // Remaining time * BASE_INVERSE / totalTravelTime
            : BASE_INVERSE;
           
        /// Margin examples:
        ///
        /// - Margin in time: totalTravelTime / totalTilesPacked / 2
        /// - Margin as %: 10000 / totalTilesPacked / 2
        ///
        /// 1 tile packed           Travel time (60 sec)    Margin in time (60/1/2 = 30)       Margin as % (100/1/2 = 50)
        ///  0 * 100 / 1 = 0%        0 seconds               [0 - 30]                           [0% - 50%]
        ///  1 * 100 / 1 = 100%      60 seconds              [30 - 60]                          [50% - 100%]
        ///
        /// 1 tile packed           Travel time (120 sec)   Margin in time (120/1/2 = 60)      Margin as % (100/1/2 = 50)
        ///  1 * 100 / 1 = 100%      120 seconds             [60 - 120]                         [50% - 100%]
        ///
        /// 1 tile packed           Travel time (180 sec)   Margin in time (180/1/2 = 90)      Margin as % (100/1/2 = 50)
        ///  0 * 100 / 1 = 0%        0 seconds               [0 - 90]                           [0% - 50%]
        ///  1 * 100 / 1 = 100%      180 seconds             [90 - 180]                         [50% - 100%]
        ///
        /// 2 tiles packed          Travel time (120 sec)   Margin in time (120/2/2 = 30)      Margin as % (100/2/2 = 25)
        ///  0 * 100 / 2 = 0%        0 seconds               [0 - 30]                           [0% - 25%]
        ///  1 * 100 / 2 = 50%       60 seconds              [30 - 90]                          [25% - 75%]
        ///  2 * 100 / 2 = 100%      120 seconds             [90 - 120]                         [75% - 100%]
        ///
        /// 3 tiles packed          Travel time (360 sec)   Margin in time (360/3/2 = 60)      Margin as % (100/3/2 = 16.66)
        ///  0 * 100 / 3 = 0%        0 seconds               [0 - 60]                           [0% - 16.66%]
        ///  1 * 100 / 3 = 33.33%    120 seconds             [60 - 180]                         [16.67% - 49.99%]
        ///  2 * 100 / 3 = 66.66%    240 seconds             [180 - 300]                        [50% - 83.32%]
        ///  3 * 100 / 3 = 100%      360 seconds             [300 - 360]                        [83.34% - 100%]
        ///
        /// 3 tiles packed          Travel time (540 sec)   Margin in time (540/3/2 = 90)      Margin as % (100/3/2 = 16.66)
        ///  0 * 100 / 3 = 0%        0 seconds               [0 - 90]                           [0% - 16.66%]
        ///  1 * 100 / 3 = 33.33%    180 seconds             [90 - 270]                         [16.67% - 49.99%]
        ///  2 * 100 / 3 = 66.66%    360 seconds             [270 - 450]                        [50% - 83.32%]
        ///  3 * 100 / 3 = 100%      540 seconds             [450 - 540]                        [83.34% - 100%]
        ///
        /// 6 tiles packed          Travel time (660 sec)   Margin in time (660/6/2 = 55)      Margin as % (100/6/2 = 8.33)
        ///  0 * 100 / 6 = 0%        0 seconds               [0 - 55]                           [0% - 8.33%]
        ///  1 * 100 / 6 = 16.66%    110 seconds             [55 - 165]                         [8.34% - 24.99%]
        ///  2 * 100 / 6 = 33.33%    220 seconds             [165 - 275]                        [25% - 41.66%]
        ///  3 * 100 / 6 = 50%       330 seconds             [275 - 385]                        [41.67% - 58.32%]
        ///  4 * 100 / 6 = 66.66%    440 seconds             [385 - 495]                        [58.33% - 74.99%]
        ///  5 * 100 / 6 = 83.33%    550 seconds             [495 - 605]                        [75% - 91.66%]
        ///  6 * 100 / 6 = 100%      660 seconds             [605 - 660]                        [91.67% - 100%]
        uint margin = BASE_INVERSE / totalTilesPacked / 2;

        // Valid when the traveler is near to tileIndex
        if (position == RoutePosition.Current)
        {
            if (routeProgressPercentage + margin >= closestTileProgressPercentage && 
                routeProgressPercentage <= closestTileProgressPercentage + margin)
            {
                return true;
            }
        }

        // Valid when traveler is before tileIndex
        else if (position == RoutePosition.Upcoming)
        {
            if (routeProgressPercentage + margin < closestTileProgressPercentage)
            {
                return true;
            }
        }

        // Valid when traveler is after tileIndex
        else if (position == RoutePosition.Passed)
        {
            if (routeProgressPercentage > closestTileProgressPercentage + margin)
            {
                return true;
            }
        }

        // Unknow position param
        else 
        {
            revert ArgumentInvalid();
        }

        return false;
    }


    /// @dev Retrieve players from the tile with `tileIndex`
    /// @param tileIndex Retrieve players from this tile
    /// @param start Starting point in the chain
    /// @param max Max amount of players to return
    function getPlayers(uint16 tileIndex, address start, uint max)
        public virtual view  
        returns (address[] memory players)
    {
        players = new address[](max);

        // No players
        if (start == address(0) && tileDataDynamic[tileIndex].lastEnteredPlayer == address(0))
        {
            return players;
        }

        // Set first player
        players[0] = start == address(0) 
            ? tileDataDynamic[tileIndex].lastEnteredPlayer : start;

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

    
    /// @dev Retrieve player data for `account`
    /// @param account The account to retreive player data for
    /// @return PlayerData data
    function getPlayerData(address account)
        public virtual override view 
        returns (PlayerNavigationData memory)
    {
        return playerData[account];
    }


    /// @dev Retrieve general player data for `account`
    /// @param account The account to retreive player data for
    /// @return tileIndex The tile that the player is at
    /// @return canInteract Wether the player can interact with the tile
    function getPlayerLocationData(address account)
        public virtual override view 
        returns (
            uint16 tileIndex,
            bool canInteract)
    {
        tileIndex = playerData[account].location_tileIndex;
        canInteract = _playerCanInteract(account);
    }


    /// @dev Retrieve travel data for `account`
    /// @param account The account to retreive travel data for
    /// @return isIdle Wether the player is idle
    /// @return isTraveling Wether the player is traveling
    /// @return isEmbarked Wether the player is on a ship (on water)
    /// @return tileIndex The tile that the player is at or traveling to
    /// @return route The route that the player is traveling
    /// @return arrival The datetime on wich the player arrives at `tileIndex`
    function getPlayerTravelData(address account)
        public virtual override view 
        returns (
            bool isIdle,
            bool isTraveling,
            bool isEmbarked,
            uint16 tileIndex,
            bytes32 route,
            uint64 arrival)
    {
        tileIndex = playerData[account].location_tileIndex;
        isTraveling = _playerIsTraveling(account);
        isEmbarked =  _tileIsUnderwater(tileIndex);
        route = playerData[account].location_route;
        arrival = playerData[account].location_arrival;
        isIdle = uint64(block.timestamp) > arrival + PLAYER_IDLE_TIME;
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
            revert PlayerAlreadyEnteredMap(msg.sender);
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
            msg.sender, mapsIndex[0], PLAYER_START_POSITION, uint64(block.timestamp));
    }


    /// @dev Moves a player from one tile to another
    /// @param path Tiles that represent a route
    function playerMove(uint16[] memory path)
        onlyEntered(msg.sender)
        public virtual  
    {
        address account = msg.sender;

        // Enforce player not traveling
        if (_playerIsTraveling(account))
        {
            revert PlayerIsTraveling(account, playerData[account].location_arrival);
        }

        // Move player
        _playerMove(account, path);

        // Emit
        emit PlayerMove(
            account, 
            path[0], 
            path[path.length - 1], 
            playerData[account].location_route, 
            playerData[account].location_arrival);
    }


    /**
     * System functions
     */
    /// @dev Prevents `account` from traveling `until`
    /// @param account The player to lock
    /// @param until The datetime on which the lock expires
    function __freeze(address account, uint64 until) 
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account].frozenUntil = until;
    }


    /// @dev Freezes `account1` and `account2` `until`
    /// @param account1 The first player to freeze
    /// @param account2 The second player to freeze
    /// @param until The datetime on which the lock expires
    function __freeze(address account1, address account2, uint64 until) 
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account1].frozenUntil = until;
        playerData[account2].frozenUntil = until;
    }

    
    /// @dev Unfreeze `account`
    /// @param account The player to unfreeze
    function __unfreeze(address account)
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account].frozenUntil = 0;
    }


    /// @dev Unfreeze `account1` and `account2`
    /// @param account1 The first player to unfreeze
    /// @param account2 The second player to unfreeze
    function __unfreeze(address account1, address account2)
        public override virtual 
        onlyRole(SYSTEM_ROLE)
    {
        playerData[account1].frozenUntil = 0;
        playerData[account2].frozenUntil = 0;
    }


    /**
     * Internal functions
     */
    /// @dev Returns true if an initialized tile with `index` exists in a finalized map
    /// @param index Position of the tile in the tiles array
    /// @return bool Wether a tile at `index` exists
    function _tileExists(uint16 index)
        internal view 
        returns (bool)
    {
        return tileDataStatic[index].initialized && maps[mapsIndex[tileDataStatic[index].mapIndex]].finalized;
    }


    /// @dev Returns true if tile at `index` is underwater (waterLevel > elevation)
    /// @param index Position of the tile in the tiles array
    /// @return bool Wether the tile at `index` is underwater
    function _tileIsUnderwater(uint16 index)
        internal view 
        returns (bool)
    {
        return tileDataStatic[index].waterLevel > tileDataStatic[index].elevation;
    }


    /// @dev Tests if `a` and `b` are neighbors
    /// @param a Left hand tile index
    /// @param b Right hand tile index
    /// @return bool Wether a and b are neighbors
    function _tileIsAdjecentTo(uint16 a, uint16 b) 
        internal view 
        returns (bool) 
    {
        Map storage map = maps[mapsIndex[tileDataStatic[a].mapIndex]];
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


    /// @dev Populate (or override) the tile at `index` with `tileData`. The `index` is used to determin  
    /// the map to which the tile belongs as well as it's cooridinates within that map.
    /// @param index Index of the tile
    /// @param tileData Tile data 
    function _setTile(
        uint16 index, 
        TileStatic memory tileData) 
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

        if (!tileDataStatic[index].initialized)
        {
            initializedTileCount++;
        }

        tileDataStatic[index].initialized = true;
        tileDataStatic[index].mapIndex = uint16(mapsIndex.length - 1);
        tileDataStatic[index].group = tileData.group;
        tileDataStatic[index].safety = tileData.safety;
        tileDataStatic[index].biome = tileData.biome;
        tileDataStatic[index].terrain = tileData.terrain;
        tileDataStatic[index].elevation = tileData.elevation;
        tileDataStatic[index].waterLevel = tileData.waterLevel;
        tileDataStatic[index].vegetationLevel = tileData.vegetationLevel;
        tileDataStatic[index].rockLevel = tileData.rockLevel;
        tileDataStatic[index].wildlifeLevel = tileData.wildlifeLevel;
        tileDataStatic[index].riverFlags = tileData.riverFlags;
        tileDataStatic[index].hasRoad = tileData.hasRoad;
        tileDataStatic[index].hasLake = tileData.hasLake;

        // Set resources
        for (uint i = 0; i < tileData.resources.length; i++)
        {
            tileDataStatic[index].resourcesIndex.push(tileData.resources[i].resource);
            tileDataStatic[index].resources[tileData.resources[i].resource] = tileData.resources[i].initialAmount;
            tileDataDynamic[index].resources[tileData.resources[i].resource] = tileData.resources[i].initialAmount;
        }
    }


    /// @dev Traverse the path and validate that account is allowed to travel path
    /// @param path Route of tiles to validate
    /// @param account Player to validate against
    /// @return isValid True if `account` can travel `path`
    /// @return turns The amount of turns to reach destination
    /// @return route The route data that can be used to travel `path`
    /// 
    /// Route data format:
    ///  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    /// | Duration per turn (8 bits) | Total turns (8 bits) | Total tiles in path (8 bits) | Total tiles packed (8 bits) | Origin (16 bits) | Tile 4 (16 bits) | ... | Tile 14 (16 bits) |
    /// |----------------------------|----------------------|------------------------------|-----------------------------|------------------|------------------|-----|-------------------|
    /// | 0                          | 8                    | 16                           | 24                          | 32               | 48               | ... | 208               |
    ///  --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    function _traversePath(uint16[] memory path, address account) 
        internal  
        returns (
            bool isValid, 
            uint8 turns, 
            bytes32 route)
    {
        // Validate path length
        if (path.length < 2 || path.length > PATH_MAX_LENGTH)
        {
            return (false, 0, bytes32(0));
        }

        // Validate player start location
        if (path[0] != playerData[account].location_tileIndex)
        {
            return (false, 0, bytes32(0));
        }
        
        // Leave space for meta data
        uint bitOffset = ROUTE_PACKING_META_DATA_OFFSET; 

        // Validate segments
        uint movementCostFromOrigin; 
        for (uint i = 1; i < path.length; i++)
        {
            // Validate segment in the same map as origin
            if (tileDataStatic[path[0]].mapIndex != tileDataStatic[path[i]].mapIndex)
            {
                return (false, 0, bytes32(0));
            }

            // Movement cost for current tile
            uint movementCost;  
            (isValid, movementCost) = _traversePathSegment(
                path[i - 1], path[i]);

            if (!isValid)
            {
                return (false, 0, bytes32(0));
            }

            movementCostFromOrigin += movementCost;

            // Next turn
            uint8 nextTurn = uint8((movementCostFromOrigin - 1) / playerData[account].movement);
            if (nextTurn > turns)
            {
                movementCostFromOrigin = nextTurn * playerData[account].movement + movementCost;
                turns = nextTurn;
            }

            // Pack every third tile after the origin
            if (i % 3 == 0 && i != path.length - 1) 
            {
                // Add tile to route
                bitOffset += ROUTE_PACKING_TILE_BIT_LENGTH;
                route |= bytes32(uint(path[i])) << bitOffset;
            }
        }

        // Convert to non-zero based
        turns += 1; 

        // Add metadata to route
        route |= bytes32(uint(MOVEMENT_TURN_DURATION)); 
        route |= bytes32(uint(turns)) << ROUTE_PACKING_TOTAL_TURNS_OFFSET; 
        route |= bytes32(uint(path.length)) << ROUTE_PACKING_TOTAL_TILES_OFFSET; 
        route |= bytes32(uint(1 + (path.length - 2) / 3)) << ROUTE_PACKING_TOTAL_PACKED_TILES_OFFSET; 

        // Add origin to route
        route |= bytes32(uint(path[0])) << ROUTE_PACKING_META_DATA_OFFSET; 

        // If we got this far, the path is valid
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
        if (!_tileIsAdjecentTo(fromTileIndex, toTileIndex))
        {
            return (false, 0);
        }

        // Land 
        if (!_tileIsUnderwater(fromTileIndex) && !_tileIsUnderwater(toTileIndex))
        {
            EdgeType edgeType = _getEdgeType(
                tileDataStatic[fromTileIndex].elevation, tileDataStatic[toTileIndex].elevation);
            if (edgeType == EdgeType.Cliff)
            {
                return (false, 0); // Can't move over cliffs
            }

            // Base land movement costs
            movementCost += edgeType == EdgeType.Flat ? 
                MOVEMENT_COST_LAND_FLAT : MOVEMENT_COST_LAND_SLOPE;

            // Add vegetation movement penalty
            movementCost += tileDataStatic[toTileIndex].vegetationLevel + tileDataStatic[toTileIndex].rockLevel;
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
                tileDataStatic[fromTileIndex].waterLevel, tileDataStatic[toTileIndex].elevation);
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
                tileDataStatic[fromTileIndex].elevation, tileDataStatic[toTileIndex].waterLevel);
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
    /// @param path Tiles that represent a route
    function _playerMove(address account, uint16[] memory path)
        internal 
    {
        PlayerNavigationData storage data = playerData[account];

        // Enforce player not frozen
        if (data.frozenUntil > block.timestamp)
        {
            revert PlayerIsFrozen(account, data.frozenUntil);
        }

        // Traverse path
        (bool isValidPath, uint turns, bytes32 route) = _traversePath(
            path, msg.sender);

        // Enforce valid path
        if (!isValidPath)
        {
            revert PathInvalid();
        }

        // Travel to destination
        data.location_route = route;
        data.location_arrival = uint64(block.timestamp + turns * MOVEMENT_TURN_DURATION);

        // Exit
        _playerExitTile(account);

        // Enter
        _playerEnterTile(account, path[path.length - 1], data.location_arrival);
    }


    /// @dev Remove `account` from `tileIndex` 
    /// @param account Player thats exiting the tile
    function _playerExitTile(address account)
        internal 
    {
        if (playerData[account].chain_next == address(0))
        {
            // Fix chain (replace head)
            tileDataDynamic[playerData[account].location_tileIndex].lastEnteredPlayer = playerData[account].chain_prev;
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
        playerData[account].chain_prev = tileDataDynamic[tileIndex].lastEnteredPlayer;
        playerData[tileDataDynamic[tileIndex].lastEnteredPlayer].chain_next = account; 
        tileDataDynamic[tileIndex].lastEnteredPlayer = account;
    }
}