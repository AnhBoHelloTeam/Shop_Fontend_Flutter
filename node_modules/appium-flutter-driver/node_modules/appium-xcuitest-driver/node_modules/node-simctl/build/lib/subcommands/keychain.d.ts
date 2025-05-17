export default commands;
export type CertOptions = {
    /**
     * - whether the `cert` argument
     * is the path to the certificate on the local file system or
     * a raw certificate content
     */
    raw?: boolean | undefined;
};
declare namespace commands {
    /**
     * @typedef {Object} CertOptions
     * @property {boolean} [raw=false] - whether the `cert` argument
     * is the path to the certificate on the local file system or
     * a raw certificate content
     */
    /**
     * Adds the given certificate to the Trusted Root Store on the simulator
     *
     * @since Xcode 11.4 SDK
     * @this {import('../simctl').Simctl}
     * @param {string} cert the full path to a valid .cert file containing
     * the certificate content or the certificate content itself, depending on
     * options
     * @param {CertOptions} [opts={}]
     * @throws {Error} if the current SDK version does not support the command
     * or there was an error while adding the certificate
     * @throws {Error} If the `udid` instance property is unset
     */
    function addRootCertificate(this: import("../simctl").default, cert: string, opts?: CertOptions): Promise<void>;
    /**
     * Adds the given certificate to the Keychain Store on the simulator
     *
     * @since Xcode 11.4 SDK
     * @this {import('../simctl').Simctl}
     * @param {string} cert the full path to a valid .cert file containing
     * the certificate content or the certificate content itself, depending on
     * options
     * @param {CertOptions} [opts={}]
     * @throws {Error} if the current SDK version does not support the command
     * or there was an error while adding the certificate
     * @throws {Error} If the `udid` instance property is unset
     */
    function addCertificate(this: import("../simctl").default, cert: string, opts?: CertOptions): Promise<void>;
    /**
     * Resets the simulator keychain
     *
     * @since Xcode 11.4 SDK
     * @this {import('../simctl').Simctl}
     * @throws {Error} if the current SDK version does not support the command
     * or there was an error while resetting the keychain
     * @throws {Error} If the `udid` instance property is unset
     */
    function resetKeychain(this: import("../simctl").default): Promise<void>;
}
//# sourceMappingURL=keychain.d.ts.map