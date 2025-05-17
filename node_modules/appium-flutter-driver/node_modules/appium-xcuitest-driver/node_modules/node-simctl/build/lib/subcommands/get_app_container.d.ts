export default commands;
declare namespace commands {
    /**
     * Get the full path to the particular application container
     * on the local file system. Note, that this subcommand throws
     * an error if bundle id of a system application is provided,
     * like 'com.apple.springboard'.
     * It is required that Simulator is in _booted_ state.
     *
    * @this {import('../simctl').Simctl}
     * @param {string} bundleId - Bundle identifier of an application.
     * @param {string?} [containerType=null] - Which container type to return. Possible values
     *                                  are 'app', 'data', 'groups', '<A specific App Group container>'.
     *                                  The default value is 'app'.
     * @return {Promise<string>} Full path to the given application container on the local
     *                  file system.
     * @throws {Error} If the corresponding simctl subcommand command
     *                 returns non-zero return code.
     * @throws {Error} If the `udid` instance property is unset
     */
    function getAppContainer(this: import("../simctl").default, bundleId: string, containerType?: string | null): Promise<string>;
}
//# sourceMappingURL=get_app_container.d.ts.map