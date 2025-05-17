export default commands;
declare namespace commands {
    /**
     * Gets base64 screenshot for device
     * It is required that Simulator is in _booted_ state.
     *
     * @this {import('../simctl').Simctl}
     * @since Xcode SDK 8.1
     * @return {Promise<string>} Base64-encoded Simulator screenshot.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function getScreenshot(this: import("../simctl").default): Promise<string>;
}
//# sourceMappingURL=io.d.ts.map