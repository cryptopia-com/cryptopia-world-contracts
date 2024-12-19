// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../../game/inventories/types/InventoryEnums.sol";
import "../../../../game/inventories/errors/InventoryErrors.sol";
import "../../../../game/quests/rewards/INonFungibleQuestReward.sol";
import "../../blueprints/IBlueprints.sol";
import "../CryptopiaERC721.sol";

/// @title Cryptopia Blueprints
/// @notice Non-fungible token that represends blueprints in Cryptopia
/// @dev Implements the ERC721 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaBlueprintToken is CryptopiaERC721, IBlueprints, INonFungibleQuestReward {

    /**
     * Storage
     */
    uint private _currentTokenId; 

    /// @dev tokenId => building
    mapping(uint => bytes32) public blueprintInstances;


     /**
     * Events
     */
    /// @dev Emitted when a blueprint is minted
    /// @param tokenId The id of the minted blueprint
    /// @param blueprint The name of the minted blueprint
    /// @param to The player or account that received the minted blueprint
    event BlueprintMinted(uint indexed tokenId, bytes32 blueprint, address to);

    /// @dev Emitted when a blueprint is burned
    /// @param tokenId The id of the burned blueprint
    /// @param blueprint The name of the burned blueprint
    event BlueprintBurned(uint indexed tokenId, bytes32 blueprint);


    /// @dev Contract initializer sets shared base uri
    /// @param _authenticator Whitelist for easy trading
    /// @param initialContractURI Location to contract info
    /// @param initialBaseTokenURI Base of location where token data is stored. To be postfixed with tokenId
    function initialize(
        address _authenticator, 
        string memory initialContractURI, 
        string memory initialBaseTokenURI) 
        public initializer 
    {
        __CryptopiaERC721_init(
            "Cryptopia Blueprints", "BLUERPINT", _authenticator, initialContractURI, initialBaseTokenURI);
    }


    /**
     * Admin functions
     */
    /// @dev Mint a new blueprint
    /// @param blueprint The name of the blueprint
    /// @param to The address to mint the blueprint to
    function mint(bytes32 blueprint, address to) 
        public virtual
        onlyRole(MINTER_ROLE)
        returns (uint tokenId)
    {
        // Mint
        tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();
        blueprintInstances[tokenId] = blueprint;

        // Emit event
        emit BlueprintMinted(tokenId, blueprint, to);
    }


    /** 
     * Public functions
     */
    /// @dev Retrieves the building of the blueprint with `tokenId`
    /// @param tokenId The blueprint token ID
    /// @return building unique name
    function getBuilding(uint tokenId) 
        public virtual override view   
        returns(bytes32)
    {
        return blueprintInstances[tokenId];
    }


    /**
     * System functions
     */
    /// @dev Mints a blueprint to an address
    /// @param to address of the owner of the blueprint
    /// @param blueprint Unique building name
    function __mintTo(address to, bytes32 blueprint)  
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
    {
        uint tokenId = _getNextTokenId();
        _mint(to, tokenId);
        _incrementTokenId();
        blueprintInstances[tokenId] = blueprint;

        // Emit event
        emit BlueprintMinted(tokenId, blueprint, to);
    }


    /// @dev Mint a quest reward
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param blueprint The item to mint
    function __mintQuestReward(address player, Inventory inventory, bytes32 blueprint)
        public virtual override 
        onlyRole(SYSTEM_ROLE) 
        returns (uint tokenId)
    {
        tokenId = _mintReward(player, inventory, blueprint);
    }


    /// @dev Destroys `tokenId`.
    /// @notice The approval is cleared when the token is burned.
    /// @notice This is an internal function that does not check if the sender is authorized to operate on the token.
    /// @param tokenId The blueprint token ID 
    function __burn(uint tokenId) 
        public virtual override
        onlyRole(SYSTEM_ROLE)  
    {
        // Burn token
        _burn(tokenId);

        // Emit event
        emit BlueprintBurned(tokenId, blueprintInstances[tokenId]);

        // Remove instance
        delete blueprintInstances[tokenId];
    }


    /**
     * Private functions
     */
    /// @dev calculates the next token ID based on value of _currentTokenId
    /// @return uint for the next token ID
    function _getNextTokenId() private view returns (uint) 
    {
        return _currentTokenId + 1;
    }


    /// @dev increments the value of _currentTokenId
    function _incrementTokenId() private 
    {
        _currentTokenId++;
    }


     /// @dev Mint a reward
    /// @param player The player to mint the item to
    /// @param inventory The inventory to mint the item to
    /// @param blueprint The item to mint
    function _mintReward(address player, Inventory inventory, bytes32 blueprint)
        internal 
        returns (uint tokenId)
    {
        tokenId = _getNextTokenId();
        _incrementTokenId();
        blueprintInstances[tokenId] = blueprint;

        // Only into wallet
        if (inventory != Inventory.Wallet)
        {
             revert InventoryInvalid(inventory);
        }

        // Mint token
        _mint(player, tokenId);

        // Emit event
        emit BlueprintMinted(tokenId, blueprint, player);
    }
}