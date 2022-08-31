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
import android.view.View;
import android.widget.TextView;

import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;

import java.io.Serializable;
import java.util.HashMap;
import java.util.Locale;

import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;

public class MapPickLocationActivity extends AppCompatActivity {

    private GoogleMap googleMap;
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

    public void onSaveClicked(View view) {
        if (selectedMarker == null) {
            Utils.showDialog(this, getString(R.string.app_name),
                    getString(R.string.select_location_msg),
                    (dialog, which) -> dialog.dismiss(),
                    getString(R.string.ok), null, null, false);
            return;
        }
        String resultData;
        if (selectedMarker == customLocationMarker) {
            resultData = (String) selectedMarker.getTag();
        } else {
            resultData = String.format(Locale.getDefault(), Constants.LOCATION_PICKER_DATA_FORMAT,
                    selectedMarker.getPosition().latitude, selectedMarker.getPosition().longitude);
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
        initialCameraPosition = Utils.Explore.optLatLng(initialLocation);
        if (initialCameraPosition == null) {
            initialCameraPosition = Constants.DEFAULT_INITIAL_CAMERA_POSITION;
        }
    }

    private void initMapFragment() {
        SupportMapFragment mapFragment = ((SupportMapFragment) getSupportFragmentManager().findFragmentById(R.id.map_fragment));
        if (mapFragment != null) {
            mapFragment.getMapAsync(this::didGetMapAsync);
        }
    }

    private void didGetMapAsync(GoogleMap map) {
        googleMap = map;
        googleMap.setMapType(GoogleMap.MAP_TYPE_TERRAIN);
        googleMap.setOnMarkerClickListener(marker -> {
            setSelectedLocationMarker(marker);
            return true;
        });
        googleMap.setOnMapClickListener(this::onMapClicked);
        googleMap.setIndoorEnabled(true);
        googleMap.moveCamera(CameraUpdateFactory.newLatLngZoom(initialCameraPosition, Constants.INDOORS_BUILDING_ZOOM));
        loadInitialLocation();
    }

    private void loadInitialLocation() {
        if (initialLocation != null) {
            LatLng latLng = Utils.Explore.optLatLng(initialLocation);
            if (latLng != null) {
                selectedMarker = createCustomLocationMarker(initialLocation);
                updateLocationInfo(selectedMarker);
            }
        }
    }

    private void onMapClicked(LatLng latLng) {
        if ((selectedMarker != null) || (customLocationMarker != null)) {
            clearCustomLocationMarker();
            setSelectedLocationMarker(null);
        } else {
            Marker customMarker = createCustomLocationMarker(latLng);
            setSelectedLocationMarker(customMarker);
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
        if (Utils.Str.isEmpty(locationName)) {
            locationName = String.format(Locale.getDefault(), "%f, %f", latLng.latitude, latLng.longitude);
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
        String tag = String.format(Locale.getDefault(), Constants.LOCATION_PICKER_DATA_FORMAT, latLng.latitude, latLng.longitude);
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
                latLng.latitude, latLng.longitude);
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
            String locationName = marker.getTitle();
            locationInfoText = getString(R.string.location_label, locationName);
        } else {
            locationInfoText = getString(R.string.select_location_msg);
        }
        locationInfoTextView.setText(locationInfoText);
    }
}
