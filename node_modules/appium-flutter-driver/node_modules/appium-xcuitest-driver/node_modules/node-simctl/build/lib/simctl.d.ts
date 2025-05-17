export default Simctl;
export type XCRun = {
    /**
     * Full path to the xcrun script
     */
    path: string | null;
};
export type TAsyncOpts = {
    asynchronous: true;
};
export type ExecOpts = {
    /**
     * - The list of additional subcommand arguments.
     * It's empty by default.
     */
    args?: string[] | undefined;
    /**
     * - Environment variables mapping. All these variables
     * will be passed Simulator and used in the executing function.
     */
    env?: Record<string, any> | undefined;
    /**
     * - Set it to _false_ to throw execution errors
     * immediately without logging any additional information.
     */
    logErrors?: boolean | undefined;
    /**
     * - Whether to execute the given command
     * 'synchronously' or 'asynchronously'. Affects the returned result of the function.
     */
    asynchronous?: boolean | undefined;
    /**
     * - Explicitly sets streams encoding for the executed
     * command input and outputs.
     */
    encoding?: string | undefined;
    /**
     * - One or more architecture names to be enforced while
     * executing xcrun. See https://github.com/appium/appium/issues/18966 for more details.
     */
    architectures?: string | string[] | undefined;
    /**
     * - The maximum number of milliseconds
     * to wait for single synchronous xcrun command. If not provided explicitly, then
     * the value of execTimeout property is used by default.
     */
    timeout?: number | undefined;
};
export type SimctlOpts = {
    /**
     * - The xcrun properties. Currently only one property
     * is supported, which is `path` and it by default contains `null`, which enforces
     * the instance to automatically detect the full path to `xcrun` tool and to throw
     * an exception if it cannot be detected. If the path is set upon instance creation
     * then it is going to be used by `exec` and no autodetection will happen.
     */
    xcrun?: XCRun | undefined;
    /**
     * - The default maximum number of milliseconds
     * to wait for single synchronous xcrun command.
     */
    execTimeout?: number | undefined;
    /**
     * - Whether to wire xcrun error messages
     * into debug log before throwing them.
     */
    logErrors?: boolean | undefined;
    /**
     * - The unique identifier of the current device, which is
     * going to be implicitly passed to all methods, which require it. It can either be set
     * upon instance creation if it is already known in advance or later when/if needed via the
     * corresponding instance setter.
     */
    udid?: string | null | undefined;
    /**
     * - Full path to the set of devices that you want to manage.
     * By default this path usually equals to ~/Library/Developer/CoreSimulator/Devices
     */
    devicesSetPath?: string | null | undefined;
};
/**
 * @typedef {Object} XCRun
 * @property {string?} path Full path to the xcrun script
 */
/**
 * @typedef {{asynchronous: true}} TAsyncOpts
 */
/**
 * @typedef {Object} ExecOpts
 * @property {string[]} [args=[]] - The list of additional subcommand arguments.
 * It's empty by default.
 * @property {Record<string, any>} [env={}] - Environment variables mapping. All these variables
 * will be passed Simulator and used in the executing function.
 * @property {boolean} [logErrors=true] - Set it to _false_ to throw execution errors
 * immediately without logging any additional information.
 * @property {boolean} [asynchronous=false] - Whether to execute the given command
 * 'synchronously' or 'asynchronously'. Affects the returned result of the function.
 * @property {string} [encoding] - Explicitly sets streams encoding for the executed
 * command input and outputs.
 * @property {string|string[]} [architectures] - One or more architecture names to be enforced while
 * executing xcrun. See https://github.com/appium/appium/issues/18966 for more details.
 * @property {number} [timeout] - The maximum number of milliseconds
 * to wait for single synchronous xcrun command. If not provided explicitly, then
 * the value of execTimeout property is used by default.
 */
/**
 * @typedef {Object} SimctlOpts
 * @property {XCRun} [xcrun] - The xcrun properties. Currently only one property
 * is supported, which is `path` and it by default contains `null`, which enforces
 * the instance to automatically detect the full path to `xcrun` tool and to throw
 * an exception if it cannot be detected. If the path is set upon instance creation
 * then it is going to be used by `exec` and no autodetection will happen.
 * @property {number} [execTimeout=600000] - The default maximum number of milliseconds
 * to wait for single synchronous xcrun command.
 * @property {boolean} [logErrors=true] - Whether to wire xcrun error messages
 * into debug log before throwing them.
 * @property {string?} [udid] - The unique identifier of the current device, which is
 * going to be implicitly passed to all methods, which require it. It can either be set
 * upon instance creation if it is already known in advance or later when/if needed via the
 * corresponding instance setter.
 * @property {string?} [devicesSetPath] - Full path to the set of devices that you want to manage.
 * By default this path usually equals to ~/Library/Developer/CoreSimulator/Devices
 */
