// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../source/tokens/ERC777/CryptopiaERC777.sol";

contract MockERC777Token is CryptopiaERC777 {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address[] memory defaultOperators, address authenticator) initializer public {
        __CryptopiaERC777_init("MockERC777Token", "MOCK777", defaultOperators, authenticator);
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount, "", "");
    }
}