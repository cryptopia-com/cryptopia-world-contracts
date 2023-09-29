// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777Upgradeable.sol";

import "../../tokens/ERC777/CryptopiaAssetToken/CryptopiaAssetToken.sol";
import "../AssetEnums.sol";
import "./ICryptopiaAssetRegister.sol";

/// @title Cryptopia asset register
/// @dev Cryptopia assets register that holds refs to assets such as natural resources and fabricates
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAssetRegister is ICryptopiaAssetRegister, OwnableUpgradeable {

    // Limitation to prevent experimental
    uint32 constant MAX_ACCOUNTS_ASSET_INFOS_CALL = 3;

    /// @dev Assets
    mapping(bytes32 => address) public assets;
    bytes32[] private assetsIndex;

    /// @dev Resources
    mapping (AssetEnums.Resource => address) public resources;


    /*
     * Public functions
     */
    /// @dev Constructor
    function initialize() 
        initializer public 
    {
        __Ownable_init();
    }


    /// @dev Retreives the amount of assets
    /// @return count Number of assets
    function getAssetCount()
        public virtual override view 
        returns (uint256 count)
    {
        count = assetsIndex.length;
    }


    /// @dev Retreives the asset at `index`.
    /// @param index Asset index.
    /// @return contractAddress Address of the asset.
    function getAssetAt(uint256 index)
        public virtual override view  
        returns (address contractAddress)
    {
        contractAddress = _getAssetAt(index);
    }


    /// @dev Retreives the assets from `cursor` to `cursor` plus `length`.
    /// @param cursor Starting index.
    /// @param length Amount of assets to return.
    /// @return contractAddresses Addresses of the assets.
    function getAssets(uint256 cursor, uint256 length)
        public virtual override view 
        returns (address[] memory contractAddresses)
    {
        contractAddresses = new address[](length);
        for (uint256 i = cursor; i < length; i++)
        {
            contractAddresses[i] = _getAssetAt(i);
        }
    }


    /// @dev Retreives asset and balance info for `account` from the asset at `index`.
    /// @param index Asset index.
    /// @param accounts Accounts to retrieve the balances for.
    /// @return contractAddress Address of the asset.
    /// @return name Address of the asset.
    /// @return symbol Address of the asset.
    /// @return balances Ballances of `accounts` the asset.
    function getAssetInfoAt(uint256 index, address[] memory accounts)
        public virtual override view  
        returns (address contractAddress, string memory name, string memory symbol, uint256[] memory balances)
    {
        (contractAddress, name, symbol, balances) = _getAssetInfoAt(index, accounts);
    }


    /// @dev Retreives asset and balance infos for `accounts` from the assets from `cursor` to `cursor` plus `length`. Has limitations to avoid experimental.
    /// @param cursor Starting index.
    /// @param length Amount of asset infos to return.
    /// @param accounts Accounts to retrieve the balances for.
    /// @return contractAddresses Address of the asset.
    /// @return names Address of the asset.
    /// @return symbols Address of the asset.
    /// @return balances1 Asset balances of accounts[0].
    /// @return balances2 Asset balances of accounts[1].
    /// @return balances3 Asset balances of accounts[2].
    function getAssetInfos(uint256 cursor, uint256 length, address[] memory accounts)
        public virtual override view  
        returns (
            address[] memory contractAddresses, 
            bytes32[] memory names, 
            bytes32[] memory symbols, 
            uint256[] memory balances1, 
            uint256[] memory balances2, 
            uint256[] memory balances3)
    {
        // We don't want to experiment
        require(accounts.length <= MAX_ACCOUNTS_ASSET_INFOS_CALL, "CryptopiaAssetRegister: Max accounts exceeded");

        contractAddresses = new address[](length);
        names = new bytes32[](length);
        symbols = new bytes32[](length);
        balances1 = new uint256[](length);
        balances2 = new uint256[](length);
        balances3 = new uint256[](length);

        for (uint256 i = cursor; i < length; i++)
        {
            string memory name;
            string memory symbol;
            uint256[] memory balances;
            (contractAddresses[i], name, symbol, balances) = _getAssetInfoAt(i, accounts);
            
            names[i] = stringToBytes32(name);
            symbols[i] = stringToBytes32(symbol);
            
            if (accounts.length > 0)
            {
               balances1[i] = balances[0];
            }

            if (accounts.length > 1)
            {
               balances2[i] = balances[1];
            }

            if (accounts.length > 2)
            {
               balances3[i] = balances[2];
            }
        }
    }


    /// @dev Getter for resources
    /// @param resource {AssetEnums.Resource}
    /// @return address The resource asset contract address 
    function getAssetByResrouce(AssetEnums.Resource resource) 
        public virtual override view 
        returns (address)
    {
        return resources[resource];
    }


    /// @dev Register an asset
    /// @param asset Contact address
    /// @param isResource true if `asset` is a resource
    /// @param resource {AssetEnums.Resource}
    function registerAsset(address asset, bool isResource, AssetEnums.Resource resource) 
        public virtual override 
        onlyOwner 
    {
        bytes32 key = keccak256(bytes(IERC777Upgradeable(asset).symbol()));
        require(assets[key] == address(0), "CryptopiaAssetRegister: Asset already registered");

        assets[key] = asset;
        assetsIndex.push(key);

        if (isResource)
        {
            require(resources[resource] == address(0), "CryptopiaAssetRegister: Resouce already registered");
            resources[resource] = asset;
        }
    }


    /*
     * Internal functions
     */
    /// @dev Retreives the asset at `index`.
    /// @param index Asset index.
    /// @return contractAddress Address of the asset.
    function _getAssetAt(uint256 index)
        internal 
        view 
        returns (address contractAddress)
    {
        contractAddress = assets[assetsIndex[index]];
    }


    /// @dev Retreives asset and balance info for `account` from the asset at `index`.
    /// @param index Asset index.
    /// @param accounts Accounts to retrieve the balances for.
    /// @return contractAddress Address of the asset.
    /// @return name Address of the asset.
    /// @return symbol Address of the asset.
    function _getAssetInfoAt(uint256 index, address[] memory accounts)
        internal 
        view 
        returns (address contractAddress, string memory name, string memory symbol, uint256[] memory balances)
    {
        contractAddress = assets[assetsIndex[index]];
        name = CryptopiaAssetToken(contractAddress).name();
        symbol = CryptopiaAssetToken(contractAddress).symbol();

        balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++)
        {
            balances[i] = CryptopiaAssetToken(contractAddress).balanceOf(accounts[i]);
        }
    }


    // @dev https://ethereum.stackexchange.com/questions/9142/how-to-convert-a-string-to-bytes32
    function stringToBytes32(string memory source) 
        internal 
        pure 
        returns (bytes32 result) 
    {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }
}