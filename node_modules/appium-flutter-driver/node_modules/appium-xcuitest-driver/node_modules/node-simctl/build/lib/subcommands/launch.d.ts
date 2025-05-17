export default commands;
declare namespace commands {
    /**
     * Execute the particular application package on Simulator.
     * It is required that Simulator is in _booted_ state and
     * the application with given bundle identifier is already installed.
     *
     * @this {import('../simctl').Simctl}
     * @param {string} bundleId - Bundle identifier of the application,
     *                            which is going to be removed.
     * @param {number} [tries=5] - The maximum number of retries before
     *                             throwing an exception.
     * @return {Promise<string>} the actual command output
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function launchApp(this: import("../simctl").default, bundleId: string, tries?: number): Promise<string>;
}
//# sourceMappingURL=launch.d.ts.map