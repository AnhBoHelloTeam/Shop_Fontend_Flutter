"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const commands = {};
/**
 * Delete the particular Simulator from available devices list.
 *
 * @this {import('../simctl').Simctl}
 * @throws {Error} If the corresponding simctl subcommand command
 *                 returns non-zero return code.
 * @throws {Error} If the `udid` instance property is unset
 */
commands.deleteDevice = async function deleteDevice() {
    await this.exec('delete', {
        args: [this.requireUdid('delete')]
    });
};
exports.default = commands;
//# sourceMappingURL=delete.js.map