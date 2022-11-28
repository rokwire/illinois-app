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

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.Context;
import android.content.res.Resources;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.ViewParent;
import android.widget.FrameLayout;
import android.widget.RelativeLayout;

import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.OnMapReadyCallback;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.MapStyleOptions;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.gson.Gson;
import com.google.maps.android.ui.IconGenerator;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import androidx.annotation.NonNull;
import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.MainActivity;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;

public class MapView extends FrameLayout implements OnMapReadyCallback {

    private Context context;
    private int mapId;
    private Object args;
    private Activity activity;
    private com.google.android.gms.maps.MapView googleMapView;
    private GoogleMap googleMap;
    private MapStyleOptions mapStyleOptions;

    private ArrayList<Object> explores;
    private HashMap exploreOptions;
    private List<Object> displayExplores;
    private List<Marker> markers;

    private IconGenerator iconGenerator;
    private View markerLayoutView;
    private View markerGroupLayoutView;
    private float cameraZoom;

    private boolean mapLayoutPassed;
    private boolean enableLocationValue;

    public MapView(Context context, int mapId, Object args) {
        super(context);
        this.context = context;
        this.mapId = mapId;
        this.args = args;
        if (context instanceof Activity) {
            this.activity = (Activity) context;
        }
        init();
    }

    public void onDestroy() {
        clearMarkers();
        if (googleMapView != null) {
            googleMapView.onDestroy();
        }
    }

    private void onCreate() {
        if (googleMapView != null) {
            googleMapView.onCreate(null);
        }
    }

    private void onResume() {
        if (googleMapView != null) {
            googleMapView.onResume();
        }
    }

    @Override
    protected void onLayout(boolean changed, int l, int t, int r, int b) {
        googleMapView.layout(0, 0, r, b);
        if (!mapLayoutPassed) {
            mapLayoutPassed = true;
            acknowledgeExplores();
        }
    }

    private void init() {
        initValuesFromArguments();
        initMarkerView();
        initMapView();
        initMapStyleOptions();
    }

    private void initMapView() {
        googleMapView = new com.google.android.gms.maps.MapView(context);
        googleMapView.setBackgroundColor(0xFF0000FF);
        addView(googleMapView);
        onCreate();
        googleMapView.getMapAsync(this);
    }

    private void initMarkerView() {
        iconGenerator = new IconGenerator(activity);
        iconGenerator.setBackground(activity.getDrawable(R.color.transparent));
        LayoutInflater inflater = (activity != null) ? (LayoutInflater) activity.getSystemService(Context.LAYOUT_INFLATER_SERVICE) : null;
        markerLayoutView = (inflater != null) ? inflater.inflate(R.layout.marker_info_layout, null) : null;
        markerGroupLayoutView = (inflater != null) ? inflater.inflate(R.layout.marker_group_layout, null) : null;
    }

    private void initMapStyleOptions() {
        try {
            mapStyleOptions = MapStyleOptions.loadRawResourceStyle(context, R.raw.mapstyle_nopoi);
        } catch (Resources.NotFoundException e) {
            Log.e("MapView", "Failed to load map style options from resources. Stacktrace:");
            e.printStackTrace();
        }
    }

    @Override
    public void onMapReady(@NonNull GoogleMap map) {
        onResume();
        googleMap = map;
        enableMyLocation(enableLocationValue);
        googleMap.setMapStyle(mapStyleOptions);
        googleMap.setOnMarkerClickListener(this::onMarkerClicked);
        googleMap.setOnMapClickListener(this::onMapClick);
        googleMap.setOnCameraIdleListener(this::onCameraIdle);
        googleMap.moveCamera(CameraUpdateFactory.newCameraPosition(CameraPosition.fromLatLngZoom(Constants.DEFAULT_INITIAL_CAMERA_POSITION, Constants.DEFAULT_CAMERA_ZOOM)));
        showExploresOnMap();
        relocateMyLocationButton();
    }

