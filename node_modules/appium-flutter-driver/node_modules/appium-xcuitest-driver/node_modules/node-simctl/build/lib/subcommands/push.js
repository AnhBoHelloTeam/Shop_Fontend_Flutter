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
 * Send a simulated push notification
 *
 * @since Xcode 11.4 SDK
 * @this {import('../simctl').Simctl}
 * @param {Object} payload - The object that describes Apple push notification content.
 * It must contain a top-level "Simulator Target Bundle" key with a string value matching
 * the target application‘s bundle identifier and "aps" key with valid Apple Push Notification values.
 * For example:
 * {
 *   "Simulator Target Bundle": "com.apple.Preferences",
 *   "aps": {
 *     "alert": "This is a simulated notification!",
 *     "badge": 3,
 *     "sound": "default"
 *   }
 * }
 * @throws {Error} if the current SDK version does not support the command
 * or there was an error while pushing the notification
 * @throws {Error} If the `udid` instance property is unset
 */
commands.pushNotification = async function pushNotification(payload) {
    const dstPath = path_1.default.resolve(os_1.default.tmpdir(), `${(0, uuid_1.v4)()}.json`);
    try {
        await promises_1.default.writeFile(dstPath, JSON.stringify(payload), 'utf8');
        await this.exec('push', {
            args: [this.requireUdid('push'), dstPath],
        });
    }
    finally {
        await (0, rimraf_1.rimraf)(dstPath);
    }
};
exports.default = commands;
//# sourceMappingURL=push.js.map