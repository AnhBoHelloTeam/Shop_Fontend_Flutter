"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const lodash_1 = __importDefault(require("lodash"));
const asyncbox_1 = require("asyncbox");
const commands = {};
/**
 * Execute the particular application package on Simulator.
 * It is required that Simulator is in _booted_ state and
 * the application with given bundle identifier is already installed.
 *
 * @this {import('../simctl').Simctl}
 * @param {string} bundleId - Bundle identifier of the application,
 *                            which is going to be removed.
 * @param {number} [tries=5] - The maximum number of retries before
 *                             throwing an exception.
 * @return {Promise<string>} the actual command output
 * @throws {Error} If the corresponding simctl subcommand command
 *                 returns non-zero return code.
 * @throws {Error} If the `udid` instance property is unset
 */
commands.launchApp = async function launchApp(bundleId, tries = 5) {
    // @ts-ignore A string will always be returned
    return await (0, asyncbox_1.retryInterval)(tries, 1000, async () => {
        const { stdout } = await this.exec('launch', {
            args: [this.requireUdid('launch'), bundleId],
        });
        return lodash_1.default.trim(stdout);
    });
};
exports.default = commands;
//# sourceMappingURL=launch.js.map