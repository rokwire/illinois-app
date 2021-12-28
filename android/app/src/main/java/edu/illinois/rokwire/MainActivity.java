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

import android.Manifest;
import android.app.Activity;
import android.app.Application;
import android.content.Context;
import android.content.Intent;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.location.LocationManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.provider.Settings;
import android.util.Base64;
import android.util.Log;
import android.widget.Toast;

import androidx.annotation.NonNull;
import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;

import com.arubanetworks.meridian.Meridian;
import com.google.firebase.FirebaseApp;
import com.google.zxing.BarcodeFormat;
import com.google.zxing.MultiFormatWriter;
import com.google.zxing.WriterException;
import com.google.zxing.common.BitMatrix;
import com.journeyapps.barcodescanner.BarcodeEncoder;
import com.mapsindoors.mapssdk.MapsIndoors;

import java.io.ByteArrayOutputStream;
import java.security.SecureRandom;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;

import edu.illinois.rokwire.geofence.GeofenceMonitor;
import edu.illinois.rokwire.maps.MapActivity;
import edu.illinois.rokwire.maps.MapDirectionsActivity;
import edu.illinois.rokwire.maps.MapViewFactory;
import edu.illinois.rokwire.maps.MapPickLocationActivity;
import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity implements MethodChannel.MethodCallHandler {

    private static final String TAG = "MainActivity";

    private final int REQUEST_LOCATION_PERMISSION_CODE = 1;

    private static MethodChannel METHOD_CHANNEL;
    private static final String NATIVE_CHANNEL = "edu.illinois.rokwire/native_call";
    private static MainActivity instance = null;

    private static MethodChannel.Result pickLocationResult;

    private HashMap keys;

    private int preferredScreenOrientation;
    private Set<Integer> supportedScreenOrientations;

    private RequestLocationCallback rlCallback;

    private Toast statusToast;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        instance = this;
        initScreenOrientation();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        GeofenceMonitor.getInstance().unInit();
    }

    public static MainActivity getInstance() {
        return instance;
    }

    public App getApp() {
        Application application = getApplication();
        return (application instanceof App) ? (App) application : null;
    }

    public static void invokeFlutterMethod(String methodName, Object arguments) {
        if (METHOD_CHANNEL != null) {
            getInstance().runOnUiThread(() -> METHOD_CHANNEL.invokeMethod(methodName, arguments));
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);

        if (requestCode == REQUEST_LOCATION_PERMISSION_CODE) {
            boolean granted;
            if (grantResults.length > 1 &&
                    grantResults[0] == PackageManager.PERMISSION_GRANTED && grantResults[1] == PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "granted");
                granted = true;
            } else {
                Log.d(TAG, "not granted");
                granted = false;
            }
            if (rlCallback != null) {
                rlCallback.onResult(granted);
                rlCallback = null;
            }
        }
    }

    public HashMap getKeys() {
        return keys;
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        METHOD_CHANNEL = new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), NATIVE_CHANNEL);
        METHOD_CHANNEL.setMethodCallHandler(this);

        flutterEngine
                .getPlatformViewsController()
                .getRegistry()
                .registerViewFactory("mapview", new MapViewFactory(this, flutterEngine.getDartExecutor().getBinaryMessenger()));
    }

    private void initScreenOrientation() {
        preferredScreenOrientation = ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
        supportedScreenOrientations = new HashSet<>(Collections.singletonList(preferredScreenOrientation));
    }

    private void initWithParams(Object keys) {
        HashMap keysMap = null;
        if (keys instanceof HashMap) {
            keysMap = (HashMap) keys;
        }
        if (keysMap == null) {
            return;
        }
        this.keys = keysMap;

        // Google Maps cannot be initialized dynamically. Its api key has to be in AndroidManifest.xml file.
        // Read it from config for MapsIndoors.
        String googleMapsApiKey = Utils.Map.getValueFromPath(keysMap, "google.maps.api_key", null);

        // MapsIndoors
        String mapsIndoorsApiKey = Utils.Map.getValueFromPath(keysMap, "mapsindoors.api_key", null);
        if (!Utils.Str.isEmpty(mapsIndoorsApiKey)) {
            MapsIndoors.initialize(
                    getApplicationContext(),
                    mapsIndoorsApiKey
            );
        }
        if (!Utils.Str.isEmpty(googleMapsApiKey)) {
            MapsIndoors.setGoogleAPIKey(googleMapsApiKey);
        }

        // Meridian
        String meridianEditorToken = Utils.Map.getValueFromPath(keysMap, "meridian.app_token", null);
        Meridian.DomainRegion[] domainRegions = Meridian.DomainRegion.values();
        int domainRegionIndex = Utils.Map.getValueFromPath(keysMap, "meridian.domain_region", 0);
        Meridian.DomainRegion domainRegion = (domainRegionIndex < domainRegions.length) ? domainRegions[domainRegionIndex] : Meridian.DomainRegion.DomainRegionDefault;
        Meridian.configure(this);
        Meridian.getShared().setDomainRegion(domainRegion);
        if (!Utils.Str.isEmpty(meridianEditorToken)) {
            Meridian.getShared().setEditorToken(meridianEditorToken);
        }

        // Geofence
        GeofenceMonitor.getInstance().init();
    }

    private void launchMapsDirections(Object explore, Object options) {
        Intent intent = new Intent(this, MapDirectionsActivity.class);
        if (explore instanceof HashMap) {
            HashMap singleExplore = (HashMap) explore;
            intent.putExtra("explore", singleExplore);
        } else if (explore instanceof ArrayList) {
            ArrayList exploreList = (ArrayList) explore;
            intent.putExtra("explore", exploreList);
        }
        HashMap optionsMap = (options instanceof HashMap) ? (HashMap) options : null;
        if (optionsMap != null) {
            intent.putExtra("options", optionsMap);
        }
        startActivity(intent);
    }

    private void launchMap(Object target, Object options, Object markers) {
        HashMap targetMap = (target instanceof HashMap) ? (HashMap) target : null;
        HashMap optionsMap = (options instanceof HashMap) ? (HashMap) options : null;
        ArrayList<HashMap> markersValues = (markers instanceof  ArrayList) ? ( ArrayList<HashMap>) markers : null;
        Intent intent = new Intent(this, MapActivity.class);
        Bundle serializableExtras = new Bundle();
        serializableExtras.putSerializable("target", targetMap);
        serializableExtras.putSerializable("options", optionsMap);
        serializableExtras.putSerializable("markers", markersValues);
        intent.putExtras(serializableExtras);
        startActivity(intent);
    }

    private void launchMapsLocationPick(Object exploreParam) {
        HashMap explore = null;
        if (exploreParam instanceof HashMap) {
            explore = (HashMap) exploreParam;
        }
        Intent locationPickerIntent =  new Intent(this, MapPickLocationActivity.class);
        locationPickerIntent.putExtra("explore", explore);
        startActivityForResult(locationPickerIntent, Constants.SELECT_LOCATION_ACTIVITY_RESULT_CODE);
    }

    private void launchNotification(MethodCall methodCall) {
        String title = methodCall.argument("title");
        String body = methodCall.argument("body");
        App app = getApp();
        if (app != null) {
            app.showNotification(title, body);
        }
    }

    private void requestLocationPermission(MethodChannel.Result result) {
        Utils.AppSharedPrefs.saveBool(this, Constants.LOCATION_PERMISSIONS_REQUESTED_KEY, true);
        //check if granted
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED  ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "request permission");

            rlCallback = new RequestLocationCallback() {
                @Override
                public void onResult(boolean granted) {
                    if (granted) {
                        result.success("allowed");

                        GeofenceMonitor.getInstance().onLocationPermissionGranted();
                    } else {
                        result.success("denied");
                    }
                }
            };

            ActivityCompat.requestPermissions(MainActivity.this,
                    new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION},
                    REQUEST_LOCATION_PERMISSION_CODE);
        } else {
            Log.d(TAG, "already granted");
            GeofenceMonitor.getInstance().onLocationPermissionGranted();
            result.success("allowed");
        }
    }

    private String getLocationServicesStatus() {
        boolean locationServicesEnabled;
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            // This is new method provided in API 28
            LocationManager lm = (LocationManager) getSystemService(Context.LOCATION_SERVICE);
            locationServicesEnabled = ((lm != null) && lm.isLocationEnabled());
        } else {
            // This is Deprecated in API 28
            int mode = Settings.Secure.getInt(getContentResolver(), Settings.Secure.LOCATION_MODE,
                    Settings.Secure.LOCATION_MODE_OFF);
            locationServicesEnabled = (mode != Settings.Secure.LOCATION_MODE_OFF);
        }
        if (locationServicesEnabled) {
            if ((ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
                    ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED)) {
                return "allowed";
            } else {
                boolean locationPermissionRequested = Utils.AppSharedPrefs.getBool(this, Constants.LOCATION_PERMISSIONS_REQUESTED_KEY, false);
                return locationPermissionRequested ? "denied" : "not_determined";
            }
        } else {
            return "disabled";
        }
    }

    private List<String> handleEnabledOrientations(Object orientations) {
        List<String> resultList = new ArrayList<>();
        if (preferredScreenOrientation != ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) {
            resultList.add(getScreenOrientationToString(preferredScreenOrientation));
        }
        if (supportedScreenOrientations != null && !supportedScreenOrientations.isEmpty()) {
            for (int supportedOrientation : supportedScreenOrientations) {
                if (supportedOrientation != preferredScreenOrientation) {
                    resultList.add(getScreenOrientationToString(supportedOrientation));
                }
            }
        }
        List<String> orientationsList;
        if (orientations instanceof List) {
            orientationsList = (List<String>) orientations;
            int preferredOrientation = ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
            Set<Integer> supportedOrientations = new HashSet<>();
            for (String orientationString : orientationsList) {
                int orientation = getScreenOrientationFromString(orientationString);
                if (orientation != ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) {
                    supportedOrientations.add(orientation);
                    if (preferredOrientation == ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) {
                        preferredOrientation = orientation;
                    }
                }
            }
            if ((preferredOrientation != ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED) && (preferredScreenOrientation != preferredOrientation)) {
                preferredScreenOrientation = preferredOrientation;
            }
            if ((supportedOrientations.size() > 0) && !supportedOrientations.equals(supportedScreenOrientations)) {
                supportedScreenOrientations = supportedOrientations;
                int currentOrientation = getRequestedOrientation();
                if (!supportedScreenOrientations.contains(currentOrientation)) {
                    setRequestedOrientation(preferredScreenOrientation);
                }
            }
        }
        return resultList;
    }

    private Object handleGeofence(Object params) {
        HashMap paramsMap = (params instanceof HashMap) ? (HashMap) params : null;
        Object regions = (paramsMap != null) ? paramsMap.get("regions") : null;
        Object beacons = (paramsMap != null) ? paramsMap.get("beacons") : null;
        if (regions != null) {
            List<Map<String, Object>> geoFencesList = (regions instanceof List) ? (List<Map<String, Object>>) regions : null;
            GeofenceMonitor.getInstance().monitorRegions(geoFencesList);
            return GeofenceMonitor.getInstance().getCurrentIds();
        } else if (beacons != null) {
            HashMap beaconMap = (beacons instanceof HashMap) ? (HashMap) beacons : null;
            String regionId = Utils.Map.getValueFromPath(beaconMap, "regionId", null);
            String action = Utils.Map.getValueFromPath(beaconMap, "action", null);
            if ("start".equals(action)) {
                return GeofenceMonitor.getInstance().startRangingBeaconsInRegion(regionId);
            } else if ("stop".equals(action)) {
                return GeofenceMonitor.getInstance().stopRangingBeaconsInRegion(regionId);
            } else {
                return GeofenceMonitor.getInstance().getBeaconsInRegion(regionId);
            }
        } else {
            return null;
        }
    }

    private String getScreenOrientationToString(int orientationValue) {
        switch (orientationValue) {
            case ActivityInfo.SCREEN_ORIENTATION_PORTRAIT:
                return "portraitUp";
            case ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT:
                return "portraitDown";
            case ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE:
                return "landscapeLeft";
            case ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE:
                return "landscapeRight";
            default:
                return null;
        }
    }

    private String getDeviceId(){
        String deviceId = "";
        try
        {
            UUID uuid;
            final String androidId = Settings.Secure.getString(getContentResolver(), Settings.Secure.ANDROID_ID);
            uuid = UUID.nameUUIDFromBytes(androidId.getBytes("utf8"));
            deviceId = uuid.toString();
        }
        catch (Exception e)
        {
            Log.d(TAG, "Failed to generate uuid");
        }
        return deviceId;
    }

    private Object handleEncryptionKey(Object params) {
        String identifier = Utils.Map.getValueFromPath(params, "identifier", null);
        if (Utils.Str.isEmpty(identifier)) {
            return null;
        }
        int keySize = Utils.Map.getValueFromPath(params, "size", 0);
        if (keySize <= 0) {
            return null;
        }
        String base64KeyValue = Utils.AppSecureSharedPrefs.getString(this, identifier, null);
        byte[] encryptionKey = Utils.Base64.decode(base64KeyValue);
        if ((encryptionKey != null) && (encryptionKey.length == keySize)) {
            return base64KeyValue;
        } else {
            byte[] keyBytes = new byte[keySize];
            SecureRandom secRandom = new SecureRandom();
            secRandom.nextBytes(keyBytes);
            base64KeyValue = Utils.Base64.encode(keyBytes);
            Utils.AppSecureSharedPrefs.saveString(this, identifier, base64KeyValue);
            return base64KeyValue;
        }
    }

    private int getScreenOrientationFromString(String orientationString) {
        if (Utils.Str.isEmpty(orientationString)) {
            return ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
        }
        switch (orientationString) {
            case "portraitUp":
                return ActivityInfo.SCREEN_ORIENTATION_PORTRAIT;
            case "portraitDown":
                return ActivityInfo.SCREEN_ORIENTATION_REVERSE_PORTRAIT;
            case "landscapeLeft":
                return ActivityInfo.SCREEN_ORIENTATION_REVERSE_LANDSCAPE;
            case "landscapeRight":
                return ActivityInfo.SCREEN_ORIENTATION_LANDSCAPE;
            default:
                return ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED;
        }
    }

    private String handleBarcode(Object params) {
        String barcodeImageData = null;
        String content = Utils.Map.getValueFromPath(params, "content", null);
        String format = Utils.Map.getValueFromPath(params, "format", null);
        int width = Utils.Map.getValueFromPath(params, "width", 0);
        int height = Utils.Map.getValueFromPath(params, "height", 0);
        BarcodeFormat barcodeFormat = null;
        if (!Utils.Str.isEmpty(format)) {
            switch (format) {
                case "aztec":
                    barcodeFormat = BarcodeFormat.AZTEC;
                    break;
                case "codabar":
                    barcodeFormat = BarcodeFormat.CODABAR;
                    break;
                case "code39":
                    barcodeFormat = BarcodeFormat.CODE_39;
                    break;
                case "code93":
                    barcodeFormat = BarcodeFormat.CODE_93;
                    break;
                case "code128":
                    barcodeFormat = BarcodeFormat.CODE_128;
                    break;
                case "dataMatrix":
                    barcodeFormat = BarcodeFormat.DATA_MATRIX;
                    break;
                case "ean8":
                    barcodeFormat = BarcodeFormat.EAN_8;
                    break;
                case "ean13":
                    barcodeFormat = BarcodeFormat.EAN_13;
                    break;
                case "itf":
                    barcodeFormat = BarcodeFormat.ITF;
                    break;
                case "maxiCode":
                    barcodeFormat = BarcodeFormat.MAXICODE;
                    break;
                case "pdf417":
                    barcodeFormat = BarcodeFormat.PDF_417;
                    break;
                case "qrCode":
                    barcodeFormat = BarcodeFormat.QR_CODE;
                    break;
                case "rss14":
                    barcodeFormat = BarcodeFormat.RSS_14;
                    break;
                case "rssExpanded":
                    barcodeFormat = BarcodeFormat.RSS_EXPANDED;
                    break;
                case "upca":
                    barcodeFormat = BarcodeFormat.UPC_A;
                    break;
                case "upce":
                    barcodeFormat = BarcodeFormat.UPC_E;
                    break;
                case "upceanExtension":
                    barcodeFormat = BarcodeFormat.UPC_EAN_EXTENSION;
                    break;
                default:
                    break;
            }
        }

        if (barcodeFormat != null) {
            MultiFormatWriter multiFormatWriter = new MultiFormatWriter();
            Bitmap bitmap = null;
            try {
                BitMatrix bitMatrix = multiFormatWriter.encode(content, barcodeFormat, width, height);
                BarcodeEncoder barcodeEncoder = new BarcodeEncoder();
                bitmap = barcodeEncoder.createBitmap(bitMatrix);
            } catch (WriterException e) {
                Log.e(TAG, "Failed to encode image:");
                e.printStackTrace();
            }
            if (bitmap != null) {
                ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
                bitmap.compress(Bitmap.CompressFormat.PNG, 100, byteArrayOutputStream);
                byte[] byteArray = byteArrayOutputStream.toByteArray();
                if (byteArray != null) {
                    barcodeImageData = Base64.encodeToString(byteArray, Base64.NO_WRAP);
                }
            }
        }
        return barcodeImageData;
    }

    private boolean handleLaunchApp(Object params) {
        String deepLink = Utils.Map.getValueFromPath(params, "deep_link", null);
        Uri deepLinkUri = !Utils.Str.isEmpty(deepLink) ? Uri.parse(deepLink) : null;
        if (deepLinkUri == null) {
            Log.d(TAG, "Invalid deep link: " + deepLink);
            return false;
        }
        Intent appIntent = new Intent(Intent.ACTION_VIEW, deepLinkUri);
        boolean activityExists = appIntent.resolveActivityInfo(getPackageManager(), 0) != null;
        if (activityExists) {
            startActivity(appIntent);
            return true;
        } else {
            return false;
        }
    }

    private boolean handleLaunchAppSettings(Object params) {
        Uri settingsUri = Uri.fromParts("package", BuildConfig.APPLICATION_ID, null);
        Intent settingsIntent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, settingsUri);
        settingsIntent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        boolean activityExists = settingsIntent.resolveActivityInfo(getPackageManager(), 0) != null;
        if (activityExists) {
            startActivity(settingsIntent);
            return true;
        } else {
            return false;
        }
    }

    private void handleSetLaunchScreenStatus(Object params) {
        String statusText = Utils.Map.getValueFromPath(params, "status", null);

        if (statusToast != null) {
            statusToast.cancel();
            statusToast = null;
        }
        if (statusText != null) {
            statusToast = Toast.makeText(this, statusText, Toast.LENGTH_SHORT);
            statusToast.show();
        }
    }

    @Override
    protected void onActivityResult(int requestCode, int resultCode, Intent data) {
        if (requestCode == Constants.SELECT_LOCATION_ACTIVITY_RESULT_CODE) {
            if (resultCode == Activity.RESULT_OK) {
                pickLocationResult.success(data != null ? data.getStringExtra("location") : null);
            } else {
                pickLocationResult.success(null);
            }
        }

        super.onActivityResult(requestCode, resultCode, data);
    }

    /**
     * Overrides {@link io.flutter.plugin.common.MethodChannel.MethodCallHandler} onMethodCall()
     */
    @Override
    public void onMethodCall(MethodCall methodCall, @NonNull MethodChannel.Result result) {
        String method = methodCall.method;
        try {
            switch (method) {
                case Constants.APP_INIT_KEY:
                    Object keysObject = methodCall.argument("keys");
                    initWithParams(keysObject);
                    result.success(true);
                    break;
                case Constants.MAP_DIRECTIONS_KEY:
                    Object explore = methodCall.argument("explore");
                    Object optionsObj = methodCall.argument("options");
                    launchMapsDirections(explore, optionsObj);
                    result.success(true);
                    break;
                case Constants.MAP_PICK_LOCATION_KEY:
                    pickLocationResult = result;
                    launchMapsLocationPick(methodCall.argument("explore"));
                    // Result is called on latter step
                    break;
                case Constants.MAP_KEY:
                    Object target = methodCall.argument("target");
                    Object options = methodCall.argument("options");
                    Object markers = methodCall.argument("markers");
                    launchMap(target, options,markers);
                    result.success(true);
                    break;
                case Constants.SHOW_NOTIFICATION_KEY:
                    launchNotification(methodCall);
                    result.success(true);
                    break;
                case Constants.APP_DISMISS_SAFARI_VC_KEY:
                case Constants.APP_DISMISS_LAUNCH_SCREEN_KEY:
                case Constants.APP_SET_LAUNCH_SCREEN_STATUS_KEY:
                    handleSetLaunchScreenStatus(methodCall.arguments);
                    result.success(true);
                    break;
                case Constants.APP_ADD_CARD_TO_WALLET_KEY:
                    result.success(false);
                    break;
                case Constants.APP_ENABLED_ORIENTATIONS_KEY:
                    Object orientations = methodCall.argument("orientations");
                    List<String> orientationsList = handleEnabledOrientations(orientations);
                    result.success(orientationsList);
                    break;
                case Constants.APP_LOCATION_SERVICES_PERMISSION:
                    String locationServicesMethod = Utils.Map.getValueFromPath(methodCall.arguments, "method", null);
                    if ("query".equals(locationServicesMethod)) {
                        String locationServicesStatus = getLocationServicesStatus();
                        result.success(locationServicesStatus);
                    } else if ("request".equals(locationServicesMethod)) {
                        requestLocationPermission(result);
                    }
                    break;
                case Constants.APP_TRACKING_AUTHORIZATION:
                    result.success("allowed"); // tracking is allowed in Android by default
                    break;
                case Constants.FIREBASE_INFO:
                    String projectId = FirebaseApp.getInstance().getOptions().getProjectId();
                    result.success(projectId);
                    break;
                case Constants.GEOFENCE_KEY:
                    Object resultParams = handleGeofence(methodCall.arguments);
                    result.success(resultParams);
                    break;
                case Constants.DEVICE_ID_KEY:
                    String deviceId = getDeviceId();
                    result.success(deviceId);
                    break;
                case Constants.ENCRYPTION_KEY_KEY:
                    Object encryptionKey = handleEncryptionKey(methodCall.arguments);
                    result.success(encryptionKey);
                    break;
                case Constants.BARCODE_KEY:
                    String barcodeImageData = handleBarcode(methodCall.arguments);
                    result.success(barcodeImageData);
                    break;
                case Constants.LAUNCH_APP:
                    boolean appLaunched = handleLaunchApp(methodCall.arguments);
                    result.success(appLaunched);
                    break;
                case Constants.LAUNCH_APP_SETTINGS:
                    boolean settingsLaunched = handleLaunchAppSettings(methodCall.arguments);
                    result.success(settingsLaunched);
                    break;
                default:
                    result.notImplemented();
                    break;

            }
        } catch (IllegalStateException exception) {
            String errorMsg = String.format("Ignoring exception '%s'. See https://github.com/flutter/flutter/issues/29092 for details.", exception.toString());
            Log.e(TAG, errorMsg);
            exception.printStackTrace();
        }
    }

    // RequestLocationCallback

    public static class RequestLocationCallback {
        public void onResult(boolean granted) {}
    }
}
