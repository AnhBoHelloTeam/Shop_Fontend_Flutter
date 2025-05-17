"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.clear = exports.setValue = exports.getText = void 0;
const getText = async function (el) {
    const response = await this.executeElementCommand(`get_text`, el);
    return response.text;
};
exports.getText = getText;
const setValue = async function (textInput, el) {
    const clickPromise = this.click(el); // acquire focus
    let text = ``;
    if (textInput instanceof Array) {
        text = textInput.reduce((previousValue, currentValue) => `${previousValue}${currentValue}`);
    }
    else if (typeof textInput === `string`) {
        text = textInput;
    }
    else {
        throw new Error(`Invalid textInput: ${textInput}`);
    }
    await clickPromise;
    await this.execute(`flutter:enterText`, [text]);
};
exports.setValue = setValue;
const clear = async function (el) {
    await this.setValue([``], el);
};
exports.clear = clear;
//# sourceMappingURL=element.js.map