    private void initValuesFromArguments() {
        boolean myLocationEnabled = false;
        if (args instanceof Map) {
            Map<String, Object> jsonArgs = (Map) args;

            //{ "myLocationEnabled" : true}
            Object myLocationEnabledObj = jsonArgs.get("myLocationEnabled");
            if (myLocationEnabledObj instanceof Boolean) {
                myLocationEnabled = (Boolean) myLocationEnabledObj;
            }
        }
        this.enableLocationValue = myLocationEnabled;
    }

    public void applyExplores(ArrayList explores, HashMap options) {
        this.explores = explores;
        this.exploreOptions = options;
        if (mapLayoutPassed) {
            acknowledgeExplores();
        }
    }

    public void viewPoi(HashMap target) {
        if (mapLayoutPassed) {
            double latitude = Utils.Map.getValueFromPath(target, "latitude", Constants.DEFAULT_INITIAL_CAMERA_POSITION.latitude);
            double longitude = Utils.Map.getValueFromPath(target, "longitude", Constants.DEFAULT_INITIAL_CAMERA_POSITION.longitude);
            double zoom = Utils.Map.getValueFromPath(target, "zoom", Constants.DEFAULT_CAMERA_ZOOM);
            googleMap.animateCamera(CameraUpdateFactory.newCameraPosition(CameraPosition.fromLatLngZoom(new LatLng(latitude, longitude), (float) zoom)));
        }
    }

    // This has already been checked in flutter portion of the app
    @SuppressLint("MissingPermission")
    public void enableMyLocation(boolean enable) {
        enableLocationValue = enable;
        if (googleMap != null) {
            googleMap.setMyLocationEnabled(enable);
        }
    }

    private void acknowledgeExplores() {
        if ((explores != null) && mapLayoutPassed) {
            LatLngBounds bounds = getBoundsOfExplores(explores);
            if (bounds != null) {
                final int cameraPadding = 150;
                CameraUpdate cameraUpdate = CameraUpdateFactory.newLatLngBounds(bounds, cameraPadding);
                googleMap.moveCamera(cameraUpdate);
                double thresholdDistance;
                Object exploreLocationThresholdParam = (exploreOptions != null) ? exploreOptions.get("LocationThresoldDistance") : null;
                if (exploreLocationThresholdParam instanceof Double) {
                    thresholdDistance = (Double) exploreLocationThresholdParam;
                } else {
                    thresholdDistance = getThresholdDistance(googleMap.getCameraPosition().zoom);
                }
                buildDisplayExploresForThresholdDistance(thresholdDistance);
            }
        }
    }

    private void buildDisplayExplores() {
        if (mapLayoutPassed) {
            Object exploreLocationThresholdParam = (exploreOptions != null) ? exploreOptions.get("LocationThresoldDistance") : null;
            double thresholdDistance = (exploreLocationThresholdParam instanceof Double) ? (Double) exploreLocationThresholdParam : getAutomaticThresholdDistance();
            buildDisplayExploresForThresholdDistance(thresholdDistance);
        }
    }

    private void buildDisplayExploresForThresholdDistance(double thresholdDistance) {
        displayExplores = buildExplores(explores, thresholdDistance);
        showExploresOnMap();
    }

