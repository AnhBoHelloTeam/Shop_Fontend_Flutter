export const BOOTSTRAP_PATH: string;
/**
 * Information of the device under test
 */
export type DeviceInfo = {
    /**
     * - Equals to true if the current device is a real device
     */
    isRealDevice: string;
    /**
     * - The device UDID.
     */
    udid: string;
    /**
     * - The platform version of OS.
     */
    platformVersion: string;
    /**
     * - The platform name of iOS, tvOS
     */
    platformName: string;
};
/**
 * Update WebDriverAgentRunner project bundle ID with newBundleId.
 * This method assumes project file is in the correct state.
 * @param {string} agentPath - Path to the .xcodeproj directory.
 * @param {string} newBundleId the new bundle ID used to update.
 */
export function updateProjectFile(agentPath: string, newBundleId: string): Promise<void>;
/**
 * Reset WebDriverAgentRunner project bundle ID to correct state.
 * @param {string} agentPath - Path to the .xcodeproj directory.
 */
export function resetProjectFile(agentPath: string): Promise<void>;
export function setRealDeviceSecurity(keychainPath: any, keychainPassword: any): Promise<void>;
/**
 * Return the WDA object which appends existing xctest runner content
 * @param {string} platformName - The name of the platform
 * @param {number|string} wdaRemotePort - The remote port number
 * @return {object} returns a runner object which has USE_PORT
 */
export function getAdditionalRunContent(platformName: string, wdaRemotePort: number | string): object;
/**
 * Return the name of xctestrun file
 * @param {DeviceInfo} deviceInfo
 * @param {string} version - The Xcode SDK version of OS.
 * @return {string} returns xctestrunFilePath for given device
 */
export function getXctestrunFileName(deviceInfo: DeviceInfo, version: string): string;
/**
 * Information of the device under test
 * @typedef {Object} DeviceInfo
 * @property {string} isRealDevice - Equals to true if the current device is a real device
 * @property {string} udid - The device UDID.
 * @property {string} platformVersion - The platform version of OS.
 * @property {string} platformName - The platform name of iOS, tvOS
*/
/**
 * Creates xctestrun file per device & platform version.
 * We expects to have WebDriverAgentRunner_iphoneos${sdkVersion|platformVersion}-arm64.xctestrun for real device
 * and WebDriverAgentRunner_iphonesimulator${sdkVersion|platformVersion}-${x86_64|arm64}.xctestrun for simulator located @bootstrapPath
 * Newer Xcode (Xcode 10.0 at least) generate xctestrun file following sdkVersion.
 * e.g. Xcode which has iOS SDK Version 12.2 on an intel Mac host machine generates WebDriverAgentRunner_iphonesimulator.2-x86_64.xctestrun
 *      even if the cap has platform version 11.4
 *
 * @param {DeviceInfo} deviceInfo
 * @param {string} sdkVersion - The Xcode SDK version of OS.
 * @param {string} bootstrapPath - The folder path containing xctestrun file.
 * @param {number|string} wdaRemotePort - The remote port WDA is listening on.
 * @return {Promise<string>} returns xctestrunFilePath for given device
 * @throws if WebDriverAgentRunner_iphoneos${sdkVersion|platformVersion}-arm64.xctestrun for real device
 * or WebDriverAgentRunner_iphonesimulator${sdkVersion|platformVersion}-x86_64.xctestrun for simulator is not found @bootstrapPath,
 * then it will throw file not found exception
 */
export function setXctestrunFile(deviceInfo: DeviceInfo, sdkVersion: string, bootstrapPath: string, wdaRemotePort: number | string): Promise<string>;
/**
 * Return the path of xctestrun if it exists
 * @param {DeviceInfo} deviceInfo
 * @param {string} sdkVersion - The Xcode SDK version of OS.
 * @param {string} bootstrapPath - The folder path containing xctestrun file.
 * @returns {Promise<string>}
 */
export function getXctestrunFilePath(deviceInfo: DeviceInfo, sdkVersion: string, bootstrapPath: string): Promise<string>;
/**
 * Ensures the process is killed after the timeout
 *
 * @param {string} name
 * @param {import('teen_process').SubProcess} proc
 * @returns {Promise<void>}
 */
export function killProcess(name: string, proc: import("teen_process").SubProcess): Promise<void>;
/**
 * Generate a random integer.
 *
 * @return {number} A random integer number in range [low, hight). `low`` is inclusive and `high` is exclusive.
 */
export function randomInt(low: any, high: any): number;
/**
 * Retrieves WDA upgrade timestamp
 *
 * @return {Promise<number?>} The UNIX timestamp of the package manifest. The manifest only gets modified on
 * package upgrade.
 */
export function getWDAUpgradeTimestamp(): Promise<number | null>;
/**
 * Kills running XCTest processes for the particular device.
 *
 * @param {string} udid - The device UDID.
 * @param {boolean} isSimulator - Equals to true if the current device is a Simulator
 */
export function resetTestProcesses(udid: string, isSimulator: boolean): Promise<void>;
/**
 * Get the IDs of processes listening on the particular system port.
 * It is also possible to apply additional filtering based on the
 * process command line.
 *
 * @param {string|number} port - The port number.
 * @param {?Function} filteringFunc - Optional lambda function, which
 *                                    receives command line string of the particular process
 *                                    listening on given port, and is expected to return
 *                                    either true or false to include/exclude the corresponding PID
 *                                    from the resulting array.
 * @returns {Promise<string[]>} - the list of matched process ids.
 */
export function getPIDsListeningOnPort(port: string | number, filteringFunc?: Function | null): Promise<string[]>;
export function killAppUsingPattern(pgrepPattern: any): Promise<void>;
/**
 * Return true if the platformName is tvOS
 * @param {string} platformName The name of the platorm
 * @returns {boolean} Return true if the platformName is tvOS
 */
export function isTvOS(platformName: string): boolean;
//# sourceMappingURL=utils.d.ts.map