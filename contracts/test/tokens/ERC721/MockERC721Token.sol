// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

import "../../../source/tokens/ERC721/concrete/CryptopiaERC721.sol";

contract MockERC721Token is CryptopiaERC721 {
    bytes32 constant private MINTER_ROLE = keccak256("MINTER_ROLE");

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address authenticator) initializer public {
        __CryptopiaERC721_init("MockERC721Token", "MOCK721", authenticator, "", "");
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function safeMint(address to, uint256 tokenId) public onlyRole(MINTER_ROLE) {
        _safeMint(to, tokenId);
    }
}
