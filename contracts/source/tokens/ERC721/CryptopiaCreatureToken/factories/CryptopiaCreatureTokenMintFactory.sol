// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12 < 0.9.0;

import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "../../../ERC20/retriever/TokenRetriever.sol";
import "../ICryptopiaCreatureToken.sol";


/// @title Cryptopia Creature Token Factory 
/// @dev Non-fungible token (ERC721) factory that mints CryptopiaCreature tokens
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract CryptopiaCreatureTokenMintFactory is OwnableUpgradeable, TokenRetriever {

    struct MintData 
    {
        bool mintable;
        uint24 species;
        bytes32 rare;
        bytes32 legendary;
        uint mintFee;
    }

    /**
     * Storage
     */
    uint constant MINT_SPECIAL_COMMON_MIN_AMOUNT = 12;
    uint constant MINT_SPECIAL_RARE_MIN_AMOUNT = 24;

    // Random
    uint public constant INVERSE_BASIS_POINT = 10_000; 
    uint public constant MIN_LEGENDARY_SCORE = 99_90; // 0.1%
    uint public constant MIN_RARE_SCORE = 95_00; // 4.9%

    // Beneficiary
    address payable public beneficiary;

    // Creatures
    mapping (bytes32 => MintData) mintData;
    mapping (uint24 => bytes32) public specialsSpeciesToCreature;

    // State
    address public token;
    bytes32 private _currentRandomSeed;


    /**
     * Public Functions
     */
    /// @dev Setup the factory
    /// @param _token The token that is minted
    /// @param _beneficiary Funds are withdrawn to this account
    function initialize(address _token, address payable _beneficiary) 
        public initializer 
    {
        __Ownable_init();
        token = _token;
        beneficiary = _beneficiary;
    }


    /// @dev Set the beneficiary
    /// @param _beneficiary Funds are withdrawn to this account
    function setBeneficiary(address payable _beneficiary) public onlyOwner {
        beneficiary = _beneficiary;
    }


    /// @dev Retreive creature mint data
    /// @param creature of the creature to check
    /// @return mintable True if able to mint
    /// @return special True if special creature
    /// @return rare version of `creature`
    /// @return legendary version of `creature`
    /// @return mintFee Fee to mint a `creature`
    function getMintData(bytes32 creature) 
        public view 
        returns (
            bool mintable, 
            bool special,  
            bytes32 rare, 
            bytes32 legendary,
            uint mintFee
        )
    {
        mintable = mintData[creature].mintable;
        special = specialsSpeciesToCreature[mintData[creature].species] == creature;
        rare = mintData[creature].rare;
        legendary = mintData[creature].legendary;
        mintFee = mintData[creature].mintFee;
    }


    /// @dev Mark a creature as mintable and indicate if it's special or not (special creatures can't be minted directly)
    /// @param creatures Creature name
    /// @param special If true marks this creature as special for this `species`
    /// @param rare Reference to the rare version
    /// @param legendary Reference to the legendary version
    /// @param mintFees Fee to mint a `_creature`
    function setMintData(bytes32[] memory creatures, bool[] memory special, bytes32[] memory rare, bytes32[] memory legendary, uint[] memory mintFees) 
        public onlyOwner 
    {
        for (uint i = 0; i < creatures.length; i++)
        {
            (bytes32 fileHash,,,uint24 species,,,,,,,,) = ICryptopiaCreatureToken(token).getCreature(creatures[i]);
            require(fileHash != 0, "Creature doesn't exist in token contract");

            mintData[creatures[i]].mintable = true;
            mintData[creatures[i]].species = species;
            mintData[creatures[i]].rare = rare[i];
            mintData[creatures[i]].legendary = legendary[i];
            mintData[creatures[i]].mintFee = mintFees[i];

            if (special[i])
            {
                specialsSpeciesToCreature[species] = creatures[i];
            }
            else if (specialsSpeciesToCreature[species] == creatures[i])
            {
                specialsSpeciesToCreature[species] = 0;
            }
        }
    }


    /// @dev Mint `creatures` `to` address
    /// @param creatures Creatures to mint
    /// @param sexes Sex of each creature
    /// @param to Address to mint to
    function mint(bytes32[] memory creatures, uint8[] memory sexes, address to) 
        public payable 
    {
        // Random
        bytes32 random = _random();
        bytes32 currentCreature;
        uint currentScore;

        uint24 species = mintData[creatures[0]].species;
        bool eligibleForSpecial = creatures.length >= MINT_SPECIAL_COMMON_MIN_AMOUNT;
        
        // Mint creatures
        uint totalMintFee = 0;
        for (uint i = 0; i < creatures.length; i++) 
        {
            require(_exists(creatures[i]), "Unable to mint a non-existing creature");
            require(!_isSpecial(creatures[i]), "Unable to mint a special creature");

            // All creatures have to be of the same species to be elegible for special
            if (eligibleForSpecial && mintData[creatures[i]].species != species)
            {
                eligibleForSpecial = false;
            }

            uint mintFee = _getMintFee(1, creatures[i]);
            totalMintFee += mintFee;

            // Enforce mint fee
            require(0 != mintFee, "Unable to mint a creature without a mint fee");
            
            currentScore = _randomAt(random, i);
            if (currentScore >= MIN_LEGENDARY_SCORE)
            {
                currentCreature = mintData[creatures[i]].legendary;
            }
            else if (currentScore >= MIN_RARE_SCORE)
            {
                currentCreature = mintData[creatures[i]].rare;
            }
            else 
            {
                currentCreature = creatures[i];
            }

            ICryptopiaCreatureToken(token).mintTo(
                to, currentCreature, 0 == sexes[i] ? 0 : 1);
        }

        // Enforce fee
        require(_canPayMintFee(totalMintFee, msg.value), "Unable to pay mint fee");

        // Mint special
        if (!eligibleForSpecial || !_hasSpecial(species))
        {
            return; 
        }

        currentScore = MathUpgradeable.max(
            _randomAt(random, creatures.length), 
            creatures.length >= MINT_SPECIAL_RARE_MIN_AMOUNT 
                ? MIN_RARE_SCORE : 0);

        if (currentScore >= MIN_LEGENDARY_SCORE)
        {
            currentCreature = mintData[specialsSpeciesToCreature[species]].legendary;
        }
        else if (currentScore >= MIN_RARE_SCORE)
        {
            currentCreature = mintData[specialsSpeciesToCreature[species]].rare;
        }
        else 
        {
            currentCreature = specialsSpeciesToCreature[species];
        }

        ICryptopiaCreatureToken(token).mintTo(
                to, currentCreature, 0 == sexes[sexes.length - 1] ? 0 : 1);
    }


    /// @dev Returns true if the call has enough ether to pay the minting fee
    /// @param creatures The creatures that are being minted
    /// @return bool True if the minting fee can be payed
    function canPayMintFee(bytes32[] memory creatures) public view returns (bool) {
        return _canPayMintFee(_getMintFee(creatures), address(msg.sender).balance);
    }


    /// @dev Returns the amount needed to pay the minting fee
    /// @param creatures The creatures that are being minted
    /// @return uint The amount needed to pay the minting fee
    function getMintFee(bytes32[] memory creatures) public view returns (uint) {
        return _getMintFee(creatures);
    }


    /// @dev Withdraws to beneficiary 
    function withdraw() public {
        beneficiary.transfer(address(this).balance);
    }
    

    /**
     * Internal Functions
     */
    /// @dev Checks if `creature` is special
    /// @param creature Name of the creature to check
    /// @return bool True if special
    function _exists(bytes32 creature) internal view returns (bool)
    {
        return mintData[creature].mintable;
    }


    /// @dev Checks if `creature` is special
    /// @param creature Name of the creature to check
    /// @return bool True if special
    function _isSpecial(bytes32 creature) internal view returns (bool)
    {
        return specialsSpeciesToCreature[mintData[creature].species] == creature;
    }


    /// @dev Checks if there is a special creature for `species`
    /// @param species The species to check for
    /// @return bool True if there is a special 
    function _hasSpecial(uint24 species) internal view returns (bool)
    {
        return specialsSpeciesToCreature[species] != 0;
    }


    /// @dev Returns if the call has enough ether to pay the minting fee
    /// @param totalFee Number of items to mint
    /// @param received The amount that was received
    /// @return bool True if the minting fee can be payed
    function _canPayMintFee(uint totalFee, uint received) internal pure returns (bool) {
        return received >= totalFee;
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param creatures The creatures that are being minted
    /// @return mintFee The amount needed to pay the minting fee
    function _getMintFee(bytes32[] memory creatures) internal view returns (uint mintFee) {
        for (uint i = 0; i < creatures.length; i++)
        {
            mintFee += mintData[creatures[i]].mintFee;
        }
    }


    /// @dev Returns the ether amount needed to pay the minting fee
    /// @param numberOfCreaturesToMint Number of items to mint
    /// @param creature The creature that's being minted
    /// @return uint The amount needed to pay the minting fee
    function _getMintFee(uint numberOfCreaturesToMint, bytes32 creature) internal view returns (uint) {
        return mintData[creature].mintFee * numberOfCreaturesToMint;
    }


    /// @dev Pseudo-random hash generator
    /// @return bytes32 Random hash
    function _random() internal returns (bytes32) {
        _currentRandomSeed = keccak256(
            abi.encodePacked(blockhash(block.number - 1), 
            _msgSender(), 
            _currentRandomSeed));
        return _currentRandomSeed;
    }


    /// @dev Get a number from a random `seed` at `index`
    /// @param _hash Randomly generated hash 
    /// @param index Used as salt
    /// @return uint32 Random number
    function _randomAt(bytes32 _hash, uint index) private pure returns(uint32) {
        return uint32(uint(keccak256(abi.encodePacked(_hash, index))) % INVERSE_BASIS_POINT);
    }
}