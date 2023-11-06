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
export const PLAYER_IDLE_TIME = 600; // 10 minutes
export const MOVEMENT_TURN_DURATION = 60; // 1 min
export const MOVEMENT_COST_LAND_FLAT = 11;
export const MOVEMENT_COST_LAND_SLOPE = 19;
export const MOVEMENT_COST_WATER = 5;
export const MOVEMENT_COST_WATER_EMBARK_DISEMBARK = 25; 

/**
 * Pirate mechanics settings
 */
export const PirateMechanicsConfig = {

    // Base values
    MAX_CHARISMA : 100, // Denominator
    
    // Settings
    MAX_RESPONSE_TIME : 600, // 10 minutes

    // Scaling factors
    SPEED_SCALING_FACTOR : 50,
    LUCK_SCALING_FACTOR : 10,

    // Other factors
    BASE_NEGOCIATION_DEDUCTION_FACTOR : 20, // 20%
    BASE_NEGOCIATION_DEDUCTION_FACTOR_PRECISION : 100, // Denominator

    // Randomness
    BASE_ESCAPE_THRESHOLD : 5_000, // 50%

    // Costs
    BASE_FUEL_COST : BigInt("1000000000000000000"),
}