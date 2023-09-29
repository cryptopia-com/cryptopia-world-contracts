// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "../../../ERC20/retriever/TokenRetriever.sol";
import "../ICryptopiaCaptureToken.sol";

/// @title Cryptopia Capture Token Mint Factory 
/// @dev Non-fungible token (ERC721) factory that mints CryptopiaCapture tokens
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaCaptureTokenMintFactory is OwnableUpgradeable, TokenRetriever {

    struct MintData 
    {
        bool mintable;
        uint mintFee;
    }

    /**
     * Storage
     */
    // Beneficiary
    address payable public beneficiary;

    // Items
    mapping (bytes32 => MintData) mintData;

    // State
    address public token;
    bytes32 private _currentRandomSeed;


    /**
     * Public Functions
     */
    /// @dev Setup the factory
    /// @param _token The token that is minted
    /// @param _beneficiary Funds are withdrawn to this account
    function initialize(address _token, address payable _beneficiary) 
        public initializer 
    {
        __Ownable_init();
        token = _token;
        beneficiary = _beneficiary;
    }


    /// @dev Set the beneficiary
    /// @param _beneficiary Funds are withdrawn to this account
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }


    /// @dev Retreive mint data
    /// @param item of the creature to check
    /// @return mintable True if mintable
    /// @return mintFee Fee to mint an item
    function getMintData(bytes32 item) 
        public view 
        returns (
            bool mintable, 
            uint mintFee
        )
    {
        mintable = mintData[item].mintable;
        mintFee = mintData[item].mintFee;
    }


    /// @dev Mark an item as mintable and set it's mint price
    /// @param item Type of item
    /// @param mintFee Fee to mint an `item`
    function setMintData(bytes32[] memory item, uint[] memory mintFee) 
        public onlyOwner 
    {
        for (uint i = 0; i < item.length; i++)
        {
            (,,uint240 strength) = ICryptopiaCaptureToken(token).getItem(item[i]);
            require(strength != 0, "Item doesn't exist in token contract");

            mintData[item[i]].mintable = true;
            mintData[item[i]].mintFee = mintFee[i];
        }
    }


    /// @dev Mint `items` to `to`
    /// @param items Type of each item being minted
    /// @param to Address to mint to
    function mint(bytes32[] memory items, address to) 
        public payable 
    {
        // Mint items
        uint totalMintFee = 0;
        for (uint i = 0; i < items.length; i++) 
        {
            uint mintFee = _getMintFee(1, items[i]);
            totalMintFee += mintFee;

            // Enforce mint fee
            require(0 != mintFee, "Unable to mint an item without a mint fee");

            ICryptopiaCaptureToken(token).mintTo(
                to, items[i]);
        }

        // Enforce fee
        require(_canPayMintFee(totalMintFee, msg.value), "Unable to pay mint fee");
    }


    /// @dev Returns true if the call has enough ether to pay the minting fee
    /// @param items The items that are being minted
    /// @return bool True if the minting fee can be payed
    function canPayMintFee(bytes32[] memory items) public view returns (bool) {
        return _canPayMintFee(_getMintFee(items), address(msg.sender).balance);
    }


    /// @dev Returns the amount needed to pay the minting fee
    /// @param items The items that are being minted
    /// @return uint The amount needed to pay the minting fee
    function getMintFee(bytes32[] memory items) public view returns (uint) {
        return _getMintFee(items);
    }


    /// @dev Withdraws to beneficiary 
    function withdraw() public {
        beneficiary.transfer(address(this).balance);
    }


    /**
     * Internal Functions
     */
    /// @dev Returns if the call has enough ether to pay the minting fee
    /// @param totalFee Number of items to mint
    /// @param received The amount that was received
    /// @return bool True if the minting fee can be payed
    function _canPayMintFee(uint totalFee, uint received) internal pure returns (bool) {
        return received >= totalFee;
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param items The items that are being minted
    /// @return mintFee The amount needed to pay the minting fee
    function _getMintFee(bytes32[] memory items) internal view returns (uint mintFee) {
        for (uint i = 0; i < items.length; i++)
        {
            mintFee += mintData[items[i]].mintFee;
        }
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param numberOfItemsToMint Number of items to mint
    /// @param item The item that's being minted
    /// @return uint The amount needed to pay the minting fee
    function _getMintFee(uint numberOfItemsToMint, bytes32 item) internal view returns (uint) {
        return mintData[item].mintFee * numberOfItemsToMint;
    }
}