"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.NoSessionProxy = void 0;
const base_driver_1 = require("@appium/base-driver");
class NoSessionProxy extends base_driver_1.JWProxy {
    constructor(opts = {}) {
        super(opts);
    }
    getUrlForProxy(url) {
        if (url === '') {
            url = '/';
        }
        const proxyBase = `${this.scheme}://${this.server}:${this.port}${this.base}`;
        let remainingUrl = '';
        if ((new RegExp('^/')).test(url)) {
            remainingUrl = url;
        }
        else {
            throw new Error(`Did not know what to do with url '${url}'`);
        }
        remainingUrl = remainingUrl.replace(/\/$/, ''); // can't have trailing slashes
        return proxyBase + remainingUrl;
    }
}
exports.NoSessionProxy = NoSessionProxy;
exports.default = NoSessionProxy;
//# sourceMappingURL=no-session-proxy.js.map