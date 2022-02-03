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

    private static MethodChannel METHOD_CHANNEL;
    private static final String NATIVE_CHANNEL = "edu.illinois.rokwire/native_call";
    private static MainActivity instance = null;

    private static MethodChannel.Result pickLocationResult;

    private HashMap keys;

    private int preferredScreenOrientation;
    private Set<Integer> supportedScreenOrientations;

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
    }

    public static MainActivity getInstance() {
        return instance;
    }

    public static void invokeFlutterMethod(String methodName, Object arguments) {
        if (METHOD_CHANNEL != null) {
            getInstance().runOnUiThread(() -> METHOD_CHANNEL.invokeMethod(methodName, arguments));
        }
    }

    @Override
    public void onRequestPermissionsResult(int requestCode, @NonNull String[] permissions, @NonNull int[] grantResults) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults);
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
        try {
            String meridianEditorToken = Utils.Map.getValueFromPath(keysMap, "meridian.app_token", null);
            Meridian.DomainRegion[] domainRegions = Meridian.DomainRegion.values();
            int domainRegionIndex = Utils.Map.getValueFromPath(keysMap, "meridian.domain_region", 0);
            Meridian.DomainRegion domainRegion = (domainRegionIndex < domainRegions.length) ? domainRegions[domainRegionIndex] : Meridian.DomainRegion.DomainRegionDefault;
            Meridian.configure(this, meridianEditorToken);
            Meridian.getShared().setDomainRegion(domainRegion);
            //if (!Utils.Str.isEmpty(meridianEditorToken)) {
            //    Meridian.getShared().setEditorToken(meridianEditorToken);
            //}
        }
        catch (Exception e)
        {
            Log.d(TAG, "Failed to generate uuid");
        }
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
                case Constants.APP_DISMISS_LAUNCH_SCREEN_KEY:
                    result.success(false);
                    break;
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
                case Constants.BARCODE_KEY:
                    String barcodeImageData = handleBarcode(methodCall.arguments);
                    result.success(barcodeImageData);
                    break;
                case Constants.TEST_KEY:
                    result.success(false);
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
