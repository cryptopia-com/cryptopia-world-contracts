// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";

import "../../../authentication/IAuthenticator.sol";
import "../../ERC20/concrete/CryptopiaERC20Retriever.sol";

/// @title Cryptopia ERC721 
/// @notice Non-fungible token that extends Openzeppelin ERC721
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
abstract contract CryptopiaERC721 is ERC721EnumerableUpgradeable, AccessControlUpgradeable, CryptopiaERC20Retriever {

    /**
     * Roles
     */
    bytes32 constant internal SYSTEM_ROLE = keccak256("SYSTEM_ROLE");


    /**
     *  Storage
     */
    string private _contractURI;
    string private _baseTokenURI;

    /// Refs
    IAuthenticator public authenticator;


    /// @dev Contract initializer sets shared base uri
    /// @param _name Token name (long)
    /// @param _symbol Token ticker symbol (short)
    /// @param _authenticator Whitelist
    /// @param _initialContractURI Location to contract info
    /// @param _initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function __CryptopiaERC721_init(
        string memory _name, 
        string memory _symbol, 
        address _authenticator,  
        string memory _initialContractURI, 
        string memory _initialBaseTokenURI) 
        internal onlyInitializing
    {
        __AccessControl_init();
        __ERC721_init(_name, _symbol);
        __ERC721Enumerable_init_unchained();
        __CryptopiaERC721_init_unchained(
            _authenticator, 
            _initialContractURI, 
            _initialBaseTokenURI);
    }


    /// @dev Contract initializer sets shared base uri
    /// @param _authenticator Whiteliste for proxies
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function __CryptopiaERC721_init_unchained(
        address _authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI) 
        internal onlyInitializing
    {
        authenticator = IAuthenticator(_authenticator);
        _contractURI = initialContractURI;
        _baseTokenURI = initialBaseTokenURI;

        // Grant admin role
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /** 
     * Admin functions
     */
    /// @dev Set contract URI
    /// @param uri Location to contract info
    function setContractURI(string memory uri) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        _contractURI = uri;
    }


    /// @dev Set base token URI 
    /// @param uri Base of location where token data is stored. To be postfixed with tokenId
    function setBaseTokenURI(string memory uri) 
        public virtual  
        onlyRole(DEFAULT_ADMIN_ROLE)  
    {
        _baseTokenURI = uri;
    }


    /// @dev Failsafe mechanism
    /// Allows the owner to retrieve tokens from the contract that 
    /// might have been send there by accident
    /// @param tokenContract The address of ERC20 compatible token
    function retrieveTokens(address tokenContract) 
        public virtual override  
        onlyRole(DEFAULT_ADMIN_ROLE) 
    {
        super.retrieveTokens(tokenContract);
    }


    /** 
     * Public functions
     */
    /// @dev Get contract URI
    /// @return location to contract info
    function getContractURI() 
        public virtual view 
        returns (string memory) 
    {
        return _contractURI;
    }


    /// @dev Get base token URI 
    /// @return Base of location where token data is stored. To be postfixed with tokenId
    function getBaseTokenURI() 
        public virtual view 
        returns (string memory) 
    {
        return _baseTokenURI;
    }


    /// @dev getTokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param tokenId Token ID
    /// @return uri where token data can be retrieved
    function getTokenURI(uint tokenId) 
        public virtual view 
        returns (string memory) 
    {
        return string(abi.encodePacked(getBaseTokenURI(), tokenId));
    }


    /// @dev tokenURI() postfixed with the token ID baseTokenURI(){tokenID}
    /// @param tokenId Token ID
    /// @return uri where token data can be retrieved
    function tokenURI(uint tokenId) 
        public override view 
        returns (string memory)
    {
        return getTokenURI(tokenId);
    }


    /// @dev Returns whether `spender` is authorized to manage `tokenId`
    /// @param owner Owner of the token
    /// @param spender Account to check
    /// @param tokenId Token id to check
    /// @return true if `spender` is allowed ot manage `_tokenId`
    function isAuthorized(address owner, address spender, uint256 tokenId) 
        public view 
        returns (bool)
    {
        return _isAuthorized(owner, spender, tokenId);
    }


    /// @dev Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings
    /// @param owner Token owner
    /// @param operator Operator to check
    /// @return bool true if `_operator` is approved for all
    function isApprovedForAll(address owner, address operator) 
        public override(ERC721Upgradeable, IERC721) view 
        returns (bool) 
    {
        if (authenticator.authenticate(operator)) 
        {
            return true; // Whitelisted proxy contract for easy trading
        }

        return super.isApprovedForAll(owner, operator);
    }

    
    /// @dev Calls supportsInterface for all parent contracts 
    /// @param interfaceId The signature of the interface
    /// @return bool True if `interfaceId` is supported
    function supportsInterface(bytes4 interfaceId) 
        override(ERC721EnumerableUpgradeable, AccessControlUpgradeable) 
        public virtual view 
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }
}