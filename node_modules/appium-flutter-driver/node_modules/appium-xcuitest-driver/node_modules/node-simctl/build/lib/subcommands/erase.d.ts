export default commands;
declare namespace commands {
    /**
     * Reset the content and settings of the particular Simulator.
     * It is required that Simulator is in _shutdown_ state.
     *
     * @this {import('../simctl').Simctl}
     * @param {number} [timeout=10000] - The maximum number of milliseconds to wait
     *                                   unit device reset is completed.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function eraseDevice(this: import("../simctl").default, timeout?: number): Promise<void>;
}
//# sourceMappingURL=erase.d.ts.map