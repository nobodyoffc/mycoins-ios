// Single source of truth for the version shown in-app: package.json, kept in
// step with MARKETING_VERSION in the Xcode project.
import pkg from '../../package.json';

export const APP_VERSION: string = pkg.version;
