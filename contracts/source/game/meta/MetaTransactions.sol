// SPDX-License-Identifier: ISC
pragma solidity ^0.8.20 < 0.9.0;

library MetaTransactions {

    bytes32 constant public EIP712_TRANSFER_PROPOSAL_SCHEMA_HASH = keccak256(
        "TransferProposal(address from,address to,bytes32 assets,bytes32 tokenIds,bytes32 amounts,bytes32 inventories,uint256 deadline,uint256 nonce,address contract)");
}
