// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

import "./ICryptopiaMarket.sol";

/// @title Cryptopia Market
/// @dev Facilitates the listing of NFT's on the Cryptopia market
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaMarket is ICryptopiaMarket, OwnableUpgradeable {

    // Libs
    using SafeMathUpgradeable for uint;

    /// @dev To prevent stack depth error
    struct InternalStorage 
    {
        address listing_owner;
        address offer_account;
        address offer_asset;
        uint offer_value;
    }

    /// @dev Arbitrary offer
    struct Offer 
    {
        /// @dev Ordered iterating - Offer that was submitted after us (above us in the list)
        bytes32 chain_next;

        /// @dev Ordered iterating - Offer that was submitted before us (below us in the list)
        bytes32 chain_prev;

        /// @dev Offer value in asset
        uint value;

        /// @dev ERC20 or native when 0
        address asset;

        /// @dev Account that made the offer
        address account;
    }

    /// @dev Listing of a single token in an ERC721 compatible contact
    struct Listing 
    {
        /// @dev Unordered iterating
        uint index;

        /// @dev price in asset
        uint price;

        /// @dev ERC20 or native when 0
        address asset;

        /// @dev Token owner
        address owner;

        /// @dev asset => Offer count 
        mapping(address => uint) offerCount;

        /// @dev asset => Offer ID (Heads of linked lists)
        mapping(address => bytes32) bestOffer;

        /// @dev offerId => Offer
        mapping(bytes32 => Offer) offers;
    }

    /// @dev Market for an ERC721 compatible asset
    struct Market 
    {
        /// @dev Unordered iterating
        uint index;

        /// @dev tokenId => Listing
        mapping (uint => Listing) listings;
        uint[] listingsIndex;
    }

    /// @dev erc721 => Market
    mapping(address => Market) private markets;
    address[] private marketsIndex; 

    /// @dev ERC20 (or native when 0) => index
    mapping (address => uint) private acceptedAssets;
    address[] private acceptedAssetsIndex;

    /// @dev erc721 => asset (ERC20 or native when 0) => uint
    mapping(address => mapping(address => uint)) private minOfferValue;


    /**
     * Events
     */
    /// @dev Emitted when a market is added
    /// @param erc721 ERC721 contract address
    event MarketAdd(address indexed erc721);

    /// @dev Emitted when a market is removed
    /// @param erc721 ERC721 contract address
    event MarketRemove(address indexed erc721);

    /// @dev Emitted when a token is listed
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID that was added
    /// @param owner Account that owns the token
    event ListingAdd(address indexed erc721, uint indexed tokenId, address indexed owner);

    /// @dev Emitted when a token listing is updated
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID that was updated
    /// @param owner Account that owns the token
    event ListingUpdate(address indexed erc721, uint indexed tokenId, address indexed owner);

    /// @dev Emitted when a token listing is removed
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID that was removed
    /// @param owner Account that owns the token
    event ListingRemove(address indexed erc721, uint indexed tokenId, address indexed owner);

    /// @dev Emitted when an offer is added
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID that the offer is for
    /// @param account Account that the offer belongs to
    /// @param offerId ID composed of erc721, tokenId, value and asset
    event OfferAdd(address indexed erc721, uint indexed tokenId, address indexed account, bytes32 offerId);

    /// @dev Emitted when an offer is removed
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID that the offer is for
    /// @param account Account that the offer belongs to
    /// @param offerId ID composed of erc721, tokenId, value and asset
    event OfferRemove(address indexed erc721, uint indexed tokenId, address indexed account, bytes32 offerId);


    /**
     * Modifiers
     */
    /// @dev Requires that the `erc721` market exists
    /// @param erc721 ERC721 contract address
    modifier onlyExistingMarket(address erc721)
    {
        require(_marketExists(erc721), "Non-existing market");
        _;
    }


    /// @dev Requires that the `asset` is accepted
    /// @param asset ERC20 contract address or 0 when native
    modifier onlyAcceptedAsset(address asset)
    {
        require(_isAcceptedAsset(asset), "Asset not accepted");
        _;
    }


    /// @dev Requires that `tokenId` is listed in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to test against
    modifier onlyListed(address erc721, uint tokenId)
    {
        require(_isListed(erc721, tokenId), "Token not listed");
        _;
    }


    /// @dev Requires that `tokenId` is not listed
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to test against
    modifier onlyUnlisted(address erc721, uint tokenId)
    {
        require(!_isListed(erc721, tokenId), "Token is listed");
        _;
    }


    /// @dev Requires that sender is the owner of `tokenId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to test against
    modifier onlyTokenOwner(address erc721, uint tokenId)
    {
        require(
            (_isListed(erc721, tokenId) && markets[erc721].listings[tokenId].owner == _msgSender()) || 
            IERC721Upgradeable(erc721).ownerOf(tokenId) == _msgSender(), 
            "Sender is not the token owner"
        );
        _;
    }


    /// @dev Requires that an offer with `offerId` exists for token `tokenId` in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to test against
    /// @param offerId Offer ID to test against
    modifier onlyExistingOffer(address erc721, uint tokenId, bytes32 offerId)
    {
        require(_offerExists(erc721, tokenId, offerId), "Non-existing offer");
        _;
    }


    /// @dev Requires that sender is the owner of the offer with `offerId` for token `tokenId` in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to test against
    /// @param offerId Offer ID to test against
    modifier onlyOfferOwner(address erc721, uint tokenId, bytes32 offerId)
    {
        require(
            markets[erc721].listings[tokenId].offers[offerId].account == _msgSender(), 
            "Sender is not the offer owner"
        );
        _;
    }


    /** 
     * Public functions
     */
    /// @dev Contract initializer
    /// @param _markets Initial markets
    /// @param _assets Initial accepted assets
    function initialize(address[] memory _markets, address[] memory _assets) 
        public initializer
    {
        __Ownable_init();

        // Add markets
        for (uint i = 0; i < _markets.length; i++)
        {
            marketsIndex.push(_markets[i]);
            markets[_markets[i]].index = marketsIndex.length - 1;
        }

        // Add assets
        for (uint i = 0; i < _assets.length; i++)
        {
            acceptedAssetsIndex.push(_assets[i]);
            acceptedAssets[_assets[i]] = acceptedAssetsIndex.length - 1;
        }
    }


    /// @dev Returns the amount of markets
    /// @return count The amount of markets
    function getMarketCount() 
        public virtual override view 
        returns (uint count)
    {
        count = marketsIndex.length;
    }


    /// @dev Retrieve a range of markets
    /// @param skip Starting index
    /// @param take Amount of offers
    /// @return erc721 ERC721 contract address
    /// @return listingCount Number of listings
    function getMarkets(uint32 skip, uint32 take) 
        public virtual override view 
        returns (
            address[] memory erc721,
            uint[] memory listingCount
        )
    {
        erc721 = new address[](take);
        listingCount = new uint[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            erc721[i] = marketsIndex[index];
            listingCount[i] = markets[erc721[i]].listingsIndex.length;
            index++;
        }
    }


    /// @dev Add an `erc721` market
    /// @param erc721 ERC721 contract address
    function addMarket(address erc721)
        public virtual override 
        onlyOwner()
    {
        // Require non-existing market
        require(!_marketExists(erc721), "Market already exists");

        // Add market
        marketsIndex.push(erc721);
        markets[erc721].index = marketsIndex.length - 1;

        // Emit
        emit MarketAdd(erc721);
    }


    /// @dev Remove a `erc721` market
    /// @param erc721 ERC721 contract address
    function removeMarket(address erc721)
        public virtual override 
        onlyOwner() 
        onlyExistingMarket(erc721) 
    {
        // Remove market
        Market storage market = markets[erc721];
        marketsIndex[market.index] = marketsIndex[marketsIndex.length - 1];
        marketsIndex.pop();

        // Emit
        emit MarketRemove(erc721);
    }


    /// @dev Returns the amount of accepted assets
    /// @return count The amount of accepted assets
    function getAcceptedAssetCount() 
        public virtual override view 
        returns (uint count)
    {
        return acceptedAssetsIndex.length;
    }


    /// @dev Retrieve a range of accepted assets
    /// @param skip Starting index
    /// @param take Amount of assets
    /// @return asset ERC20 contract address or 0 for native
    function getAcceptedAssets(uint32 skip, uint32 take) 
        public virtual override view 
        returns (
            address[] memory asset
        )
    {
        asset = new address[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            asset[i] = acceptedAssetsIndex[index];
            index++;
        }
    }


    /// @dev Add an accepted `asset`
    /// @param asset ERC20 contract address or 0 for native
    function addAcceptedAsset(address asset)
        public virtual override 
        onlyOwner()
    {
        // Require not accepted asset
        require(!_isAcceptedAsset(asset), "Asset already accepted");

        // Add market
        acceptedAssetsIndex.push(asset);
        acceptedAssets[asset] = acceptedAssetsIndex.length - 1;
    }


    /// @dev Remove an accepted `asset`
    /// @param asset ERC20 contract address or 0 for native
    function removeAcceptedAsset(address asset)
        public virtual override 
        onlyOwner() 
        onlyAcceptedAsset(asset) 
    {
        // Remove accepted asset
        acceptedAssetsIndex[acceptedAssets[asset]] = acceptedAssetsIndex[acceptedAssetsIndex.length - 1];
        acceptedAssetsIndex.pop();
    }


    /// @dev Returns the amount of listings in `erc721`
    /// @param erc721 ERC721 contract address
    /// @return count The amount of listings
    function getListingCount(address erc721) 
        public virtual override view 
        returns (uint count)
    {
        count = markets[erc721].listingsIndex.length;
    }


    /// @dev Retrieve a range of listings in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param skip Starting index
    /// @param take Amount of offers
    /// @return tokenId Offer identifiers
    /// @return price Price in asset
    /// @return asset ERC20 or native when 0
    /// @return owner Token owner
    function getListings(address erc721, uint32 skip, uint32 take) 
        public virtual override view 
        returns (
            uint[] memory tokenId,
            uint[] memory price,
            address[] memory asset,
            address[] memory owner
        )
    {
        tokenId = new uint[](take);
        price = new uint[](take);
        asset = new address[](take);
        owner = new address[](take);

        uint index = skip;
        for (uint i = 0; i < take; i++)
        {
            tokenId[i] = markets[erc721].listingsIndex[index];
            Listing storage listing = markets[erc721].listings[tokenId[i]];
            price[i] = listing.price;
            asset[i] = listing.asset;
            owner[i] = listing.owner;
            index++;
        }
    }


    /// @dev Retrieve a listing in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to get the listing for
    /// @return isListed True if listed
    /// @return price Price in asset
    /// @return asset ERC20 or native when 0
    /// @return owner Token owner
    function getListing(address erc721, uint tokenId) 
        public virtual override view 
        returns (
            bool isListed,
            uint price,
            address asset,
            address owner
        )
    {
        isListed = _isListed(erc721, tokenId);
        if (isListed)
        {
            Listing storage listing = markets[erc721].listings[tokenId];
            price = listing.price;
            asset = listing.asset;
            owner = listing.owner;
        }
    }

    
    /// @dev List 'tokenId' in `erc721` and transfer ownership to Cryptopia
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to add the listing for
    /// @param price Price in asset
    /// @param asset ERC20 or native when 0
    function addListing(address erc721, uint tokenId, uint price, address asset)
        public virtual override 
        onlyAcceptedAsset(asset) 
        onlyExistingMarket(erc721) 
        onlyUnlisted(erc721, tokenId) 
        onlyTokenOwner(erc721, tokenId)
    {
        // Transfer 
        IERC721Upgradeable(erc721).transferFrom(_msgSender(), address(this), tokenId);

        // Create 
        Listing storage listing = markets[erc721].listings[tokenId];
        markets[erc721].listingsIndex.push(tokenId);
        listing.index = markets[erc721].listingsIndex.length - 1;
        listing.price = price;
        listing.asset = asset;
        listing.owner = _msgSender();

        // Emit
        emit ListingAdd(erc721, tokenId, listing.owner);
    }


    /// @dev Update listing for'tokenId' in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to update the listing for
    /// @param price Price in asset
    /// @param asset ERC20 or native when 0
    function updateListing(address erc721, uint tokenId, uint price, address asset)
        public virtual override 
        onlyAcceptedAsset(asset) 
        onlyExistingMarket(erc721) 
        onlyListed(erc721, tokenId) 
        onlyTokenOwner(erc721, tokenId)
    {
        // Update 
        Listing storage listing = markets[erc721].listings[tokenId];
        listing.price = price;
        listing.asset = asset;

        // Emit
        emit ListingUpdate(erc721, tokenId, listing.owner);
    }


    /// @dev Delist 'tokenId' in `erc721` and returns the token to it's owner
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to remove the listing for
    function removeListing(address erc721, uint tokenId)
        public virtual override 
        onlyListed(erc721, tokenId) 
        onlyTokenOwner(erc721, tokenId) 
    {
        // Remove 
        _removeListing(erc721, tokenId);

        // Transfer 
        IERC721Upgradeable(erc721).transferFrom(
            address(this), _msgSender(), tokenId);

        // Emit
        emit ListingRemove(erc721, tokenId, _msgSender());
    }


    /// @dev Buy listed token with 'tokenId' in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to remove the listing for
    function buyToken(address erc721, uint tokenId)
        public payable virtual override 
        onlyExistingMarket(erc721) 
        onlyListed(erc721, tokenId) 
    {
        // Remove listing (only index is removed)
        _removeListing(erc721, tokenId);

        Listing storage listing = markets[erc721].listings[tokenId];
        address sender = _msgSender();

        // Require non-owner
        require(sender != listing.owner, "Already owned");

        // Require price
        require(listing.price > 0, "Missing price");

        // Native
        if (address(0) == listing.asset)
        {
            // Require payment
            require(msg.value == listing.price, "Payment failed (Native)");
            (bool success,) = sender.call{value: listing.price}("");
            require(success, "Payment failed (Native)");
        }

        // ERC20
        else 
        {
            // Require payment
            require(
                IERC20Upgradeable(listing.asset)
                    .transferFrom(sender, listing.owner, listing.price), 
                "Payment failed (ERC20)"
            );
        }

        // Transfer 
        IERC721Upgradeable(erc721).transferFrom(
            address(this), sender, tokenId);

        // Emit
        emit ListingRemove(erc721, tokenId, listing.owner);
    }


    /// @dev Returns the min amount of `asset` that that is required to submit an offer in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param asset Asset that the offer is made in
    function getMinOfferValue(address erc721, address asset)
        public virtual override view
        returns (uint value)
    {
        value = minOfferValue[erc721][asset];
    }


    /// @dev Sets the min amount of `asset` that that is required to submit an offer in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param asset Asset that the offer is made in
    /// @param value The min amount required to submit an offer
    function setMinOfferValue(address erc721, address asset, uint value)
        public virtual override 
        onlyOwner() 
    {
        minOfferValue[erc721][asset] = value;
    }


    /// @dev Returns the amount of offers for `tokenId` in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to retrieve the listing status for
    /// @param asset Asset in which the offers are denoted
    /// @return count The amount of offers
    function getOfferCount(address erc721, uint tokenId, address asset) 
        public virtual override view 
        returns (uint count)
    {
        count = markets[erc721].listings[tokenId].offerCount[asset];
    }


    /// @dev Retrieve an offers for `tokenId` in `erc721` by `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to retrieve offers for
    /// @param offerId Unique ID within the listing space
    /// @return value Offer value in asset
    /// @return asset ERC20 or native when 0
    /// @return account Offer identifiers
    function getOffer(address erc721, uint tokenId, bytes32 offerId) 
        public virtual override view  
        returns (
            uint value,
            address asset,
            address account
        )
    {
        Offer storage offer = markets[erc721].listings[tokenId].offers[offerId];
        value = offer.value;
        asset = offer.asset;
        account = offer.account;
    }


    /// @dev Retrieve a range of offers for `tokenId` in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to retrieve offers for
    /// @param asset Retrieve offers that are denoted in this asset
    /// @param start Starting offer
    /// @param take Amount of offers
    /// @return offerId Offer identifiers
    /// @return value Offer value in asset
    /// @return account Offer identifiers
    function getOffers(address erc721, uint tokenId, address asset, bytes32 start, uint32 take) 
        public virtual override view  
        returns (
            bytes32[] memory offerId,
            uint[] memory value,
            address[] memory account
        )
    {
        offerId = new bytes32[](take);
        value = new uint[](take);
        account = new address[](take);

        Listing storage listing = markets[erc721].listings[tokenId];
        if (start == 0)
        {
            start = listing.bestOffer[asset]; // Head of the chain
        }
        else 
        {
            require(listing.offers[start].asset == asset, "Asset mismatch");
        }

        bytes32 currentOfferId = start;
        Offer storage currentOffer = listing.offers[currentOfferId];
        for (uint i = 0; i < take; i++)
        {
            offerId[i] = currentOfferId;
            value[i] = currentOffer.value;
            account[i] = currentOffer.account;
            currentOfferId = currentOffer.chain_prev;
            currentOffer = listing.offers[currentOffer.chain_prev];
        }
    }


    /// @dev Add an offer for `tokenId` in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param value Offer value
    /// @param asset Asset that the value is denoted in
    function addOffer(address erc721, uint tokenId, uint value, address asset)
        public payable virtual override 
        onlyAcceptedAsset(asset) 
        onlyExistingMarket(erc721) 
    {
        // Require valid value
        require(value > 0, "Zero value");
        require(value >= minOfferValue[erc721][asset], "Value too low (min)");

        Listing storage listing = markets[erc721].listings[tokenId];
        require(value > listing.offers[listing.bestOffer[asset]].value, "Value too low (overbid)");

        bytes32 offerId = keccak256(
            abi.encodePacked(erc721, tokenId, value, asset));

        // Require non duplicate
        require(!_offerExists(erc721, tokenId, offerId), "Duplicate offer");

        // Create
        Offer storage offer = listing.offers[offerId];
        offer.chain_next = 0;
        offer.chain_prev = listing.bestOffer[asset];
        offer.value = value;
        offer.asset = asset;
        offer.account = _msgSender();

        // Update
        listing.offers[listing.bestOffer[asset]].chain_next = offerId;
        listing.bestOffer[asset] = offerId;
        listing.offerCount[asset]++;

        // Native
        if (address(0) == asset)
        {
            // Require payment
            require(msg.value == value, "Payment failed (Native)");
        }

        // ERC20
        else 
        {
            // Require payment
            require(
                IERC20Upgradeable(asset)
                    .transferFrom(offer.account, address(this), value), 
                "Payment failed (ERC20)"
            );
        }

        // Emit
        emit OfferAdd(erc721, tokenId, offer.account, offerId);
    }


    /// @dev Remove the offer for `tokenId` in `erc721` with `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param offerId Unique ID within the listing space
    function removeOffer(address erc721, uint tokenId, bytes32 offerId)
        public virtual override 
        onlyExistingOffer(erc721, tokenId, offerId) 
        onlyOfferOwner(erc721, tokenId, offerId) 
    {
        Offer storage offer = markets[erc721].listings[tokenId].offers[offerId];
        uint value = offer.value; 

        // Remove offer
        _removeOffer(erc721, tokenId, offerId);

        // Native
        if (address(0) == offer.asset)
        {
            // Return payment
            (bool success,) = payable(offer.account).call{value: value}("");
            require(success, "Payment failed (Native)");
        }

        // ERC20
        else 
        {
            // Return payment
            require(
                IERC20Upgradeable(offer.asset)
                    .transferFrom(address(this), offer.account, value), 
                "Payment failed (ERC20)"
            );
        }

        // Emit
        emit OfferRemove(erc721, tokenId, offer.account, offerId);
    }


    /// @dev Accept the offer for `tokenId` in `erc721` with `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param offerId Unique ID within the listing space
    function acceptOffer(address erc721, uint tokenId, bytes32 offerId)
        public virtual override 
        onlyExistingMarket(erc721) 
        onlyListed(erc721, tokenId) 
        onlyTokenOwner(erc721, tokenId) 
        onlyExistingOffer(erc721, tokenId, offerId) 
    {
        InternalStorage memory store;
        store.listing_owner = markets[erc721].listings[tokenId].owner;
        store.offer_account = markets[erc721].listings[tokenId].offers[offerId].account;
        store.offer_asset = markets[erc721].listings[tokenId].offers[offerId].asset;
        store.offer_value = markets[erc721].listings[tokenId].offers[offerId].value; // Value is set to 0 by _removeOffer()

        // Remove listing (only index is removed)
        _removeListing(erc721, tokenId);

        // Remove offer
        _removeOffer(erc721, tokenId, offerId);

        // Native
        if (address(0) == store.offer_asset)
        {
            // Require payment
            (bool success,) = payable(store.listing_owner).call{value: store.offer_value}("");
            require(success, "Payment failed (Native)");
        }

        // ERC20
        else 
        {
            // Require payment
            require(
                IERC20Upgradeable(store.offer_asset)
                    .transferFrom(address(this), store.listing_owner, store.offer_value), 
                "Payment failed (ERC20)"
            );
        }

        // Transfer token
        IERC721Upgradeable(erc721).transferFrom(
            address(this), store.offer_account, tokenId);

        // Emit
        emit ListingRemove(erc721, tokenId, store.listing_owner);
        emit OfferRemove(erc721, tokenId, store.offer_account, offerId);
    }


    /// @dev Decline the offer for `tokenId` in `erc721` with `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param offerId Unique ID within the listing space
    function declineOffer(address erc721, uint tokenId, bytes32 offerId)
        public virtual override 
        onlyTokenOwner(erc721, tokenId) 
        onlyExistingOffer(erc721, tokenId, offerId) 
    {
        Offer storage offer = markets[erc721].listings[tokenId].offers[offerId];

        // Remove offer
        _removeOffer(erc721, tokenId, offerId);

        // Native
        if (address(0) == offer.asset)
        {
            // Return payment
            (bool success,) = payable(offer.account).call{value: offer.value}("");
            require(success, "Payment failed (Native)");
        }

        // ERC20
        else 
        {
            // Return payment
            require(
                IERC20Upgradeable(offer.asset)
                    .transferFrom(address(this), offer.account, offer.value), 
                "Payment failed (ERC20)"
            );
        }

        // Emit
        emit OfferRemove(erc721, tokenId, offer.account, offerId);
    }


    /** 
     * Internal functions
     */
    /// @dev True if the `erc721` market exists
    /// @param erc721 ERC721 contract address
    function _marketExists(address erc721) 
        internal view returns (bool) 
    {
        return marketsIndex.length > markets[erc721].index && 
            erc721 == marketsIndex[markets[erc721].index];
    }


    /// @dev True if the `asset` is accepted
    /// @param asset ERC20 contract address or native if 0
    function _isAcceptedAsset(address asset) 
        internal view returns (bool) 
    {
        return acceptedAssetsIndex.length > 0 && 
            asset == acceptedAssetsIndex[acceptedAssets[asset]];
    }


    /// @dev True if `tokenId` is listed in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to test against
    function _isListed(address erc721, uint tokenId) 
        internal view returns (bool) 
    {
        return markets[erc721].listingsIndex.length > markets[erc721].listings[tokenId].index && 
            tokenId == markets[erc721].listingsIndex[markets[erc721].listings[tokenId].index];
    }


    /// @dev Delist 'tokenId' in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to remove the listing for
    function _removeListing(address erc721, uint tokenId) 
        internal 
    {
        Market storage market = markets[erc721];
        market.listingsIndex[market.listings[tokenId].index] = market.listingsIndex[market.listingsIndex.length - 1];
        market.listingsIndex.pop();
    }


    /// @dev True if the offer for `tokenId` in `erc721` with `offerId` exists
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param offerId ID composed of erc721, tokenId, value and asset
    function _offerExists(address erc721, uint tokenId, bytes32 offerId) 
        internal view returns (bool) 
    {
        return markets[erc721].listings[tokenId].offers[offerId].value > 0;
    }


    /// @dev Remove the offer with `offerId` for `tokenId` in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to remove the listing for
    /// @param offerId ID composed of erc721, tokenId, value and asset
    function _removeOffer(address erc721, uint tokenId, bytes32 offerId) 
        internal 
    {
        Listing storage listing = markets[erc721].listings[tokenId];
        if (listing.offers[offerId].chain_next == 0)
        {
            // Fix chain (replace head)
            listing.bestOffer[listing.offers[offerId].asset] = listing.offers[offerId].chain_prev;
            listing.offers[listing.offers[offerId].chain_prev].chain_next = 0;
        }
        else 
        {
            // Fix chain (connect prev to next)
            listing.offers[listing.offers[offerId].chain_next].chain_prev = listing.offers[offerId].chain_prev;
            listing.offers[listing.offers[offerId].chain_prev].chain_next = listing.offers[offerId].chain_next;
        }

        // Invalidate offer
        listing.offers[offerId].value = 0;

        // Update stats
        markets[erc721].listings[tokenId].offerCount[listing.offers[offerId].asset]--;
    }
}