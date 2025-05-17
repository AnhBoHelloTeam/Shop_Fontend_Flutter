"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.BOOTSTRAP_PATH = void 0;
exports.updateProjectFile = updateProjectFile;
exports.resetProjectFile = resetProjectFile;
exports.setRealDeviceSecurity = setRealDeviceSecurity;
exports.getAdditionalRunContent = getAdditionalRunContent;
exports.getXctestrunFileName = getXctestrunFileName;
exports.setXctestrunFile = setXctestrunFile;
exports.getXctestrunFilePath = getXctestrunFilePath;
exports.killProcess = killProcess;
exports.randomInt = randomInt;
exports.getWDAUpgradeTimestamp = getWDAUpgradeTimestamp;
exports.resetTestProcesses = resetTestProcesses;
exports.getPIDsListeningOnPort = getPIDsListeningOnPort;
exports.killAppUsingPattern = killAppUsingPattern;
exports.isTvOS = isTvOS;
const support_1 = require("@appium/support");
const teen_process_1 = require("teen_process");
const path_1 = __importDefault(require("path"));
const logger_1 = __importDefault(require("./logger"));
const lodash_1 = __importDefault(require("lodash"));
const constants_1 = require("./constants");
const bluebird_1 = __importDefault(require("bluebird"));
const fs_1 = __importDefault(require("fs"));
const asyncbox_1 = require("asyncbox");
const os_1 = require("os");
const PROJECT_FILE = 'project.pbxproj';
/**
 * Calculates the path to the current module's root folder
 *
 * @returns {string} The full path to module root
 * @throws {Error} If the current module root folder cannot be determined
 */
const getModuleRoot = lodash_1.default.memoize(function getModuleRoot() {
    let currentDir = path_1.default.dirname(path_1.default.resolve(__filename));
    let isAtFsRoot = false;
    while (!isAtFsRoot) {
        const manifestPath = path_1.default.join(currentDir, 'package.json');
        try {
            if (fs_1.default.existsSync(manifestPath) &&
                JSON.parse(fs_1.default.readFileSync(manifestPath, 'utf8')).name === 'appium-webdriveragent') {
                return currentDir;
            }
        }
        catch { }
        currentDir = path_1.default.dirname(currentDir);
        isAtFsRoot = currentDir.length <= path_1.default.dirname(currentDir).length;
    }
    throw new Error('Cannot find the root folder of the appium-webdriveragent Node.js module');
});
exports.BOOTSTRAP_PATH = getModuleRoot();
async function getPIDsUsingPattern(pattern) {
    const args = [
        '-if', // case insensitive, full cmdline match
        pattern,
    ];
    try {
        const { stdout } = await (0, teen_process_1.exec)('pgrep', args);
        return stdout.split(/\s+/)
            .map((x) => parseInt(x, 10))
            .filter(lodash_1.default.isInteger)
            .map((x) => `${x}`);
    }
    catch (err) {
        logger_1.default.debug(`'pgrep ${args.join(' ')}' didn't detect any matching processes. Return code: ${err.code}`);
        return [];
    }
}
async function killAppUsingPattern(pgrepPattern) {
    const signals = [2, 15, 9];
    for (const signal of signals) {
        const matchedPids = await getPIDsUsingPattern(pgrepPattern);
        if (lodash_1.default.isEmpty(matchedPids)) {
            return;
        }
        const args = [`-${signal}`, ...matchedPids];
        try {
            await (0, teen_process_1.exec)('kill', args);
        }
        catch (err) {
            logger_1.default.debug(`kill ${args.join(' ')} -> ${err.message}`);
        }
        if (signal === lodash_1.default.last(signals)) {
            // there is no need to wait after SIGKILL
            return;
        }
        try {
            await (0, asyncbox_1.waitForCondition)(async () => {
                const pidCheckPromises = matchedPids
                    .map((pid) => (0, teen_process_1.exec)('kill', ['-0', pid])
                    // the process is still alive
                    .then(() => false)
                    // the process is dead
                    .catch(() => true));
                return (await bluebird_1.default.all(pidCheckPromises))
                    .every((x) => x === true);
            }, {
                waitMs: 1000,
                intervalMs: 100,
            });
            return;
        }
        catch {
            // try the next signal
        }
    }
}
/**
 * Return true if the platformName is tvOS
 * @param {string} platformName The name of the platorm
 * @returns {boolean} Return true if the platformName is tvOS
 */