export class Simctl {
    /**
     * @param {SimctlOpts} [opts={}]
     */
    constructor(opts?: SimctlOpts);
    /** @type {XCRun} */
    xcrun: XCRun;
    /** @type {number} */
    execTimeout: number;
    /** @type {boolean} */
    logErrors: boolean;
    /** @type {string?} */
    _udid: string | null;
    /** @type {string?} */
    _devicesSetPath: string | null;
    set udid(value: string | null);
    get udid(): string | null;
    set devicesSetPath(value: string | null);
    get devicesSetPath(): string | null;
    /**
     * @param {string?} [commandName=null]
     * @returns {string}
     */
    requireUdid(commandName?: string | null): string;
    /**
     * @returns {Promise<string>}
     */
    requireXcrun(): Promise<string>;
    /**
     * Execute the particular simctl command.
     *
     * @template {ExecOpts} TExecOpts
     * @param {string} subcommand - One of available simctl subcommands.
     * Execute `xcrun simctl` in Terminal to see the full list  of available subcommands.
     * @param {TExecOpts} [opts]
     * @return {Promise<TExecOpts extends TAsyncOpts ? import('teen_process').SubProcess : import('teen_process').TeenProcessExecResult>}
     * Either the result of teen process's `exec` or
     * `SubProcess` instance depending of `opts.asynchronous` value.
     * @throws {Error} If the simctl subcommand command returns non-zero return code.
     */
    exec<TExecOpts extends ExecOpts>(subcommand: string, opts?: TExecOpts): Promise<TExecOpts extends TAsyncOpts ? import("teen_process").SubProcess : import("teen_process").TeenProcessExecResult<any>>;
    addMedia: (this: Simctl, filePath: string) => Promise<import("teen_process").TeenProcessExecResult<any>>;
    appInfo: (this: Simctl, bundleId: string) => Promise<string>;
    bootDevice: (this: Simctl) => Promise<void>;
    startBootMonitor: (this: Simctl, opts?: BootMonitorOptions) => Promise<import("teen_process").SubProcess>;
    createDevice: (this: Simctl, name: string, deviceTypeId: string, platformVersion: string, opts?: SimCreationOpts) => Promise<string>;
    deleteDevice: (this: Simctl) => Promise<void>;
    eraseDevice: (this: Simctl, timeout?: number) => Promise<void>;
    getAppContainer: (this: Simctl, bundleId: string, containerType?: string | null) => Promise<string>;
    getEnv: (this: Simctl, varName: string) => Promise<string | null>;
    installApp: (this: Simctl, appPath: string) => Promise<void>;
    getScreenshot: (this: Simctl) => Promise<string>;
    addRootCertificate: (this: Simctl, cert: string, opts?: CertOptions) => Promise<void>;
    addCertificate: (this: Simctl, cert: string, opts?: CertOptions) => Promise<void>;
    resetKeychain: (this: Simctl) => Promise<void>;
    launchApp: (this: Simctl, bundleId: string, tries?: number) => Promise<string>;
    getDevicesByParsing: (this: Simctl, platform?: string | null) => Promise<Record<string, any>>;
    getDevices: (this: Simctl, forSdk?: string | null, platform?: string | null) => Promise<any | DeviceInfo[]>;
    getRuntimeForPlatformVersionViaJson: (this: Simctl, platformVersion: string, platform?: string) => Promise<string>;
    getRuntimeForPlatformVersion: (this: Simctl, platformVersion: string, platform?: string) => Promise<string>;
    getDeviceTypes: (this: Simctl) => Promise<string[]>;
    list: (this: Simctl) => Promise<any>;
    setLocation: (this: Simctl, latitude: string | number, longitude: string | number) => Promise<void>;
    clearLocation: (this: Simctl) => Promise<void>;
    openUrl: (this: Simctl, url: string) => Promise<import("teen_process").TeenProcessExecResult<any>>;
    setPasteboard: (this: Simctl, content: string, encoding?: BufferEncoding) => Promise<void>;
    getPasteboard: (this: Simctl, encoding?: string) => Promise<string>;
    grantPermission: (this: Simctl, bundleId: string, perm: string) => Promise<void>;
    revokePermission: (this: Simctl, bundleId: string, perm: string) => Promise<void>;
    resetPermission: (this: Simctl, bundleId: string, perm: string) => Promise<void>;
    pushNotification: (this: Simctl, payload: any) => Promise<void>;
    shutdownDevice: (this: Simctl) => Promise<void>;
    spawnProcess: (this: Simctl, args: string | string[], env?: object) => Promise<import("teen_process").TeenProcessExecResult<any>>;
    spawnSubProcess: (this: Simctl, args: string | string[], env?: object) => Promise<import("teen_process").SubProcess>;
    terminateApp: (this: Simctl, bundleId: string) => Promise<void>;
    getAppearance: (this: Simctl) => Promise<string>;
    setAppearance: (this: Simctl, appearance: string) => Promise<void>;
    getIncreaseContrast: (this: Simctl) => Promise<string>;
    setIncreaseContrast: (this: Simctl, increaseContrast: string) => Promise<void>;
    getContentSize: (this: Simctl) => Promise<string>;
    setContentSize: (this: Simctl, contentSizeAction: string) => Promise<void>;
    removeApp: (this: Simctl, bundleId: string) => Promise<void>;
}
import { SubProcess } from 'teen_process';
//# sourceMappingURL=simctl.d.ts.map