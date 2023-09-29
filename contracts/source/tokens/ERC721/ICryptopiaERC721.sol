// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title ICryptopiaERC721
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaERC721 {

    /// @dev Get contract URI
    /// @return location to contract info
    function getContractURI() 
        external view 
        returns (string memory);


    /// @dev Set contract URI
    /// @param uri Location to contract info
    function setContractURI(string memory uri) 
        external;


    /// @dev Get base token URI 
    /// @return base of location where token data is stored. To be postfixed with tokenId
    function getBaseTokenURI() 
        external view 
        returns (string memory);


    /// @dev Set base token URI 
    /// @param uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory uri) 
        external;


    /// @dev getTokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param tokenId Token ID
    /// @return location where token data is stored
    function getTokenURI(uint tokenId) 
        external view 
        returns (string memory);


    /// @dev Returns whether `_spender` is allowed to manage `_tokenId`
    /// @param spender Account to check
    /// @param tokenId Token id to check
    /// @return true if `spender` is allowed ot manage `_tokenId`
    function isApprovedOrOwner(address spender, uint256 tokenId) external view returns (bool);
}