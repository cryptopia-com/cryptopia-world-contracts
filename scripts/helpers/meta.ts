import { ethers, network} from "hardhat";
import { EIP712Domain, EIP712TypeDefinition, TransferProposal } from '../types/meta'
import { HardhatEthersSigner } from "@nomicfoundation/hardhat-ethers/signers";

const EIP712_DOMAIN_NAME = "Cryptopia";
const EIP712_DOMAIN_VERSION = "1.0.0";

/**
 * @dev Get the signature of a proposal
 * 
 * @param signer The signer
 * @param contract The contract address of the executor
 * @param proposal The proposal
 * @returns The signature
 */
export const getTransferProposalSignature = async (signer: HardhatEthersSigner, contract: string, proposal: TransferProposal) : Promise<string> =>
{
    const domain: EIP712Domain = {
        name: EIP712_DOMAIN_NAME,
        version: EIP712_DOMAIN_VERSION,
        chainId: network.config.chainId as number,
        verifyingContract: proposal.from
    };

    const proposalTypeDefinition: EIP712TypeDefinition = {
        TransferProposal: [
            { name: "from", type: "address" },
            { name: "to", type: "address" },
            { name: "assets", type: "bytes32" },
            { name: "tokenIds", type: "bytes32" },
            { name: "amounts", type: "bytes32" },
            { name: "inventories", type: "bytes32" },
            { name: "deadline", type: "uint256"},
            { name: "nonce", type: "uint256"},
            { name: "contract", type: "address"}
        ]
    }

    return signer.signTypedData(
        domain, 
        proposalTypeDefinition,
        {
            from: proposal.from,
            to: proposal.to,
            assets: ethers.solidityPackedKeccak256(["address[]"], [proposal.assets]),
            tokenIds: ethers.solidityPackedKeccak256(["uint256[]"], [proposal.tokenIds]),
            amounts: ethers.solidityPackedKeccak256(["uint256[]"], [proposal.amounts]),
            inventories: ethers.solidityPackedKeccak256(["uint8[]"], [proposal.inventories]),
            deadline: proposal.deadline,
            nonce: 0,
            contract: contract
        });
}