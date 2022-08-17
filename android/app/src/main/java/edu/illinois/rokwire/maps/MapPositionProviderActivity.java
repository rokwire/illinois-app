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

package edu.illinois.rokwire.maps;

import android.graphics.Color;
import android.graphics.PointF;
import android.location.Location;
import android.os.Bundle;
import android.os.Looper;
import android.util.Log;
import android.view.MenuItem;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.android.volley.VolleyError;
import com.arubanetworks.meridian.editor.EditorKey;
import com.arubanetworks.meridian.location.MeridianLocation;
import com.arubanetworks.meridian.location.MeridianLocationManager;
import com.arubanetworks.meridian.maps.MapInfo;
import com.arubanetworks.meridian.requests.MapInfoGroupRequest;
import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.maps.model.Marker;
import com.mapsindoors.mapssdk.MPPositionResult;
import com.mapsindoors.mapssdk.MapControl;
import com.mapsindoors.mapssdk.MapsIndoors;
import com.mapsindoors.mapssdk.OnPositionUpdateListener;
import com.mapsindoors.mapssdk.OnStateChangedListener;
import com.mapsindoors.mapssdk.PermissionsAndPSListener;
import com.mapsindoors.mapssdk.Point;
import com.mapsindoors.mapssdk.PositionProvider;
import com.mapsindoors.mapssdk.PositionResult;
import com.mapsindoors.mapssdk.errors.MIError;

import java.io.Serializable;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Timer;
import java.util.TimerTask;

import edu.illinois.rokwire.MainActivity;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;

public class MapPositionProviderActivity extends MapActivity implements MeridianLocationManager.LocationUpdateListener, PositionProvider {
    //region Class fields

    //Android Location
    private FusedLocationProviderClient fusedLocationClient;
    protected Location coreLocation;
    private com.google.android.gms.location.LocationRequest coreLocationRequest;
    private LocationCallback coreLocationCallback;

    //Meridian location
    private EditorKey mrAppKey;
    private MeridianLocationManager mrLocationManager;
    protected MeridianLocation mrLocation;
    private List<MapInfo> mrMaps;
    private Throwable mrLocationError;

    //Location timer
    private Timer locationTimer;
    private static final long LOCATION_TIMER_MILLIS = 1000; //1 sec
    protected long locationTimestamp;

    //MapsIndoors
    protected MapControl mapControl;
    protected MPPositionResult mpPositionResult;
    private boolean isRunning;
    private OnPositionUpdateListener mpPositionUpdateListener;

    private boolean firstLocationUpdatePassed;
    private HashMap options;
    private TextView debugStatusView;
    private boolean showDebugLocation;

    //endregion

