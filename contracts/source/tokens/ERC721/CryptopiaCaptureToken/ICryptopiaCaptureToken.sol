// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;


/// @title ICryptopiaCaptureToken Token
/// @dev Non-fungible token (ERC721) 
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface ICryptopiaCaptureToken {

    /// @dev Returns the amount of different items
    /// @return uint The amount of different items
    function getItemCount() 
        external view 
        returns (uint);


    /// @dev Retreive capture items by name
    /// @param name Unique capture token name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return strength influences the chance on has in capturing a creature
    function getItem(bytes32 name) 
        external view 
        returns (
            uint8 rarity,
            uint8 class,
            uint240 strength
        );


    /// @dev Retreive a rance of capture items
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return name Token name
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return strength influences the chance on has in capturing a creature
    function getItems(uint skip, uint take) 
        external view 
        returns (
            bytes32[] memory name,
            uint8[] memory rarity,
            uint8[] memory class,
            uint240[] memory strength
        );


    /// @dev Retreive data by item token ID
    /// @param tokenId Unique token Id
    /// @return rarity 0 = common, 1 = rare, 2 = legendary
    /// @return class 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @return strength influences the chance on has in capturing a creature
    function getItemByTokenId(uint tokenId) 
        external view 
        returns (
            uint8 rarity,
            uint8 class,
            uint240 strength
        );

    
    /// @dev Add or update capture data
    /// @param names Unique capture token name
    /// @param rarities 0 = common, 1 = rare, 2 = legendary, 3 = master
    /// @param classes 0 = Carnivore, 1 = Herbivore, 2 = Amphibian, 3 = Aerial
    /// @param strengths influences the chance on has in capturing a creature
    function setItems(bytes32[] memory names, uint8[] memory rarities, uint8[] memory classes, uint240[] memory strengths) 
        external;


    /// @dev Mints a token to an address
    /// @param to address of the future owner of the token
    /// @param name Unique capture token name
    function mintTo(address to, bytes32 name) 
        external;


    /// @dev Burns `tokenId`. See {ERC721-_burn}.
    /// @param tokenId The token that's burned
    function burn(uint tokenId) 
        external;
}