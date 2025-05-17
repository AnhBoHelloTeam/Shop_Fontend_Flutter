export default commands;
declare namespace commands {
    /**
     * Set the content of Simulator pasteboard.
     * It is required that Simulator is in _booted_ state.
     *
     * @since Xcode SDK 8.1
     * @this {import('../simctl').Simctl}
     * @param {string} content - The actual string content to be set.
     * @param {BufferEncoding} [encoding='utf8'] - The encoding of the given pasteboard content.
     * utf8 by default.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function setPasteboard(this: import("../simctl").default, content: string, encoding?: BufferEncoding): Promise<void>;
}
//# sourceMappingURL=pbcopy.d.ts.map