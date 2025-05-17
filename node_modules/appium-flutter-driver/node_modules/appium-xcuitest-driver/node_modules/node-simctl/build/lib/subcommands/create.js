"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = __importDefault(require("lodash"));
const logger_1 = __importStar(require("../logger"));
const asyncbox_1 = require("asyncbox");
const helpers_1 = require("../helpers");
const SIM_RUNTIME_NAME_SUFFIX_IOS = 'iOS';
const DEFAULT_CREATE_SIMULATOR_TIMEOUT = 10000;
const commands = {};
/**
 * @typedef {Object} SimCreationOpts
 * @property {string} [platform='iOS'] - Platform name in order to specify runtime such as 'iOS', 'tvOS', 'watchOS'
 * @property {number} [timeout=10000] - The maximum number of milliseconds to wait
 *                                      unit device creation is completed.
 */
/**
 * Create Simulator device with given name for the particular
 * platform type and version.
 *
 * @this {import('../simctl').Simctl}
 * @param {string} name - The device name to be created.
 * @param {string} deviceTypeId - Device type, for example 'iPhone 6'.
 * @param {string} platformVersion - Platform version, for example '10.3'.
 * @param {SimCreationOpts} [opts={}] - Simulator options for creating devices.
 * @return {Promise<string>} The UDID of the newly created device.
 * @throws {Error} If the corresponding simctl subcommand command
 *                 returns non-zero return code.
 */
commands.createDevice = async function createDevice(name, deviceTypeId, platformVersion, opts = {}) {
    const { platform = SIM_RUNTIME_NAME_SUFFIX_IOS, timeout = DEFAULT_CREATE_SIMULATOR_TIMEOUT } = opts;
    let runtimeIds = [];
    // Try getting runtimeId using JSON flag
    try {
        runtimeIds.push(await this.getRuntimeForPlatformVersionViaJson(platformVersion, platform));
    }
    catch { }
    if (lodash_1.default.isEmpty(runtimeIds)) {
        // at first make sure that the runtime id is the right one
        // in some versions of Xcode it will be a patch version
        let runtimeId;
        try {
            runtimeId = await this.getRuntimeForPlatformVersion(platformVersion, platform);
        }
        catch {
            logger_1.default.warn(`Unable to find runtime for iOS '${platformVersion}'. Continuing`);
            runtimeId = platformVersion;
        }
        // get the possible runtimes, which will be iterated over
        // start with major-minor version
        let potentialRuntimeIds = [(0, helpers_1.normalizeVersion)(runtimeId)];
        if (runtimeId.split('.').length === 3) {
            // add patch version if it exists
            potentialRuntimeIds.push(runtimeId);
        }
        // add modified versions, since modern Xcodes use this, then the bare
        // versions, to accomodate older Xcodes
        runtimeIds.push(...(potentialRuntimeIds.map((id) => `${helpers_1.SIM_RUNTIME_NAME}${platform}-${id.replace(/\./g, '-')}`)), ...potentialRuntimeIds);
    }
    // go through the runtime ids and try to create a simulator with each
    let udid;
    for (const runtimeId of runtimeIds) {
        logger_1.default.debug(logger_1.LOG_PREFIX, `Creating simulator with name '${name}', device type id '${deviceTypeId}' and runtime id '${runtimeId}'`);
        try {
            const { stdout } = await this.exec('create', {
                args: [name, deviceTypeId, runtimeId]
            });
            udid = stdout.trim();
            break;
        }
        catch {
            // the error gets logged in `simExec`
        }
    }
    if (!udid) {
        throw new Error(`Could not create simulator with name '${name}', device ` +
            `type id '${deviceTypeId}', with runtime ids ` +
            `${runtimeIds.map((id) => `'${id}'`).join(', ')}`);
    }
    // make sure that it gets out of the "Creating" state
    const retries = parseInt(`${timeout / 1000}`, 10);
    await (0, asyncbox_1.retryInterval)(retries, 1000, async () => {
        const devices = lodash_1.default.values(await this.getDevices());
        for (const deviceArr of lodash_1.default.values(devices)) {
            for (const device of deviceArr) {
                if (device.udid === udid) {
                    if (device.state === 'Creating') {
                        // need to retry
                        throw new Error(`Device with udid '${udid}' still being created`);
                    }
                    else {
                        // stop looking, we're done
                        return;
                    }
                }
            }
        }
        throw new Error(`Device with udid '${udid}' not yet created`);
    });
    return udid;
};
exports.default = commands;
//# sourceMappingURL=create.js.map