// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../IERC20Retriever.sol";

/// @title CryptopiaERC20Retriever
/// @notice Allows tokens to be retrieved from a contract
/// @author Frank Bonnet - <frankbonnet@outlook.com>
abstract contract CryptopiaERC20Retriever is IERC20Retriever {
    using SafeERC20 for IERC20;

    /// @dev Extracts tokens from the contract
    /// @param _tokenContract The address of ERC20 compatible token
    function retrieveTokens(address _tokenContract) 
        public virtual 
    {
        IERC20 tokenInstance = IERC20(_tokenContract);
        uint tokenBalance = tokenInstance.balanceOf(address(this));
        if (tokenBalance > 0) 
        {
            tokenInstance.safeTransfer(
                msg.sender, tokenBalance);
        }
    }
}
