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
import android.util.Log;

import com.hid.origo.api.ble.OrigoRssiSensitivity;

import java.util.HashMap;
import java.util.List;

import androidx.annotation.NonNull;
import edu.illinois.rokwire.Constants;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MobileAccessPlugin implements MethodChannel.MethodCallHandler, FlutterPlugin {

    private static final String TAG = "MobileAccessPlugin";

    private static MethodChannel methodChannel;

    private final MobileAccessKeysApiFacade apiFacade;

    public MobileAccessPlugin(Activity activity) {
        MobileAccessKeysApiFactory keysApiFactory = new MobileAccessKeysApiFactory(activity.getApplicationContext());
        this.apiFacade = new MobileAccessKeysApiFacade(activity, keysApiFactory);
    }

    //region Activity APIs

    public void onActivityCreate() {
        apiFacade.onActivityCreate();
    }

    public void onActivityStart() {
        apiFacade.onApplicationStartup();
    }

    public void onActivityResume() {
        apiFacade.onActivityResume();
    }

    public void onActivityPause() {
        apiFacade.onActivityPause();
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
                    boolean success = handleMobileAccessSetRssiSensitivity(call.arguments);
                    result.success(success);
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

    public static void invokeEndpointSetupFinishedMethod(boolean result) {
        invokeFlutterMethod("endpoint.register.finished", result);
    }

    private static void invokeFlutterMethod(String methodName, Object arguments) {
        if ((methodChannel != null) && (methodName != null)) {
            methodChannel.invokeMethod(methodName, arguments);
        }
    }

    //endregion
}
