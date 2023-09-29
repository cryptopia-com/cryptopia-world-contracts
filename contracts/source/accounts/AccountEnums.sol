// SPDX-License-Identifier: ISC
pragma solidity ^0.8.12 < 0.9.0;

/// @title Account enums
/// @author Frank Bonnet - <frankbonnet@outlook.com>
contract AccountEnums {

    enum Sex 
    {
        Undefined,
        Male,
        Female
    }

    enum Gender 
    {
        Male,
        Female
    }

    enum Relationship
    {
        None,
        Friend,
        Family,
        Spouse
    }
}