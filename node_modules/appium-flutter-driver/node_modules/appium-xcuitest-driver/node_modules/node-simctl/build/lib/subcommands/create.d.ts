export default commands;
export type SimCreationOpts = {
    /**
     * - Platform name in order to specify runtime such as 'iOS', 'tvOS', 'watchOS'
     */
    platform?: string | undefined;
    /**
     * - The maximum number of milliseconds to wait
     *    unit device creation is completed.
     */
    timeout?: number | undefined;
};
declare namespace commands {
    /**
     * @typedef {Object} SimCreationOpts
     * @property {string} [platform='iOS'] - Platform name in order to specify runtime such as 'iOS', 'tvOS', 'watchOS'
     * @property {number} [timeout=10000] - The maximum number of milliseconds to wait
     *                                      unit device creation is completed.
     */
    /**
     * Create Simulator device with given name for the particular
     * platform type and version.
     *
     * @this {import('../simctl').Simctl}
     * @param {string} name - The device name to be created.
     * @param {string} deviceTypeId - Device type, for example 'iPhone 6'.
     * @param {string} platformVersion - Platform version, for example '10.3'.
     * @param {SimCreationOpts} [opts={}] - Simulator options for creating devices.
     * @return {Promise<string>} The UDID of the newly created device.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     */
    function createDevice(this: import("../simctl").default, name: string, deviceTypeId: string, platformVersion: string, opts?: SimCreationOpts): Promise<string>;
}
//# sourceMappingURL=create.d.ts.map