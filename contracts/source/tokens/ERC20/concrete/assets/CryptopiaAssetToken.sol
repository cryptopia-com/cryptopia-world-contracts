// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

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
    /// @param name_ Token name
    /// @param symbol_ Token symbol
    function initialize(
        string memory name_, 
        string memory symbol_, 
        address _inventoriesContract) 
        public virtual initializer 
    {
        __CryptopiaERC20_init(name_, symbol_);

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


    /// @dev Burns 'amount' token from an address
    /// @param from Account to burn the tokens from
    /// @param amount Amount of tokens to burn
    function __burnFrom(address from, uint amount) 
        public override 
        onlyRole(SYSTEM_ROLE) 
    {
        _burn(from, amount);
    }


    /// @dev Mints 'amount' of tokens to 'player' and assigns them to 'inventory'
    /// @param player The player to mint the tokens to
    /// @param inventory The inventory to mint the tokens to
    /// @param amount The amount of tokens to mint
    function __mintToInventory(address player, Inventory inventory, uint amount) 
        public override 
        onlyRole(SYSTEM_ROLE) 
    {
        // Mint
        _mint(inventoriesContract, amount); 

        // Assign
        IInventories(inventoriesContract)
            .__assignFungibleToken(player, inventory, address(this), amount);
    }


    /// @dev Burns 'amount' of tokens from 'player' and removes them from 'inventory'
    /// @param player The player to burn the tokens from
    /// @param inventory The inventory to burn the tokens from
    /// @param amount The amount of tokens to burn
    function __burnFromInventory(address player, Inventory inventory, uint amount)
        public override 
        onlyRole(SYSTEM_ROLE) 
    {
        // Deduct from inventory
        IInventories(inventoriesContract)
            .__deductFungibleToken(player, inventory, address(this), amount, false);

        // Burn
        _burn(inventoriesContract, amount); 
    }


    /// @dev Mint quest reward
    /// @param player The player that completed the quest
    /// @param inventory The inventory to mint the reward to
    /// @param amount The amount of tokens to mint
    function __mintQuestReward(address player, Inventory inventory, uint amount) 
        public override 
    {
        __mintToInventory(player, inventory, amount);
    }
}