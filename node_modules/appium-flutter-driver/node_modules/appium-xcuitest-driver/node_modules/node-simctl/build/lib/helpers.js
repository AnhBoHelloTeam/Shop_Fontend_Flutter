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
Object.defineProperty(exports, "__esModule", { value: true });
exports.SIM_RUNTIME_NAME = exports.DEFAULT_EXEC_TIMEOUT = void 0;
exports.normalizeVersion = normalizeVersion;
exports.getXcrunBinary = getXcrunBinary;
const semver = __importStar(require("semver"));
exports.DEFAULT_EXEC_TIMEOUT = 10 * 60 * 1000; // ms
exports.SIM_RUNTIME_NAME = 'com.apple.CoreSimulator.SimRuntime.';
/**
 * "Normalize" the version, since iOS uses 'major.minor' but the runtimes can
 * be 'major.minor.patch'
 *
 * @param {string} version - the string version
 * @return {string} The version in 'major.minor' form
 * @throws {Error} If the version not parseable by the `semver` package
 */
function normalizeVersion(version) {
    const semverVersion = semver.coerce(version);
    if (!semverVersion) {
        throw new Error(`Unable to parse version '${version}'`);
    }
    return `${semverVersion.major}.${semverVersion.minor}`;
}
/**
 * @returns {string}
 */
function getXcrunBinary() {
    return process.env.XCRUN_BINARY || 'xcrun';
}
//# sourceMappingURL=helpers.js.map