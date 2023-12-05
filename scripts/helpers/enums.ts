/**
 * Resolves the enum value from the string value.
 * 
 * @param {T} enumType - The enum type.
 * @param {string} strValue - The string value.
 * @returns {T[keyof T]} - The enum value.
 */
export function resolveEnum<T>(enumType: T, strValue: string): T[keyof T] {
    for (const key in enumType) {
        if (typeof enumType[key] === 'number' && key.toLowerCase() === strValue.toLowerCase()) {
            return enumType[key] as T[keyof T];
        }
    }
    
    throw new Error(`Invalid enum value: ${strValue}`);
}