// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/**
 * ITokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 29/09/2017
 * #author HFB
 */
interface ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) external;
}