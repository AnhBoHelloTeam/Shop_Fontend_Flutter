export default commands;
declare namespace commands {
    /**
     * Boot the particular Simulator if it is not running.
     *
     * @this {import('../simctl').Simctl}
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function bootDevice(this: import("../simctl").default): Promise<void>;
}
//# sourceMappingURL=boot.d.ts.map