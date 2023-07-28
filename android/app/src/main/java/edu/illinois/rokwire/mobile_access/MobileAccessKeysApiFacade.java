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
import android.content.Context;
import android.content.pm.PackageManager;
import android.media.AudioManager;
import android.os.Build;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.util.Log;
import android.widget.Toast;

import com.assaabloy.mobilekeys.api.ble.util.UuidPair;
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
import com.hid.origo.api.ble.OrigoOpeningTrigger;
import com.hid.origo.api.ble.OrigoOpeningTriggerMediator;
import com.hid.origo.api.ble.OrigoOpeningType;
import com.hid.origo.api.ble.OrigoReader;
import com.hid.origo.api.ble.OrigoReaderConnectionCallback;
import com.hid.origo.api.ble.OrigoReaderConnectionListener;
import com.hid.origo.api.ble.OrigoRssiSensitivity;
import com.hid.origo.api.ble.OrigoScanConfiguration;
import com.hid.origo.api.ble.OrigoTwistAndGoOpeningTrigger;
import com.hid.origo.api.hce.OrigoHceConnectionCallback;
import com.hid.origo.api.hce.OrigoHceConnectionListener;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.rokwire_plugin.Utils;
import io.flutter.plugin.common.PluginRegistry;

public class MobileAccessKeysApiFacade implements OrigoKeysApiFacade, PluginRegistry.RequestPermissionsResultListener {

    private static final String TAG = "MobileAccessKeysApiFacade";

    private static final int REQUEST_LOCATION_PERMISSION_CODE = 10;

    private final OrigoMobileKeys mobileKeys;
    private final OrigoKeysApiFactory mobileKeysApiFactory;
    private OrigoReaderConnectionCallback bleReaderConnectionCallback;
    private OrigoHceConnectionCallback hceReaderConnectionCallback;
    private final Activity activity;
    private AudioManager audioManager;

    private boolean isAllowedToScan = false;
    private boolean isScanning = false;
    private boolean isStarted = false;

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
        bleReaderConnectionCallback = new OrigoReaderConnectionCallback(activity.getApplicationContext());
        bleReaderConnectionCallback.registerReceiver(bleReaderConnectionListener);

        hceReaderConnectionCallback = new OrigoHceConnectionCallback(activity.getApplicationContext());
        hceReaderConnectionCallback.registerReceiver(hceReaderConnectionListener);