function isTvOS(platformName) {
    return lodash_1.default.toLower(platformName) === lodash_1.default.toLower(constants_1.PLATFORM_NAME_TVOS);
}
async function replaceInFile(file, find, replace) {
    let contents = await support_1.fs.readFile(file, 'utf8');
    let newContents = contents.replace(find, replace);
    if (newContents !== contents) {
        await support_1.fs.writeFile(file, newContents, 'utf8');
    }
}
/**
 * Update WebDriverAgentRunner project bundle ID with newBundleId.
 * This method assumes project file is in the correct state.
 * @param {string} agentPath - Path to the .xcodeproj directory.
 * @param {string} newBundleId the new bundle ID used to update.
 */
async function updateProjectFile(agentPath, newBundleId) {
    let projectFilePath = path_1.default.resolve(agentPath, PROJECT_FILE);
    try {
        // Assuming projectFilePath is in the correct state, create .old from projectFilePath
        await support_1.fs.copyFile(projectFilePath, `${projectFilePath}.old`);
        await replaceInFile(projectFilePath, new RegExp(lodash_1.default.escapeRegExp(constants_1.WDA_RUNNER_BUNDLE_ID), 'g'), newBundleId);
        logger_1.default.debug(`Successfully updated '${projectFilePath}' with bundle id '${newBundleId}'`);
    }
    catch (err) {
        logger_1.default.debug(`Error updating project file: ${err.message}`);
        logger_1.default.warn(`Unable to update project file '${projectFilePath}' with ` +
            `bundle id '${newBundleId}'. WebDriverAgent may not start`);
    }
}
/**
 * Reset WebDriverAgentRunner project bundle ID to correct state.
 * @param {string} agentPath - Path to the .xcodeproj directory.
 */
async function resetProjectFile(agentPath) {
    const projectFilePath = path_1.default.join(agentPath, PROJECT_FILE);
    try {
        // restore projectFilePath from .old file
        if (!await support_1.fs.exists(`${projectFilePath}.old`)) {
            return; // no need to reset
        }
        await support_1.fs.mv(`${projectFilePath}.old`, projectFilePath);
        logger_1.default.debug(`Successfully reset '${projectFilePath}' with bundle id '${constants_1.WDA_RUNNER_BUNDLE_ID}'`);
    }
    catch (err) {
        logger_1.default.debug(`Error resetting project file: ${err.message}`);
        logger_1.default.warn(`Unable to reset project file '${projectFilePath}' with ` +
            `bundle id '${constants_1.WDA_RUNNER_BUNDLE_ID}'. WebDriverAgent has been ` +
            `modified and not returned to the original state.`);
    }
}
async function setRealDeviceSecurity(keychainPath, keychainPassword) {
    logger_1.default.debug('Setting security for iOS device');
    await (0, teen_process_1.exec)('security', ['-v', 'list-keychains', '-s', keychainPath]);
    await (0, teen_process_1.exec)('security', ['-v', 'unlock-keychain', '-p', keychainPassword, keychainPath]);
    await (0, teen_process_1.exec)('security', ['set-keychain-settings', '-t', '3600', '-l', keychainPath]);
}
/**
 * Information of the device under test
 * @typedef {Object} DeviceInfo
 * @property {string} isRealDevice - Equals to true if the current device is a real device
 * @property {string} udid - The device UDID.
 * @property {string} platformVersion - The platform version of OS.
 * @property {string} platformName - The platform name of iOS, tvOS
*/
/**
 * Creates xctestrun file per device & platform version.
 * We expects to have WebDriverAgentRunner_iphoneos${sdkVersion|platformVersion}-arm64.xctestrun for real device
 * and WebDriverAgentRunner_iphonesimulator${sdkVersion|platformVersion}-${x86_64|arm64}.xctestrun for simulator located @bootstrapPath
 * Newer Xcode (Xcode 10.0 at least) generate xctestrun file following sdkVersion.
 * e.g. Xcode which has iOS SDK Version 12.2 on an intel Mac host machine generates WebDriverAgentRunner_iphonesimulator.2-x86_64.xctestrun
 *      even if the cap has platform version 11.4
 *
 * @param {DeviceInfo} deviceInfo
 * @param {string} sdkVersion - The Xcode SDK version of OS.
 * @param {string} bootstrapPath - The folder path containing xctestrun file.
 * @param {number|string} wdaRemotePort - The remote port WDA is listening on.
 * @return {Promise<string>} returns xctestrunFilePath for given device
 * @throws if WebDriverAgentRunner_iphoneos${sdkVersion|platformVersion}-arm64.xctestrun for real device
 * or WebDriverAgentRunner_iphonesimulator${sdkVersion|platformVersion}-x86_64.xctestrun for simulator is not found @bootstrapPath,
 * then it will throw file not found exception
 */
