export default commands;
declare namespace commands {
    /**
     * Shutdown the given Simulator if it is running.
     *
     * @this {import('../simctl').Simctl}
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function shutdownDevice(this: import("../simctl").default): Promise<void>;
}
//# sourceMappingURL=shutdown.d.ts.map