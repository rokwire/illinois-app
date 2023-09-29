/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package edu.illinois.rokwire;

public class Constants {

    // Flutter communication methods
    static final String APP_INIT_KEY = "init";
    static final String APP_DISMISS_LAUNCH_SCREEN_KEY = "dismissLaunchScreen";
    static final String APP_SET_LAUNCH_SCREEN_STATUS_KEY = "setLaunchScreenStatus";
    static final String APP_ENABLED_ORIENTATIONS_KEY = "enabledOrientations";
    static final String DEEPLINK_SCHEME_KEY = "deepLinkScheme";
    static final String BARCODE_KEY = "barcode";
    static final String TEST_KEY = "test";

    // Mobile Access
    public static final String MOBILE_ACCESS_START_KEY = "start";
    public static final String MOBILE_ACCESS_AVAILABLE_KEYS_KEY = "availableKeys";
    public static final String MOBILE_ACCESS_REGISTER_ENDPOINT_KEY = "registerEndpoint";
    public static final String MOBILE_ACCESS_UNREGISTER_ENDPOINT_KEY = "unregisterEndpoint";
    public static final String MOBILE_ACCESS_IS_ENDPOINT_REGISTERED_KEY = "isEndpointRegistered";
    public static final String MOBILE_ACCESS_SET_RSSI_SENSITIVITY_KEY = "setRssiSensitivity";
    public static final String MOBILE_ACCESS_SET_LOCK_SERVICE_CODES_KEY = "setLockServiceCodes";
    public static final String MOBILE_ACCESS_GET_LOCK_SERVICE_CODES_KEY = "getLockServiceCodes";
    public static final String MOBILE_ACCESS_ENABLE_TWIST_AND_GO_KEY = "enableTwistAndGo";
    public static final String MOBILE_ACCESS_IS_TWIST_AND_GO_ENABLED_KEY = "isTwistAndGoEnabled";
    public static final String MOBILE_ACCESS_ENABLE_UNLOCK_VIBRATION_KEY = "enableUnlockVibration";
    public static final String MOBILE_ACCESS_IS_UNLOCK_VIBRATION_ENABLED_KEY = "isUnlockVibrationEnabled";
    public static final String MOBILE_ACCESS_ENABLE_UNLOCK_SOUND_KEY = "enableUnlockSound";
    public static final String MOBILE_ACCESS_IS_UNLOCK_SOUND_ENABLED_KEY = "isUnlockSoundEnabled";
    public static final String MOBILE_ACCESS_ALLOW_SCANNING_KEY = "allowScanning";
    public static final String MOBILE_ACCESS_LOCK_SERVICE_CODES_DELIMITER = ",";
    public static final String MOBILE_ACCESS_LOCK_SERVICE_CODES_PREFS_KEY = "mobile_access_lock_service_codes";
    public static final String MOBILE_ACCESS_TWIST_AND_GO_ENABLED_PREFS_KEY = "mobile_access_twist_n_go_enabled";
    public static final String MOBILE_ACCESS_UNLOCK_VIBRATION_ENABLED_PREFS_KEY = "mobile_access_unlock_vibration_enabled";
    public static final String MOBILE_ACCESS_UNLOCK_SOUND_ENABLED_PREFS_KEY = "mobile_access_unlock_sound_enabled";
    public static final String MOBILE_ACCESS_START_FINISHED_KEY = "start.finished";
    public static final String MOBILE_ACCESS_ENDPOINT_REGISTER_FINISHED_KEY = "endpoint.register.finished";
    public static final String MOBILE_ACCESS_DEVICE_SCANNING_KEY = "device.scanning";

}