async function setXctestrunFile(deviceInfo, sdkVersion, bootstrapPath, wdaRemotePort) {
    const xctestrunFilePath = await getXctestrunFilePath(deviceInfo, sdkVersion, bootstrapPath);
    const xctestRunContent = await support_1.plist.parsePlistFile(xctestrunFilePath);
    const updateWDAPort = getAdditionalRunContent(deviceInfo.platformName, wdaRemotePort);
    const newXctestRunContent = lodash_1.default.merge(xctestRunContent, updateWDAPort);
    await support_1.plist.updatePlistFile(xctestrunFilePath, newXctestRunContent, true);
    return xctestrunFilePath;
}
/**
 * Return the WDA object which appends existing xctest runner content
 * @param {string} platformName - The name of the platform
 * @param {number|string} wdaRemotePort - The remote port number
 * @return {object} returns a runner object which has USE_PORT
 */
function getAdditionalRunContent(platformName, wdaRemotePort) {
    const runner = `WebDriverAgentRunner${isTvOS(platformName) ? '_tvOS' : ''}`;
    return {
        [runner]: {
            EnvironmentVariables: {
                // USE_PORT must be 'string'
                USE_PORT: `${wdaRemotePort}`
            }
        }
    };
}
/**
 * Return the path of xctestrun if it exists
 * @param {DeviceInfo} deviceInfo
 * @param {string} sdkVersion - The Xcode SDK version of OS.
 * @param {string} bootstrapPath - The folder path containing xctestrun file.
 * @returns {Promise<string>}
 */
async function getXctestrunFilePath(deviceInfo, sdkVersion, bootstrapPath) {
    // First try the SDK path, for Xcode 10 (at least)
    const sdkBased = [
        path_1.default.resolve(bootstrapPath, `${deviceInfo.udid}_${sdkVersion}.xctestrun`),
        sdkVersion,
    ];
    // Next try Platform path, for earlier Xcode versions
    const platformBased = [
        path_1.default.resolve(bootstrapPath, `${deviceInfo.udid}_${deviceInfo.platformVersion}.xctestrun`),
        deviceInfo.platformVersion,
    ];
    for (const [filePath, version] of [sdkBased, platformBased]) {
        if (await support_1.fs.exists(filePath)) {
            logger_1.default.info(`Using '${filePath}' as xctestrun file`);
            return filePath;
        }
        const originalXctestrunFile = path_1.default.resolve(bootstrapPath, getXctestrunFileName(deviceInfo, version));
        if (await support_1.fs.exists(originalXctestrunFile)) {
            // If this is first time run for given device, then first generate xctestrun file for device.
            // We need to have a xctestrun file **per device** because we cant not have same wda port for all devices.
            await support_1.fs.copyFile(originalXctestrunFile, filePath);
            logger_1.default.info(`Using '${filePath}' as xctestrun file copied by '${originalXctestrunFile}'`);
            return filePath;
        }
    }
    throw new Error(`If you are using 'useXctestrunFile' capability then you ` +
        `need to have a xctestrun file (expected: ` +
        `'${path_1.default.resolve(bootstrapPath, getXctestrunFileName(deviceInfo, sdkVersion))}')`);
}
/**
 * Return the name of xctestrun file
 * @param {DeviceInfo} deviceInfo
 * @param {string} version - The Xcode SDK version of OS.
 * @return {string} returns xctestrunFilePath for given device
 */
