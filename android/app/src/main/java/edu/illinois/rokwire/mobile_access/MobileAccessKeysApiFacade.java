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

import android.Manifest;
import android.app.Activity;
import android.app.Notification;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;
import android.widget.Toast;

import com.hid.origo.OrigoKeysApiFacade;
import com.hid.origo.OrigoKeysApiFactory;
import com.hid.origo.api.OrigoMobileKey;
import com.hid.origo.api.OrigoMobileKeys;
import com.hid.origo.api.OrigoMobileKeysApi;
import com.hid.origo.api.OrigoMobileKeysCallback;
import com.hid.origo.api.OrigoMobileKeysException;
import com.hid.origo.api.OrigoMobileKeysProgressCallback;
import com.hid.origo.api.OrigoProgressEvent;
import com.hid.origo.api.OrigoReaderConnectionController;
import com.hid.origo.api.OrigoReaderConnectionInfoType;
import com.hid.origo.api.ble.OrigoOpeningResult;
import com.hid.origo.api.ble.OrigoOpeningStatus;
import com.hid.origo.api.ble.OrigoOpeningType;
import com.hid.origo.api.ble.OrigoReader;
import com.hid.origo.api.ble.OrigoReaderConnectionCallback;
import com.hid.origo.api.ble.OrigoReaderConnectionListener;
import com.hid.origo.api.ble.OrigoScanConfiguration;
import com.hid.origo.api.hce.OrigoHceConnectionCallback;
import com.hid.origo.api.hce.OrigoHceConnectionListener;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import io.flutter.plugin.common.PluginRegistry;

public class MobileAccessKeysApiFacade implements OrigoKeysApiFacade, PluginRegistry.RequestPermissionsResultListener {

    private static final String TAG = "MobileAccessKeysApiFacade";

    private static final int REQUEST_LOCATION_PERMISSION_CODE = 10;

    private final OrigoMobileKeys mobileKeys;
    private final OrigoKeysApiFactory mobileKeysApiFactory;
    private final Activity activity;

    public MobileAccessKeysApiFacade(Activity activity, OrigoKeysApiFactory apiFactory) {
        this.activity = activity;
        this.mobileKeysApiFactory = apiFactory;
        this.mobileKeys = mobileKeysApiFactory.getMobileKeys();
    }

    //region Public APIs

    public void onApplicationStartup() {
        getMobileKeys().applicationStartup(mobileKeysStartupCallBack);
    }

    public void onActivityCreate() {
        OrigoReaderConnectionCallback readerConnectionCallback = new OrigoReaderConnectionCallback(activity.getApplicationContext());
        readerConnectionCallback.registerReceiver(readerConnectionListener);

        OrigoHceConnectionCallback hceConnectionCallback = new OrigoHceConnectionCallback(activity.getApplicationContext());
        hceConnectionCallback.registerReceiver(hceConnectionListener);
    }

    public void onActivityResume() {
        //TBD: DD - check when to start / stop scanning based on the user selection
        if (canScan()) {
            startScanning();
        }
    }

    public void onActivityPause() {
        if (canScan()) {
            stopScanning();
        }
    }

    public void setupEndpoint(String invitationCode) {
        if (!isEndpointSetUpComplete()) {
            getMobileKeys().endpointSetup(mobileKeysEndpointSetupCallBack, invitationCode);
        }
    }

    public void unregisterEndpoint() {
        if (isEndpointSetUpComplete()) {
            getMobileKeys().unregisterEndpoint(mobileKeysUnregisterEndpointCallBack);
        }
    }

    public List<HashMap<String, Object>> getKeysDetails() {
        if (!isEndpointSetUpComplete()) {
            Log.d(TAG, "getKeysDetails: Mobile Access Keys endpoint is not set up.");
            return null;
        }
        if (getMobileKeys() != null) {
            try {
                List<OrigoMobileKey> origoMobileKeys = getMobileKeys().listMobileKeys();
                if ((origoMobileKeys != null) && !origoMobileKeys.isEmpty()) {
                    SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
                    List<HashMap<String, Object>> keysJson = new ArrayList<>();
                    for (OrigoMobileKey key : origoMobileKeys) {
                        Calendar endCalendarDate = key.getEndDate();
                        HashMap<String, Object> keyJson = new HashMap<>();
                        keyJson.put("label", key.getLabel());
                        keyJson.put("card_number", key.getCardNumber());
                        keyJson.put("issuer", key.getIssuer());
                        keyJson.put("type", key.getType());
                        keyJson.put("external_id", key.getExternalId());
                        if (endCalendarDate != null) {
                            keyJson.put("expiration_date", dateFormat.format(endCalendarDate.getTime()));
                        }
                        keysJson.add(keyJson);
                    }
                    return keysJson;
                }
            } catch (OrigoMobileKeysException e) {
                Log.e(TAG, String.format("Failed to list mobile keys. Cause message: %s \nError code: %s", e.getCauseMessage(), e.getErrorCode()));
                e.printStackTrace();
            }
        }
        return null;
    }

