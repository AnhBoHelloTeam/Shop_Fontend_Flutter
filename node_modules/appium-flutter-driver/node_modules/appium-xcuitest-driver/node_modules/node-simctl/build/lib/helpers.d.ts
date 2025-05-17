/**
 * "Normalize" the version, since iOS uses 'major.minor' but the runtimes can
 * be 'major.minor.patch'
 *
 * @param {string} version - the string version
 * @return {string} The version in 'major.minor' form
 * @throws {Error} If the version not parseable by the `semver` package
 */
export function normalizeVersion(version: string): string;
/**
 * @returns {string}
 */
export function getXcrunBinary(): string;
export const DEFAULT_EXEC_TIMEOUT: number;
export const SIM_RUNTIME_NAME: "com.apple.CoreSimulator.SimRuntime.";
//# sourceMappingURL=helpers.d.ts.map