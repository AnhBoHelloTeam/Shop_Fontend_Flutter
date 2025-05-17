export default commands;
declare namespace commands {
    /**
     * Retrieves the current UI appearance value from the given simulator
     *
     * @since Xcode 11.4 SDK
     * @this {import('../simctl').Simctl}
     * @return {Promise<string>} the appearance value, for example 'light' or 'dark'
     * @throws {Error} if the current SDK version does not support the command
     * or there was an error while getting the value
     * @throws {Error} If the `udid` instance property is unset
     */
    function getAppearance(this: import("../simctl").default): Promise<string>;
    /**
     * Sets the UI appearance to the given style
     *
     * @since Xcode 11.4 SDK
     * @this {import('../simctl').Simctl}
     * @param {string} appearance valid appearance value, for example 'light' or 'dark'
     * @throws {Error} if the current SDK version does not support the command
     * or there was an error while getting the value
     * @throws {Error} If the `udid` instance property is unset
     */
    function setAppearance(this: import("../simctl").default, appearance: string): Promise<void>;
    /**
     * Retrieves the current increase contrast configuration value from the given simulator.
     * The value could be:
     *   - enabled: Increase Contrast is enabled.
     *   - disabled: Increase Contrast is disabled.
     *   - unsupported: The platform or runtime version do not support the Increase Contrast setting.
     *   - unknown: The current setting is unknown or there was an error detecting it.
     *
     * @since Xcode 15 (but lower xcode could have this command)
     * @this {import('../simctl').Simctl}
     * @return {Promise<string>} the contrast configuration value.
     *                           Possible return value is 'enabled', 'disabled',
     *                           'unsupported' or 'unknown' with Xcode 16.2.
     * @throws {Error} if the current SDK version does not support the command
     * or there was an error while getting the value.
     * @throws {Error} If the `udid` instance property is unset
     */
    function getIncreaseContrast(this: import("../simctl").default): Promise<string>;
    /**
     * Sets the increase constrast configuration for the given simulator.
     * Acceptable values (with Xcode 16.2, iOS 18.1) are 'enabled' or 'disabled'
     * They would change in the future version, so please validate the given value
     * in the caller side.
     *
     * @since Xcode 15 (but lower xcode could have this command)
     * @this {import('../simctl').Simctl}
     * @param {string} increaseContrast valid increase constrast configuration value.
     *                                  Acceptable value is 'enabled' or 'disabled' with Xcode 16.2.
     * @throws {Error} if the current SDK version does not support the command
     * or the given value was invalid for the command.
     * @throws {Error} If the `udid` instance property is unset
     */
    function setIncreaseContrast(this: import("../simctl").default, increaseContrast: string): Promise<void>;
    /**
     * Retrieves the current content size value from the given simulator.
     * The value could be:
     * 	 Standard sizes: extra-small, small, medium, large, extra-large,
     *                   extra-extra-large, extra-extra-extra-large
     *   Extended range sizes: accessibility-medium, accessibility-large,
     *                         accessibility-extra-large, accessibility-extra-extra-large,
     *                         accessibility-extra-extra-extra-large
     *   Other values: unknown, unsupported.
     *
     * @since Xcode 15 (but lower xcode could have this command)
     * @this {import('../simctl').Simctl}
     * @return {Promise<string>} the content size value. Possible return value is
     *                           extra-small, small, medium, large, extra-large, extra-extra-large,
     *                           extra-extra-extra-large, accessibility-medium, accessibility-large,
     *                           accessibility-extra-large, accessibility-extra-extra-large,
     *                           accessibility-extra-extra-extra-large,
     *                           unknown or unsupported with Xcode 16.2.
     * @throws {Error} if the current SDK version does not support the command
     * or there was an error while getting the value.
     * @throws {Error} If the `udid` instance property is unset
     */
    function getContentSize(this: import("../simctl").default): Promise<string>;
    /**
     * Sets content size for the given simulator.
     * Acceptable values (with Xcode 16.2, iOS 18.1) are below:
     * 	 Standard sizes: extra-small, small, medium, large, extra-large,
     *                   extra-extra-large, extra-extra-extra-large
     *   Extended range sizes: accessibility-medium, accessibility-large,
     *                         accessibility-extra-large, accessibility-extra-extra-large,
     *                         accessibility-extra-extra-extra-large
     * Or 'increment' or 'decrement'
     * They would change in the future version, so please validate the given value
     * in the caller side.
     *
     * @since Xcode 15 (but lower xcode could have this command)
     * @this {import('../simctl').Simctl}
     * @param {string} contentSizeAction valid content size or action value. Acceptable value is
     *                                   extra-small, small, medium, large, extra-large, extra-extra-large,
     *                                   extra-extra-extra-large, accessibility-medium, accessibility-large,
     *                                   accessibility-extra-large, accessibility-extra-extra-large,
     *                                   accessibility-extra-extra-extra-large with Xcode 16.2.
     * @throws {Error} if the current SDK version does not support the command
     * or the given value was invalid for the command.
     * @throws {Error} If the `udid` instance property is unset
     */
    function setContentSize(this: import("../simctl").default, contentSizeAction: string): Promise<void>;
}
//# sourceMappingURL=ui.d.ts.map