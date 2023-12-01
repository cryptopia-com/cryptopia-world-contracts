// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

import "../CryptopiaERC20.sol";
import "../../assets/IAssetToken.sol";
import "../../../../game/inventories/IInventories.sol";
import "../../../../game/quests/rewards/IFungibleQuestReward.sol";

/// @title Cryptopia Asset Token
/// @notice Cryptoipa asset such as natural resources.
/// @dev Implements the ERC20 standard
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaAssetToken is CryptopiaERC20, IAssetToken, IFungibleQuestReward {


    /**
     * Storage
     */
    // Refs
    address public inventoriesContract;


    /// @dev Contract Initializer
    /// @param name Token name
    /// @param symbol Token symbol
    function initialize(
        string memory name, 
        string memory symbol, 
        address _inventoriesContract) 
        public initializer 
    {
        __CryptopiaERC20_init(name, symbol);

        // Refs
        inventoriesContract = _inventoriesContract;
    }


    /**
     * System functions
     */
    /// @dev Mints 'amount' token to an address
    /// @param to Account to mint the tokens for
    /// @param amount Amount of tokens to mint
    function __mintTo(address to, uint amount) 
        public override 
        onlyRole(SYSTEM_ROLE) 
    {
        _mint(to, amount);
    }


    /// @dev Mint quest reward
    /// @param amount The amount of tokens to mint
    /// @param player The player that completed the quest
    /// @param inventory The inventory to mint the reward to
    function __mintQuestReward(uint amount, address player, Inventory inventory) 
        public override 
        onlyRole(SYSTEM_ROLE) 
    {
        // Mint
        _mint(inventoriesContract, amount); 

        // Assign
        IInventories(inventoriesContract)
            .__assignFungibleToken(player, inventory, address(this), amount);
    }
}