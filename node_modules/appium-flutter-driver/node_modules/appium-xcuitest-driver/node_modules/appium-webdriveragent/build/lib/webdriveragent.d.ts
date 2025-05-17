export class WebDriverAgent {
    /**
     * @param {import('appium-xcode').XcodeVersion} xcodeVersion
     * // TODO: make args typed
     * @param {import('@appium/types').StringRecord} [args={}]
     * @param {import('@appium/types').AppiumLogger?} [log=null]
     */
    constructor(xcodeVersion: import("appium-xcode").XcodeVersion, args?: import("@appium/types").StringRecord, log?: import("@appium/types").AppiumLogger | null);
    /** @type {string} */
    bootstrapPath: string;
    /** @type {string} */
    agentPath: string;
    xcodeVersion: import("appium-xcode/build/lib/xcode").XcodeVersion;
    args: import("@appium/types").StringRecord<any>;
    log: import("@appium/types").AppiumLogger;
    device: any;
    platformVersion: any;
    platformName: any;
    iosSdkVersion: any;
    host: any;
    isRealDevice: boolean;
    idb: any;
    wdaBundlePath: any;
    wdaLocalPort: any;
    wdaRemotePort: any;
    wdaBaseUrl: any;
    prebuildWDA: any;
    webDriverAgentUrl: any;
    started: boolean;
    wdaConnectionTimeout: any;
    useXctestrunFile: any;
    usePrebuiltWDA: any;
    derivedDataPath: any;
    mjpegServerPort: any;
    updatedWDABundleId: any;
    wdaLaunchTimeout: any;
    usePreinstalledWDA: any;
    xctestApiClient: any;
    updatedWDABundleIdSuffix: any;
    xcodebuild: XcodeBuild | null;
    /**
     * Return true if the session does not need xcodebuild.
     * @returns {boolean} Whether the session needs/has xcodebuild.
     */
    get canSkipXcodebuild(): boolean;
    /**
     * Return bundle id for WebDriverAgent to launch the WDA.
     * The primary usage is with 'this.usePreinstalledWDA'.
     * It adds `.xctrunner` as suffix by default but 'this.updatedWDABundleIdSuffix'
     * lets skip it.
     *
     * @returns {string} Bundle ID for Xctest.
     */
    get bundleIdForXctest(): string;
    /**
     * @param {string} [bootstrapPath]
     * @param {string} [agentPath]
     */
    setWDAPaths(bootstrapPath?: string, agentPath?: string): void;
    /**
     * @returns {Promise<void>}
     */
    cleanupObsoleteProcesses(): Promise<void>;
    /**
     * Return boolean if WDA is running or not
     * @return {Promise<boolean>} True if WDA is running
     * @throws {Error} If there was invalid response code or body
     */
    isRunning(): Promise<boolean>;
    /**
     * @returns {string}
     */
    get basePath(): string;
    /**
     * Return current running WDA's status like below
     * {
     *   "state": "success",
     *   "os": {
     *     "name": "iOS",
     *     "version": "11.4",
     *     "sdkVersion": "11.3"
     *   },
     *   "ios": {
     *     "simulatorVersion": "11.4",
     *     "ip": "172.254.99.34"
     *   },
     *   "build": {
     *     "time": "Jun 24 2018 17:08:21",
     *     "productBundleIdentifier": "com.facebook.WebDriverAgentRunner"
     *   }
     * }
     *
     * @param {number} [timeoutMs=0] If the given timeoutMs is zero or negative number,
     *                               this function will return the response of `/status` immediately. If the given timeoutMs,
     *                               this function will try to get the response of `/status` up to the timeoutMs.
     * @return {Promise<import('@appium/types').StringRecord|null>} State Object
     * @throws {Error} If there was an error within timeoutMs timeout.
     *                 No error is raised if zero or negative number for the timeoutMs.
     */
    getStatus(timeoutMs?: number): Promise<import("@appium/types").StringRecord | null>;
    /**
     * Uninstall WDAs from the test device.
     * Over Xcode 11, multiple WDA can be in the device since Xcode 11 generates different WDA.
     * Appium does not expect multiple WDAs are running on a device.
     *
     * @returns {Promise<void>}
     */
    uninstall(): Promise<void>;
    _cleanupProjectIfFresh(): Promise<void>;
    /**
     * @typedef {Object} LaunchWdaViaDeviceCtlOptions
     * @property {Record<string, string|number>} [env] environment variables for the launching WDA process
     */
    /**
     * Launch WDA with preinstalled package with 'xcrun devicectl device process launch'.
     * The WDA package must be prepared properly like published via
     * https://github.com/appium/WebDriverAgent/releases
     * with proper sign for this case.
     *
     * When we implement launching XCTest service via appium-ios-device,
     * this implementation can be replaced with it.
     *
     * @param {LaunchWdaViaDeviceCtlOptions} [opts={}] launching WDA with devicectl command options.
     * @return {Promise<void>}
     */
    _launchViaDevicectl(opts?: {
        /**
         * environment variables for the launching WDA process
         */
        env?: Record<string, string | number> | undefined;
    }): Promise<void>;
    /**
     * Launch WDA with preinstalled package without xcodebuild.
     * @param {string} sessionId Launch WDA and establish the session with this sessionId
     * @return {Promise<import('@appium/types').StringRecord|null>} State Object
     * @throws {Error} If there was an error within timeoutMs timeout.
     *                 No error is raised if zero or negative number for the timeoutMs.
     */
    launchWithPreinstalledWDA(sessionId: string): Promise<import("@appium/types").StringRecord | null>;
    /**
     * Return current running WDA's status like below after launching WDA
     * {
     *   "state": "success",
     *   "os": {
     *     "name": "iOS",
     *     "version": "11.4",
     *     "sdkVersion": "11.3"
     *   },
     *   "ios": {
     *     "simulatorVersion": "11.4",
     *     "ip": "172.254.99.34"
     *   },
     *   "build": {
     *     "time": "Jun 24 2018 17:08:21",
     *     "productBundleIdentifier": "com.facebook.WebDriverAgentRunner"
     *   }
     * }
     *
     * @param {string} sessionId Launch WDA and establish the session with this sessionId
     * @return {Promise<any?>} State Object
     * @throws {Error} If there was invalid response code or body
     */
    launch(sessionId: string): Promise<any | null>;
    /**
     * @param {string} _url
     * @returns {void}
     */
    set url(_url: string);
    /**
     * @returns {import('url').UrlWithStringQuery}
     */
    get url(): import("url").UrlWithStringQuery;
    /**
     * @returns {Promise<void>}
     */
    startWithIDB(): Promise<void>;
    /**
     *
     * @param {string} wdaBundlePath
     * @returns {Promise<string>}
     */
    parseBundleId(wdaBundlePath: string): Promise<string>;
    /**
     * @returns {Promise<{wdaBundleId: string, testBundleId: string, wdaBundlePath: string}>}
     */
    prepareWDA(): Promise<{
        wdaBundleId: string;
        testBundleId: string;
        wdaBundlePath: string;
    }>;
    /**
     * @returns {Promise<string>}
     */
    fetchWDABundle(): Promise<string>;
    /**
     * @returns {Promise<boolean>}
     */
    isSourceFresh(): Promise<boolean>;
    /**
     * @param {string} sessionId
     * @returns {void}
     */
    setupProxies(sessionId: string): void;
    jwproxy: JWProxy | undefined;
    proxyReqRes: any;
    noSessionProxy: NoSessionProxy | undefined;
    /**
     * @returns {Promise<void>}
     */
    quit(): Promise<void>;
    _url: url.UrlWithStringQuery | undefined;
    /**
     * @param {boolean} started
     * @returns {void}s
     */
    set fullyStarted(started: boolean);
    /**
     * @returns {boolean}
     */
    get fullyStarted(): boolean;
    /**
     * @returns {Promise<string|undefined>}
     */
    retrieveDerivedDataPath(): Promise<string | undefined>;
    /**
     * Reuse running WDA if it has the same bundle id with updatedWDABundleId.
     * Or reuse it if it has the default id without updatedWDABundleId.
     * Uninstall it if the method faces an exception for the above situation.
     * @returns {Promise<void>}
     */
    setupCaching(): Promise<void>;
    /**
     * Quit and uninstall running WDA.
     * @returns {Promise<void>}
     */
    quitAndUninstall(): Promise<void>;
}
export default WebDriverAgent;
import { XcodeBuild } from './xcodebuild';
import { JWProxy } from '@appium/base-driver';
import { NoSessionProxy } from './no-session-proxy';
import url from 'url';
//# sourceMappingURL=webdriveragent.d.ts.map