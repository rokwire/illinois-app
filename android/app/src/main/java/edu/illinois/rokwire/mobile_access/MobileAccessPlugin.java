/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

package edu.illinois.rokwire.mobile_access;

import android.app.Activity;
import android.content.Context;
import android.util.Log;

import com.hid.origo.api.ble.OrigoRssiSensitivity;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Objects;

import androidx.annotation.NonNull;
import edu.illinois.rokwire.BuildConfig;
import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.rokwire_plugin.Utils;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MobileAccessPlugin implements MethodChannel.MethodCallHandler, FlutterPlugin {

    //region Member fields

    private static final String TAG = "MobileAccessPlugin";

    private static MethodChannel methodChannel;

    private final MobileAccessKeysApiFacade apiFacade;
    private final Context appContext;

    //endregion

    //region Initialization

    public MobileAccessPlugin(Activity activity) {
        this.appContext = activity.getApplicationContext();
        Integer[] lockServiceCodes = getStoredLockServiceCodes();
        boolean twistAndGoEnabled = isTwistAndGoEnabled();
        MobileAccessKeysApiFactory keysApiFactory = new MobileAccessKeysApiFactory(appContext, lockServiceCodes, twistAndGoEnabled);
        this.apiFacade = new MobileAccessKeysApiFacade(activity, keysApiFactory);
    }

    //endregion

    //region Activity APIs

    public void onActivityCreate() {
        apiFacade.onActivityCreate();
    }

    public void onActivityStart() {
        apiFacade.onApplicationStartup();
    }

    public void onActivityDestroy() {
        apiFacade.onActivityDestroy();
    }

    //endregion

    //region Method Handler

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String method = call.method;
        try {
            switch (method) {
                case Constants.MOBILE_ACCESS_START_KEY:
                    result.success(true);
                    if (apiFacade.isStarted()) {
                        MobileAccessPlugin.invokeStartFinishedMethod(true);
                    }
                    break;
                case Constants.MOBILE_ACCESS_AVAILABLE_KEYS_KEY:
                    List<HashMap<String, Object>> keys = handleMobileAccessKeys();
                    result.success(keys);
                    break;
                case Constants.MOBILE_ACCESS_REGISTER_ENDPOINT_KEY:
                    boolean endpointSetupInitiated = handleMobileAccessRegisterEndpoint(call.arguments);
                    result.success(endpointSetupInitiated);
                    break;
                case Constants.MOBILE_ACCESS_UNREGISTER_ENDPOINT_KEY:
                    handleMobileAccessUnregisterEndpoint();
                    result.success(true);
                    break;
                case Constants.MOBILE_ACCESS_IS_ENDPOINT_REGISTERED_KEY:
                    boolean isRegistered = handleMobileAccessIsEndpointRegistered();
                    result.success(isRegistered);
                    break;
                case Constants.MOBILE_ACCESS_SET_RSSI_SENSITIVITY_KEY:
                    boolean rssiChanged = handleMobileAccessSetRssiSensitivity(call.arguments);
                    result.success(rssiChanged);
                    break;
                case Constants.MOBILE_ACCESS_SET_LOCK_SERVICE_CODES_KEY:
                    boolean lockCodesChanged = handleSetLockServiceCodes(call.arguments);
                    result.success(lockCodesChanged);
                    break;
                case Constants.MOBILE_ACCESS_GET_LOCK_SERVICE_CODES_KEY:
                    int[] lockServiceCodes = handleGetLockServiceCodes();
                    result.success(lockServiceCodes);
                    break;
                case Constants.MOBILE_ACCESS_ENABLE_TWIST_AND_GO_KEY:
                    boolean twistAndGoChanged = handleEnableTwistAndGo(call.arguments);
                    result.success(twistAndGoChanged);
                    break;
                case Constants.MOBILE_ACCESS_IS_TWIST_AND_GO_ENABLED_KEY:
                    boolean twistAndGoEnabled = handleIsTwistAndGoEnabled();
                    result.success(twistAndGoEnabled);
                    break;
                case Constants.MOBILE_ACCESS_ENABLE_UNLOCK_VIBRATION_KEY:
                    boolean unlockVibrationChanged = handleEnableUnlockVibration(call.arguments);
                    result.success(unlockVibrationChanged);
                    break;
                case Constants.MOBILE_ACCESS_IS_UNLOCK_VIBRATION_ENABLED_KEY:
                    boolean isUnlockVibrationEnabled = handleIsUnlockVibrationEnabled();
                    result.success(isUnlockVibrationEnabled);
                    break;
                case Constants.MOBILE_ACCESS_ENABLE_UNLOCK_SOUND_KEY:
                    boolean unlockSoundChanged = handleEnableUnlockSound(call.arguments);
                    result.success(unlockSoundChanged);
                    break;
                case Constants.MOBILE_ACCESS_IS_UNLOCK_SOUND_ENABLED_KEY:
                    boolean isUnlockSoundEnabled = handleIsUnlockSoundEnabled();
                    result.success(isUnlockSoundEnabled);
                    break;
                case Constants.MOBILE_ACCESS_ALLOW_SCANNING_KEY:
                    handleAllowScanning(call.arguments);
                    result.success(true);
                    break;
                default:
                    result.notImplemented();
                    break;

            }
        } catch (IllegalStateException exception) {
            String errorMsg = String.format("Ignoring exception '%s'. See https://github.com/flutter/flutter/issues/29092 for details.", exception);
            Log.e(TAG, errorMsg);
            exception.printStackTrace();
        }
    }

    //endregion

    //region Native methods implementation

    private List<HashMap<String, Object>> handleMobileAccessKeys() {
        return apiFacade.getKeysDetails();
    }

    private boolean handleMobileAccessRegisterEndpoint(Object params) {
        String invitationCode = null;
        if (params instanceof String) {
            invitationCode = (String) params;
        }
        return apiFacade.setupEndpoint(invitationCode);
    }

    private void handleMobileAccessUnregisterEndpoint() {
        apiFacade.unregisterEndpoint();
    }

    private boolean handleMobileAccessIsEndpointRegistered() {
        return apiFacade.isEndpointSetUpComplete();
    }

    private boolean handleMobileAccessSetRssiSensitivity(Object arguments) {
        OrigoRssiSensitivity origoRssiSensitivity = null;
        if (arguments instanceof String) {
            String sensitivityValue = (String) arguments;
            switch (sensitivityValue) {
                case "high":
                    origoRssiSensitivity = OrigoRssiSensitivity.HIGH;
                    break;
                case "normal":
                    origoRssiSensitivity = OrigoRssiSensitivity.NORMAL;
                    break;
                case "low":
                    origoRssiSensitivity = OrigoRssiSensitivity.LOW;
                    break;
            }
        }
        if (origoRssiSensitivity != null) {
            return apiFacade.changeRssiSensitivity(origoRssiSensitivity);
        } else {
            return false;
        }
    }

    private boolean handleSetLockServiceCodes(Object arguments) {
        int[] lockServiceCodes = null;
        if (arguments instanceof ArrayList<?>) {
            ArrayList<?> lockCodesValue = (ArrayList<?>) arguments;
            for (int i = 0; i < lockCodesValue.size(); i++) {
                Object codeObject = lockCodesValue.get(i);
                if (i == 0) {
                    if (codeObject instanceof Integer) {
                        lockServiceCodes = new int[lockCodesValue.size()];
                        lockServiceCodes[i] = (Integer) codeObject;
                    } else {
                        break;
                    }
                } else {
                    // We checked that this list is from integers so the cast is safe
                    lockServiceCodes[i] = (Integer) codeObject;
                }
            }
        }
        if (lockServiceCodes != null) {
            boolean codesChanged = apiFacade.changeLockServiceCodes(lockServiceCodes);
            if (codesChanged) {
                saveLockServiceCodes(lockServiceCodes);
            }
            return codesChanged;
        } else {
            Log.d(TAG, "handleSetLockServiceCodes: lock service codes arguments are missing or they are not integers");
            return false;
        }
    }

    private int[] handleGetLockServiceCodes() {
        return apiFacade.getLockServiceCodes();
    }

    private boolean handleEnableTwistAndGo(Object arguments) {
        boolean enable = false;
        if (arguments instanceof Boolean) {
            enable = (Boolean) arguments;
        }
        boolean successfullyChanged = apiFacade.enableTwistAndGoOpening(enable);
        if (successfullyChanged) {
            saveTwistAndGoEnabled(enable);
        }
        return successfullyChanged;
    }

    private boolean handleIsTwistAndGoEnabled() {
        return apiFacade.isTwistAndGoOpeningEnabled();
    }

    private boolean handleEnableUnlockVibration(Object arguments) {
        boolean enable = false;
        if (arguments instanceof Boolean) {
            enable = (Boolean) arguments;
        }
        return apiFacade.enableUnlockVibration(enable);
    }

    private boolean handleIsUnlockVibrationEnabled() {
        return apiFacade.isUnlockVibrationEnabled();
    }

    private boolean handleEnableUnlockSound(Object arguments) {
        boolean enable = false;
        if (arguments instanceof Boolean) {
            enable = (Boolean) arguments;
        }
        return apiFacade.enableUnlockSound(enable);
    }

    private boolean handleIsUnlockSoundEnabled() {
        return apiFacade.isUnlockSoundEnabled();
    }

    private void handleAllowScanning(Object arguments) {
        boolean allow = false;
        if (arguments instanceof Boolean) {
            allow = (Boolean) arguments;
        }
        apiFacade.allowScanning(allow);
    }

    //endregion

    //region SharedPrefs helpers

    private Integer[] getStoredLockServiceCodes() {
        String storedLockServiceCodesValue = Utils.AppSecureSharedPrefs.getString(appContext, Constants.MOBILE_ACCESS_LOCK_SERVICE_CODES_PREFS_KEY, null);
        if (!Utils.Str.isEmpty(storedLockServiceCodesValue)) {
            String[] lockCodesStringArr = storedLockServiceCodesValue.split(Constants.MOBILE_ACCESS_LOCK_SERVICE_CODES_DELIMITER);
            Integer[] lockCodes = new Integer[lockCodesStringArr.length];
            for (int i = 0; i < lockCodesStringArr.length; i++) {
                lockCodes[i] = Integer.parseInt(lockCodesStringArr[i]);
            }
            return lockCodes;
        }
        return new Integer[]{BuildConfig.ORIGO_LOCK_SERVICE_CODE}; // Default Lock Service Code
    }

    private void saveLockServiceCodes(int[] lockServiceCodes) {
        String formattedLockServiceCodes = null;
        if ((lockServiceCodes != null) && (lockServiceCodes.length > 0)) {
            StringBuilder sb = new StringBuilder();
            for (Integer code : lockServiceCodes) {
                sb.append(code).append(Constants.MOBILE_ACCESS_LOCK_SERVICE_CODES_DELIMITER);
            }
            formattedLockServiceCodes = sb.deleteCharAt(sb.length() - Constants.MOBILE_ACCESS_LOCK_SERVICE_CODES_DELIMITER.length()).toString(); // remove the last delimiter
        }
        Utils.AppSecureSharedPrefs.saveString(appContext, Constants.MOBILE_ACCESS_LOCK_SERVICE_CODES_PREFS_KEY, formattedLockServiceCodes);
    }

    private boolean isTwistAndGoEnabled() {
        return Utils.AppSharedPrefs.getBool(appContext, Constants.MOBILE_ACCESS_TWIST_AND_GO_ENABLED_PREFS_KEY, false);
    }

    private void saveTwistAndGoEnabled(boolean enabled) {
        Utils.AppSharedPrefs.saveBool(appContext, Constants.MOBILE_ACCESS_TWIST_AND_GO_ENABLED_PREFS_KEY, enabled);
    }

    //endregion

    //region Flutter Plugin implementation

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), "edu.illinois.rokwire/mobile_access");
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
    }

    public static void invokeStartFinishedMethod(boolean result) {
        invokeFlutterMethod(Constants.MOBILE_ACCESS_START_FINISHED_KEY, result);
    }

    public static void invokeEndpointSetupFinishedMethod(boolean result) {
        invokeFlutterMethod(Constants.MOBILE_ACCESS_ENDPOINT_REGISTER_FINISHED_KEY, result);
    }

    public static void invokeEndpointDeviceScanning(boolean scanning) {
        invokeFlutterMethod(Constants.MOBILE_ACCESS_DEVICE_SCANNING_KEY, scanning);
    }

    private static void invokeFlutterMethod(String methodName, Object arguments) {
        if ((methodChannel != null) && (methodName != null)) {
            methodChannel.invokeMethod(methodName, arguments);
        }
    }

    //endregion
}
