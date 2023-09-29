// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "./ITokenRetriever.sol";

/**
 * TokenRetriever
 *
 * Allows tokens to be retrieved from a contract
 *
 * #created 31/12/2021
 * #author HFB
 */
contract TokenRetriever is ITokenRetriever {

    /**
     * Extracts tokens from the contract
     *
     * @param _tokenContract The address of ERC20 compatible token
     */
    function retrieveTokens(address _tokenContract) override virtual public {
        ERC20Upgradeable tokenInstance = ERC20Upgradeable(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(address(this));
        if (tokenBalance > 0) {
            tokenInstance.transfer(msg.sender, tokenBalance);
        }
    }
}