    //region Activity methods

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        initUiViews();
        initCoreLocation();
        initMeridian();
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (mapControl != null) {
            mapControl.onStart();
        }
        startMonitor();
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (mapControl != null) {
            mapControl.onStop();
        }
        stopMonitor();
    }

    @Override
    protected void onResume() {
        super.onResume();
        if (mapControl != null) {
            mapControl.onResume();
        }
    }

    @Override
    protected void onPause() {
        super.onPause();
        if (mapControl != null) {
            mapControl.onPause();
        }
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (mapControl != null) {
            mapControl.onDestroy();
        }
    }

    @Override
    public void onLowMemory() {
        super.onLowMemory();
        if (mapControl != null) {
            mapControl.onLowMemory();
        }
    }

    /**
     * Handle up (back) navigation button clicked
     */
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        onBackPressed();
        return true;
    }

    //endregion

    //region Common initialization

    @Override
    protected void initParameters() {
        super.initParameters();
        Serializable optionsSerializable = getIntent().getSerializableExtra("options");
        if (optionsSerializable instanceof HashMap) {
            this.options = (HashMap) optionsSerializable;
        }
    }

    protected void initUiViews() {
        showDebugLocation = Utils.Map.getValueFromPath(options, "showDebugLocation", false);
        if (showDebugLocation) {
            debugStatusView = findViewById(R.id.debugStatusTextView);
            debugStatusView.setVisibility(View.VISIBLE);
        }
    }

    //endregion

    //region Map views initialization

    @Override
    protected void afterMapInitialized() {
        super.afterMapInitialized();
        initMapControl();
    }

    private void initMapControl() {
        mapControl = new MapControl(this);
        mapControl.setGoogleMap(googleMap, mapFragment.getView());
        MapsIndoors.setPositionProvider(this);
        mapControl.showUserPosition(true);
        mapControl.setOnFloorUpdateListener((building, i) -> onFloorChanged(i));
        mapControl.setOnMarkerClickListener(this::onMarkerClicked);
        mapControl.addOnCameraIdleListener(this::onCameraIdle);
        mapControl.init(this::mapControlDidInit);
    }

    private void mapControlDidInit(MIError error) {
        Log.d(getLogTag(), "mapControlDidInit()");
        runOnUiThread(() -> {
            if (error == null) {
                afterMapControlInitialized();
            } else {
                Log.d(getLogTag(), error.message);
            }
        });
    }

    protected void afterMapControlInitialized() {
        mapControl.selectFloor(0);
        boolean showLevels = Utils.Map.getValueFromPath(options, "enableLevels", true);
        mapControl.enableFloorSelector(showLevels);
        startPositioning(null);
    }

    //endregion

    //region Meridian

    protected void initMeridian() {
        HashMap keys = (MainActivity.getInstance() != null) ? MainActivity.getInstance().getKeys() : null;
        String mrAppKeyValue = (keys != null) ? Utils.Map.getValueFromPath(keys, "meridian.app_id", "") : "";
        mrAppKey = new EditorKey(mrAppKeyValue);
        mrLocationManager = new MeridianLocationManager(this, mrAppKey, this);
        loadMeridianMaps();
    }

    private void loadMeridianMaps() {
        HashMap keys = (MainActivity.getInstance() != null) ? MainActivity.getInstance().getKeys() : null;
        String groupId = (keys != null) ? Utils.Map.getValueFromPath(keys, "meridian.group_id", "") : "";
        MapInfoGroupRequest mrMapsRequest = new MapInfoGroupRequest.Builder().
                setAppKey(mrAppKey).
                setGroupId(groupId).
                setListener(maps -> {
                    mrMaps = maps;
                    if (mrLocation != null) {
                        notifyMeridianLocationUpdate();
                    } else if (coreLocation != null) {
                        notifyCoreLocationUpdate();
                    }
                }).
                setErrorListener(throwable -> {
                    if (throwable instanceof VolleyError) {
                        VolleyError ew = (VolleyError) throwable;
                        byte[] errData = (ew.networkResponse != null) ? ew.networkResponse.data : null;
                        if (errData != null) {
                            String responseBody = new String(errData, StandardCharsets.UTF_8);
                            Log.e(getLogTag(), responseBody);
                        }
                    }
                    throwable.printStackTrace();
                }).build();
        mrMapsRequest.sendRequest();
    }

    private MapInfo getMapByLocation(MeridianLocation mrLocation) {
        if (mrLocation == null || mrMaps == null || mrMaps.isEmpty()) {
            return null;
        }
        for (MapInfo map : mrMaps) {
            if (map.getKey().getId().equals(mrLocation.getMapKey().getId())) {
                return map;
            }
        }
        return null;
    }

    private void notifyMeridianLocationUpdate() {
        MapInfo map = getMapByLocation(mrLocation);
        if (map != null) {
            PointF mrLocationPointF = mrLocation.getPoint();
            PointF mapPointF = map.mapPointLatLong(mrLocationPointF.x, mrLocationPointF.y);
            int mpFloor = map.getLevel();
            Point point = new Point(mapPointF.x, mapPointF.y, mpFloor);
            MPPositionResult positionResult = new MPPositionResult(point, 0, 0, mpFloor);
            positionResult.setProvider(this);
            notifyLocationUpdate(positionResult, MPPositionProviderSource.MERIDIAN, mrLocation.getTimestamp().getTime());
        }
    }

    /**
     * MeridianLocationManager.LocationUpdateListener interface
     */

    @Override
    public void onLocationUpdate(MeridianLocation meridianLocation) {
        mrLocationError = null;
        mrLocation = meridianLocation;
        notifyMeridianLocationUpdate();
    }

    @Override
    public void onLocationError(Throwable throwable) {
        mrLocation = null;
        mrLocationError = throwable;
        notifyLocationFail();
    }

    @Override
    public void onEnableBluetoothRequest() {
        Log.d(getLogTag(), "LocationUpdateListener.onEnableBluetoothRequest");
    }

    @Override
    public void onEnableWiFiRequest() {
        Log.d(getLogTag(), "LocationUpdateListener.onEnableWiFiRequest");
    }

    @Override
    public void onEnableGPSRequest() {
        Log.d(getLogTag(), "LocationUpdateListener.onEnableGPSRequest");
    }

    //endregion

    //region MapsIndoors

    protected void onFloorChanged(int floor) {
        Log.d(getLogTag(), "MapControl.onFloorUpdate: " + floor);
    }

    protected void onCameraIdle() {
        Log.d(getLogTag(), "MapControl.onCameraIdle");
    }

    protected boolean onMarkerClicked(Marker marker) {
        Log.d(getLogTag(), "MapControl.onMarkerClicked");
        return false;
    }

    /**
     * PositionProvider interface
     */

    @NonNull
    @Override
    public String[] getRequiredPermissions() {
        return new String[0];
    }

    @Override
    public boolean isPSEnabled() {
        return true;
    }

    @Override
    public void startPositioning(@Nullable String s) {
        startMonitor();
    }

    @Override
    public void stopPositioning(@Nullable String s) {
        stopMonitor();
    }

    @Override
    public boolean isRunning() {
        return isRunning;
    }

    @Override
    public void addOnPositionUpdateListener(@Nullable OnPositionUpdateListener onPositionUpdateListener) {
        this.mpPositionUpdateListener = onPositionUpdateListener;
    }

    @Override
    public void removeOnPositionUpdateListener(@Nullable OnPositionUpdateListener onPositionUpdateListener) {
        this.mpPositionUpdateListener = null;
    }

    @Override
    public void setProviderId(@Nullable String s) {
        Log.d(getLogTag(), "PositionProvider.setProviderId");
    }

    @Override
    public void addOnStateChangedListener(@Nullable OnStateChangedListener onStateChangedListener) {
        Log.d(getLogTag(), "PositionProvider.addOnStateChangedListener");
    }

    @Override
    public void removeOnStateChangedListener(@Nullable OnStateChangedListener onStateChangedListener) {
        Log.d(getLogTag(), "PositionProvider.removeOnStateChangedListener");
    }

    @Override
    public void checkPermissionsAndPSEnabled(PermissionsAndPSListener permissionsAndPSListener) {
        Log.d(getLogTag(), "PositionProvider.checkPermissionsAndPSEnabled");
    }

    @Nullable
    @Override
    public String getProviderId() {
        Log.d(getLogTag(), "PositionProvider.getProviderId");
        return null;
    }

    @Nullable
    @Override
    public PositionResult getLatestPosition() {
        return mpPositionResult;
    }

    @Override
    public void startPositioningAfter(int i, @Nullable String s) {
        new Timer().schedule(new TimerTask() {
            @Override
            public void run() {
                startPositioning(s);
            }
        }, i);
    }

    @Override
    public void terminate() {
        Log.d(getLogTag(), "PositionProvider.terminate");
    }

    //endregion

    //region Core Location

    private void initCoreLocation() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this);
        createCoreLocationCallback();
        createCoreLocationRequest();
    }

    private void notifyCoreLocationUpdate() {
        if ((coreLocation != null) && (mrLocation == null)) {
            Point coreLocationPoint = new Point(coreLocation.getLatitude(), coreLocation.getLongitude(), 0);
            MPPositionResult positionResult = new MPPositionResult(coreLocationPoint, 0, 0, 0);
            positionResult.setProvider(this);
            notifyLocationUpdate(positionResult, MPPositionProviderSource.CORE, coreLocation.getTime());
        }
    }

    private void createCoreLocationRequest() {
        coreLocationRequest = com.google.android.gms.location.LocationRequest.create();
        coreLocationRequest.setInterval(60000); //in millis
        coreLocationRequest.setFastestInterval(30000); //in millis
        coreLocationRequest.setPriority(com.google.android.gms.location.LocationRequest.PRIORITY_HIGH_ACCURACY);
    }

    private void createCoreLocationCallback() {
        coreLocationCallback = new LocationCallback() {
            @Override
            public void onLocationResult(LocationResult locationResult) {
                if (locationResult == null) {
                    return;
                }
                for (Location location : locationResult.getLocations()) {
                    coreLocation = location;
                }
                notifyCoreLocationUpdate();
            }
        };
    }

    //endregion

    //region Common Location

    protected void notifyLocationUpdate(MPPositionResult positionResult, MPPositionProviderSource source, long timestamp) {
        if (positionResult != null) {
            mpPositionResult = positionResult;
            locationTimestamp = timestamp;
            if (mpPositionUpdateListener != null) {
                mpPositionUpdateListener.onPositionUpdate(positionResult);
            }
            if (!firstLocationUpdatePassed) {
                firstLocationUpdatePassed = true;
                handleFirstLocationUpdate();
            }
            if ((debugStatusView != null) && showDebugLocation) {
                String sourceAbbr;
                int sourceColor;
                if (source == MPPositionProviderSource.MERIDIAN) {
                    sourceAbbr = "MR";
                    sourceColor = Color.rgb(0, 0, 255);
                } else if (source == MPPositionProviderSource.CORE) {
                    sourceAbbr = "CL";
                    sourceColor = Color.rgb(0, 126, 0);
                } else {
                    sourceAbbr = "UNK";
                    sourceColor = Color.rgb(126, 126, 126);
                }
                double lat = 0.0d;
                double lng = 0.0d;
                int floor = 0;
                if (mpPositionResult.getPoint() != null) {
                    lat = mpPositionResult.getPoint().getLat();
                    lng = mpPositionResult.getPoint().getLng();
                    floor = mpPositionResult.getFloor();
                }
                debugStatusView.setText(String.format(Locale.getDefault(), "%s [%.6f, %.6f] @ %d", sourceAbbr, lat, lng, floor));
                debugStatusView.setTextColor(sourceColor);
            }
        }
    }

    protected void notifyLocationFail() {
        if (mrLocationError != null) {
            if (mpPositionUpdateListener != null) {
                mpPositionUpdateListener.onPositionFailed(this);
            }
        }
    }

    protected void handleFirstLocationUpdate() {

    }

    private void startMonitor() {
        if (!isRunning) {
            if (mrLocationManager != null) {
                mrLocationManager.startListeningForLocation();
            }
            if (fusedLocationClient != null) {
                new Timer().schedule(new TimerTask() {
                    @Override
                    public void run() {
                        fusedLocationClient.requestLocationUpdates(coreLocationRequest, coreLocationCallback, Looper.getMainLooper());
                    }
                }, LOCATION_TIMER_MILLIS); //Delay Core Location updates. Wait first for meridian
            }
            isRunning = true;
            startLocationTimer();
        }
    }

    private void stopMonitor() {
        if (isRunning) {
            stopLocationTimer();
            if (mrLocationManager != null) {
                mrLocationManager.stopListeningForLocation();
            }
            mrLocation = null;
            mrLocationError = null;
            if (fusedLocationClient != null) {
                fusedLocationClient.removeLocationUpdates(coreLocationCallback);
            }
            isRunning = false;
        }
    }

    private void startLocationTimer() {
        stopLocationTimer();
        locationTimer = new Timer();
        locationTimer.schedule(new TimerTask() {
            @Override
            public void run() {
                onLocationTimerTimeout();
            }
        }, (LOCATION_TIMER_MILLIS * 4));
    }

    private void stopLocationTimer() {
        if (locationTimer != null) {
            locationTimer.cancel();
            locationTimer = null;
        }
    }

    protected void onLocationTimerTimeout() {
        stopLocationTimer();
    }

    //endregion

    //region Utilities

    protected String getLogTag() {
        return MapPositionProviderActivity.class.getSimpleName();
    }

    //endregion

    protected enum MPPositionProviderSource {MERIDIAN, CORE}
}
