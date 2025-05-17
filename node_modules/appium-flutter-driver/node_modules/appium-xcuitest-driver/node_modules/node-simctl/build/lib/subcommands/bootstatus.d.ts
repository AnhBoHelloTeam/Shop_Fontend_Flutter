export default commands;
export type BootMonitorOptions = {
    /**
     * - Simulator booting timeout in ms.
     */
    timeout?: number | undefined;
    /**
     * - This event is fired when data migration stage starts.
     */
    onWaitingDataMigration?: Function | undefined;
    /**
     * - This event is fired when system app wait stage starts.
     */
    onWaitingSystemApp?: Function | undefined;
    /**
     * - This event is fired when Simulator is fully booted.
     */
    onFinished?: Function | undefined;
    /**
     * - This event is fired when there was an error while monitoring the booting process
     * or when the timeout has expired.
     */
    onError?: Function | undefined;
    /**
     * Whether to preboot the Simulator
     * if this command is called and it is not already in booted or booting state.
     */
    shouldPreboot?: boolean | undefined;
};
declare namespace commands {
    /**
     * @typedef {Object} BootMonitorOptions
     * @property {number} [timeout=240000] - Simulator booting timeout in ms.
     * @property {Function} [onWaitingDataMigration] - This event is fired when data migration stage starts.
     * @property {Function} [onWaitingSystemApp] - This event is fired when system app wait stage starts.
     * @property {Function} [onFinished] - This event is fired when Simulator is fully booted.
     * @property {Function} [onError] - This event is fired when there was an error while monitoring the booting process
     * or when the timeout has expired.
     * @property {boolean} [shouldPreboot=false] Whether to preboot the Simulator
     * if this command is called and it is not already in booted or booting state.
     */
    /**
     * Start monitoring for boot status of the particular Simulator.
     * If onFinished property is not set then the method will block
     * until Simulator booting is completed.
     * The method is only available since Xcode8.
     *
     * @this {import('../simctl').Simctl}
     * @param {BootMonitorOptions} [opts={}] - Monitoring options.
     * @returns {Promise<import('teen_process').SubProcess>} The instance of the corresponding monitoring process.
     * @throws {Error} If the Simulator fails to finish booting within the given timeout and onFinished
     * property is not set.
     * @throws {Error} If the `udid` instance property is unset
     */
    function startBootMonitor(this: import("../simctl").default, opts?: BootMonitorOptions): Promise<import("teen_process").SubProcess>;
}
//# sourceMappingURL=bootstatus.d.ts.map