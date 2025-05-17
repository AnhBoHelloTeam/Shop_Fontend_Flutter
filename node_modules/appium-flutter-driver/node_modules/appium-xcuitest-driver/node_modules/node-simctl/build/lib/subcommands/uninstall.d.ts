export default commands;
declare namespace commands {
    /**
     * Remove the particular application package from Simulator.
     * It is required that Simulator is in _booted_ state and
     * the application with given bundle identifier is already installed.
     *
     * @this {import('../simctl').Simctl}
     * @param {string} bundleId - Bundle identifier of the application,
     *                            which is going to be removed.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function removeApp(this: import("../simctl").default, bundleId: string): Promise<void>;
}
//# sourceMappingURL=uninstall.d.ts.map