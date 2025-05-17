"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const os_1 = __importDefault(require("os"));
const promises_1 = __importDefault(require("fs/promises"));
const uuid_1 = require("uuid");
const path_1 = __importDefault(require("path"));
const lodash_1 = __importDefault(require("lodash"));
const rimraf_1 = require("rimraf");
const commands = {};
/**
 *
 * @param {string|Buffer} payload
 * @param {(filePath: string) => Promise<any>} onPayloadStored
 */
async function handleRawPayload(payload, onPayloadStored) {
    const filePath = path_1.default.resolve(os_1.default.tmpdir(), `${(0, uuid_1.v4)()}.pem`);
    try {
        if (lodash_1.default.isBuffer(payload)) {
            await promises_1.default.writeFile(filePath, payload);
        }
        else {
            await promises_1.default.writeFile(filePath, payload, 'utf8');
        }
        await onPayloadStored(filePath);
    }
    finally {
        await (0, rimraf_1.rimraf)(filePath);
    }
}
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
commands.addRootCertificate = async function addRootCertificate(cert, opts = {}) {
    const { raw = false, } = opts;
    const execMethod = async (/** @type {string} */ certPath) => await this.exec('keychain', {
        args: [this.requireUdid('keychain add-root-cert'), 'add-root-cert', certPath],
    });
    if (raw) {
        await handleRawPayload(cert, execMethod);
    }
    else {
        await execMethod(cert);
    }
};
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
commands.addCertificate = async function addCertificate(cert, opts = {}) {
    const { raw = false, } = opts;
    const execMethod = async (certPath) => await this.exec('keychain', {
        args: [this.requireUdid('keychain add-cert'), 'add-cert', certPath],
    });
    if (raw) {
        await handleRawPayload(cert, execMethod);
    }
    else {
        await execMethod(cert);
    }
};
/**
 * Resets the simulator keychain
 *
 * @since Xcode 11.4 SDK
 * @this {import('../simctl').Simctl}
 * @throws {Error} if the current SDK version does not support the command
 * or there was an error while resetting the keychain
 * @throws {Error} If the `udid` instance property is unset
 */
commands.resetKeychain = async function resetKeychain() {
    await this.exec('keychain', {
        args: [this.requireUdid('keychain reset'), 'reset'],
    });
};
exports.default = commands;
//# sourceMappingURL=keychain.js.map