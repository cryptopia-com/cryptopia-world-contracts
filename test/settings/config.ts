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
export const MapConfig = {

    // Input constraints
    MAP_MAX_SIZE: 4800,
    PATH_MAX_LENGTH: 31,

    // Player settings
    PLAYER_START_POSITION: 0,
    PLAYER_START_MOVEMENT: 25,
    PLAYER_IDLE_TIME: 600, // 10 minutes

    // Movement settings
    MOVEMENT_TURN_DURATION: 60, // 1 min
    MOVEMENT_COST_LAND_FLAT: 11,
    MOVEMENT_COST_LAND_SLOPE: 19,
    MOVEMENT_COST_WATER: 5,
    MOVEMENT_COST_WATER_EMBARK_DISEMBARK: 25
}

/**
 * Player settings
 */
export const PlayerConfig = {

    // Base values
    MAX_CHARISMA: 100, // Denominator
    MAX_LUCK: 100, // Denominator
}

export const BuildingConfig = {

    // Base values
    CONSTRUCTION_COMPLETE: 1000
}

/**
 * Pirate mechanics settings
 */
export const PirateMechanicsConfig = {

    // Test settings
    MAX_ESCAPE_ATTEMPTS: 10,
    MAX_QUICK_BATTLE_ATTEMPTS: 10,

    // Settings
    MAX_RESPONSE_TIME: 600, // 10 minutes

    // Scaling factors
    SPEED_SCALING_FACTOR: 50,
    LUCK_SCALING_FACTOR: 10,

    // Other factors
    BASE_NEGOTIATION_DEDUCTION_FACTOR: 50, // 50%
    BASE_NEGOTIATION_DEDUCTION_FACTOR_PRECISION: 100, // Denominator

    // Randomness
    BASE_ESCAPE_THRESHOLD: 5_000, // 50%

    // Costs
    BASE_FUEL_COST: BigInt("1000000000000000000")
}