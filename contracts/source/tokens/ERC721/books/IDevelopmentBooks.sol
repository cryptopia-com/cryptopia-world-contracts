// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "./types/DevelopmentBookDataTypes.sol";

/// @title Cryptopia Development Books Token Contract
/// @notice Books that are learnable and can be used to increase the stats of a player
/// @author Frank Bonnet - <frankbonnet@outlook.com>
interface IDevelopmentBooks {

    /**
     * Public functions
     */
    /// @dev Returns the amount of different books
    /// @return count The amount of different books
    function getBookCount() 
        external view 
        returns (uint);


    /// @dev Retreive a book by name
    /// @param _name Book name (unique)
    /// @return book a single book
    function getBook(bytes32 _name) 
        external view 
        returns (DevelopmentBook memory book);


    /// @dev Retreive a book by index
    /// @param index The index of the book to retreive
    /// @return book a single book
    function getBookAt(uint index) 
        external view 
        returns (DevelopmentBook memory book);


    /// @dev Retreive a rance of books
    /// @param skip Starting index
    /// @param take Amount of items
    /// @return books_ a range of books
    function getBooks(uint skip, uint take) 
        external view 
        returns (DevelopmentBook[] memory books_);


    /// @dev Retreive a book by token id
    /// @param tokenId The id of the book to retreive
    /// @return instance a single book instance
    function getBookInstance(uint tokenId) 
        external view 
        returns (DevelopmentBookInstance memory instance);

    
    /// @dev Retreive books by token ids
    /// @param tokenIds The ids of the skins to retreive
    /// @return instances a range of book instances
    function getBookInstances(uint[] memory tokenIds) 
        external view 
        returns (DevelopmentBookInstance[] memory instances);
}