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

import android.Manifest;
import android.content.Context;
import android.content.SharedPreferences;
import android.content.pm.PackageManager;
import android.graphics.Color;
import android.location.Location;
import android.os.Build;
import android.os.Bundle;
import android.os.Looper;
import android.preference.PreferenceManager;
import android.text.Html;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AlertDialog;

import com.google.android.gms.location.FusedLocationProviderClient;
import com.google.android.gms.location.LocationCallback;
import com.google.android.gms.location.LocationResult;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.maps.CameraUpdate;
import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.model.BitmapDescriptorFactory;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.maps.model.PolygonOptions;
import com.google.android.gms.maps.model.Polyline;
import com.google.android.gms.maps.model.PolylineOptions;
import com.google.maps.android.ui.IconGenerator;

import org.json.JSONObject;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import androidx.core.app.ActivityCompat;
import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.MainActivity;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;
import edu.illinois.rokwire.navigation.model.NavBounds;
import edu.illinois.rokwire.navigation.model.NavCoord;
import edu.illinois.rokwire.navigation.model.NavPolyline;
import edu.illinois.rokwire.navigation.model.NavRoute;
import edu.illinois.rokwire.navigation.Navigation;
import edu.illinois.rokwire.navigation.model.NavRouteLeg;
import edu.illinois.rokwire.navigation.model.NavRouteStep;

public class MapDirectionsActivity extends MapActivity implements Navigation.NavigationListener {

    //region Class fields

    private static final String TAG = MapDirectionsActivity.class.getSimpleName();

    //Android Location
    private FusedLocationProviderClient fusedLocationClient;
    protected Location coreLocation;
    private com.google.android.gms.location.LocationRequest coreLocationRequest;
    private LocationCallback coreLocationCallback;

    //Explores - could be Event, Dining, Laundry or ParkingLotInventory
    private Object explore;
    private HashMap exploreLocation;
    private Marker exploreMarker;
    private IconGenerator iconGenerator;
    private View markerLayoutView;
    private View markerGroupLayoutView;
    private float cameraZoom;

    //Navigation
    private Navigation navigation;
    private NavRoute navRoute;
    private String navRouteError;
    private CameraPosition cameraPosition;
    private List<Integer> routeStepCoordCounts;
    private Polyline routePolyline;
    private NavStatus navStatus = NavStatus.UNKNOWN;
    private boolean navAutoUpdate;
    private int currentLegIndex = 0;
    private int currentStepIndex = -1;
    private boolean buildRouteAfterInitialization;
    private Polyline segmentPolyline;
    private Marker segmentStartMarker;
    private Marker segmentEndMarker;

