export default commands;
declare namespace commands {
    /**
     * Invoke hidden appinfo subcommand to get the information
     * about applications installed on Simulator, including
     * system applications ({@link getAppContainer} does not "see" such apps).
     * Simulator server should be in 'booted' state for this call to work properly.
     * The tool is only available since Xcode SDK 8.1
     *
     * @this {import('../simctl').Simctl}
     * @param {string} bundleId - The bundle identifier of the target application.
     * @return {Promise<string>} The information about installed application.
     *
     * Example output for non-existing application container:
     * <pre>
     * {
     *   CFBundleIdentifier = "com.apple.MobileSafari";
     *   GroupContainers =     {
     *   };
     *   SBAppTags =     (
     *   );
     * }
     * </pre>
     *
     * Example output for an existing system application container:
     * <pre>
     * {
     *   ApplicationType = Hidden;
     *   Bundle = "file:///Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/CoreServices/SpringBoard.app";
     *   CFBundleDisplayName = SpringBoard;
     *   CFBundleExecutable = SpringBoard;
     *   CFBundleIdentifier = "com.apple.springboard";
     *   CFBundleName = SpringBoard;
     *   CFBundleVersion = 50;
     *   GroupContainers =     {
     *   };
     *   Path = "/Applications/Xcode-beta.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/System/Library/CoreServices/SpringBoard.app";
     *   SBAppTags =     (
     *   );
     * }
     * </pre>
     * @throws {Error} If the `udid` instance property is unset
     */
    function appInfo(this: import("../simctl").default, bundleId: string): Promise<string>;
}
//# sourceMappingURL=appinfo.d.ts.map