    //endregion

    //region OrigoKeysApiFacade implementation

    @Override
    public void onStartUpComplete() {
        Log.d(TAG, "onStartUpComplete");
        if (isEndpointSetUpComplete()) {
            getMobileKeys().endpointUpdate(mobileKeysEndpointUpdateCallBack);
        }
    }

    @Override
    public void onEndpointSetUpComplete() {
        Log.d(TAG, "onEndpointSetUpComplete");
    }

    @Override
    public void endpointNotPersonalized() {
        Log.d(TAG, "endpointNotPersonalized");
    }

    @Override
    public boolean isEndpointSetUpComplete() {
        boolean isEndpointSetup = false;
        try {
            isEndpointSetup = mobileKeys.isEndpointSetupComplete();
        } catch (OrigoMobileKeysException e) {
            Log.d(TAG, "isEndpointSetUpComplete: exception: " + e.getCauseMessage() + "\n\n" + e.getMessage());
            e.printStackTrace();
        }
        return isEndpointSetup;
    }

    @Override
    public OrigoMobileKeys getMobileKeys() {
        return mobileKeysApiFactory.getMobileKeys();
    }

    @Override
    public OrigoReaderConnectionController getReaderConnectionController() {
        return mobileKeysApiFactory.getReaderConnectionController();
    }

    @Override
    public OrigoScanConfiguration getOrigoScanConfiguration() {
        return mobileKeysApiFactory.getOrigoScanConfiguration();
    }

    //endregion

    //region OrigoMobileKeysCallback implementation

