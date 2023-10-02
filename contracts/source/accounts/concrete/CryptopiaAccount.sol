// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/interfaces/IERC1820RegistryUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC777/IERC777RecipientUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721ReceiverUpgradeable.sol";

import "./multisig/MultiSigWallet.sol";
import "../IAccount.sol";

/// @title Cryptopia Account
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAccount is IAccount, Initializable, MultiSigWallet, IERC777RecipientUpgradeable, IERC721ReceiverUpgradeable {

    /**
     * Storage
     */
    address constant private ERC1820_ADDRESS = 0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24;
    bytes32 constant private ERC777_RECIPIENT_INTERFACE = keccak256("ERC777TokensRecipient");

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

        // Register as ERC777 recipient
        IERC1820RegistryUpgradeable(ERC1820_ADDRESS).setInterfaceImplementer(
            address(this), ERC777_RECIPIENT_INTERFACE, address(this));

        username = _username;
    }


    /**
     * @dev Called by an {IERC777} token contract whenever tokens are being
     * moved or created into a registered account (`to`). The type of operation
     * is conveyed by `from` being the zero address or not.
     *
     * This call occurs _after_ the token contract's state is updated, so
     * {IERC777-balanceOf}, etc., can be used to query the post-operation state.
     *
     * This function may revert to prevent the operation from being executed.
     */
    function tokensReceived(
        address operator,
        address from,
        address to,
        uint256 amount,
        bytes calldata userData,
        bytes calldata operatorData
    ) public virtual override 
    {
        // Nothing for now
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