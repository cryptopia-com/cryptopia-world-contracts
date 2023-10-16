// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../../../source/game/assets/types/AssetEnums.sol";

/// @title Cryptopia Maps
/// @dev Contains world data and player positions
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract MockCryptopiaMap is Initializable {

    /// @dev Tile data that is used to construct the mesh in the client
    struct Tile {
        bool initialized;
        uint16 mapIndex;
        uint8 terrainPrimaryIndex;
        uint8 terrainSecondaryIndex;
        uint8 terrainBlendFactor;
        uint8 terrainOrientation;
        uint8 elevation;
        uint8 waterLevel;
        uint8 vegitationLevel;
        uint8 rockLevel;
        uint8 incommingRiverData;
        uint8 outgoingRiverData;
        uint8 roadFlags;
    }

    /// @dev Tile meta data
    struct TileData 
    {
        /// @dev Wildlife 
        WildlifeData wildlife;
    }

    /// @dev Wildlife on tile
    struct WildlifeData 
    {
        /// @dev Indicates type of wildlife
        bytes32 creature;

        /// @dev Indicates level of wildlife that remains
        uint128 level;
    }

    /// @dev Player data
    struct PlayerData {

        /// @dev Tile that the player is currently on
        uint32 location_tileIndex;

        /// @dev When the player arrives at `tileIndex`
        uint location_arrival;
    }


    // Data
    mapping(uint32 => Tile) public tiles;
    mapping(uint32 => TileData) public tileData;
    mapping(address => PlayerData) public playerData;


    /// @dev Mock initializer
    function initialize(
        address[] memory player_accounts, uint32[] memory player_locations) 
        public initializer 
    {
        for (uint i = 0; i < player_accounts.length; i++)
        {
            playerData[player_accounts[i]] = PlayerData(
                player_locations[i], block.timestamp);
        }
    }


    function playerMove(address player_account, uint32 player_location)
        public 
    {
        playerData[player_account].location_tileIndex = player_location;
    }


    function setTiles(uint32[] memory indices, uint8[11][] memory values) public
    {
        for (uint i = 0; i < indices.length; i++)
        {
            tiles[indices[i]].initialized = true;
            tiles[indices[i]].mapIndex = uint16(0);
            tiles[indices[i]].terrainPrimaryIndex = values[i][0];
            tiles[indices[i]].terrainSecondaryIndex = values[i][1];
            tiles[indices[i]].terrainBlendFactor = values[i][2];
            tiles[indices[i]].terrainOrientation = values[i][3];
            tiles[indices[i]].elevation = values[i][4];
            tiles[indices[i]].waterLevel = values[i][5];
            tiles[indices[i]].vegitationLevel = values[i][6];
            tiles[indices[i]].rockLevel = values[i][7];
            tiles[indices[i]].incommingRiverData = values[i][8];
            tiles[indices[i]].outgoingRiverData = values[i][9];
            tiles[indices[i]].roadFlags = values[i][10];
        }
    }


    function setWildlifeData(uint32[] memory indices, bytes32[] memory wildlife_creatures, uint128[] memory wildlife_levels) public
    {
        for (uint i = 0; i < wildlife_creatures.length; i++)
        {
            tileData[indices[i]].wildlife = WildlifeData(
                wildlife_creatures[i], wildlife_levels[i]);
        }
    }





    /// @dev Returns data about the players ability to interact with resources 
    /// @param account Player to retrieve data for
    /// @param resource Type of resource to test for
    /// @return uint the amount of `resource` that can be minted
    function getPlayerResourceData(address account, ResourceType resource) 
        public view 
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
                ? tiles[tileIndex].waterLevel - tiles[tileIndex].elevation // Deeper water = more fish
                : 1; // Small water body
        }

        // Meat
        if (resource == ResourceType.Meat)
        {
            uint32 tileIndex = playerData[account].location_tileIndex;
            if (_tileIsUnderwater(tileIndex))
            {
                return 0;
            }

            return tileData[tileIndex].wildlife.level;
        }

        // Fruit || Wood
        if (resource == ResourceType.Fruit || resource == ResourceType.Wood)
        {
            return tiles[playerData[account].location_tileIndex].vegitationLevel;
        }
        
        // Stone
        if (resource == ResourceType.Stone)
        {
            return tiles[playerData[account].location_tileIndex].rockLevel;
        }

        // Sand
        if (resource == ResourceType.Sand)
        {
            return 1;
        }

        return 0;
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

    /// @dev Returns true if tile at `index` is underwater (waterLevel > elevation)
    /// @param index Position of the tile in the tiles array
    /// @return bool Wether the tile at `index` is underwater
    function _tileIsUnderwater(uint32 index)
        internal view 
        returns (bool)
    {
        return tiles[index].waterLevel > tiles[index].elevation;
    }
}