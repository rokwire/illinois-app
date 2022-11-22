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
    private List<Object> explores;
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
            showExploresOnMap();
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
        googleMap.setOnCameraIdleListener(this::updateMarkers);
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

    private void moveCameraToSpecificPosition() {
        CameraUpdate cameraUpdate;
        if ((markers == null) || markers.isEmpty()) {
            cameraUpdate = CameraUpdateFactory.newLatLngZoom(Constants.DEFAULT_INITIAL_CAMERA_POSITION, Constants.DEFAULT_CAMERA_ZOOM);
        }
        else if (markers.size() == 1) {
            cameraUpdate = CameraUpdateFactory.newLatLngZoom(markers.get(0).getPosition(), Constants.DEFAULT_CAMERA_ZOOM);
        }
        else {
            LatLngBounds.Builder builder = new LatLngBounds.Builder();
            for (Marker marker : markers) {
                builder.include(marker.getPosition());
            }
            LatLngBounds bounds = builder.build();
            int width = getResources().getDisplayMetrics().widthPixels;
            int height = getResources().getDisplayMetrics().heightPixels;
            int padding = 150; // offset from edges of the map in pixels
            cameraUpdate = CameraUpdateFactory.newLatLngBounds(bounds, width, height, padding);
        }
        googleMap.animateCamera(cameraUpdate);
    }

    public void applyExplores(ArrayList explores, HashMap options) {
        this.explores = buildExplores(explores, options);
        if (mapLayoutPassed) {
            showExploresOnMap();
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

    private List<Object> buildExplores(ArrayList rawExplores, HashMap options) {
        if (rawExplores == null || rawExplores.size() == 0) {
            return null;
        }
        Object exploreLocationThresholdParam = (options != null) ? options.get("LocationThresoldDistance") : null;
        double exploreLocationThresholdDistance = Constants.EXPLORE_LOCATION_THRESHOLD_DISTANCE;
        if (exploreLocationThresholdParam instanceof Double) {
            exploreLocationThresholdDistance = (Double) exploreLocationThresholdParam;
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
                            if ((distance != null) && (distance < exploreLocationThresholdDistance) && sameFloor) {
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
        if (explores != null && explores.size() > 0) {
            markers = new ArrayList<>();
            for (Object explore : explores) {
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
        moveCameraToSpecificPosition();
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
        boolean updateMarkerInfo = (currentCameraZoom != cameraZoom);
        if (markers != null && !markers.isEmpty()) {
            for (Marker marker : markers) {
                if (updateMarkerInfo) {
                    boolean singleExploreMarker = Utils.Explore.optSingleExploreMarker(marker);
                    Utils.Explore.updateCustomMarkerAppearance(getContext(), marker, singleExploreMarker, currentCameraZoom, cameraZoom, markerLayoutView, markerGroupLayoutView, iconGenerator);
                }
            }
        }
        cameraZoom = currentCameraZoom;
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
}