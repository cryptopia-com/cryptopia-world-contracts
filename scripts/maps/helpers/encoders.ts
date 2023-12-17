import { HexCellSection } from "../types/enums";

/**
 * Encodes rock data from a binary string into a `bytes4` format.
 * 
 * This function takes a binary string representing rock data across various cell sections
 * (NE, E, SE, SW, W, NW, C) and encodes it into a hexadecimal string compatible with the `bytes4` type in Solidity.
 * Each cell section's data is assumed to be represented by 4 bits in the input binary string (2 bits for Level and 2 bits for Decal),
 * and the function packs these bits into the `bytes4` format.
 *
 * The `HexCellSection` enum is used to map each section to its corresponding bit position in the final `bytes4` value.
 * The function ensures that the binary data is correctly aligned and padded to fit into a 4-byte hexadecimal string.
 *
 * @param binaryInput - A binary string representing the rock data. The string should start with '0b' and
 *                      contain the binary data for each section in the order defined in `HexCellSection`.
 * @returns A hexadecimal string representing the encoded rock data, formatted as `bytes4`.
 *
 * Example usage:
 * const binaryInput: string = '0b01010101010101010101010101010101';
 * const encodedData: string = encodeRockData(binaryInput);
 * console.log(encodedData); // Outputs the encoded data in hexadecimal format
 */
export function encodeRockData(binaryInput: string): string {

    // Convert binary string to BigInt
    let inputBigInt: bigint = BigInt(binaryInput);

    // Initialize the result as a BigInt
    let result: bigint = BigInt(0);

    // Constants
    const sectionBitLength: number = 4;
    const levelDecalMask: bigint = 0xFn; // 0b1111

    // Iterate over each section in HexCellSection
    for (const section in HexCellSection) 
    {
      if (!isNaN(Number(section))) 
      {
        // Extract 4 bits for the level and decal
        let levelDecal: bigint = inputBigInt & levelDecalMask;

        // Shift the input for the next iteration
        inputBigInt >>= 4n;

        // Pack the level and decal into the result
        result |= (levelDecal << BigInt(Number(section) * sectionBitLength));
      }
    }

    // Convert to hexadecimal string and format as bytes4
    let hexString = BigInt(result).toString(16);
    return '0x' + hexString.padStart(8, '0');
}

/**
 * Encodes vegetation data from a binary string into a `bytes8` format.
 * 
 * This function takes a binary string representing vegetation data across various cell sections
 * (NE, E, SE, SW, W, NW, C) and encodes it into a hexadecimal string compatible with the `bytes8` type in Solidity.
 * Each cell section's data is assumed to be represented by 2 bits in the input binary string, and the function
 * packs these bits into a 6-bit section for each direction in the `bytes8` format.
 *
 * The `HexCellSection` enum is used to map each section to its corresponding bit position in the final `bytes8` value.
 * The function ensures that the binary data is correctly aligned and padded to fit into an 8-byte hexadecimal string.
 *
 * @param inputBinary - A binary string representing the vegetation data. The string should start with '0b' and
 *                      contain the binary data for each section in the order defined in `HexCellSection`.
 * @returns A hexadecimal string representing the encoded vegetation data, formatted as `bytes8`.
 *
 * Example usage:
 * const inputBinary: string = '0b010101010101010101010101010101010101010101010101010101010101';
 * const encodedData: string = encodeVegetationData(inputBinary);
 * console.log(encodedData); // Outputs the encoded data in hexadecimal format
 */
export function encodeVegetationData(binaryInput: string): string {

    // Convert binary string to BigInt
    let inputBigInt: bigint = BigInt(binaryInput);

    // Initialize the result as a BigInt
    let result: bigint = BigInt(0);

    // Constants
    const sectionBitLength: number = 6; // 6 bits per section (2 bits each for Level, Decal, and Stamp)
    const sectionMask: bigint = 0x3Fn; // Mask for 6 bits (0b111111)

    // Iterate over each section in HexCellSection
    for (const section in HexCellSection) 
    {
        if (!isNaN(Number(section))) 
        {
            // Extract 6 bits for the level, decal, and stamp
            let sectionData: bigint = inputBigInt & sectionMask;

            // Shift the input for the next iteration
            inputBigInt >>= 6n; // Shift by 6 bits for the next section

            // Pack the section data into the result
            result |= (sectionData << BigInt(Number(section) * sectionBitLength));
        }
    }

    // Convert to hexadecimal string and format as bytes8
    let hexString = BigInt(result).toString(16);
    return '0x' + hexString.padStart(16, '0');
}

/**
 * Encodes wildlife data from a binary string into a 20-bit long mask and formats it as `bytes4`.
 * Each wildlife species is represented by 2 bits in the mask.
 * The binary string should represent the wildlife levels in sequence.
 *
 * @param inputBinary - A binary string representing the wildlife data levels.
 *                      Each pair of bits in the string corresponds to the level of a wildlife species.
 * @returns A hexadecimal string representing the encoded wildlife data, formatted as `bytes4`.
 *
 * Example usage:
 * const inputBinary: string = '0b01000000000000000000';
 * const encodedData: string = encodeWildlifeData(inputBinary);
 * console.log(encodedData); // Outputs the encoded data in `bytes4` format
 */
export function encodeWildlifeData(inputBinary: string): string {
    const NUM_WILDLIFE_SPECIES: number = 10;
    let inputBigInt: bigint = BigInt(inputBinary);
    let result: number = 0;
  
    for (let i = 0; i < NUM_WILDLIFE_SPECIES; i++) 
    {
        result <<= 2;
        result += Number(0b11n & inputBigInt);
        inputBigInt >>= 2n;
    }
  
     // Convert to hexadecimal string and format as bytes4
     let hexString = BigInt(result).toString(16);
     return '0x' + hexString.padStart(8, '0');
  }