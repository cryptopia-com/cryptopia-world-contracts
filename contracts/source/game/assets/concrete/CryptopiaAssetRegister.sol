// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../../../errors/ArgumentErrors.sol";
import "../types/AssetEnums.sol";
import "../IAssetRegister.sol";

/// @title Cryptopia asset register
/// @dev Cryptopia assets register that holds refs to assets such as natural resources and fabricates
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAssetRegister is Initializable, AccessControlUpgradeable, IAssetRegister {

    /**
     * Storage
     */ 
    /// @dev Assets
    mapping(bytes32 => address) public assets;
    bytes32[] private assetsIndex;

    /// @dev Resources
    mapping (Resource => address) public resources;


    /**
     * Events
     */
    /// @dev Emitted when an asset is successfully registered
    /// @param asset Address of the asset contract registered
    /// @param symbol Symbol of the asset registered
    /// @param isResource Indicates whether the asset is marked as a resource
    /// @param resource Resource type if it is a resource; undefined otherwise
    event RegisterAsset(address indexed asset, string indexed symbol, bool indexed isResource, Resource resource);


    /**
     * Errors
     */
    /// @dev Emitted when `symbol` is already registered as an asset
    /// @param symbol The symbol that is already registered as an asset
    error AssetAlreadyRegistered(string symbol);

    /// @dev Emitted when `resource` is already registered as a resource
    /// @param resource The resource that is already registered
    error ResourceAlreadyRegistered(Resource resource);


    /// @dev Constructor
    function initialize() 
        initializer public 
    {
        __AccessControl_init();

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /**
     * Admin functions
     */
    /// @dev Register an asset
    /// @param asset Contact address
    /// @param isResource true if `asset` is a resource
    /// @param resource {Resource}
    function registerAsset(address asset, bool isResource, Resource resource) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
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


    /**
     * Public functions
     */
    /// @dev Retreives the amount of assets
    /// @return count Number of assets
    function getAssetCount()
        public virtual override view 
        returns (uint count)
    {
        count = assetsIndex.length;
    }


    /// @dev Retreives the asset at `index`.
    /// @param index Asset index.
    /// @return contractAddress Address of the asset.
    function getAssetAt(uint index)
        public virtual override view  
        returns (address contractAddress)
    {
        contractAddress = _getAssetAt(index);
    }


    /// @dev Retreives the assets from `skip` to `skip` plus `take`.
    /// @param skip Starting index.
    /// @param take Amount of assets to return.
    /// @return contractAddresses Addresses of the assets.
    function getAssets(uint skip, uint take)
        public virtual override view 
        returns (address[] memory contractAddresses)
    {
        contractAddresses = new address[](take);
        for (uint i = skip; i < take; i++)
        {
            contractAddresses[i] = _getAssetAt(i);
        }
    }


    /// @dev Retreives asset and balance info for `account` from the asset at `index`
    /// @param index Asset index
    /// @param accounts Accounts to retrieve the balances for
    /// @return assetInfo Asset info
    function getAssetInfoAt(uint index, address[] memory accounts)
        external view 
        returns (AssetInfo memory assetInfo)
    {
        assetInfo = _getAssetInfoAt(index, accounts);
    }


    /// @dev Retreives asset and balance infos for `accounts` from the assets from `skip` to `skip` plus `take`. 
    /// @param skip Starting index
    /// @param take Amount of asset infos to return
    /// @param accounts Accounts to retrieve the balances for
    /// @return assetInfos Asset infos
    function getAssetInfos(uint skip, uint take, address[] memory accounts)
        external view 
        returns (AssetInfo[] memory assetInfos)
    {
        uint length = take;
        if (assetsIndex.length < skip + take)
        {
            length = assetsIndex.length - skip;
        }

        assetInfos = new AssetInfo[](length);
        for (uint i = 0; i < length; i++)
        {
            assetInfos[i] = _getAssetInfoAt(skip + i, accounts);
        }
    }


    /// @dev Getter for resources
    /// @param resource {Resource}
    /// @return address The resource asset contract address 
    function getAssetByResrouce(Resource resource) 
        public virtual override view 
        returns (address)
    {
        return resources[resource];
    }


    /*
     * Internal functions
     */
    /// @dev Retreives the asset at `index`.
    /// @param index Asset index.
    /// @return contractAddress Address of the asset.
    function _getAssetAt(uint index)
        internal view 
        returns (address contractAddress)
    {
        contractAddress = assets[assetsIndex[index]];
    }


    /// @dev Retreives asset and balance info for `account` from the asset at `index`
    /// @param index Asset index
    /// @param accounts Accounts to retrieve the balances for
    /// @return assetInfo Asset info
    function _getAssetInfoAt(uint index, address[] memory accounts)
        internal view 
        returns (AssetInfo memory assetInfo)
    {
        assetInfo.contractAddress = assets[assetsIndex[index]];
        assetInfo.name = ERC20Upgradeable(assetInfo.contractAddress).name();
        assetInfo.symbol = ERC20Upgradeable(assetInfo.contractAddress).symbol();

        assetInfo.balances = new uint[](accounts.length); 
        for (uint i = 0; i < accounts.length; i++) 
        {
            assetInfo.balances[i] = IERC20(assetInfo.contractAddress)
                .balanceOf(accounts[i]);
        }
    }
}