    //Navigation UI
    private static final String TRAVEL_MODE_PREFS_KEY = "directions.travelMode";
    private static final String[] TRAVEL_MODES = {Navigation.TRAVEL_MODE_WALKING, Navigation.TRAVEL_MODE_BICYCLING,
            Navigation.TRAVEL_MODE_DRIVING, Navigation.TRAVEL_MODE_TRANSIT};
    private String selectedTravelMode;
    private Map<String, View> travelModesMap;
    private View navRefreshButton;
    private View navTravelModesContainer;
    private View navAutoUpdateButton;
    private View navPrevButton;
    private View navNextButton;
    private TextView navStepLabel;
    private View routeLoadingFrame;

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
        initExplore();
        initNavigation();
        buildTravelModes();
    }

    @Override
    protected void onStart() {
        super.onStart();
        startMonitor();
    }

    @Override
    protected void onStop() {
        super.onStop();
        stopMonitor();
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (navigation != null) {
            navigation.dismiss();
        }
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

    protected void initDebugView() {
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
        buildExploreMarker();
        buildPolygon();
        if (buildRouteAfterInitialization) {
            buildRouteAfterInitialization = false;
            buildRoute();
        }
        initGoogleMap();
    }

    private void initGoogleMap() {
        googleMap.setOnMarkerClickListener(this::onMarkerClicked);
        googleMap.setOnCameraIdleListener(this::onCameraIdle);

        // This check is done in the flutter part but still check for permissions to prevent warnings.
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            return;
        }
        googleMap.setMyLocationEnabled(true); // Allow the blue dot that shows my location
        googleMap.getUiSettings().setMyLocationButtonEnabled(false); // Disallow the button in the upper right corner which relocates the camera position
    }

    private boolean onMarkerClicked(Marker marker) {
        Object exploreMarkerRawData = Utils.Explore.optExploreMarkerRawData(marker);
        return (exploreMarkerRawData != null);
    }

    private void onCameraIdle() {
        updateExploreMarkerAppearance();
    }

    //endregion

    //region Core Location

    private void initCoreLocation() {
        fusedLocationClient = LocationServices.getFusedLocationProviderClient(this);
        createCoreLocationRequest();
        createCoreLocationCallback();
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
                coreLocation = (locationResult != null) ? locationResult.getLastLocation() : null;
                onCoreLocationUpdate();
            }
        };
    }

    private void onCoreLocationUpdate() {
        if (coreLocation != null) {
            if (!firstLocationUpdatePassed) {
                firstLocationUpdatePassed = true;
                handleFirstLocationUpdate();
            }

            if ((navStatus == NavStatus.PROGRESS) && navAutoUpdate) {
                updateNavByCurrentLocation();
            } else {
                updateNav();
            }

            if ((debugStatusView != null) && showDebugLocation) {
                debugStatusView.setText(String.format(Locale.getDefault(), "[%.6f, %.6f]", coreLocation.getLatitude(), coreLocation.getLongitude()));
            }
        }
    }

    private void startMonitor() {
        if (fusedLocationClient != null) {
            // This check is done in the flutter part but still check for permissions to prevent warnings.
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED &&
                    ActivityCompat.checkSelfPermission(this, Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
                return;
            }
            fusedLocationClient.requestLocationUpdates(coreLocationRequest, coreLocationCallback, Looper.getMainLooper());
        }
    }

    private void stopMonitor() {
        if (fusedLocationClient != null) {
            fusedLocationClient.removeLocationUpdates(coreLocationCallback);
        }
    }

    //endregion

    //region Explores

    private void initExplore() {
        Serializable exploreSerializable = getIntent().getSerializableExtra("explore");
        if (exploreSerializable == null) {
            return;
        }
        if (exploreSerializable instanceof HashMap) {
            HashMap singleExplore;
            singleExplore = (HashMap) exploreSerializable;
            this.explore = singleExplore;
            initExploreLocation(singleExplore);
        } else if (exploreSerializable instanceof ArrayList) {
            ArrayList explores = (ArrayList) exploreSerializable;
            this.explore = explores;
            Object firstExplore = (explores.size() > 0) ? explores.get(0) : null;
            if (firstExplore instanceof HashMap) {
                initExploreLocation((HashMap) firstExplore);
            }
        }
    }

    protected void initUiViews() {
        TextView titleTextView = findViewById(R.id.toolbarTitleView);
        if (titleTextView != null) {
            titleTextView.setText(getString(R.string.directionsTitle));
        }
        initDebugView();
        showDirectionsUiViews();
        iconGenerator = new IconGenerator(this);
        iconGenerator.setBackground(getDrawable(R.color.transparent));
        LayoutInflater inflater = (LayoutInflater) getSystemService(Context.LAYOUT_INFLATER_SERVICE);
        if (inflater != null) {
            markerLayoutView = inflater.inflate(R.layout.marker_info_layout, null);
            markerGroupLayoutView = inflater.inflate(R.layout.marker_group_layout, null);
        }
        navRefreshButton = findViewById(R.id.navRefreshButton);
        navTravelModesContainer = findViewById(R.id.navTravelModesContainer);
        navAutoUpdateButton = findViewById(R.id.navAutoUpdateButton);
        navPrevButton = findViewById(R.id.navPrevButton);
        navNextButton = findViewById(R.id.navNextButton);
        navStepLabel = findViewById(R.id.navStepLabel);
        routeLoadingFrame = findViewById(R.id.routeLoadingFrame);
    }

    private void showDirectionsUiViews() {
        View topNavBar = findViewById(R.id.topNavBar);
        if (topNavBar != null) {
            topNavBar.setVisibility(View.VISIBLE);
        }
        View bottomNavBar = findViewById(R.id.bottomNavBar);
        if (topNavBar != null) {
            bottomNavBar.setVisibility(View.VISIBLE);
        }
    }

    private void buildExploreMarker() {
        if (exploreLocation != null) {
            LatLng locationLatLng = Utils.Explore.optLatLng(exploreLocation);
            MarkerOptions markerOptions = Utils.Explore.constructMarkerOptions(this, explore, locationLatLng, markerLayoutView, markerGroupLayoutView, iconGenerator);
            if (markerOptions != null) {
                exploreMarker = googleMap.addMarker(markerOptions);
                JSONObject tagJson = Utils.Explore.constructMarkerTagJson(this, exploreMarker.getTitle(), explore);
                exploreMarker.setTag(tagJson);
            }
            updateExploreMarkerAppearance();
        }
    }

    private void updateExploreMarkerAppearance() {
        float currentCameraZoom = googleMap.getCameraPosition().zoom;
        boolean updateMarkerInfo = (currentCameraZoom != cameraZoom);
        if (updateMarkerInfo) {
            boolean singleExploreMarker = Utils.Explore.optSingleExploreMarker(exploreMarker);
            Utils.Explore.updateCustomMarkerAppearance(this, exploreMarker, singleExploreMarker, currentCameraZoom, cameraZoom, markerLayoutView, markerGroupLayoutView, iconGenerator);
        }
        cameraZoom = currentCameraZoom;
    }

    private void initExploreLocation(HashMap singleExplore) {
        Utils.ExploreType exploreType = Utils.Explore.getExploreType(singleExplore);
        if ((exploreType == Utils.ExploreType.PARKING) || (exploreType == Utils.ExploreType.MTD_STOP)) {
            LatLng latLng = Utils.Explore.optLocationLatLng(singleExplore);
            if (latLng != null) {
                this.exploreLocation = Utils.Explore.createLocationMap(latLng);
            }
        } else if (exploreType == Utils.ExploreType.STUDENT_COURSE) {
            this.exploreLocation = Utils.Explore.optStudentCourseLocation(singleExplore, true);
        } else {
            this.exploreLocation = Utils.Explore.optLocation(singleExplore);
        }
    }

    private void buildPolygon() {
        if (googleMap == null) {
            return;
        }
        List<LatLng> polygonPoints = Utils.Explore.getExplorePolygon(explore);
        if ((polygonPoints == null) || polygonPoints.isEmpty()) {
            return;
        }
        Utils.ExploreType exploreType = Utils.Explore.getExploreType(explore);
        int strokeColor = getResources().getColor(Utils.Explore.getExploreColorResource(exploreType));
        int fillColor = Color.argb(10, 0, 0, 0);
        googleMap.addPolygon(new PolygonOptions().addAll(polygonPoints).
                clickable(false).strokeColor(strokeColor).strokeWidth(5.0f).fillColor(fillColor).zIndex(1.0f));
    }

    //endregion

    //region Navigation

    public void onRefreshNavClicked(View view) {
        navRoute = null;
        navRouteError = null;
        if (routePolyline != null) {
            routePolyline.remove();
            routePolyline = null;
        }
        removeMarker(segmentStartMarker);
        segmentStartMarker = null;
        removeMarker(segmentEndMarker);
        segmentEndMarker = null;
        removePolyline(segmentPolyline);
        segmentPolyline = null;
        routeStepCoordCounts = null;
        navStatus = NavStatus.UNKNOWN;
        navAutoUpdate = false;

        if (cameraPosition != null && googleMap != null) {
            googleMap.animateCamera(CameraUpdateFactory.newLatLngZoom(cameraPosition.target, cameraPosition.zoom));
        }
        cameraPosition = null;

        updateNav();
        buildRoute();
    }

    public void onAutoUpdateNavClicked(View view) {
        if (navStatus == NavStatus.PROGRESS) {
            NavRouteSegmentPath segmentPath = findNearestRouteSegmentByCurrentLocation();
            if (isValidSegmentPath(segmentPath)) {
                currentLegIndex = segmentPath.legIndex;
                currentStepIndex = segmentPath.stepIndex;
                moveTo(currentLegIndex, currentStepIndex);
                navAutoUpdate = true;
            }
            updateNav();
        }
    }

    public void onWalkTravelModeClicked(View view) {
        changeSelectedTravelMode(Navigation.TRAVEL_MODE_WALKING);
    }

    public void onBikeTravelModeClicked(View view) {
        changeSelectedTravelMode(Navigation.TRAVEL_MODE_BICYCLING);
    }

    public void onDriveTravelModeClicked(View view) {
        changeSelectedTravelMode(Navigation.TRAVEL_MODE_DRIVING);
    }

    public void onTransitTravelModeClicked(View view) {
        changeSelectedTravelMode(Navigation.TRAVEL_MODE_TRANSIT);
    }

    public void onPrevNavClicked(View view) {
        if (navStatus == NavStatus.START) {
            //Do nothing
        } else if (navStatus == NavStatus.PROGRESS) {
            if (navRoute == null) {
                return;
            }
            if (currentStepIndex > 0) {
                moveTo(currentLegIndex, --currentStepIndex);
            } else if (currentLegIndex > 0) {
                currentLegIndex--;
                List<NavRouteLeg> routeLegs = navRoute.getLegs();
                NavRouteLeg currentLeg = routeLegs.get(currentLegIndex);
                List<NavRouteStep> routeSteps = currentLeg.getSteps();
                int stepsSize = routeSteps.size();
                currentStepIndex = stepsSize - 1;
                moveTo(currentLegIndex, currentStepIndex);
            } else {
                navStatus = NavStatus.START;
            }
        } else if (navStatus == NavStatus.FINISHED) {
            navStatus = NavStatus.PROGRESS;
            moveTo(currentLegIndex, currentStepIndex);
        }
        updateNavAutoUpdate();
        updateNav();
    }

    public void onNextNavClicked(View view) {
        if (navStatus == NavStatus.START) {
            navStatus = NavStatus.PROGRESS;
            currentLegIndex = 0;
            currentStepIndex = 0;
            moveTo(currentLegIndex, currentStepIndex);
            notifyRouteStart();
        } else if (navStatus == NavStatus.PROGRESS) {
            if (navRoute == null) {
                return;
            }
            List<NavRouteLeg> routeLegs = navRoute.getLegs();
            int legsSize = routeLegs.size();
            NavRouteLeg currentLeg = routeLegs.get(currentLegIndex);
            List<NavRouteStep> routeSteps = currentLeg.getSteps();
            int stepsSize = routeSteps.size();
            if ((currentStepIndex + 1) < stepsSize) {
                moveTo(currentLegIndex, ++currentStepIndex);
            } else if ((currentLegIndex + 1) < legsSize) {
                currentStepIndex = 0;
                currentLegIndex++;
                moveTo(currentLegIndex, currentStepIndex);
            } else {
                navStatus = NavStatus.FINISHED;
                notifyRouteFinish();
            }
        } else if (navStatus == NavStatus.FINISHED) {/*Do nothing*/}
        updateNavAutoUpdate();
        updateNav();
    }

    private void buildTravelModes() {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
        String selectedTravelMode = Utils.Map.getValueFromPath(options, "travelMode", (String)null);
        if (selectedTravelMode == null) {
            selectedTravelMode = preferences.getString(TRAVEL_MODE_PREFS_KEY, Navigation.TRAVEL_MODE_WALKING);
        }
        travelModesMap = new HashMap<>();
        for (String currentTravelMode : TRAVEL_MODES) {
            View travelModeView = null;
            switch (currentTravelMode) {
                case Navigation.TRAVEL_MODE_WALKING:
                    travelModeView = findViewById(R.id.walkTravelModeButton);
                    break;
                case Navigation.TRAVEL_MODE_BICYCLING:
                    travelModeView = findViewById(R.id.bikeTravelModeButton);
                    break;
                case Navigation.TRAVEL_MODE_DRIVING:
                    travelModeView = findViewById(R.id.driveTravelModeButton);
                    break;
                case Navigation.TRAVEL_MODE_TRANSIT:
                    travelModeView = findViewById(R.id.transitTravelModeButton);
                    break;
                default:
                    break;
            }
            if (travelModeView != null) {
                travelModesMap.put(currentTravelMode, travelModeView);
                if (currentTravelMode.equals(selectedTravelMode)) {
                    this.selectedTravelMode = selectedTravelMode;
                    travelModeView.setBackgroundResource(R.color.grey40);
                }
            }
        }
    }

    private void buildRoute() {
        if (selectedTravelMode == null) {
            selectedTravelMode = Navigation.TRAVEL_MODE_WALKING;
        }
        buildRoute(selectedTravelMode);
    }

    private void buildRoute(String travelModeValue) {
        showLoadingFrame(true);
        if (travelModeValue == null || travelModeValue.isEmpty()) {
            travelModeValue = Navigation.TRAVEL_MODE_WALKING;
        }
        NavCoord originCoord = (coreLocation != null) ? new NavCoord(coreLocation.getLatitude(), coreLocation.getLongitude()) : null;
        NavCoord destinationCoord = getRouteDestinationCoord();
        if (originCoord == null || destinationCoord == null) {
            showLoadingFrame(false);
            Log.e(TAG, "buildRoute() -> origin or destination coordinate is null!");
            String routeFailedMsg = String.format(getString(R.string.routeFailedMsg), "");
            showAlert(routeFailedMsg);
            return;
        }
        navigation.findRoutesFromOrigin(originCoord, destinationCoord, travelModeValue);
    }

    /***
     * Calculates route destination {@link NavCoord} based on explore type.
     * @return parking entrance if explore is Parking, explore location - otherwise
     */
    private NavCoord getRouteDestinationCoord() {
        Utils.ExploreType exploreType = Utils.Explore.getExploreType(explore);
        LatLng destinationLatLng = null;

        if (exploreType == Utils.ExploreType.PARKING) {
            HashMap exploreMap = (HashMap) explore;
            destinationLatLng = Utils.Explore.optLocationLatLng(exploreMap);
            if (destinationLatLng != null) {
                return new NavCoord(destinationLatLng.latitude, destinationLatLng.longitude);
            }
        }
        destinationLatLng = Utils.Explore.optLatLng(exploreLocation);
        if (destinationLatLng != null) {
            return new NavCoord(destinationLatLng.latitude, destinationLatLng.longitude);
        } else {
            return null;
        }
    }

    private void changeSelectedTravelMode(String newTravelMode) {
        if (newTravelMode != null) {
            navRoute = null;
            navRouteError = null;
            if (routePolyline != null) {
                routePolyline.remove();
                routePolyline = null;
            }
            removeMarker(segmentStartMarker);
            segmentStartMarker = null;
            removeMarker(segmentEndMarker);
            segmentEndMarker = null;
            removePolyline(segmentPolyline);
            segmentPolyline = null;
            routeStepCoordCounts = null;
            navStatus = NavStatus.UNKNOWN;
            navAutoUpdate = false;
            if (travelModesMap != null) {
                for (String travelMode : travelModesMap.keySet()) {
                    View travelModeView = travelModesMap.get(travelMode);
                    if (travelModeView != null) {
                        int backgroundResource = (newTravelMode.equals(travelMode)) ? R.color.grey40 : 0;
                        travelModeView.setBackgroundResource(backgroundResource);
                    }
                }
            }
            updateNav();
            selectedTravelMode = newTravelMode;
            buildRoute(newTravelMode);

            SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
            SharedPreferences.Editor editor = preferences.edit();
            editor.putString(TRAVEL_MODE_PREFS_KEY, selectedTravelMode);
            editor.apply();
        }
    }

    private void handleFirstLocationUpdate() {
        if (exploreLocation == null) {
            if (coreLocation != null) {
                LatLng cameraPosition = new LatLng(coreLocation.getLatitude(), coreLocation.getLongitude());
                if (googleMap != null) {
                    googleMap.moveCamera(CameraUpdateFactory.newLatLng(cameraPosition));
                }
            }
        } else if (coreLocation == null) {
            showLoadingFrame(false);
            LatLng cameraPosition = Utils.Explore.optLatLng(exploreLocation);
            if ((googleMap != null) && (cameraPosition != null)) {
                googleMap.moveCamera(CameraUpdateFactory.newLatLng(cameraPosition));
            }
            String errorMessage = getString(R.string.locationFailedMsg);
            showAlert(errorMessage);
        } else {
            if (!isNavRouteLoading() && (navRoute == null) && (navRouteError == null)) {
                if (googleMap != null) {
                    buildRoute();
                } else {
                    buildRouteAfterInitialization = true;
                }
            }
        }
    }

    private void didBuildRoute() {
        showLoadingFrame(false);
        if (navRoute != null) {
            buildRoutePolyline();
            cameraPosition = googleMap.getCameraPosition();
            navStatus = NavStatus.START;
        } else {
            String routeFailedMsg = String.format(getString(R.string.routeFailedMsg), (navRouteError != null) ? navRouteError : "");
            showAlert(routeFailedMsg);
        }

        updateNav();

        LatLngBounds routeBounds = buildRouteBounds();
        if (routeBounds != null) {
            googleMap.moveCamera(CameraUpdateFactory.newLatLngBounds(routeBounds, 50));
        }
    }

    private LatLngBounds buildRouteBounds() {
        LatLngBounds routeBounds = null;
        LatLng currentLatLng = (coreLocation != null) ? new LatLng(coreLocation.getLatitude(), coreLocation.getLongitude()) : null;
        if (currentLatLng != null) {
            LatLng exploreLatLng = Utils.Explore.optLatLng(exploreLocation);
            LatLngBounds.Builder latLngBuilder = new LatLngBounds.Builder();
            latLngBuilder.include(currentLatLng);
            latLngBuilder.include(exploreLatLng);
            if (navRoute != null && navRoute.getBounds() != null) {
                NavBounds routeLatLngBounds = navRoute.getBounds();
                if (routeLatLngBounds != null) {
                    latLngBuilder.include(routeLatLngBounds.getNortheast().toLatLng());
                    latLngBuilder.include(routeLatLngBounds.getSouthwest().toLatLng());
                }
            }
            routeBounds = latLngBuilder.build();
        }
        return routeBounds;
    }

    private void buildRoutePolyline() {
        routeStepCoordCounts = new ArrayList<>();
        List<LatLng> routePoints = new ArrayList<>();
        for (NavRouteLeg routeLeg : navRoute.getLegs()) {
            for (NavRouteStep routeStep : routeLeg.getSteps()) {
                NavPolyline routePolyline = routeStep.getPolyline();
                if (routePolyline != null) {
                    List<LatLng> polylinePoints = routePolyline.getLatLngCoordinates();
                    if (polylinePoints != null) {
                        routePoints.addAll(polylinePoints);
                        routeStepCoordCounts.add(polylinePoints.size());
                    }
                }
            }
        }
        if (googleMap != null) {
            routePolyline = googleMap.addPolyline(new PolylineOptions().addAll(routePoints));
        }
    }

    private Polyline placePolylineForStep(Polyline polyline, NavRouteStep step) {
        List<LatLng> coordinates = ((step != null) && (step.getPolyline() != null)) ? step.getPolyline().getLatLngCoordinates() : null;
        if (coordinates == null) {
            removePolyline(polyline);
            return null;
        }
        if (polyline != null) {
            polyline.setPoints(coordinates);
            return polyline;
        } else {
            return googleMap.addPolyline(new PolylineOptions().addAll(coordinates).color(Color.parseColor("#3474d6")));
        }
    }

    private void removePolyline(Polyline polyline) {
        if (polyline != null) {
            polyline.remove();
        }
    }

    private Marker placeMarkerTo(Marker marker, LatLng latLng) {
        if (latLng == null) {
            removeMarker(marker);
            return null;
        }
        if (marker != null) {
            marker.setPosition(latLng);
            return marker;
        } else {
            return googleMap.addMarker(buildSegmentMarkerOptions(latLng));
        }
    }

    private void removeMarker(Marker marker) {
        if (marker != null) {
            marker.remove();
        }
    }

    private MarkerOptions buildSegmentMarkerOptions(LatLng location) {
        MarkerOptions markerOptions = new MarkerOptions();
        markerOptions.position(location);
        markerOptions.visible(true);
        markerOptions.icon(BitmapDescriptorFactory.fromResource(R.drawable.marker_segment_directions));
        markerOptions.anchor(0.5f, 0.5f);
        return markerOptions;
    }

    private void moveTo(int legIndex, int stepIndex) {
        NavRouteLeg leg = ((legIndex >= 0) && (legIndex < navRoute.getLegs().size())) ? navRoute.getLegs().get(legIndex) : null;
        NavRouteStep step = ((stepIndex >= 0) && (leg != null) && (leg.getSteps() != null) && (stepIndex < leg.getSteps().size())) ? leg.getSteps().get(stepIndex) : null;

        CameraUpdate cameraUpdate;

        if (step != null) {
            LatLng startLocation = step.getStartLocation().toLatLng();
            LatLng endLocation = step.getEndLocation().toLatLng();
            segmentStartMarker = placeMarkerTo(segmentStartMarker, startLocation);
            if (!startLocation.equals(endLocation)) {
                segmentEndMarker = placeMarkerTo(segmentEndMarker, endLocation);
                segmentPolyline = placePolylineForStep(segmentPolyline, step);
                LatLngBounds.Builder latLngBuilder = new LatLngBounds.Builder();
                latLngBuilder.include(startLocation);
                latLngBuilder.include(endLocation);
                cameraUpdate = CameraUpdateFactory.newLatLngBounds(latLngBuilder.build(), 50);
            } else {
                removeMarker(segmentEndMarker);
                removePolyline(segmentPolyline);
                cameraUpdate = CameraUpdateFactory.newLatLngZoom(startLocation, googleMap.getCameraPosition().zoom);
            }
        } else {
            removeMarker(segmentStartMarker);
            removeMarker(segmentEndMarker);
            removePolyline(segmentPolyline);
            LatLngBounds routeBounds = buildRouteBounds();
            cameraUpdate = CameraUpdateFactory.newLatLngBounds(routeBounds, 50);
        }
        googleMap.animateCamera(cameraUpdate);
    }

    private void updateNav() {
        navRefreshButton.setVisibility(View.VISIBLE);
        enableView(navRefreshButton, true);

        int travelModesVisibility = ((navStatus != NavStatus.UNKNOWN) && (navStatus != NavStatus.START)) ? View.GONE : View.VISIBLE;
        navTravelModesContainer.setVisibility(travelModesVisibility);
        enableView(navTravelModesContainer, true);

        int autoUpdateVisibility = ((navStatus != NavStatus.PROGRESS) || navAutoUpdate) ? View.GONE : View.VISIBLE;
        navAutoUpdateButton.setVisibility(autoUpdateVisibility);
        int navBottomVisibility = (navStatus == NavStatus.UNKNOWN) ? View.GONE : View.VISIBLE;
        navPrevButton.setVisibility(navBottomVisibility);
        navNextButton.setVisibility(navBottomVisibility);
        navStepLabel.setVisibility(navBottomVisibility);

        if (navStatus == NavStatus.START) {
            String routeDisplayDescription = buildRouteDisplayDescription();
            boolean hasDescription = (routeDisplayDescription != null) && !routeDisplayDescription.isEmpty();
            String secondRow = hasDescription ? String.format("<br>(%s)", routeDisplayDescription) : "";
            String stepHtmlContent = String.format("<b>%s</b>%s", getString(R.string.start), secondRow);
            setStepHtml(stepHtmlContent);
            enableView(navPrevButton, false);
            enableView(navNextButton, true);
        } else if (navStatus == NavStatus.PROGRESS) {
            List<NavRouteLeg> routeLegs = navRoute.getLegs();
            NavRouteLeg leg = (currentLegIndex >= 0 && currentLegIndex < routeLegs.size()) ? routeLegs.get(currentLegIndex) : null;
            List<NavRouteStep> routeSteps = (leg != null) ? leg.getSteps() : null;
            NavRouteStep step = ((routeSteps != null) && (currentStepIndex >= 0) && (currentStepIndex < routeSteps.size())) ?
                    routeSteps.get(currentStepIndex) : null;
            if (step != null) {
                if (step.getHtmlInstructions() != null) {
                    setStepHtml(step.getHtmlInstructions());
                } else if (step.getManeuver() != null) {
                    navStepLabel.setText(step.getManeuver());
                } else if (!Utils.Str.isEmpty(step.getDistance().getText()) || !Utils.Str.isEmpty(step.getDuration().getText())) {
                    String plainStepText = String.format("%s / %s", step.getDistance().getText(), step.getDuration().getText());
                    navStepLabel.setText(plainStepText);
                }
            } else {
                String plainStepText = String.format(getString(R.string.routeLegStepFormat), (currentLegIndex + 1), (currentStepIndex + 1));
                navStepLabel.setText(plainStepText);
            }

            enableView(navPrevButton, true);
            enableView(navNextButton, true);

        } else if (navStatus == NavStatus.FINISHED) {
            String htmlContent = String.format("<b>%s</b>", getString(R.string.finish));
            setStepHtml(htmlContent);
            enableView(navPrevButton, true);
            enableView(navNextButton, false);
        }
    }

    private void updateNavAutoUpdate() {
        NavRouteSegmentPath segmentPath = findNearestRouteSegmentByCurrentLocation();
        navAutoUpdate = (isValidSegmentPath(segmentPath) &&
                (currentLegIndex == segmentPath.legIndex) &&
                (currentStepIndex == segmentPath.stepIndex));
    }

    private void updateNavByCurrentLocation() {
        if ((navStatus == NavStatus.PROGRESS) && navAutoUpdate &&
                (coreLocation != null) && (navRoute != null)) {
            NavRouteSegmentPath segmentPath = findNearestRouteSegmentByCurrentLocation();
            if (isValidSegmentPath(segmentPath)) {
                updateNavFromSegmentPath(segmentPath);
            }
        }
    }

    private void updateNavFromSegmentPath(NavRouteSegmentPath segmentPath) {
        boolean modified = false;
        if (currentLegIndex != segmentPath.legIndex) {
            currentLegIndex = segmentPath.legIndex;
            modified = true;
        }
        if (currentStepIndex != segmentPath.stepIndex) {
            currentStepIndex = segmentPath.stepIndex;
            modified = true;
        }
        if (modified) {
            moveTo(currentLegIndex, currentStepIndex);
            updateNav();
        }
    }

    @NonNull
    private NavRouteSegmentPath findNearestRouteSegmentByCurrentLocation() {
        NavRouteSegmentPath minRouteSegmentPath = new NavRouteSegmentPath(-1, -1);
        if ((coreLocation != null) && (navRoute != null)) {
            double minLegDistance = -1;
            LatLng locationLatLng = new LatLng(coreLocation.getLatitude(), coreLocation.getLongitude());
            int globalStepIndex = 0;
            int locationIndex = 0;
            List<LatLng> routePolylinePoints = routePolyline.getPoints();
            List<NavRouteLeg> routeLegs = navRoute.getLegs();
            for (int legIndex = 0; legIndex < routeLegs.size(); legIndex++) {
                NavRouteLeg routeLeg = routeLegs.get(legIndex);
                List<NavRouteStep> legSteps = routeLeg.getSteps();
                for (int stepIndex = 0; stepIndex < legSteps.size(); stepIndex++) {
                    int increasedIndex = (globalStepIndex < routeStepCoordCounts.size()) ? routeStepCoordCounts.get(globalStepIndex) : 0;
                    int lastLocationIndex = locationIndex + increasedIndex;
                    while (locationIndex < lastLocationIndex) {
                        LatLng latLng = routePolylinePoints.get(locationIndex);
                        Double coordDistance = Utils.Location.getDistanceBetween(locationLatLng, latLng);
                        if (coordDistance != null && (minLegDistance < 0.0d || coordDistance < minLegDistance)) {
                            minLegDistance = coordDistance;
                            minRouteSegmentPath = new NavRouteSegmentPath(legIndex, stepIndex);
                            locationIndex = lastLocationIndex;
                            break;
                        }
                        locationIndex++;
                    }
                    globalStepIndex++;
                }
            }
        }
        return minRouteSegmentPath;
    }

    private boolean isValidSegmentPath(NavRouteSegmentPath segmentPath) {
        if (navRoute == null || segmentPath == null) {
            return false;
        }
        List<NavRouteLeg> routeLegs = navRoute.getLegs();
        if ((segmentPath.legIndex >= 0) && (segmentPath.legIndex < routeLegs.size())) {
            NavRouteLeg leg = routeLegs.get(segmentPath.legIndex);
            return (segmentPath.stepIndex >= 0) && (segmentPath.stepIndex < leg.getSteps().size());
        }
        return false;
    }

    private void setStepHtml(String htmlContent) {
        String formattedHtml = String.format("<html><body><center>%s</center></body></html>", htmlContent);
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            navStepLabel.setText(Html.fromHtml(formattedHtml, Html.FROM_HTML_MODE_COMPACT));
        } else {
            navStepLabel.setText(Html.fromHtml(formattedHtml));
        }
    }

    private String buildRouteDisplayDescription() {
        if (navRoute == null) {
            return null;
        }
        StringBuilder descriptionBuilder = new StringBuilder();

        // Distance
        String displayDistance = null;
        if (navRoute.getLegs().size() == 1) {
            displayDistance = navRoute.getLegs().get(0).getDistance().getText();
        } else if ((navRoute.getDistance() != null) && (navRoute.getDistance() > 0)) {
            // 1 foot = 0.3048 meters
            // 1 mile = 1609.34 meters

            long totalMeters = Math.abs(navRoute.getDistance());
            double totalMiles = (totalMeters / 1609.34d);
            if (descriptionBuilder.length() > 0) {
                descriptionBuilder.append(", ");
            }
            displayDistance = String.format(Locale.getDefault(), "%.1f %s", totalMiles, getString((totalMiles != 1.0) ? R.string.miles : R.string.mile));
        }
        if (!Utils.Str.isEmpty(displayDistance)) {
            descriptionBuilder.append(displayDistance);
        }

        // Duration
        String displayDuration = null;
        if (navRoute.getLegs().size() == 1) {
            displayDuration = navRoute.getLegs().get(0).getDuration().getText();
        } else if ((navRoute.getDuration() != null) && (navRoute.getDuration() > 0)) {
            long totalSeconds = Math.abs(navRoute.getDuration());
            long totalMinutes = totalSeconds / 60;
            long totalHours = totalMinutes / 60;
            long minutes = totalMinutes % 60;

            String formattedTime;
            if (totalHours < 1) {
                formattedTime = String.format(Locale.getDefault(), "%d %s", minutes, getString(R.string.minute));
            } else if (totalHours < 24) {
                formattedTime = String.format(Locale.getDefault(), "%d h %2d %s", totalHours, minutes, getString(R.string.minute));
            } else {
                formattedTime = String.format(Locale.getDefault(), "%d h", totalHours);
            }
            displayDuration = formattedTime;
        }

        if (!Utils.Str.isEmpty(displayDuration)) {
            if (descriptionBuilder.length() > 0) {
                descriptionBuilder.append(", ");
            }
            descriptionBuilder.append(displayDuration);
        }

        String routeSummary = navRoute.getSummary();
        if ((descriptionBuilder.length() == 0) && !Utils.Str.isEmpty(routeSummary)) {
            descriptionBuilder.append(routeSummary);
        }
        return descriptionBuilder.toString();
    }

    private void notifyRouteStart() {
        notifyRouteEvent("map.route.start");
    }

    private void notifyRouteFinish() {
        notifyRouteEvent("map.route.finish");
    }

    private void notifyRouteEvent(String event) {
        String originString = null;
        String destinationString = null;
        String locationString = null;
        List<NavRouteLeg> routeLegs = (navRoute != null) ? navRoute.getLegs() : null;
        int legsCount = (routeLegs != null && routeLegs.size() > 0) ? routeLegs.size() : 0;
        if (legsCount > 0) {
            NavCoord origin = routeLegs.get(0).getStartLocation();
            NavCoord destination = routeLegs.get(legsCount - 1).getEndLocation();
            originString = String.format(Locale.getDefault(), Constants.ANALYTICS_ROUTE_LOCATION_FORMAT, origin.getLat(), origin.getLng());
            destinationString = String.format(Locale.getDefault(), Constants.ANALYTICS_ROUTE_LOCATION_FORMAT, destination.getLat(), destination.getLng());
        }
        if (coreLocation != null) {
            locationString = String.format(Locale.getDefault(), Constants.ANALYTICS_USER_LOCATION_FORMAT, coreLocation.getLatitude(), coreLocation.getLongitude(), coreLocation.getTime());
        }
        String analyticsParam = String.format(Locale.getDefault(), "{\"origin\":%s,\"destination\":%s,\"location\":%s}", originString, destinationString, locationString);
        MainActivity.invokeFlutterMethod(event, analyticsParam);
    }

    //endregion

    //region Route Navigation

    private void initNavigation() {
        this.navigation = new Navigation(this, this);
    }

    @Override
    public void onNavigationResponse(List<NavRoute> routes, String errorResponse) {
        navRoute = (routes != null) ? routes.get(0) : null;
        navRouteError = errorResponse;
        didBuildRoute();
    }

    //endregion

    //region Utilities

    private void showLoadingFrame(boolean show) {
        if (routeLoadingFrame != null) {
            routeLoadingFrame.setVisibility(show ? View.VISIBLE : View.GONE);
        }
    }

    private boolean isNavRouteLoading() {
        return (routeLoadingFrame != null) && (routeLoadingFrame.getVisibility() == View.VISIBLE);
    }

    private void showAlert(String message) {
        String appName = getString(R.string.app_name);
        AlertDialog.Builder alertBuilder = new AlertDialog.Builder(this);
        alertBuilder.setTitle(appName);
        alertBuilder.setMessage(message);
        alertBuilder.setPositiveButton(R.string.ok, null);
        alertBuilder.show();
    }

    private void enableView(View view, boolean enabled) {
        if (view == null) {
            return;
        }
        float viewAlpha = enabled ? 1.0f : 0.5f;
        view.setEnabled(enabled);
        view.setAlpha(viewAlpha);
    }

    //endregion

    //region NavStatus

    private enum NavStatus {UNKNOWN, START, PROGRESS, FINISHED}

    //endregion

    //region NavRouteSegmentPath

    private static class NavRouteSegmentPath {
        private final int legIndex;
        private final int stepIndex;

        private NavRouteSegmentPath(int legIndex, int stepIndex) {
            this.legIndex = legIndex;
            this.stepIndex = stepIndex;
        }
    }

    //endregion
}
