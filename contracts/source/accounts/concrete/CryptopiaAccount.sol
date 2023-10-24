// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./multisig/MultiSigWallet.sol";
import "../IAccount.sol";

/// @title Cryptopia Account
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAccount is Initializable, MultiSigWallet, IAccount, IERC721Receiver {

    /**
     * Storage
     */
    /// @dev Unique username
    bytes32 public username;


    /** 
     * Public functions
     */
    /// @dev Contract constructor sets initial owners, required number of confirmations, daily withdraw limit and unique username.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    /// @param _username Unique username
    function initialize(address[] memory _owners, uint _required, uint _dailyLimit, bytes32 _username) 
        public initializer 
    {
        __Multisig_init(_owners, _required, _dailyLimit);
        username = _username;
    }


    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) 
        public virtual override 
        returns (bytes4) 
    {
        return this.onERC721Received.selector;
    }
}