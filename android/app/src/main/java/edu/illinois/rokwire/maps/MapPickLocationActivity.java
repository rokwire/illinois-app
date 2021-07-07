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

import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.mapsindoors.mapssdk.MPLocation;
import com.mapsindoors.mapssdk.MapControl;
import com.mapsindoors.mapssdk.MapsIndoors;
import com.mapsindoors.mapssdk.errors.MIError;

import org.json.JSONException;
import org.json.JSONObject;

import java.io.Serializable;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;

import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;

public class MapPickLocationActivity extends AppCompatActivity {

    private static final String TAG = MapPickLocationActivity.class.getSimpleName();

    private SupportMapFragment mapFragment;
    private GoogleMap googleMap;
    private MapControl mapControl;
    private TextView locationInfoTextView;
    private Marker customLocationMarker;
    private Marker selectedMarker;
    private HashMap initialLocation;
    private LatLng initialCameraPosition;
    private HashMap explore;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.map_pick_location_layout);

        initHeaderBar();
        initInitialLocation();
        initMapFragment();
        locationInfoTextView = findViewById(R.id.locationInfoTextView);
        updateLocationInfo(null);
    }

    @Override
    protected void onStart() {
        super.onStart();
        if (mapControl != null) {
            mapControl.onStart();
        }
    }

    @Override
    protected void onStop() {
        super.onStop();
        if (mapControl != null) {
            mapControl.onStop();
        }
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

    public void onSaveClicked(View view) {
        if (selectedMarker == null) {
            Utils.showDialog(this, getString(R.string.app_name),
                    getString(R.string.select_location_msg),
                    (dialog, which) -> dialog.dismiss(),
                    getString(R.string.ok), null, null, false);
            return;
        }
        String resultData = null;
        if (selectedMarker == customLocationMarker) {
            resultData = (String) selectedMarker.getTag();
        } else {
            MPLocation location = mapControl.getLocation(selectedMarker);
            if (location != null) {
                resultData = String.format(Locale.getDefault(), Constants.LOCATION_PICKER_DATA_FORMAT,
                        selectedMarker.getPosition().latitude, selectedMarker.getPosition().longitude,
                        location.getFloor(), (selectedMarker.getSnippet() != null ? selectedMarker.getSnippet() : ""),
                        location.getId(), location.getName());
            }
        }
        Intent resultDataIntent = new Intent();
        resultDataIntent.putExtra("location", resultData);
        setResult(RESULT_OK, resultDataIntent);
        finish();
    }

    private void initHeaderBar() {
        setSupportActionBar(findViewById(R.id.toolbar));
        ActionBar actionBar = getSupportActionBar();
        if (actionBar != null) {
            actionBar.setDisplayShowTitleEnabled(false);
            actionBar.setDisplayHomeAsUpEnabled(true);
            actionBar.setDisplayShowHomeEnabled(true);
        }
    }

    private void initInitialLocation() {
        Bundle initialLocationArguments = getIntent().getExtras();
        if (initialLocationArguments != null) {
            Serializable serializable = initialLocationArguments.getSerializable("explore");
            if (serializable instanceof HashMap) {
                explore = (HashMap) serializable;
                initialLocation = Utils.Explore.optLocation(explore);
            }
        }
        initialCameraPosition = Constants.DEFAULT_INITIAL_CAMERA_POSITION;
        if (initialLocation != null) {
            initialCameraPosition = Utils.Explore.optLatLng(initialLocation);
        }
    }

    private void initMapFragment() {
        mapFragment = ((SupportMapFragment) getSupportFragmentManager().findFragmentById(R.id.map_fragment));
        if (mapFragment != null) {
            mapFragment.getMapAsync(this::didGetMapAsync);
        }
    }

    private void didGetMapAsync(GoogleMap map) {
        googleMap = map;
        googleMap.setMapType(GoogleMap.MAP_TYPE_TERRAIN);
        googleMap.moveCamera(CameraUpdateFactory.newLatLngZoom(initialCameraPosition, Constants.INDOORS_BUILDING_ZOOM));
        setupMapsIndoors();
        loadInitialLocation();
    }

    private void setupMapsIndoors() {
        mapControl = new MapControl(this);
        mapControl.setGoogleMap(googleMap, mapFragment.getView());
        mapControl.setOnMarkerClickListener(marker -> {
            setSelectedLocationMarker(marker);
            return true;
        });
        mapControl.setOnMapClickListener(this::onMapClicked);
        mapControl.setOnFloorUpdateListener((building, i) -> onFloorUpdate());
        mapControl.init(this::mapControlDidInit);
    }

    private void mapControlDidInit(MIError error) {
        runOnUiThread(() -> {
            if (error == null) {
                mapControl.selectFloor(0);
            } else {
                Log.e(TAG, error.message);
            }
        });
    }

    private void loadInitialLocation() {
        if (initialLocation != null) {
            String locationId = null;
            Object locationIdObj = initialLocation.get("location_id");
            if (locationIdObj instanceof String) {
                locationId = (String) locationIdObj;
            }
            // MapsIndoors removed mapControl.getMarker(locationId) in version 3.x.x
            MPLocation mpLocation = (locationId != null) ? MapsIndoors.getLocationById(locationId) : null;
            int floorIndex = Utils.Explore.optFloor(initialLocation);
            selectedMarker = createCustomLocationMarker(initialLocation);
            mapControl.selectFloor(floorIndex);
            updateLocationInfo(selectedMarker);
        }
    }

    private boolean onMapClicked(@NonNull LatLng latLng, @Nullable List<MPLocation> list) {
        runOnUiThread(() -> {
            if ((selectedMarker != null) || (customLocationMarker != null)) {
                clearCustomLocationMarker();
                setSelectedLocationMarker(null);
            } else {
                Marker customMarker = createCustomLocationMarker(latLng);
                setSelectedLocationMarker(customMarker);
            }
        });
        return true;
    }

    private void onFloorUpdate() {
        updateCustomLocationMarker();
        updateSelectedMarker();
    }

    private void updateCustomLocationMarker() {
        if (customLocationMarker == null) {
            return;
        }
        int floorIndex;
        Object userDataObj = customLocationMarker.getTag();
        if (userDataObj instanceof Integer) {
            floorIndex = (Integer) userDataObj;
        } else {
            floorIndex = getFloorIndexFromMarkerTag(userDataObj);
        }
        boolean markerVisible = (floorIndex == mapControl.getCurrentFloorIndex());
        if (markerVisible && (!customLocationMarker.isInfoWindowShown())) {
            customLocationMarker.setVisible(true);
            customLocationMarker.showInfoWindow();
        } else if (!markerVisible && (customLocationMarker.isInfoWindowShown())) {
            customLocationMarker.hideInfoWindow();
            customLocationMarker.setVisible(false);
        }
    }

    private int getFloorIndexFromMarkerTag(Object markerTag) {
        if (!(markerTag instanceof String)) {
            return 0;
        }
        JSONObject tagJson = null;
        try {
            tagJson = new JSONObject((String) markerTag);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        Integer floorIndex = null;
        if (tagJson != null) {
            floorIndex = tagJson.optInt("floor", 0);
        }
        return (floorIndex != null) ? floorIndex : 0;
    }

    private void updateSelectedMarker() {
        if (selectedMarker == null) {
            return;
        }
        int floorIndex = 0;
        if (selectedMarker == customLocationMarker) {
            floorIndex = getFloorIndexFromMarkerTag(customLocationMarker);
        } else {
            MPLocation location = mapControl.getLocation(selectedMarker);
            if (location != null) {
                floorIndex = location.getFloor();
            }
        }
        if (floorIndex == mapControl.getCurrentFloorIndex()) {
            selectedMarker.showInfoWindow();
        } else {
            selectedMarker.hideInfoWindow();
        }
    }

    private Marker createCustomLocationMarker(HashMap locationMap) {
        clearCustomLocationMarker();
        LatLng latLng = Utils.Explore.optLatLng(locationMap);
        String locationName = null;
        Object nameObj = locationMap.get("name");
        if (nameObj instanceof String) {
            locationName = (String) nameObj;
        }
        String locationDesc = null;
        Object descrObj = locationMap.get("description");
        if (descrObj instanceof String) {
            locationDesc = (String) descrObj;
        }
        MarkerOptions markerOptions = new MarkerOptions();
        markerOptions.position(latLng);
        markerOptions.zIndex(1);
        markerOptions.title(locationName);
        markerOptions.snippet(locationDesc);
        customLocationMarker = googleMap.addMarker(markerOptions);
        String tag = String.format(Locale.getDefault(), Constants.LOCATION_PICKER_DATA_FORMAT, latLng.latitude, latLng.longitude, Utils.Explore.optFloor(locationMap), locationDesc, "", locationName);
        customLocationMarker.setTag(tag);
        customLocationMarker.showInfoWindow();
        return customLocationMarker;
    }

    private Marker createCustomLocationMarker(LatLng latLng) {
        clearCustomLocationMarker();
        MarkerOptions markerOptions = new MarkerOptions();
        markerOptions.position(latLng);
        markerOptions.zIndex(1);
        String latLangAsTitle = String.format(Locale.getDefault(), "%f, %f", latLng.latitude, latLng.longitude);
        String title = (explore != null) ? (String)explore.get("name") : latLangAsTitle;
        if (Utils.Str.isEmpty(title) || "null".equals(title)) {
            title = latLangAsTitle;
        }
        markerOptions.title(title);
        customLocationMarker = googleMap.addMarker(markerOptions);
        String userData = String.format(Locale.getDefault(), Constants.LOCATION_PICKER_DATA_FORMAT,
                latLng.latitude, latLng.longitude, mapControl.getCurrentFloorIndex(),
                "", "", "");//empty "name", "description" and empty "location_id"
        customLocationMarker.setTag(userData);
        customLocationMarker.showInfoWindow();
        return customLocationMarker;
    }

    private void setSelectedLocationMarker(Marker marker) {
        if ((customLocationMarker != null) && (customLocationMarker != marker)) {
            clearCustomLocationMarker();
        }
        selectedMarker = marker;
        if (selectedMarker != null) {
            selectedMarker.showInfoWindow();
        }
        updateLocationInfo(marker);
    }

    private void clearCustomLocationMarker() {
        if (customLocationMarker != null) {
            if (selectedMarker == customLocationMarker) {
                selectedMarker.hideInfoWindow();
                selectedMarker = null;
            }
            customLocationMarker.hideInfoWindow();
            customLocationMarker.remove();
            customLocationMarker = null;
        }
    }

    private void updateLocationInfo(Marker marker) {
        String locationInfoText;
        if (marker != null) {
            MPLocation location = mapControl.getLocation(marker);
            String locationName = (location != null) ? location.getName() : marker.getTitle();
            locationInfoText = getString(R.string.location_label, locationName);
        } else {
            locationInfoText = getString(R.string.select_location_msg);
        }
        locationInfoTextView.setText(locationInfoText);
    }
}
