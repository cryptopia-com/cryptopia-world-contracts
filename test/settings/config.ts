/**
 * Revert mode
 * 
 * If true the tests should expect custom errors to be thrown by the multi-sig wallet
 * instead of the ExecutionFailure event being emitted.
 */
export const REVERT_MODE = true;

/**
 * Map settings
 */
export const MAP_MAX_SIZE = 4800;
export const PATH_MAX_LENGTH = 31;
export const PLAYER_START_POSITION = 0;
export const PLAYER_START_MOVEMENT = 25;
export const MOVEMENT_TURN_DURATION = 60; // 1 min
export const MOVEMENT_COST_LAND_FLAT = 11;
export const MOVEMENT_COST_LAND_SLOPE = 19;
export const MOVEMENT_COST_WATER = 5;
export const MOVEMENT_COST_WATER_EMBARK_DISEMBARK = 25; 

/**
 * Pirate mechanics settings
 */
export const BASE_FUEL_COST = BigInt("10000000000000000000");