    private List<Object> buildExplores(ArrayList rawExplores, double thresholdDistance) {
        if (rawExplores == null || rawExplores.size() == 0) {
            return null;
        }
        List<ArrayList<HashMap>> mappedExploreGroups = new ArrayList<>();
        int rawExploresCount = rawExplores.size();
        for (int rawExploresIndex = 0; rawExploresIndex < rawExploresCount; rawExploresIndex++) {
            Object exploreObject = rawExplores.get(rawExploresIndex);
            if (exploreObject instanceof HashMap) {
                HashMap explore = (HashMap) exploreObject;
                Integer exploreFloor = Utils.Explore.optLocationFloor(explore);
                LatLng exploreLatLng = Utils.Explore.optLocationLatLng(explore);
                if (exploreLatLng != null) {
                    boolean exploreMapped = false;
                    for (List<HashMap> mappedExploreGroup : mappedExploreGroups) {
                        for (HashMap mappedExplore : mappedExploreGroup) {
                            LatLng mappedExploreLatLng = Utils.Explore.optLocationLatLng(mappedExplore);
                            Double distance = Utils.Location.getDistanceBetween(exploreLatLng, mappedExploreLatLng);
                            Integer mappedExploreFloor = Utils.Explore.optLocationFloor(mappedExplore);
                            boolean sameFloor = (exploreFloor == null && mappedExploreFloor == null) ||
                                    ((exploreFloor != null && mappedExploreFloor != null) && exploreFloor.equals(mappedExploreFloor));
                            if ((distance != null) && (distance <= thresholdDistance) && sameFloor) {
                                mappedExploreGroup.add(explore);
                                exploreMapped = true;
                                break;
                            }
                        }
                        if (exploreMapped) {
                            break;
                        }
                    }
                    if (!exploreMapped) {
                        ArrayList<HashMap> mappedExploreGroup = new ArrayList<>(Collections.singletonList(explore));
                        mappedExploreGroups.add(mappedExploreGroup);
                    }
                }
            }
        }
        List<Object> resultExplores = new ArrayList<>();
        for (List<HashMap> mappedExploreGroup : mappedExploreGroups) {
            if (mappedExploreGroup.size() == 1) {
                HashMap firstExplore = mappedExploreGroup.get(0);
                resultExplores.add(firstExplore);
            } else {
                resultExplores.add(mappedExploreGroup);
            }
        }
        return resultExplores;
    }

    private void showExploresOnMap() {
        if (googleMap == null || !mapLayoutPassed) {
            return;
        }
        clearMarkers();
        if (displayExplores != null && displayExplores.size() > 0) {
            markers = new ArrayList<>();
            for (Object explore : displayExplores) {
                MarkerOptions markerOptions = Utils.Explore.constructMarkerOptions(getContext(), explore, markerLayoutView, markerGroupLayoutView, iconGenerator);
                if (markerOptions != null) {
                    Marker marker = googleMap.addMarker(markerOptions);
                    JSONObject tagJson = Utils.Explore.constructMarkerTagJson(getContext(), marker.getTitle(), explore);
                    marker.setTag(tagJson);
                    markers.add(marker);
                }
            }
        }
        updateMarkers();
    }

    private synchronized void clearMarkers() {
        if (markers != null) {
            for (Marker marker : markers) {
                marker.remove();
            }
            markers.clear();
            markers = null;
        }
    }

    private void updateMarkers() {
        float currentCameraZoom = googleMap.getCameraPosition().zoom;
        boolean updateMarkerInfo = Utils.Explore.shouldUpdateMarkerView(currentCameraZoom, cameraZoom);
        if (updateMarkerInfo) {
            if (markers != null && !markers.isEmpty()) {
                for (Marker marker : markers) {
                    boolean singleExploreMarker = Utils.Explore.optSingleExploreMarker(marker);
                    Utils.Explore.updateCustomMarkerAppearance(getContext(), marker, singleExploreMarker, currentCameraZoom, cameraZoom, markerLayoutView, markerGroupLayoutView, iconGenerator);
                }
            }
        }
        cameraZoom = currentCameraZoom;
    }

    private void updateMapStyle() {
        boolean hideBuildingLabelsValue = false;
        Object hideBuildingsLabelParam = (exploreOptions != null) ? exploreOptions.get("HideBuildingLabels") : null;
        if (hideBuildingsLabelParam instanceof Boolean) {
            hideBuildingLabelsValue = (Boolean) hideBuildingsLabelParam;
        }
        if (hideBuildingLabelsValue) {
            MapStyleOptions mapStyle = (cameraZoom >= Constants.MAP_NO_POI_THRESHOLD_ZOOM) ? mapStyleOptions : null;
            googleMap.setMapStyle(mapStyle);
        }
    }

