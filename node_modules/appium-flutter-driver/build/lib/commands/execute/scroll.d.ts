import { FlutterDriver } from '../../driver';
export declare const scroll: (self: FlutterDriver, elementBase64: string, opts: {
    dx: number;
    dy: number;
    durationMilliseconds: number;
    frequency?: number;
}) => Promise<any>;
export declare const longTap: (self: FlutterDriver, elementBase64: string, opts: {
    durationMilliseconds: number;
    frequency?: number;
}) => Promise<any>;
export declare const scrollUntilVisible: (self: FlutterDriver, elementBase64: string, opts: {
    item: string;
    alignment: number;
    dxScroll: number;
    dyScroll: number;
    durationMilliseconds: number;
    frequency?: number;
    waitTimeoutMilliseconds?: number;
}) => Promise<any>;
export declare const scrollUntilTapable: (self: FlutterDriver, elementBase64: string, opts: {
    item: string;
    alignment: number;
    dxScroll: number;
    dyScroll: number;
    durationMilliseconds: number;
    frequency?: number;
    waitTimeoutMilliseconds?: number;
}) => Promise<any>;
export declare const scrollIntoView: (self: FlutterDriver, elementBase64: string, opts: {
    alignment: number;
    timeout?: number;
}) => Promise<any>;
//# sourceMappingURL=scroll.d.ts.map