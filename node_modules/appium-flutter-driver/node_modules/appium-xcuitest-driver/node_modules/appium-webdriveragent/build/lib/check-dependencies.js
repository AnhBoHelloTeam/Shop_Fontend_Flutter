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
exports.checkForDependencies = checkForDependencies;
exports.bundleWDASim = bundleWDASim;
const support_1 = require("@appium/support");
const lodash_1 = __importDefault(require("lodash"));
const teen_process_1 = require("teen_process");
const path_1 = __importDefault(require("path"));
const xcodebuild_1 = require("./xcodebuild");
const xcode = __importStar(require("appium-xcode"));
const constants_1 = require("./constants");
const utils_1 = require("./utils");
const logger_1 = __importDefault(require("./logger"));
async function buildWDASim() {
    const args = [
        '-project', path_1.default.join(utils_1.BOOTSTRAP_PATH, 'WebDriverAgent.xcodeproj'),
        '-scheme', constants_1.WDA_SCHEME,
        '-sdk', constants_1.SDK_SIMULATOR,
        'CODE_SIGN_IDENTITY=""',
        'CODE_SIGNING_REQUIRED="NO"',
        'GCC_TREAT_WARNINGS_AS_ERRORS=0',
    ];
    await (0, teen_process_1.exec)('xcodebuild', args);
}
async function checkForDependencies() {
    logger_1.default.debug('Dependencies are up to date');
    return false;
}
/**
 *
 * @param {XcodeBuild} xcodebuild
 * @returns {Promise<string>}
 */
async function bundleWDASim(xcodebuild) {
    if (xcodebuild && !lodash_1.default.isFunction(xcodebuild.retrieveDerivedDataPath)) {
        xcodebuild = new xcodebuild_1.XcodeBuild(/** @type {import('appium-xcode').XcodeVersion} */ (await xcode.getVersion(true)), {});
    }
    const derivedDataPath = await xcodebuild.retrieveDerivedDataPath();
    if (!derivedDataPath) {
        throw new Error('Cannot retrieve the path to the Xcode derived data folder');
    }
    const wdaBundlePath = path_1.default.join(derivedDataPath, 'Build', 'Products', 'Debug-iphonesimulator', constants_1.WDA_RUNNER_APP);
    if (await support_1.fs.exists(wdaBundlePath)) {
        return wdaBundlePath;
    }
    await buildWDASim();
    return wdaBundlePath;
}
//# sourceMappingURL=check-dependencies.js.map