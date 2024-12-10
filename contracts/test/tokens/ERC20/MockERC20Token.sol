// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

import "../../../source/tokens/ERC20/concrete/CryptopiaERC20.sol";

contract MockERC20Token is CryptopiaERC20 {

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __CryptopiaERC20_init("MockERC20Token", "MOCK20");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(SYSTEM_ROLE, msg.sender);
    }

    function __mint(address to, uint amount) public onlyRole(SYSTEM_ROLE) {
        _mint(to, amount);
    }
}