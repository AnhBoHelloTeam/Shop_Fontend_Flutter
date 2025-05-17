export default commands;
export type DeviceInfo = {
    /**
     * - The device name.
     */
    name: string;
    /**
     * - The device UDID.
     */
    udid: string;
    /**
     * - The current Simulator state, for example 'booted' or 'shutdown'.
     */
    state: string;
    /**
     * - The SDK version, for example '10.3'.
     */
    sdk: string;
};
declare namespace commands {
    /**
     * @typedef {Object} DeviceInfo
     * @property {string} name - The device name.
     * @property {string} udid - The device UDID.
     * @property {string} state - The current Simulator state, for example 'booted' or 'shutdown'.
     * @property {string} sdk - The SDK version, for example '10.3'.
     */
    /**
     * Parse the list of existing Simulator devices to represent
     * it as convenient mapping.
     *
     * @this {import('../simctl').Simctl}
     * @param {string?} [platform] - The platform name, for example 'watchOS'.
     * @return {Promise<Record<string, any>>} The resulting mapping. Each key is platform version,
     *                  for example '10.3' and the corresponding value is an
     *                  array of the matching {@link DeviceInfo} instances.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     */
    function getDevicesByParsing(this: import("../simctl").default, platform?: string | null): Promise<Record<string, any>>;
    /**
     * Parse the list of existing Simulator devices to represent
     * it as convenient mapping for the particular platform version.
     *
     * @this {import('../simctl').Simctl}
     * @param {string?} [forSdk] - The sdk version,
     *                           for which the devices list should be parsed,
     *                           for example '10.3'.
     * @param {string?} [platform] - The platform name, for example 'watchOS'.
     * @return {Promise<Object|DeviceInfo[]>} If _forSdk_ is set then the list
     *                                    of devices for the particular platform version.
     *                                    Otherwise the same result as for {@link getDevicesByParsing}
     *                                    function.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code or if no matching
     *                 platform version is found in the system.
     */
    function getDevices(this: import("../simctl").default, forSdk?: string | null, platform?: string | null): Promise<any | DeviceInfo[]>;
    /**
     * Get the runtime for the particular platform version using --json flag
     *
     * @this {import('../simctl').Simctl}
     * @param {string} platformVersion - The platform version name,
     *                                   for example '10.3'.
     * @param {string} [platform='iOS'] - The platform name, for example 'watchOS'.
     * @return {Promise<string>} The corresponding runtime name for the given
     *                  platform version.
     */
    function getRuntimeForPlatformVersionViaJson(this: import("../simctl").default, platformVersion: string, platform?: string): Promise<string>;
    /**
     * Get the runtime for the particular platform version.
     *
     * @this {import('../simctl').Simctl}
     * @param {string} platformVersion - The platform version name,
     *                                   for example '10.3'.
     * @param {string} [platform='iOS'] - The platform name, for example 'watchOS'.
     * @return {Promise<string>} The corresponding runtime name for the given
     *                  platform version.
     */
    function getRuntimeForPlatformVersion(this: import("../simctl").default, platformVersion: string, platform?: string): Promise<string>;
    /**
     * Get the list of device types available in the current Xcode installation
     *
     * @this {import('../simctl').Simctl}
     * @return {Promise<string[]>} List of the types of devices available
     * @throws {Error} If the corresponding simctl command fails
     */
    function getDeviceTypes(this: import("../simctl").default): Promise<string[]>;
    /**
     * Get the full list of runtimes, devicetypes, devices and pairs as Object
     *
     * @this {import('../simctl').Simctl}
     * @return {Promise<Object>} Object containing device types, runtimes devices and pairs.
     * The resulting JSON will be like:
     *   {
     *     "devicetypes" : [
     *       {
     *         "name" : "iPhone 4s",
     *         "identifier" : "com.apple.CoreSimulator.SimDeviceType.iPhone-4s"
     *       },
     *       ...
     *      ],
     *     "runtimes" : [
     *       {
     *         "version" : '13.0',
     *         "bundlePath" : '/Applications/Xcode11beta4.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS.simruntime',
     *         "isAvailable" : true,
     *         "name" : 'iOS 13.0',
     *         "identifier" : 'com.apple.CoreSimulator.SimRuntime.iOS-13-0',
     *         "buildversion" : '17A5534d'
     *       },
     *       ...
     *      },
     *     "devices" :
     *       {
     *         'com.apple.CoreSimulator.SimRuntime.iOS-13-0': [ [Object], [Object] ] },
     *         ...
     *       },
     *     "pairs" : {} }
     *
     *   }
     * @throws {Error} If the corresponding simctl command fails
     */
    function list(this: import("../simctl").default): Promise<any>;
}
//# sourceMappingURL=list.d.ts.map