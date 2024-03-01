// SPDX-License-Identifier: ISC
pragma solidity 0.8.20;

library MetaTransactions {

    bytes32 constant public EIP712_TRANSFER_PROPOSAL_SCHEMA_HASH = keccak256(
        "TransferProposal(address from,address to,bytes32 inventories,bytes32 assets,bytes32 amounts,bytes32 tokenIds,uint256 deadline,uint256 nonce,address contract)");
}
