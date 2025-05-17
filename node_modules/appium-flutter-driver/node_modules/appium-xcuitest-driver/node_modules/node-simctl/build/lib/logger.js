"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.LOG_PREFIX = void 0;
const logger_1 = __importDefault(require("@appium/logger"));
const LOG_PREFIX = 'simctl';
exports.LOG_PREFIX = LOG_PREFIX;
function getLogger() {
    const logger = global._global_npmlog || logger_1.default;
    if (!logger.debug) {
        logger.addLevel('debug', 1000, { fg: 'blue', bg: 'black' }, 'dbug');
    }
    return logger;
}
const log = getLogger();
exports.default = log;
//# sourceMappingURL=logger.js.map