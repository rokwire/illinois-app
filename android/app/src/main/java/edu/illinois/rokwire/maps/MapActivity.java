package edu.illinois.rokwire.maps;

import android.os.Bundle;
import android.view.MenuItem;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.GoogleMap;
import com.google.android.gms.maps.SupportMapFragment;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.MarkerOptions;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;

import androidx.appcompat.app.ActionBar;
import androidx.appcompat.app.AppCompatActivity;
import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;

public class MapActivity  extends AppCompatActivity {

    //Google Maps
    protected SupportMapFragment mapFragment;
    protected GoogleMap googleMap;

    private HashMap target;
    private ArrayList<HashMap> markers;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.map_layout);

        initHeaderBar();
        initParameters();
        initMap();
    }

    /**
     * Handle up (back) navigation button clicked
     */
    @Override
    public boolean onOptionsItemSelected(MenuItem item) {
        onBackPressed();
        return true;
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

    protected void initParameters() {
        Serializable targetSerializable = getIntent().getSerializableExtra("target");
        if (targetSerializable instanceof HashMap) {
            this.target = (HashMap) targetSerializable;
        }
        Serializable markersSerializable = getIntent().getSerializableExtra("markers");
        if (markersSerializable instanceof List) {
            this.markers = (ArrayList<HashMap>) markersSerializable;
        }
    }

    private void initMap() {
        mapFragment = ((SupportMapFragment) getSupportFragmentManager().findFragmentById(R.id.map_fragment));
        if (mapFragment != null) {
            mapFragment.getMapAsync(this::didGetMapAsync);
        }
    }

    private void didGetMapAsync(GoogleMap map) {
        googleMap = map;
        double latitude = Utils.Map.getValueFromPath(target, "latitude", Constants.DEFAULT_INITIAL_CAMERA_POSITION.latitude);
        double longitude = Utils.Map.getValueFromPath(target, "longitude", Constants.DEFAULT_INITIAL_CAMERA_POSITION.longitude);
        double zoom = Utils.Map.getValueFromPath(target, "zoom", Constants.DEFAULT_CAMERA_ZOOM);
        googleMap.moveCamera(CameraUpdateFactory.newCameraPosition(CameraPosition.fromLatLngZoom(new LatLng(latitude, longitude), (float)zoom)));
        afterMapInitialized();
    }

    protected void afterMapInitialized() {
        fillMarkers();
    }

    private void fillMarkers() {
        if (markers != null && !markers.isEmpty()) {
            for (HashMap markerData : markers) {
                Object latVal = markerData.get("latitude");
                Object lngVal = markerData.get("longitude");

                double lat = latVal instanceof Double ? (double) latVal :
                        latVal instanceof Integer ? Double.valueOf((int) latVal) : 0;
                double lng = lngVal instanceof Double ? (double) lngVal :
                        lngVal instanceof Integer ? Double.valueOf((int) lngVal) : 0;
                String name = markerData.containsKey("name") ? (String) markerData.get("name") : "";
                String description = markerData.containsKey("description") && markerData.get("description") != null ? (String) markerData.get("description") : "";

                googleMap.addMarker(new MarkerOptions()
                        .position(new LatLng(lat, lng))
                        .title(name).snippet(description)).showInfoWindow();
            }
        }
    }
}