        audioManager = (AudioManager)activity.getSystemService(Context.AUDIO_SERVICE);
    }

    public void onActivityDestroy() {
        // Manually stop scanning because native part does not receive method calls after flutter app being detached.
        stopScanning();
        if (bleReaderConnectionCallback != null) {
            bleReaderConnectionCallback.unregisterReceiver();
            bleReaderConnectionCallback = null;
        }
        if (hceReaderConnectionCallback != null) {
            hceReaderConnectionCallback.unregisterReceiver();
            hceReaderConnectionCallback = null;
        }
    }

    public boolean setupEndpoint(String invitationCode) {
        if (!isEndpointSetUpComplete()) {
            getMobileKeys().endpointSetup(mobileKeysEndpointSetupCallBack, invitationCode);
            return true;
        } else {
            return false;
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

    public boolean isStarted() {
        return isStarted;
    }

    public boolean changeRssiSensitivity(OrigoRssiSensitivity rssiSensitivity) {
        if (getOrigoScanConfiguration() != null) {
            getOrigoScanConfiguration().setRssiSensitivity(rssiSensitivity);
            return true;
        } else {
            return false;
        }
    }

    public boolean changeLockServiceCodes(int[] lockServiceCodes) {
        if ((lockServiceCodes == null) || (lockServiceCodes.length == 0)) {
            Log.d(TAG, "changeLockServiceCodes: missing lock service codes");
            return false;
        }
        if (getOrigoScanConfiguration() == null) {
            Log.d(TAG, "changeLockServiceCodes: scan configuration is null");
            return false;
        }
        getOrigoScanConfiguration().setLockServiceCodes(lockServiceCodes);
        return true;
    }

    public int[] getLockServiceCodes() {
        if (getOrigoScanConfiguration() == null) {
            Log.d(TAG, "changeLockServiceCodes: scan configuration is null");
            return null;
        }
        Map<Integer, UuidPair> lockServiceCodesUuid = getOrigoScanConfiguration().lockServiceCodeUuids();
        if (lockServiceCodesUuid != null) {
            Integer[] lockServiceCodes = new Integer[lockServiceCodesUuid.size()];
            lockServiceCodes = lockServiceCodesUuid.keySet().toArray(lockServiceCodes);
            int[] primitiveCodes = new int[lockServiceCodes.length];
            for (int i = 0; i < lockServiceCodes.length; i++) {
                primitiveCodes[i] = lockServiceCodes[i];
            }
            return primitiveCodes;
        } else {
            Log.d(TAG, "changeLockServiceCodes: missing lockServiceCodeUuids");
            return null;
        }
    }

    public boolean enableTwistAndGoOpening(boolean enable) {
        if (getOrigoScanConfiguration() == null) {
            Log.d(TAG, "enableTwistAndGoOpening: OrigoScanConfiguration is null");
            return false;
        }
        OrigoOpeningTriggerMediator rootOpeningTrigger = getOrigoScanConfiguration().getRootOpeningTrigger();
        if (rootOpeningTrigger == null) {
            Log.d(TAG, "enableTwistAndGoOpening: rootOpeningTrigger is null");
            return false;
        }
        if (enable) {
            rootOpeningTrigger.add(new OrigoTwistAndGoOpeningTrigger(activity.getApplicationContext()));
            return true;
        } else {
            List<OrigoOpeningTrigger> openingTriggers = rootOpeningTrigger.getOpeningTriggers();
            if ((openingTriggers != null)) {
                OrigoOpeningTrigger triggerToRemove = null;
                for (OrigoOpeningTrigger trigger : openingTriggers) {
                    if (trigger instanceof OrigoTwistAndGoOpeningTrigger) {
                        triggerToRemove = trigger;
                        break;
                    }
                }
                if (triggerToRemove != null) {
                    getOrigoScanConfiguration().getRootOpeningTrigger().remove(triggerToRemove);
                    return true;
                } else {
                    Log.d(TAG, "enableTwistAndGoOpening: There is no TwistAndGo trigger");
                }
            } else {
                Log.d(TAG, "enableTwistAndGoOpening: There are no opening triggers");
            }
        }
        return false;
    }

    public boolean isTwistAndGoOpeningEnabled() {
        if (getOrigoScanConfiguration() == null) {
            Log.d(TAG, "isTwistAndGoOpeningEnabled: OrigoScanConfiguration is null");
            return false;
        }
        OrigoOpeningTriggerMediator rootOpeningTrigger = getOrigoScanConfiguration().getRootOpeningTrigger();
        if (rootOpeningTrigger == null) {
            Log.d(TAG, "isTwistAndGoOpeningEnabled: rootOpeningTrigger is null");
            return false;
        }
        List<OrigoOpeningTrigger> openingTriggers = rootOpeningTrigger.getOpeningTriggers();
        if ((openingTriggers != null)) {
            for (OrigoOpeningTrigger trigger : openingTriggers) {
                if (trigger instanceof OrigoTwistAndGoOpeningTrigger) {
                    return true;
                }
            }
        } else {
            Log.d(TAG, "isTwistAndGoOpeningEnabled: There are no opening triggers");
        }
        return false;
    }

    public boolean isUnlockVibrationEnabled() {
        return Utils.AppSharedPrefs.getBool(activity.getApplicationContext(), Constants.MOBILE_ACCESS_UNLOCK_VIBRATION_ENABLED_PREFS_KEY, false);
    }

    public boolean enableUnlockVibration(boolean enabled) {
        Utils.AppSharedPrefs.saveBool(activity.getApplicationContext(), Constants.MOBILE_ACCESS_UNLOCK_VIBRATION_ENABLED_PREFS_KEY, enabled);
        if (enabled) {
            vibrateDevice();
        }
        return true;
    }

    public boolean isUnlockSoundEnabled() {
        return Utils.AppSharedPrefs.getBool(activity.getApplicationContext(), Constants.MOBILE_ACCESS_UNLOCK_SOUND_ENABLED_PREFS_KEY, false);
    }

    public boolean enableUnlockSound(boolean enabled) {
        Utils.AppSharedPrefs.saveBool(activity.getApplicationContext(), Constants.MOBILE_ACCESS_UNLOCK_SOUND_ENABLED_PREFS_KEY, enabled);
        if (enabled) {
            playSound();
        }
        return true;
    }

    public void allowScanning(boolean allow) {
        this.isAllowedToScan = allow;
        if (canScan()) {
            startScanning();
        } else {
            stopScanning();
        }
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
            isStarted = true;
            MobileAccessPlugin.invokeStartFinishedMethod(true);
            onStartUpComplete();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysStartupCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
            isStarted = false;
            MobileAccessPlugin.invokeStartFinishedMethod(false);
        }
    };

    private final OrigoMobileKeysCallback mobileKeysEndpointSetupCallBack = new OrigoMobileKeysCallback() {
        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysEndpointSetupCallBack: handleMobileKeysTransactionCompleted");
            MobileAccessPlugin.invokeEndpointSetupFinishedMethod(true);
            onEndpointSetUpComplete();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysEndpointSetupCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
            MobileAccessPlugin.invokeEndpointSetupFinishedMethod(false);
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

    private final OrigoReaderConnectionListener bleReaderConnectionListener = new OrigoReaderConnectionListener() {
        @Override
        public void onReaderConnectionOpened(OrigoReader origoReader, OrigoOpeningType origoOpeningType) {
            Log.d(TAG, "bleReaderConnectionListener: onReaderConnectionOpened: reader: " + origoReader.getName() + ", opening type: " + origoOpeningType.name());
            if (isUnlockVibrationEnabled()) {
                vibrateDevice();
            }
            if (isUnlockSoundEnabled()) {
                playSound();
            }
        }

        @Override
        public void onReaderConnectionClosed(OrigoReader origoReader, OrigoOpeningResult origoOpeningResult) {
            Log.d(TAG, "bleReaderConnectionListener: onReaderConnectionClosed");
        }

        @Override
        public void onReaderConnectionFailed(OrigoReader origoReader, OrigoOpeningType origoOpeningType, OrigoOpeningStatus origoOpeningStatus) {
            Log.d(TAG, "bleReaderConnectionListener: onReaderConnectionFailed");
        }
    };

    //endregion

    //region OrigoHceConnectionListener implementation

    private final OrigoHceConnectionListener hceReaderConnectionListener = new OrigoHceConnectionListener() {
        @Override
        public void onHceSessionOpened() {
            Log.d(TAG, "hceReaderConnectionListener: onHceSessionOpened");
            if (isUnlockVibrationEnabled()) {
                vibrateDevice();
            }
            if (isUnlockSoundEnabled()) {
                playSound();
            }
        }

        @Override
        public void onHceSessionClosed(int i) {
            Log.d(TAG, "hceReaderConnectionListener: onHceSessionClosed");
        }

        @Override
        public void onHceSessionInfo(OrigoReaderConnectionInfoType origoReaderConnectionInfoType) {
            Log.d(TAG, "hceReaderConnectionListener: onHceSessionInfo");
        }
    };

    //endregion

    //region Reader Scanning

    private boolean canScan() {
        boolean canScan = false;
        if (isAllowedToScan && isEndpointSetUpComplete()) {
            if (isEndpointSetUpComplete()) {
                if (getMobileKeys() != null) {
                    try {
                        List<OrigoMobileKey> keys = getMobileKeys().listMobileKeys();
                        canScan = (keys != null) && !keys.isEmpty();
                    } catch (OrigoMobileKeysException e) {
                        Log.e(TAG, "canStartScanning: listMobileKeys threw exception.");
                        e.printStackTrace();
                    }
                }
            }
        }
        return canScan;
    }

    private void startScanning() {
        if (!isScanning) {
            if (hasLocationPermissions()) {
                Log.d(TAG, "Native: startScanning");
                OrigoReaderConnectionController controller = OrigoMobileKeysApi.getInstance().getOrigiReaderConnectionController();
                controller.enableHce();

                Notification notification = MobileAccessUnlockNotification.create(activity);
                controller.startForegroundScanning(notification);
                onScanStateChanged(true);
            } else {
                requestLocationPermission();
            }
        }
    }

    private void stopScanning() {
        if (isScanning) {
            Log.d(TAG, "Native: stopScanning");
            OrigoReaderConnectionController controller = OrigoMobileKeysApi.getInstance().getOrigiReaderConnectionController();
            controller.disableHce();
            controller.stopScanning();
            onScanStateChanged(false);
        }
    }

    private void onScanStateChanged(boolean scanning) {
        if (isScanning != scanning) {
            isScanning = scanning;
            MobileAccessPlugin.invokeEndpointDeviceScanning(isScanning);
        }
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
            if (canScan()) {
                startScanning();
            }
            return true;
        }
        return false;
    }

    //endregion

    //region Device Specific

    private void vibrateDevice() {
        final long durationInMilliSeconds = 500;
        Vibrator vibrator = (Vibrator) activity.getSystemService(Context.VIBRATOR_SERVICE);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            vibrator.vibrate(VibrationEffect.createOneShot(durationInMilliSeconds, VibrationEffect.DEFAULT_AMPLITUDE));
        } else {
            vibrator.vibrate(durationInMilliSeconds);
        }
    }

    private void playSound() {
        audioManager.playSoundEffect(AudioManager.FX_KEY_CLICK, 2.0f);
    }

    //endregion
}
