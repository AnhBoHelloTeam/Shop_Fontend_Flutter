export class XcodeBuild {
    /**
     * @param {import('appium-xcode').XcodeVersion} xcodeVersion
     * @param {any} device
     * // TODO: make args typed
     * @param {import('@appium/types').StringRecord} [args={}]
     * @param {import('@appium/types').AppiumLogger?} [log=null]
     */
    constructor(xcodeVersion: import("appium-xcode").XcodeVersion, device: any, args?: import("@appium/types").StringRecord, log?: import("@appium/types").AppiumLogger | null);
    /** @type {SubProcess} */
    xcodebuild: SubProcess;
    xcodeVersion: import("appium-xcode/build/lib/xcode").XcodeVersion;
    device: any;
    log: import("@appium/types").AppiumLogger;
    realDevice: any;
    agentPath: any;
    bootstrapPath: any;
    platformVersion: any;
    platformName: any;
    iosSdkVersion: any;
    showXcodeLog: any;
    xcodeConfigFile: any;
    xcodeOrgId: any;
    xcodeSigningId: any;
    keychainPath: any;
    keychainPassword: any;
    prebuildWDA: any;
    usePrebuiltWDA: any;
    useSimpleBuildTest: any;
    useXctestrunFile: any;
    launchTimeout: any;
    wdaRemotePort: any;
    updatedWDABundleId: any;
    derivedDataPath: any;
    mjpegServerPort: any;
    prebuildDelay: number;
    allowProvisioningDeviceRegistration: any;
    resultBundlePath: any;
    resultBundleVersion: any;
    _didBuildFail: boolean;
    _didProcessExit: boolean;
    /**
     *
     * @param {any} noSessionProxy
     * @returns {Promise<void>}
     */
    init(noSessionProxy: any): Promise<void>;
    noSessionProxy: any;
    xctestrunFilePath: string | undefined;
    /**
     * @returns {Promise<string|undefined>}
     */
    retrieveDerivedDataPath(): Promise<string | undefined>;
    _derivedDataPathPromise: Promise<any> | undefined;
    /**
     * @returns {Promise<void>}
     */
    reset(): Promise<void>;
    /**
     * @returns {Promise<void>}
     */
    prebuild(): Promise<void>;
    /**
     * @returns {Promise<void>}
     */
    cleanProject(): Promise<void>;
    /**
     *
     * @param {boolean} [buildOnly=false]
     * @returns {{cmd: string, args: string[]}}
     */
    getCommand(buildOnly?: boolean): {
        cmd: string;
        args: string[];
    };
    /**
     * @param {boolean} [buildOnly=false]
     * @returns {Promise<SubProcess>}
     */
    createSubProcess(buildOnly?: boolean): Promise<SubProcess>;
    /**
     * @param {boolean} [buildOnly=false]
     * @returns {Promise<import('@appium/types').StringRecord>}
     */
    start(buildOnly?: boolean): Promise<import("@appium/types").StringRecord>;
    didProcessExit: boolean | undefined;
    /**
     *
     * @param {any} timer
     * @returns {Promise<import('@appium/types').StringRecord?>}
     */
    waitForStart(timer: any): Promise<import("@appium/types").StringRecord | null>;
    agentUrl: any;
    /**
     * @returns {Promise<void>}
     */
    quit(): Promise<void>;
}
export default XcodeBuild;
import { SubProcess } from 'teen_process';
//# sourceMappingURL=xcodebuild.d.ts.map