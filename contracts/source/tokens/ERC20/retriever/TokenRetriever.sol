// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";

import "./ITokenRetriever.sol";

/**
 * @title TokenRetriever
 * @notice Allows tokens to be retrieved from a contract.
 * @author Frank Bonnet - <frankbonnet@outlook.com>
 */
abstract contract TokenRetriever is ITokenRetriever {

    /**
     * @dev Extracts tokens from the contract.
     * @param _tokenContract The address of ERC20 compatible token.
     */
    function retrieveTokens(address _tokenContract) 
        public virtual 
    {
        IERC20Upgradeable tokenInstance = IERC20Upgradeable(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(address(this));
        if (tokenBalance > 0) 
        {
            SafeERC20Upgradeable.safeTransfer(
                tokenInstance, msg.sender, tokenBalance);
        }
    }
}
