// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../IMaps.sol";
import "../types/MapEnums.sol";
import "../../../tokens/ERC721/deeds/ITitleDeeds.sol";

/// @title Extends the maps contract with additional functionality to overcome size restrictions in the EVM
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaMapsExtensions is Initializable {

    /**
     * Storage
     */
    address public mapsContract;
    address public titleDeedContract;


    /// @dev Initialize
    /// @param _mapsContract Contract that we're extending
    /// @param _titleDeedContract Contract that we're extending
    function initialize(
        address _mapsContract,
        address _titleDeedContract)
        public initializer 
    {
        mapsContract = _mapsContract;
        titleDeedContract = _titleDeedContract;
    }


    /// @dev Retrieve a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return tiles The tiles
    function getTiles(uint16 skip, uint16 take) 
        public virtual view  
        returns (Tile[] memory tiles)
    { 
        tiles = new Tile[](take);
        for (uint16 i = 0; i < take; i++)
        {
            tiles[i] = IMaps(mapsContract).getTile(skip + i);
        }
    }


    /// @dev Retrieve static data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return resource1_type A type of asset that the tile contains
    /// @return resource2_type A type of asset that the tile contains
    /// @return resource3_type A type of asset that the tile contains
    /// @return resource1_initialAmount The amount of resource1 the tile contains
    /// @return resource2_initialAmount The amount of resource2 the tile contains
    /// @return resource3_initialAmount The amount of resource3 the tile contains
    function getTileDataStatic(uint16 skip, uint16 take) 
        public virtual view 
        returns (
            Resource[] memory resource1_type,
            Resource[] memory resource2_type,
            Resource[] memory resource3_type,
            uint[] memory resource1_initialAmount,
            uint[] memory resource2_initialAmount,
            uint[] memory resource3_initialAmount)
    {
        resource1_type = new Resource[](take);
        resource2_type = new Resource[](take);
        resource3_type = new Resource[](take);
        resource1_initialAmount = new uint[](take);
        resource2_initialAmount = new uint[](take);
        resource3_initialAmount = new uint[](take);

        uint16 index = skip;
        for (uint16 i = 0; i < take; i++)
        {   
            TileData memory tileData = IMaps(mapsContract)
                .getTileData(index);
            
            resource1_type[i] = tileData.resource1.type_;
            resource1_initialAmount[i] = tileData.resource1.initialAmount;

            resource2_type[i] = tileData.resource2.type_;
            resource2_initialAmount[i] = tileData.resource2.initialAmount;

            resource3_type[i] = tileData.resource3.type_;
            resource3_initialAmount[i] = tileData.resource3.initialAmount;

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
            try IERC721(titleDeedContract).ownerOf(index + 1) 
                returns (address ownerOfResult)
            {
                owner[i] = ownerOfResult;
            } 
            catch (bytes memory)
            {
                owner[i] = address(0);
            }

            TileData memory tileData = IMaps(mapsContract)
                .getTileData(index);

            player1[i] = tileData.lastEnteredPlayer;
            player2[i] = IMaps(mapsContract).getPlayerData(player1[i]).chain_prev;
            player3[i] = IMaps(mapsContract).getPlayerData(player2[i]).chain_prev;
            player4[i] = IMaps(mapsContract).getPlayerData(player3[i]).chain_prev;
            player5[i] = IMaps(mapsContract).getPlayerData(player4[i]).chain_prev;

            resource1_amount[i] = tileData.resource1.amount;
            resource2_amount[i] = tileData.resource2.amount;
            resource3_amount[i] = tileData.resource3.amount;

            index++;
        }
    }


    /// @dev Retrieve data that's attached to players
    /// @param accounts The players to retreive player data for
    /// @return location_tileIndex The tile that the player is at
    /// @return location_arrival The datetime on wich the player arrives at `location_tileIndex`
    /// @return movement Player movement budget
    /// @return frozenUntil The datetime on wich the player is no longer frozen
    function getPlayerDatas(address[] memory accounts)
        public virtual view 
        returns (
            uint16[] memory location_tileIndex,
            uint64[] memory location_arrival,
            uint16[] memory movement,
            uint64[] memory frozenUntil)
    {
        uint length = accounts.length;
        location_tileIndex = new uint16[](length);
        location_arrival = new uint64[](length);
        movement = new uint16[](length);
        frozenUntil = new uint64[](length);

        for (uint i = 0; i < length; i++)
        {
            PlayerNavigationData memory playerData = IMaps(mapsContract)
                .getPlayerData(accounts[i]);

            movement[i] = playerData.movement;
            location_tileIndex[i] = playerData.location_tileIndex;
            location_arrival[i] = playerData.location_arrival;
            frozenUntil[i] = playerData.frozenUntil;
        }
    }
}