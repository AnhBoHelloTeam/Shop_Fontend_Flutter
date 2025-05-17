export default commands;
declare namespace commands {
    /**
     * Delete the particular Simulator from available devices list.
     *
     * @this {import('../simctl').Simctl}
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function deleteDevice(this: import("../simctl").default): Promise<void>;
}
//# sourceMappingURL=delete.d.ts.map