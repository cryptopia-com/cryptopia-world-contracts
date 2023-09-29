// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Cryptopia Market
/// @dev Facilitates the listing of NFT's on the Cryptopia market
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaMarket {

    /// @dev Returns the amount of markets
    /// @return count The amount of markets
    function getMarketCount() 
        external view 
        returns (uint count);


    /// @dev Retrieve a range of markets
    /// @param skip Starting index
    /// @param take Amount of markets
    /// @return erc721 ERC721 contract address
    /// @return listingCount Number of listings
    function getMarkets(uint32 skip, uint32 take) 
        external view 
        returns (
            address[] memory erc721,
            uint[] memory listingCount
        );


    /// @dev Add an `erc721` market
    /// @param erc721 ERC721 contract address
    function addMarket(address erc721)
        external;


    /// @dev Remove a `erc721` market
    /// @param erc721 ERC721 contract address
    function removeMarket(address erc721)
        external;


    /// @dev Returns the amount of accepted assets
    /// @return count The amount of accepted assets
    function getAcceptedAssetCount() 
        external view 
        returns (uint count);


    /// @dev Retrieve a range of accepted assets
    /// @param skip Starting index
    /// @param take Amount of assets
    /// @return asset ERC20 contract address or 0 for native
    function getAcceptedAssets(uint32 skip, uint32 take) 
        external view 
        returns (
            address[] memory asset
        );


    /// @dev Add an accepted `asset`
    /// @param asset ERC20 contract address or 0 for native
    function addAcceptedAsset(address asset)
        external;


    /// @dev Remove an accepted `asset`
    /// @param asset ERC20 contract address or 0 for native
    function removeAcceptedAsset(address asset)
        external;


    /// @dev Returns the amount of listings in `erc721`
    /// @param erc721 ERC721 contract address
    /// @return count The amount of listings
    function getListingCount(address erc721) 
        external view 
        returns (uint count);


    /// @dev Retrieve a range of listings in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param skip Starting index
    /// @param take Amount of offers
    /// @return tokenId Offer identifiers
    /// @return price Price in asset
    /// @return asset ERC20 or native when 0
    /// @return owner Token owner
    function getListings(address erc721, uint32 skip, uint32 take) 
        external view 
        returns (
            uint[] memory tokenId,
            uint[] memory price,
            address[] memory asset,
            address[] memory owner
        );


    /// @dev Retrieve a listing in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to get the listing for
    /// @return isListed True if listed
    /// @return price Price in asset
    /// @return asset ERC20 or native when 0
    /// @return owner Token owner
    function getListing(address erc721, uint tokenId) 
        external view 
        returns (
            bool isListed,
            uint price,
            address asset,
            address owner
        );


    /// @dev List 'tokenId' in `erc721` and transfer ownership to Cryptopia
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to add the listing for
    /// @param price Price in asset
    /// @param asset ERC20 or native when 0
    function addListing(address erc721, uint tokenId, uint price, address asset)
        external;


    /// @dev Update listing for'tokenId' in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to update the listing for
    /// @param price Price in asset
    /// @param asset ERC20 or native when 0
    function updateListing(address erc721, uint tokenId, uint price, address asset)
        external;


    /// @dev Delist 'tokenId' in `erc721` and returns the token to it's owner
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to remove the listing for
    function removeListing(address erc721, uint tokenId)
        external;


    /// @dev Buy listed token with 'tokenId' in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to remove the listing for
    function buyToken(address erc721, uint tokenId)
        external payable;


    /// @dev Returns the min amount of `asset` that that is required to submit an offer in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param asset Asset that the offer is made in
    function getMinOfferValue(address erc721, address asset)
        external view returns (uint value);


    /// @dev Sets the min amount of `asset` that that is required to submit an offer in the `erc721` market
    /// @param erc721 ERC721 contract address
    /// @param asset Asset that the offer is made in
    /// @param value The min amount required to submit an offer
    function setMinOfferValue(address erc721, address asset, uint value)
        external;


    /// @dev Returns the amount of offers for `tokenId` in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to retrieve the listing status for
    /// @param asset Asset in which the offers are denoted
    /// @return count The amount of offers
    function getOfferCount(address erc721, uint tokenId, address asset) 
        external view returns (uint count);


    /// @dev Retrieve an offers for `tokenId` in `erc721` by `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to retrieve offers for
    /// @param offerId Unique ID within the listing space
    /// @return value Offer value in valueAsset
    /// @return valueAsset ERC20 or native when 0
    /// @return account Offer identifiers
    function getOffer(address erc721, uint tokenId, bytes32 offerId) 
        external view 
        returns (
            uint value,
            address valueAsset,
            address account
        );


    /// @dev Retrieve a range of offers for `tokenId` in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID to retrieve offers for
    /// @param asset Retrieve offers that are denoted in this asset
    /// @param start Starting offer ID
    /// @param take Amount of offers
    /// @return offerId Offer identifiers
    /// @return value Offer value in valueAsset
    /// @return account Offer identifiers
    function getOffers(address erc721, uint tokenId, address asset, bytes32 start, uint32 take) 
        external view 
        returns (
            bytes32[] memory offerId,
            uint[] memory value,
            address[] memory account
        );


    /// @dev Add an offer for `tokenId` in `erc721`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param value Offer value
    /// @param valueAsset Asset that the value is denoted in
    function addOffer(address erc721, uint tokenId, uint value, address valueAsset)
        external payable;


    /// @dev Remove the offer for `tokenId` in `erc721` with `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param offerId Unique ID within the listing space
    function removeOffer(address erc721, uint tokenId, bytes32 offerId)
        external;


    /// @dev Accept the offer for `tokenId` in `erc721` with `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param offerId Unique ID within the listing space
    function acceptOffer(address erc721, uint tokenId, bytes32 offerId)
        external;


    /// @dev Decline the offer for `tokenId` in `erc721` with `offerId`
    /// @param erc721 ERC721 contract address
    /// @param tokenId Token ID add an offer for
    /// @param offerId Unique ID within the listing space
    function declineOffer(address erc721, uint tokenId, bytes32 offerId)
        external;
}