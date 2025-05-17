export default commands;
declare namespace commands {
    /**
     * Install the particular application package on Simulator.
     * It is required that Simulator is in _booted_ state.
     *
     * @this {import('../simctl').Simctl}
     * @param {string} appPath - Full path to .app package, which is
     *                           going to be installed.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function installApp(this: import("../simctl").default, appPath: string): Promise<void>;
}
//# sourceMappingURL=install.d.ts.map