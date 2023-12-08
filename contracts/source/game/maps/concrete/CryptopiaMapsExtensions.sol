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


    /// @dev Retrieve a range of static data 
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return tileData The static tile data
    function getTileDataStatic(uint16 skip, uint16 take) 
        public virtual view  
        returns (TileStatic[] memory tileData)
    { 
        tileData = new TileStatic[](take);
        for (uint16 i = 0; i < take; i++)
        {
            tileData[i] = IMaps(mapsContract)
                .getTileDataStatic(skip + i);
        }
    }


    /// @dev Retrieve dynamic data for a range of tiles
    /// @param skip Starting index
    /// @param take Amount of tiles
    /// @return tileData The dynamic tile data
    function getTileDataDynamic(uint16 skip, uint16 take) 
        public virtual view 
        returns (TileDynamic[] memory tileData)
    {
        tileData = new TileDynamic[](take);
        for (uint16 i = 0; i < take; i++)
        {
            tileData[i] = IMaps(mapsContract)
                .getTileDataDynamic(skip + i);
        }
    }


    /// @dev Retrieve data that's attached to players
    /// @param accounts The players to retreive player data for
    /// @return playerData The player data
    function getPlayerDatas(address[] memory accounts)
        public virtual view 
        returns (PlayerNavigationData[] memory playerData)
    {
        for (uint i = 0; i < accounts.length; i++)
        {
            playerData[i] = IMaps(mapsContract)
                .getPlayerData(accounts[i]);
        }
    }
}