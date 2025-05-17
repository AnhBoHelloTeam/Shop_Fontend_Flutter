export default commands;
declare namespace commands {
    /**
     * Spawn the particular process on Simulator.
     * It is required that Simulator is in _booted_ state.
     *
     * @this {import('../simctl').Simctl}
     * @param {string|string[]} args - Spawn arguments
     * @param {object} [env={}] - Additional environment variables mapping.
     * @return {Promise<import('teen_process').TeenProcessExecResult>} Command execution result.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function spawnProcess(this: import("../simctl").default, args: string | string[], env?: object): Promise<import("teen_process").TeenProcessExecResult<any>>;
    /**
     * Prepare SubProcess instance for a new process, which is going to be spawned
     * on Simulator.
     *
     * @this {import('../simctl').Simctl}
     * @param {string|string[]} args - Spawn arguments
     * @param {object} [env={}] - Additional environment variables mapping.
     * @return {Promise<import('teen_process').SubProcess>} The instance of the process to be spawned.
     * @throws {Error} If the `udid` instance property is unset
     */
    function spawnSubProcess(this: import("../simctl").default, args: string | string[], env?: object): Promise<import("teen_process").SubProcess>;
}
//# sourceMappingURL=spawn.d.ts.map