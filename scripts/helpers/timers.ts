import { setTimeout } from 'node:timers/promises'

/**
 * Waits for the remaining time to ensure a minimum wait duration.
 * @param startTime The start time of the action in milliseconds.
 * @param minWaitTime The minimum wait time in milliseconds.
 */
export async function waitForMinimumTime(startTime: number, minWaitTime: number = 1000): Promise<void> {
    const elapsedTime = Date.now() - startTime;
    if (elapsedTime < minWaitTime) {
        await setTimeout(minWaitTime - elapsedTime);
    }
}