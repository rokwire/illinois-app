package edu.illinois.rokwire.rokwire_plugin;

import androidx.annotation.NonNull;

import android.app.Activity;
import android.Manifest;
import android.os.Build;
import android.content.Context;
import android.provider.Settings;
import android.content.pm.ActivityInfo;
import android.content.pm.PackageManager;

import android.location.LocationManager;

import androidx.core.app.ActivityCompat;
import androidx.core.content.ContextCompat;
import android.util.Log;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.plugin.common.PluginRegistry;

/** LocationServices */
public class LocationServices implements PluginRegistry.RequestPermissionsResultListener {

    private static final String TAG = "LocationServices";

    private static final String LOCATION_PERMISSIONS_REQUESTED_KEY = "location_permissions_requested";
    public static final int LOCATION_PERMISSION_REQUEST_CODE = 1;


    private static LocationServices _instance = null;

    private MethodChannel.Result _requestPermisionResult;

    public LocationServices() {
        if (_instance == null) {
            _instance = this;
        }
    }

    public static LocationServices getInstance() {
        return (_instance != null) ? _instance : new LocationServices();
    }

    public void handleMethodCall(String name, Object params, MethodChannel.Result result) {
        if (name.equals("queryStatus")) {
            result.success(getLocationServicesStatus());
        } else if (name.equals("requestPermision")) {
            requestLocationPermission(result);
        }
    }

    private String getLocationServicesStatus() {
        Context activity = RokwirePlugin.getInstance().getActivity();
        if (activity != null) {
            boolean locationServicesEnabled;
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                // This is new method provided in API 28
                LocationManager lm = (LocationManager) activity.getSystemService(Context.LOCATION_SERVICE);
                locationServicesEnabled = ((lm != null) && lm.isLocationEnabled());
            } else {
                // This is Deprecated in API 28
                int mode = Settings.Secure.getInt(activity.getContentResolver(), Settings.Secure.LOCATION_MODE,
                        Settings.Secure.LOCATION_MODE_OFF);
                locationServicesEnabled = (mode != Settings.Secure.LOCATION_MODE_OFF);
            }
            if (locationServicesEnabled) {
                if ((ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED &&
                        ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED)) {
                    return "allowed";
                } else {
                    boolean locationPermissionRequested = Utils.AppSharedPrefs.getBool(activity, LOCATION_PERMISSIONS_REQUESTED_KEY, false);
                    return locationPermissionRequested ? "denied" : "not_determined";
                }
            }
            else {
                return "disabled";
            }
        }
        else {
            return null;
        }
    }

    private void requestLocationPermission(MethodChannel.Result result) {
        Activity activity = RokwirePlugin.getInstance().getActivity();
        if (activity != null) {
            Utils.AppSharedPrefs.saveBool(activity, LOCATION_PERMISSIONS_REQUESTED_KEY, true);
            //check if granted
            if (ContextCompat.checkSelfPermission(activity, android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED  ||
                    ContextCompat.checkSelfPermission(activity, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                Log.d(TAG, "request permission");

                _requestPermisionResult = result;

                ActivityCompat.requestPermissions(activity,
                        new String[]{Manifest.permission.ACCESS_FINE_LOCATION, Manifest.permission.ACCESS_COARSE_LOCATION},
                        LOCATION_PERMISSION_REQUEST_CODE);
            } else {
                Log.d(TAG, "already granted");
                //TBD
                //if (geofenceMonitor != null) {
                //    geofenceMonitor.onLocationPermissionGranted();
                //}
                result.success("allowed");
            }
        }
    }


    // PluginRegistry.RequestPermissionsResultListener

    @Override
    public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {

        if (requestCode == LOCATION_PERMISSION_REQUEST_CODE) {
            if (_requestPermisionResult != null) {

                boolean granted = (grantResults.length > 1 &&
                        grantResults[0] == PackageManager.PERMISSION_GRANTED &&
                        grantResults[1] == PackageManager.PERMISSION_GRANTED);
                Log.d(TAG, granted ? "granted" : "not granted");
                _requestPermisionResult.success(granted ? "allowed" : "denied");
                _requestPermisionResult = null;
                if (granted) {
                    //TBD
                    //if (geofenceMonitor != null) {
                    //    geofenceMonitor.onLocationPermissionGranted();
                    //}
                }
            }
            return true;
        }
        return false;
    }
}