    private final OrigoMobileKeysCallback mobileKeysStartupCallBack = new OrigoMobileKeysCallback() {
        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysStartupCallBack: handleMobileKeysTransactionCompleted");
            onStartUpComplete();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysStartupCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
        }
    };

    private final OrigoMobileKeysCallback mobileKeysEndpointSetupCallBack = new OrigoMobileKeysCallback() {
        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysEndpointSetupCallBack: handleMobileKeysTransactionCompleted");
            Toast.makeText(activity, "Mobile Access: Register Endpoint - succeeded", Toast.LENGTH_SHORT).show();
            onEndpointSetUpComplete();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysEndpointSetupCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
            Toast.makeText(activity, "Mobile Access: Register Endpoint - failed: " + e.getErrorCode(), Toast.LENGTH_SHORT).show();
        }
    };

    //endregion

    //region OrigoMobileKeysProgressCallback implementation

    private final OrigoMobileKeysProgressCallback mobileKeysEndpointUpdateCallBack = new OrigoMobileKeysProgressCallback() {

        @Override
        public void handleMobileKeysTransactionProgress(OrigoProgressEvent origoProgressEvent) {
            Log.d(TAG, "mobileKeysEndpointUpdateCallBack: handleMobileKeysTransactionProgress: OrigoProgressEvent: " + origoProgressEvent.progressType());

        }

        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysEndpointUpdateCallBack: handleMobileKeysTransactionCompleted");
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysEndpointUpdateCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
        }
    };

    private final OrigoMobileKeysProgressCallback mobileKeysUnregisterEndpointCallBack = new OrigoMobileKeysProgressCallback() {

        @Override
        public void handleMobileKeysTransactionProgress(OrigoProgressEvent origoProgressEvent) {
            Log.d(TAG, "mobileKeysUnregisterEndpointCallBack: handleMobileKeysTransactionProgress: OrigoProgressEvent: " + origoProgressEvent.progressType());

        }

        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysUnregisterEndpointCallBack: handleMobileKeysTransactionCompleted");
            Toast.makeText(activity, "Mobile Access: Unregister Endpoint - succeeded", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysUnregisterEndpointCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
            Toast.makeText(activity, "Mobile Access: Unregister Endpoint - failed: " + e.getErrorCode(), Toast.LENGTH_SHORT).show();
        }
    };

    //endregion

    //region OrigoReaderConnectionListener implementation

    private final OrigoReaderConnectionListener readerConnectionListener = new OrigoReaderConnectionListener() {
        @Override
        public void onReaderConnectionOpened(OrigoReader origoReader, OrigoOpeningType origoOpeningType) {
            Log.d(TAG, "readerConnectionListener: onReaderConnectionOpened: reader: " + origoReader.getName() + ", opening type: " + origoOpeningType.name());
        }

        @Override
        public void onReaderConnectionClosed(OrigoReader origoReader, OrigoOpeningResult origoOpeningResult) {
            Log.d(TAG, "readerConnectionListener: onReaderConnectionClosed");
        }

        @Override
        public void onReaderConnectionFailed(OrigoReader origoReader, OrigoOpeningType origoOpeningType, OrigoOpeningStatus origoOpeningStatus) {
            Log.d(TAG, "readerConnectionListener: onReaderConnectionFailed");
        }
    };

    //endregion

    //region OrigoHceConnectionListener implementation

    private final OrigoHceConnectionListener hceConnectionListener = new OrigoHceConnectionListener() {
        @Override
        public void onHceSessionOpened() {
            Log.d(TAG, "hceConnectionListener: onHceSessionOpened");
        }

        @Override
        public void onHceSessionClosed(int i) {
            Log.d(TAG, "hceConnectionListener: onHceSessionClosed");
        }

        @Override
        public void onHceSessionInfo(OrigoReaderConnectionInfoType origoReaderConnectionInfoType) {
            Log.d(TAG, "hceConnectionListener: onHceSessionInfo");
        }
    };

    //endregion

    //region Reader Scanning

    private boolean canScan() {
        boolean hasKeys = false;
        if (isEndpointSetUpComplete()) {
            if (getMobileKeys() != null) {
                try {
                    List<OrigoMobileKey> keys = getMobileKeys().listMobileKeys();
                    hasKeys = (keys != null) && !keys.isEmpty();
                } catch (OrigoMobileKeysException e) {
                    Log.e(TAG, "canStartScanning: listMobileKeys threw exception.");
                    e.printStackTrace();
                }
            }
        }
        return hasKeys;
    }

    private void startScanning() {
        if (hasLocationPermissions()) {
            Log.d(TAG, "Starting BLE service and enabling HCE");
            OrigoReaderConnectionController controller = OrigoMobileKeysApi.getInstance().getOrigiReaderConnectionController();
            controller.enableHce();

            Notification notification = MobileAccessUnlockNotification.create(activity);
            controller.startForegroundScanning(notification);
        } else {
            requestLocationPermission();
        }
    }

    private void stopScanning() {
        OrigoReaderConnectionController controller = OrigoMobileKeysApi.getInstance().getOrigiReaderConnectionController();
        controller.stopScanning();
    }

    //endregion

    //region Permissions

    /**
     * Request location permission, location permission is required for BLE scanning when running Marshmallow or above
     */
    private void requestLocationPermission() {
        if (!hasLocationPermissions()) {
            ActivityCompat.requestPermissions(activity, getPermissions(), REQUEST_LOCATION_PERMISSION_CODE);
        }
    }

    private boolean hasLocationPermissions() {
        boolean permissionGranted = true;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            permissionGranted &= ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_SCAN) == PackageManager.PERMISSION_GRANTED
                    && ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_ADVERTISE) == PackageManager.PERMISSION_GRANTED
                    && ContextCompat.checkSelfPermission(activity, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED;
            return permissionGranted;
        }

        permissionGranted &= ContextCompat.checkSelfPermission(activity,
                Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED || ContextCompat.checkSelfPermission(activity,
                Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            permissionGranted &= ContextCompat.checkSelfPermission(activity,
                    Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED;
        }

        return permissionGranted;
    }

    private String[] getPermissions() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            return new String[]{Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.BLUETOOTH_CONNECT};
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            return new String[]{Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION};
        } else {
            return new String[]{Manifest.permission.ACCESS_COARSE_LOCATION};
        }
    }

    @Override
    public boolean onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        if (requestCode == REQUEST_LOCATION_PERMISSION_CODE) {
            startScanning();
            return true;
        }
        return false;
    }

    //endregion
}
