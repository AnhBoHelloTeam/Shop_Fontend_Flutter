export default commands;
declare namespace commands {
    /**
     * Retrieves the value of a Simulator environment variable
     *
     * @this {import('../simctl').Simctl}
     * @param {string} varName - The name of the variable to be retrieved
     * @returns {Promise<string|null>} The value of the variable or null if the given variable
     * is not present in the Simulator environment
     * @throws {Error} If there was an error while running the command
     * @throws {Error} If the `udid` instance property is unset
     */
    function getEnv(this: import("../simctl").default, varName: string): Promise<string | null>;
}
//# sourceMappingURL=getenv.d.ts.map