"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const rimraf_1 = require("rimraf");
const uuid_1 = require("uuid");
const path_1 = __importDefault(require("path"));
const os_1 = __importDefault(require("os"));
const promises_1 = __importDefault(require("fs/promises"));
const commands = {};
/**
 * Gets base64 screenshot for device
 * It is required that Simulator is in _booted_ state.
 *
 * @this {import('../simctl').Simctl}
 * @since Xcode SDK 8.1
 * @return {Promise<string>} Base64-encoded Simulator screenshot.
 * @throws {Error} If the corresponding simctl subcommand command
 *                 returns non-zero return code.
 * @throws {Error} If the `udid` instance property is unset
 */
commands.getScreenshot = async function getScreenshot() {
    const udid = this.requireUdid('io screenshot');
    const pathToScreenshotPng = path_1.default.resolve(os_1.default.tmpdir(), `${(0, uuid_1.v4)()}.png`);
    try {
        await this.exec('io', {
            args: [udid, 'screenshot', pathToScreenshotPng],
        });
        return (await promises_1.default.readFile(pathToScreenshotPng)).toString('base64');
    }
    finally {
        await (0, rimraf_1.rimraf)(pathToScreenshotPng);
    }
};
exports.default = commands;
//# sourceMappingURL=io.js.map