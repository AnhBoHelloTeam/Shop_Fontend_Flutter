"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getClipboard = exports.setClipboard = void 0;
/**
 * Set clipboard content via each native app driver
 * @param this the FlutterDriver
 * @param content the content to get the clipboard
 * @param contentType the contentType to set the data type
 */
const setClipboard = async function (content, contentType) {
    await this.proxydriver.setClipboard(content, contentType);
};
exports.setClipboard = setClipboard;
/**
 * Get the clipboard content via each native app driver
 * @param this the FlutterDriver
 * @param contentType the contentType to set the data type
 */
const getClipboard = async function (contentType) {
    await this.proxydriver.getClipboard(contentType);
};
exports.getClipboard = getClipboard;
//# sourceMappingURL=clipboard.js.map