function getXctestrunFileName(deviceInfo, version) {
    const archSuffix = deviceInfo.isRealDevice
        ? `os${version}-arm64`
        : `simulator${version}-${(0, os_1.arch)() === 'arm64' ? 'arm64' : 'x86_64'}`;
    return `WebDriverAgentRunner_${isTvOS(deviceInfo.platformName) ? 'tvOS_appletv' : 'iphone'}${archSuffix}.xctestrun`;
}
/**
 * Ensures the process is killed after the timeout
 *
 * @param {string} name
 * @param {import('teen_process').SubProcess} proc
 * @returns {Promise<void>}
 */
async function killProcess(name, proc) {
    if (!proc || !proc.isRunning) {
        return;
    }
    logger_1.default.info(`Shutting down '${name}' process (pid '${proc.proc?.pid}')`);
    logger_1.default.info(`Sending 'SIGTERM'...`);
    try {
        await proc.stop('SIGTERM', 1000);
        return;
    }
    catch (err) {
        if (!err.message.includes(`Process didn't end after`)) {
            throw err;
        }
        logger_1.default.debug(`${name} process did not end in a timely fashion: '${err.message}'.`);
    }
    logger_1.default.info(`Sending 'SIGKILL'...`);
    try {
        await proc.stop('SIGKILL');
    }
    catch (err) {
        if (err.message.includes('not currently running')) {
            // the process ended but for some reason we were not informed
            return;
        }
        throw err;
    }
}
/**
 * Generate a random integer.
 *
 * @return {number} A random integer number in range [low, hight). `low`` is inclusive and `high` is exclusive.
 */
function randomInt(low, high) {
    return Math.floor(Math.random() * (high - low) + low);
}
/**
 * Retrieves WDA upgrade timestamp
 *
 * @return {Promise<number?>} The UNIX timestamp of the package manifest. The manifest only gets modified on
 * package upgrade.
 */
async function getWDAUpgradeTimestamp() {
    const packageManifest = path_1.default.resolve(getModuleRoot(), 'package.json');
    if (!await support_1.fs.exists(packageManifest)) {
        return null;
    }
    const { mtime } = await support_1.fs.stat(packageManifest);
    return mtime.getTime();
}
/**
 * Kills running XCTest processes for the particular device.
 *
 * @param {string} udid - The device UDID.
 * @param {boolean} isSimulator - Equals to true if the current device is a Simulator
 */
async function resetTestProcesses(udid, isSimulator) {
    const processPatterns = [`xcodebuild.*${udid}`];
    if (isSimulator) {
        processPatterns.push(`${udid}.*XCTRunner`);
        // The pattern to find in case idb was used
        processPatterns.push(`xctest.*${udid}`);
    }
    logger_1.default.debug(`Killing running processes '${processPatterns.join(', ')}' for the device ${udid}...`);
    await bluebird_1.default.all(processPatterns.map(killAppUsingPattern));
}
/**
 * Get the IDs of processes listening on the particular system port.
 * It is also possible to apply additional filtering based on the
 * process command line.
 *
 * @param {string|number} port - The port number.
 * @param {?Function} filteringFunc - Optional lambda function, which
 *                                    receives command line string of the particular process
 *                                    listening on given port, and is expected to return
 *                                    either true or false to include/exclude the corresponding PID
 *                                    from the resulting array.
 * @returns {Promise<string[]>} - the list of matched process ids.
 */
async function getPIDsListeningOnPort(port, filteringFunc = null) {
    const result = [];
    try {
        // This only works since Mac OS X El Capitan
        const { stdout } = await (0, teen_process_1.exec)('lsof', ['-ti', `tcp:${port}`]);
        result.push(...(stdout.trim().split(/\n+/)));
    }
    catch (e) {
        if (e.code !== 1) {
            // code 1 means no processes. Other errors need reporting
            logger_1.default.debug(`Error getting processes listening on port '${port}': ${e.stderr || e.message}`);
        }
        return result;
    }
    if (!lodash_1.default.isFunction(filteringFunc)) {
        return result;
    }
    return await bluebird_1.default.filter(result, async (pid) => {
        let stdout;
        try {
            ({ stdout } = await (0, teen_process_1.exec)('ps', ['-p', pid, '-o', 'command']));
        }
        catch (e) {
            if (e.code === 1) {
                // The process does not exist anymore, there's nothing to filter
                return false;
            }
            throw e;
        }
        return await filteringFunc(stdout);
    });
}
//# sourceMappingURL=utils.js.map