    private boolean onMarkerClicked(Marker marker) {
        Object rawData = Utils.Explore.optExploreMarkerRawData(marker);
        if (rawData != null) {
            if (rawData instanceof HashMap) {
                Gson gson = new Gson();
                String rawDataToString = gson.toJson(rawData);
                try {
                    rawData = new JSONObject(rawDataToString);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            } else if (rawData instanceof ArrayList) {
                ArrayList rawDataList = (ArrayList) rawData;
                rawData = new JSONArray(rawDataList);
            }
            JSONObject jsonArgs = new JSONObject();
            try {
                jsonArgs.put("mapId", mapId);
                jsonArgs.put("explore", rawData);
            } catch (JSONException e) {
                e.printStackTrace();
            }
            String methodArguments = jsonArgs.toString();
            MainActivity.invokeFlutterMethod("map.explore.select", methodArguments);
            return true;
        }
        return false;
    }

    private void onMapClick(LatLng latLng) {
        JSONObject jsonArgs = new JSONObject();
        try {
            jsonArgs.put("mapId", mapId);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        String methodArguments = jsonArgs.toString();
        MainActivity.invokeFlutterMethod("map.explore.clear", methodArguments);
    }

    private void onCameraIdle() {
        CameraPosition cameraPosition = googleMap.getCameraPosition();
        float zoomDelta = Math.abs(cameraZoom - cameraPosition.zoom);
        boolean zoomDeltaPassed = (zoomDelta > Constants.MAP_THRESHOLD_ZOOM_UPDATE_STEP);
        // Prevent building explores (respectively markers) for zoom level that is above our max zoom level
        boolean maxZoomLevelNotReached = (cameraPosition.zoom < Constants.MAP_MAX_ZOOM_LEVEL_FOR_THRESHOLD);
        if (zoomDeltaPassed && maxZoomLevelNotReached) {
            buildDisplayExplores();
        } else {
            updateMarkers();
        }
        updateMapStyle();
    }

    private void relocateMyLocationButton() {
        if (googleMapView == null) {
            return;
        }
        View firstView = googleMapView.findViewById(Integer.parseInt("1"));
        if (firstView == null) {
            return;
        }
        ViewParent parentView = firstView.getParent();
        if (!(parentView instanceof View)) {
            return;
        }
        View myLocationButton = ((View) parentView).findViewById(Integer.parseInt("2"));
        if (myLocationButton == null) {
            return;
        }
        //Place it on bottom right
        RelativeLayout.LayoutParams rlp = (RelativeLayout.LayoutParams) myLocationButton.getLayoutParams();
        rlp.addRule(RelativeLayout.ALIGN_PARENT_TOP, 0);
        rlp.addRule(RelativeLayout.ALIGN_PARENT_BOTTOM, RelativeLayout.TRUE);
        rlp.setMargins(0, 0, 30, 30);
    }

    private LatLngBounds getBoundsOfExplores(ArrayList<Object> explores) {
        LatLngBounds.Builder boundsBuilder = null;
        if ((explores != null) && !explores.isEmpty()) {
            for (Object explore : explores) {
                if (explore instanceof HashMap) {
                    LatLng exploreLatLng = Utils.Explore.optLocationLatLng((HashMap) explore);
                    if (exploreLatLng != null) {
                        if (boundsBuilder == null) {
                            boundsBuilder = new LatLngBounds.Builder();
                        }
                        boundsBuilder.include(exploreLatLng);
                    }
                }
            }
        }
        return (boundsBuilder != null) ? boundsBuilder.build() : null;
    }

    private double getAutomaticThresholdDistance() {
        return getThresholdDistance(googleMap.getCameraPosition().zoom);
    }

    private float getThresholdDistance(float zoom) {
        final float[] thresholdDistanceByZoom = {
            1000000, 800000, 600000, 200000, 100000,    // zoom 0 - 4
            100000,  80000,  60000,  20000,  10000,     // zoom 5 - 9
            5000,    1000,   500,    200,    100,       // zoom 10 - 14
            50,      0                                  // zoom 15 - 16 (max zoom level)
        };

        int zoomIndex = Math.round(zoom);
        if ((zoomIndex >= 0) && (zoomIndex < thresholdDistanceByZoom.length)) {
            float zoomDistance = thresholdDistanceByZoom[zoomIndex];
            float nextZoomDistance = ((zoomIndex + 1) < thresholdDistanceByZoom.length) ? thresholdDistanceByZoom[zoomIndex + 1] : 0;
            return zoomDistance - (zoom - (float) zoomIndex) * (zoomDistance - nextZoomDistance);
        }
        return 0;
    }
}