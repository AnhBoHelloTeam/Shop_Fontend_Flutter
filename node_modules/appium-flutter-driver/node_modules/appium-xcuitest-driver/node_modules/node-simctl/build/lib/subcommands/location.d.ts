export default commands;
declare namespace commands {
    /**
     * Set the Simulator location to a specific latitude and longitude.
     * This functionality is only available since Xcode 14.
     *
     * @this {import('../simctl').Simctl}
     * @param {string|number} latitude Location latitude value
     * @param {string|number} longitude Location longitude value
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {TypeError} If any of the arguments is not a valid value.
     */
    function setLocation(this: import("../simctl").default, latitude: string | number, longitude: string | number): Promise<void>;
    /**
     * Stop any running scenario and clear any simulated location.
     *
     * @since Xcode 14.
     * @this {import('../simctl').Simctl}
     */
    function clearLocation(this: import("../simctl").default): Promise<void>;
}
//# sourceMappingURL=location.d.ts.map