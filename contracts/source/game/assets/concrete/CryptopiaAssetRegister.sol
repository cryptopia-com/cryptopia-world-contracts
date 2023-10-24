// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../types/AssetEnums.sol";
import "../IAssetRegister.sol";

/// @title Cryptopia asset register
/// @dev Cryptopia assets register that holds refs to assets such as natural resources and fabricates
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAssetRegister is Initializable, AccessControlUpgradeable, IAssetRegister {

    /**
     * Roles
     */
    bytes32 constant private SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     * Storage
     */ 
    /// @dev Limitation to prevent experimental
    uint32 constant private MAX_ACCOUNTS_ASSET_INFOS_CALL = 3;

    /// @dev Assets
    mapping(bytes32 => address) public assets;
    bytes32[] private assetsIndex;

    /// @dev Resources
    mapping (ResourceType => address) public resources;


    /**
     * Events
     */
    /// @dev Emitted when an asset is successfully registered
    /// @param asset Address of the asset contract registered
    /// @param symbol Symbol of the asset registered
    /// @param isResource Indicates whether the asset is marked as a resource
    /// @param resource Resource type if it is a resource; undefined otherwise
    event RegisterAsset(address indexed asset, string indexed symbol, bool indexed isResource, ResourceType resource);


    /**
     * Errors
     */
    /// @dev Emitted when `symbol` is already registered as an asset
    /// @param symbol The symbol that is already registered as an asset
    error AssetAlreadyRegistered(string symbol);

    /// @dev Emitted when `resource` is already registered as a resource
    /// @param resource The resource that is already registered
    error ResourceAlreadyRegistered(ResourceType resource);


    /**
     * Public functions
     */
    /// @dev Constructor
    function initialize() 
        initializer public 
    {
        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
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
        returns (
            address contractAddress, 
            string memory name, 
            string memory symbol, 
            uint256[] memory balances)
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
        // We don't want to experiment (TODO: remove this limitation)
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
            
            names[i] = bytes32(abi.encodePacked(name));
            symbols[i] = bytes32(abi.encodePacked(symbol));
            
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
    /// @param resource {ResourceType}
    /// @return address The resource asset contract address 
    function getAssetByResrouce(ResourceType resource) 
        public virtual override view 
        returns (address)
    {
        return resources[resource];
    }


    /// @dev Register an asset
    /// @param asset Contact address
    /// @param isResource true if `asset` is a resource
    /// @param resource {ResourceType}
    function registerAsset(address asset, bool isResource, ResourceType resource) 
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
    {
        string memory symbol = ERC20Upgradeable(asset).symbol();
        bytes32 key = keccak256(bytes(symbol));

        // Check if asset is not already registered
        if (assets[key] != address(0))
        {
            revert AssetAlreadyRegistered(symbol);
        }

        assets[key] = asset;
        assetsIndex.push(key);

        if (isResource)
        {
            // Check if resource is not already registered
            if (resources[resource] != address(0))
            {
                revert ResourceAlreadyRegistered(resource);
            }

            resources[resource] = asset;
        }

        // Emit event
        emit RegisterAsset(asset, symbol, isResource, resource);
    }


    /*
     * Internal functions
     */
    /// @dev Retreives the asset at `index`.
    /// @param index Asset index.
    /// @return contractAddress Address of the asset.
    function _getAssetAt(uint256 index)
        internal view 
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
        internal view 
        returns (address contractAddress, string memory name, string memory symbol, uint256[] memory balances)
    {
        contractAddress = assets[assetsIndex[index]];
        name = ERC20Upgradeable(contractAddress).name();
        symbol = ERC20Upgradeable(contractAddress).symbol();

        balances = new uint256[](accounts.length);
        for (uint256 i = 0; i < accounts.length; i++)
        {
            balances[i] = IERC20(contractAddress).balanceOf(accounts[i]);
        }
    }
}