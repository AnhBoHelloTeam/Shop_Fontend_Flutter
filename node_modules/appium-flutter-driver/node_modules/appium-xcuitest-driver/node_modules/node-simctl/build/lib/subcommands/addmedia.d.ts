export default commands;
declare namespace commands {
    /**
     * Add the particular media file to Simulator's library.
     * It is required that Simulator is in _booted_ state.
     *
     * @this {import('../simctl').Simctl}
     * @param {string} filePath - Full path to a media file on the local
     *                            file system.
     * @return {Promise<import('teen_process').TeenProcessExecResult>} Command execution result.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function addMedia(this: import("../simctl").default, filePath: string): Promise<import("teen_process").TeenProcessExecResult<any>>;
}
//# sourceMappingURL=addmedia.d.ts.map