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

import android.content.Context;
import android.content.SharedPreferences;
import android.graphics.Color;
import android.location.Location;
import android.os.Build;
import android.os.Bundle;
import android.preference.PreferenceManager;
import android.text.Html;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.appcompat.app.AlertDialog;

import com.google.android.gms.maps.CameraUpdateFactory;
import com.google.android.gms.maps.model.CameraPosition;
import com.google.android.gms.maps.model.LatLng;
import com.google.android.gms.maps.model.LatLngBounds;
import com.google.android.gms.maps.model.Marker;
import com.google.android.gms.maps.model.MarkerOptions;
import com.google.android.gms.maps.model.PolygonOptions;
import com.google.android.gms.maps.model.Polyline;
import com.google.android.gms.maps.model.PolylineOptions;
import com.google.maps.android.ui.IconGenerator;
import com.mapsindoors.mapssdk.MPDirectionsRenderer;
import com.mapsindoors.mapssdk.MPPositionResult;
import com.mapsindoors.mapssdk.MPRoutingProvider;
import com.mapsindoors.mapssdk.OnLegSelectedListener;
import com.mapsindoors.mapssdk.OnRouteResultListener;
import com.mapsindoors.mapssdk.Point;
import com.mapsindoors.mapssdk.Route;
import com.mapsindoors.mapssdk.RouteCoordinate;
import com.mapsindoors.mapssdk.RouteLeg;
import com.mapsindoors.mapssdk.RoutePolyline;
import com.mapsindoors.mapssdk.RouteStep;
import com.mapsindoors.mapssdk.TravelMode;
import com.mapsindoors.mapssdk.errors.MIError;

import org.json.JSONObject;

import java.io.Serializable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;

import edu.illinois.rokwire.Constants;
import edu.illinois.rokwire.MainActivity;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;

public class MapDirectionsActivity extends MapActivity implements OnRouteResultListener, OnLegSelectedListener {

    //region Class fields

    //Explores - could be Event, Dining, Laundry or ParkingLotInventory
    private Object explore;
    private HashMap exploreLocation;
    private Marker exploreMarker;
    private IconGenerator iconGenerator;
    private View markerLayoutView;
    private View markerGroupLayoutView;
    private float cameraZoom;

    //Navigation
    private Route mpRoute;
    private CameraPosition cameraPosition;
    private MPDirectionsRenderer mpDirectionsRenderer;
    private MPRoutingProvider mpRoutingProvider;
    private MIError mpRouteError;
    private List<Integer> mpRouteStepCoordCounts;
    private Polyline routePolyline;
    private NavStatus navStatus = NavStatus.UNKNOWN;
    private boolean navAutoUpdate;
    private int currentLegIndex = 0;
    private int currentStepIndex = -1;
    private boolean buildRouteAfterInitialization;

    //Navigation UI
    private static final String TRAVEL_MODE_PREFS_KEY = "directions.travelMode";
    private static final String[] TRAVEL_MODES = {TravelMode.WALKING, TravelMode.BICYCLING,
            TravelMode.DRIVING, TravelMode.TRANSIT};
    private String selectedTravelMode;
    private Map<String, View> travelModesMap;
    private View navRefreshButton;
    private View navTravelModesContainer;
    private View navAutoUpdateButton;
    private View navPrevButton;
    private View navNextButton;
    private TextView navStepLabel;
    private View routeLoadingFrame;

    //endregion

    //region Activity methods

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        initExplore();
        buildTravelModes();
    }

    //endregion

    //region Map views initialization

    @Override
    protected void afterMapControlInitialized() {
        super.afterMapControlInitialized();
        buildExploreMarker();
        buildPolygon();
        if (buildRouteAfterInitialization) {
            buildRouteAfterInitialization = false;
            buildRoute();
        }
    }

    //endregion

    //region Meridian

    @Override
    protected void initMeridian() {
        super.initMeridian();
        updateNav();
        showLoadingFrame(true);
    }

    //endregion

    //region MapsIndoors

    @Override
    protected boolean onMarkerClicked(Marker marker) {
        Object exploreMarkerRawData = Utils.Explore.optExploreMarkerRawData(marker);
        return (exploreMarkerRawData != null);
    }

    @Override
    protected void onFloorChanged(int floor) {
        super.onFloorChanged(floor);
        updateExploreMarkerVisibility();
    }

    @Override
    protected void onCameraIdle() {
        super.onCameraIdle();
        updateExploreMarkerAppearance();
    }

    /**
     * OnRouteResultListener
     */

    @Override
    public void onRouteResult(@Nullable Route route, @Nullable MIError miError) {
        // Workaround for multiple calling 'onRouteResult' from MapsIndoors sdk
        if (mpRoutingProvider == null) {
            return;
        }
        mpRoutingProvider.setOnRouteResultListener(null);
        mpRoutingProvider = null;
        mpRoute = route;
        mpRouteError = miError;
        runOnUiThread(this::didBuildRoute);
    }

    /**
     * OnLegSelectedListener
     */

    @Override
    public void onLegSelected(int i) {
        Log.d(getLogTag(), "OnLegSelectedListener.onLegSelected");
    }

    //endregion

    //region Common Location

    @Override
    protected void notifyLocationUpdate(MPPositionResult positionResult, MPPositionProviderSource source, long timestamp) {
        super.notifyLocationUpdate(positionResult, source, timestamp);
        if (positionResult != null) {
            if ((navStatus == NavStatus.PROGRESS) && navAutoUpdate) {
                updateNavByCurrentLocation();
            }
        }
    }

    @Override
    protected void notifyLocationFail() {
        super.notifyLocationFail();
        if (mpPositionResult == null) {
            handleFirstLocationUpdate();
        }
    }

    @Override
    protected void onLocationTimerTimeout() {
        super.onLocationTimerTimeout();
        if (mrLocation == null && coreLocation == null) {
            runOnUiThread(() -> {
                enableView(navPrevButton, false);
                enableView(navNextButton, false);
                showLoadingFrame(false);
                showAlert(getString(R.string.locationFailedMsg));
            });
        }
    }

    //endregion

    //region Explores

    private void initExplore() {
        Serializable exploreSeriazible = getIntent().getSerializableExtra("explore");
        if (exploreSeriazible == null) {
            return;
        }
        if (exploreSeriazible instanceof HashMap) {
            HashMap singleExplore;
            singleExplore = (HashMap) exploreSeriazible;
            this.explore = singleExplore;
            initExploreLocation(singleExplore);
        } else if (exploreSeriazible instanceof ArrayList) {
            ArrayList explores = (ArrayList) exploreSeriazible;
            this.explore = explores;
            Object firstExplore = (explores.size() > 0) ? explores.get(0) : null;
            if (firstExplore instanceof HashMap) {
                initExploreLocation((HashMap) firstExplore);
            }
        }
    }

    @Override
    protected void initUiViews() {
        super.initUiViews();
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

    private void updateExploreMarkerVisibility() {
        if (exploreMarker == null) {
            return;
        }
        int currentFloorIndex = (mapControl != null) ? mapControl.getCurrentFloorIndex() : 0;
        Integer markerFloor = Utils.Explore.optMarkerLocationFloor(exploreMarker);
        boolean markerVisible = (markerFloor == null) || (currentFloorIndex == markerFloor);
        exploreMarker.setVisible(markerVisible);
    }

    private void initExploreLocation(HashMap singleExplore) {
        Utils.ExploreType exploreType = Utils.Explore.getExploreType(singleExplore);
        if (exploreType == Utils.ExploreType.PARKING) {
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
        mpRoute = null;
        mpRouteError = null;
        if (routePolyline != null) {
            routePolyline.remove();
            routePolyline = null;
        }
        mpRouteStepCoordCounts = null;
        if (mpDirectionsRenderer != null) {
            mpDirectionsRenderer.clear();
            mpDirectionsRenderer = null;
        }
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
            MPRouteSegmentPath segmentPath = findNearestRouteSegmentByCurrentLocation();
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
        changeSelectedTravelMode(TravelMode.WALKING);
    }

    public void onBikeTravelModeClicked(View view) {
        changeSelectedTravelMode(TravelMode.BICYCLING);
    }

    public void onDriveTravelModeClicked(View view) {
        changeSelectedTravelMode(TravelMode.DRIVING);
    }

    public void onTransitTravelModeClicked(View view) {
        changeSelectedTravelMode(TravelMode.TRANSIT);
    }

    public void onPrevNavClicked(View view) {
        if (navStatus == NavStatus.START) {
            //Do nothing
        } else if (navStatus == NavStatus.PROGRESS) {
            if (mpRoute == null) {
                return;
            }
            if (currentStepIndex > 0) {
                moveTo(currentLegIndex, --currentStepIndex);
            } else if (currentLegIndex > 0) {
                currentLegIndex--;
                List<RouteLeg> routeLegs = mpRoute.getLegs();
                RouteLeg currentLeg = routeLegs.get(currentLegIndex);
                List<RouteStep> routeSteps = currentLeg.getSteps();
                int stepsSize = routeSteps.size();
                currentStepIndex = stepsSize - 1;
                moveTo(currentLegIndex, currentStepIndex);
            } else {
                navStatus = NavStatus.START;
                mpDirectionsRenderer.clear();
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
            if (mpRoute == null) {
                return;
            }
            List<RouteLeg> routeLegs = mpRoute.getLegs();
            int legsSize = routeLegs.size();
            RouteLeg currentLeg = routeLegs.get(currentLegIndex);
            List<RouteStep> routeSteps = currentLeg.getSteps();
            int stepsSize = routeSteps.size();
            if ((currentStepIndex + 1) < stepsSize) {
                moveTo(currentLegIndex, ++currentStepIndex);
            } else if ((currentLegIndex + 1) < legsSize) {
                currentStepIndex = 0;
                currentLegIndex++;
                moveTo(currentLegIndex, currentStepIndex);
            } else {
                navStatus = NavStatus.FINISHED;
                mpDirectionsRenderer.clear();
                notifyRouteFinish();
            }
        } else if (navStatus == NavStatus.FINISHED) {/*Do nothing*/}
        updateNavAutoUpdate();
        updateNav();
    }

    private void buildTravelModes() {
        SharedPreferences preferences = PreferenceManager.getDefaultSharedPreferences(this);
        String selectedTravelMode = preferences.getString(TRAVEL_MODE_PREFS_KEY, TravelMode.WALKING);
        travelModesMap = new HashMap<>();
        for (String currentTravelMode : TRAVEL_MODES) {
            View travelModeView = null;
            switch (currentTravelMode) {
                case TravelMode.WALKING:
                    travelModeView = findViewById(R.id.walkTravelModeButton);
                    break;
                case TravelMode.BICYCLING:
                    travelModeView = findViewById(R.id.bikeTravelModeButton);
                    break;
                case TravelMode.DRIVING:
                    travelModeView = findViewById(R.id.driveTravelModeButton);
                    break;
                case TravelMode.TRANSIT:
                    travelModeView = findViewById(R.id.transitTravelModeButton);
                    break;
                default:
                    break;
            }
            travelModesMap.put(currentTravelMode, travelModeView);
            if (currentTravelMode.equals(selectedTravelMode)) {
                this.selectedTravelMode = selectedTravelMode;
                travelModeView.setBackgroundResource(R.color.grey40);
            }
        }
    }

    private void buildRoute() {
        if (selectedTravelMode == null) {
            selectedTravelMode = TravelMode.WALKING;
        }
        buildRoute(selectedTravelMode);
    }

    private void buildRoute(String travelModeValue) {
        showLoadingFrame(true);
        if (travelModeValue == null || travelModeValue.isEmpty()) {
            travelModeValue = TravelMode.WALKING;
        }
        Point originPoint = (mpPositionResult != null) ? mpPositionResult.getPoint() : null;
        Point destinationPoint = getRouteDestinationPoint();
        if (originPoint == null || destinationPoint == null) {
            showLoadingFrame(false);
            Log.e(getLogTag(), "buildRoute() -> origin or destination point is null!");
            String routeFailedMsg = getString(R.string.routeFailedMsg);
            showAlert(routeFailedMsg);
            return;
        }
        mpRoutingProvider = new MPRoutingProvider();
        mpRoutingProvider.setOnRouteResultListener(this);
        mpRoutingProvider.setTravelMode(travelModeValue);
        mpRoutingProvider.query(originPoint, destinationPoint);
    }

    /***
     * Calculates route destination point based on explore type.
     * @return parking entrance if explore is Parking, explore location - otherwise
     */
    private Point getRouteDestinationPoint() {
        Utils.ExploreType exploreType = Utils.Explore.getExploreType(explore);
        LatLng destinationLatLng = null;

        if (exploreType == Utils.ExploreType.PARKING) {
            HashMap exploreMap = (HashMap) explore;
            destinationLatLng = Utils.Explore.optLocationLatLng(exploreMap);
            if (destinationLatLng != null) {
                return new Point(destinationLatLng.latitude, destinationLatLng.longitude, 0);
            }
        }
        destinationLatLng = Utils.Explore.optLatLng(exploreLocation);
        if (destinationLatLng != null) {
            Integer floor = Utils.Explore.optFloor(exploreLocation);
            return new Point(destinationLatLng.latitude, destinationLatLng.longitude, (floor != null ? floor : 0));
        } else {
            return null;
        }
    }

    private void changeSelectedTravelMode(String newTravelMode) {
        if (newTravelMode != null) {
            mpRoute = null;
            mpRouteError = null;
            if (routePolyline != null) {
                routePolyline.remove();
                routePolyline = null;
            }
            mpRoutingProvider = null;
            mpRouteStepCoordCounts = null;
            if (mpDirectionsRenderer != null) {
                mpDirectionsRenderer.clear();
                mpDirectionsRenderer = null;
            }
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

    @Override
    protected void handleFirstLocationUpdate() {
        if (exploreLocation == null) {
            if (mpPositionResult != null) {
                Location location = mpPositionResult.getAndroidLocation();
                if (location != null) {
                    LatLng cameraPosition = new LatLng(location.getLatitude(), location.getLongitude());
                    if (googleMap != null) {
                        googleMap.moveCamera(CameraUpdateFactory.newLatLng(cameraPosition));
                    }
                }
            }
        } else if (mpPositionResult == null) {
            showLoadingFrame(false);
            LatLng cameraPosition = Utils.Explore.optLatLng(exploreLocation);
            if ((googleMap != null) && (cameraPosition != null)) {
                googleMap.moveCamera(CameraUpdateFactory.newLatLng(cameraPosition));
            }
            String errorMessage = getString(R.string.locationFailedMsg);
            showAlert(errorMessage);
        } else {
            if ((mpRoutingProvider == null) && (mpRoute == null) && (mpRouteError == null)) {
                if ((mapControl != null) && mapControl.isReady()) {
                    buildRoute();
                } else {
                    buildRouteAfterInitialization = true;
                }
            }
        }
    }

    private void didBuildRoute() {
        showLoadingFrame(false);
        if (mpRoute != null) {
            buildRoutePolyline();
            mpDirectionsRenderer = new MPDirectionsRenderer(this, googleMap, mapControl, this);
            mpDirectionsRenderer.setRoute(mpRoute);
            cameraPosition = googleMap.getCameraPosition();
            navStatus = NavStatus.START;
        } else {
            String routeFailedMsg = getString(R.string.routeFailedMsg);
            showAlert(routeFailedMsg);
        }

        updateNav();

        Point point = mpPositionResult.getPoint();
        if (point != null) {
            LatLng currentLatLng = point.getLatLng();
            LatLng exploreLatLng = Utils.Explore.optLatLng(exploreLocation);
            LatLngBounds.Builder latLngBuilder = new LatLngBounds.Builder();
            latLngBuilder.include(currentLatLng);
            latLngBuilder.include(exploreLatLng);
            if (mpRoute != null && mpRoute.getBounds() != null) {
                Object routeBoundsObject = mpRoute.getBounds();
                if (routeBoundsObject instanceof LatLngBounds) {
                    LatLngBounds routeLatLngBounds = (LatLngBounds) routeBoundsObject;
                    latLngBuilder.include(routeLatLngBounds.northeast);
                    latLngBuilder.include(routeLatLngBounds.southwest);
                }
            }
            googleMap.moveCamera(CameraUpdateFactory.newLatLngBounds(latLngBuilder.build(), 50));
        }
    }

    private void buildRoutePolyline() {
        mpRouteStepCoordCounts = new ArrayList<>();
        List<LatLng> routePoints = new ArrayList<>();
        for (RouteLeg routeLeg : mpRoute.getLegs()) {
            for (RouteStep routeStep : routeLeg.getSteps()) {
                RoutePolyline routePolyline = routeStep.getPolyline();
                if (routePolyline != null) {
                    Point[] polylinePoints = routePolyline.getPoints();
                    for (Point point : polylinePoints) {
                        LatLng latLng = point.getLatLng();
                        routePoints.add(latLng);
                    }
                    mpRouteStepCoordCounts.add(polylinePoints.length);
                }
            }
        }
        if (googleMap != null) {
            routePolyline = googleMap.addPolyline(new PolylineOptions()
                    .addAll(routePoints)
                    .color(Color.BLUE));
        }
    }

    private void moveTo(int legIndex, int stepIndex) {
        if (mpDirectionsRenderer != null) {
            mpDirectionsRenderer.setRouteLegIndex(legIndex, stepIndex);
            mpDirectionsRenderer.animate(0, true);
        }
    }

    private void updateNav() {
        navRefreshButton.setVisibility(View.VISIBLE);
        enableView(navRefreshButton, (mpRoutingProvider == null));

        int travelModesVisibility = ((navStatus != NavStatus.UNKNOWN) && (navStatus != NavStatus.START)) ? View.GONE : View.VISIBLE;
        navTravelModesContainer.setVisibility(travelModesVisibility);
        enableView(navTravelModesContainer, (mpRoutingProvider == null));

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
            List<RouteLeg> routeLegs = mpRoute.getLegs();
            RouteLeg leg = (currentLegIndex >= 0 && currentLegIndex < routeLegs.size()) ? routeLegs.get(currentLegIndex) : null;
            List<RouteStep> routeSteps = (leg != null) ? leg.getSteps() : null;
            RouteStep step = ((routeSteps != null) && (currentStepIndex >= 0) && (currentStepIndex < routeSteps.size())) ?
                    routeSteps.get(currentStepIndex) : null;
            if (step != null) {
                if (step.getHtmlInstructions() != null) {
                    setStepHtml(step.getHtmlInstructions());
                } else if (step.getManeuver() != null || !step.getHighway().isEmpty() || !step.getAbutters().isEmpty()) {
                    String maneuver = (step.getManeuver() != null) ? step.getManeuver() : "";
                    String plainStepText = String.format("%s | %s | %s", maneuver, step.getHighway(), step.getAbutters());
                    navStepLabel.setText(plainStepText);
                } else if (step.getDistance() > 0.0f || step.getDuration() > 0.0f) {
                    String plainStepText = String.format(getString(R.string.routeDistanceDurationFormat), step.getDistance(), step.getDuration());
                    navStepLabel.setText(plainStepText);
                }
            } else {
                String plainStepText = String.format(getString(R.string.routeLegStepFormat), (currentLegIndex + 1), (currentStepIndex + 1));
                navStepLabel.setText(plainStepText);
            }

            enableView(navPrevButton, true);
            enableView(navNextButton, true);
            if (step != null) {
                updateCurrentFloor(step.getStartPoint().getZIndex());
            }

        } else if (navStatus == NavStatus.FINISHED) {
            String htmlContent = String.format("<b>%s</b>", getString(R.string.finish));
            setStepHtml(htmlContent);
            enableView(navPrevButton, true);
            enableView(navNextButton, false);
        }
    }

    private void updateCurrentFloor(int floor) {
        if (floor != mapControl.getCurrentFloorIndex()) {
            mapControl.selectFloor(floor);
            onFloorChanged(floor);
        }
    }

    private void updateNavAutoUpdate() {
        MPRouteSegmentPath segmentPath = findNearestRouteSegmentByCurrentLocation();
        navAutoUpdate = (isValidSegmentPath(segmentPath) &&
                (currentLegIndex == segmentPath.legIndex) &&
                (currentStepIndex == segmentPath.stepIndex));
    }

    private void updateNavByCurrentLocation() {
        if ((navStatus == NavStatus.PROGRESS) && navAutoUpdate &&
                (mpPositionResult != null) && (mpRoute != null) && (mpDirectionsRenderer != null)) {
            MPRouteSegmentPath segmentPath = findNearestRouteSegmentByCurrentLocation();
            if (isValidSegmentPath(segmentPath)) {
                updateNavFromSegmentPath(segmentPath);
            }
        }
    }

    private void updateNavFromSegmentPath(MPRouteSegmentPath segmentPath) {
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
    private MPRouteSegmentPath findNearestRouteSegmentByCurrentLocation() {
        MPRouteSegmentPath minRouteSegmentPath = new MPRouteSegmentPath(-1, -1);
        if (mpPositionResult != null && mpRoute != null) {
            double minLegDistance = -1;
            Point mpPoint = mpPositionResult.getPoint();
            if (mpPoint != null) {
                LatLng locationLatLng = mpPoint.getLatLng();
                int globalStepIndex = 0;
                int locationIndex = 0;
                List<LatLng> routePolylinePoints = routePolyline.getPoints();
                List<RouteLeg> routeLegs = mpRoute.getLegs();
                for (int legIndex = 0; legIndex < routeLegs.size(); legIndex++) {
                    RouteLeg routeLeg = routeLegs.get(legIndex);
                    List<RouteStep> legSteps = routeLeg.getSteps();
                    for (int stepIndex = 0; stepIndex < legSteps.size(); stepIndex++) {
                        int increasedIndex = (globalStepIndex < mpRouteStepCoordCounts.size()) ? mpRouteStepCoordCounts.get(globalStepIndex) : 0;
                        int lastLocationIndex = locationIndex + increasedIndex;
                        while (locationIndex < lastLocationIndex) {
                            LatLng latLng = routePolylinePoints.get(locationIndex);
                            Double coordDistance = Utils.Location.getDistanceBetween(locationLatLng, latLng);
                            if (coordDistance != null && (minLegDistance < 0.0d || coordDistance < minLegDistance)) {
                                minLegDistance = coordDistance;
                                minRouteSegmentPath = new MPRouteSegmentPath(legIndex, stepIndex);
                                locationIndex = lastLocationIndex;
                                break;
                            }
                            locationIndex++;
                        }
                        globalStepIndex++;
                    }
                }
            }
        }
        return minRouteSegmentPath;
    }

    private boolean isValidSegmentPath(MPRouteSegmentPath segmentPath) {
        if (mpRoute == null || segmentPath == null) {
            return false;
        }
        List<RouteLeg> routeLegs = mpRoute.getLegs();
        if ((segmentPath.legIndex >= 0) && (segmentPath.legIndex < routeLegs.size())) {
            RouteLeg leg = routeLegs.get(segmentPath.legIndex);
            if ((segmentPath.stepIndex >= 0) && segmentPath.stepIndex < leg.getSteps().size()) {
                return true;
            }
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
        if (mpRoute == null) {
            return null;
        }
        StringBuilder descriptionBuilder = new StringBuilder();

        if (mpRoute.getDistance() > 0) {
            // 1 foot = 0.3048 meters
            // 1 mile = 1609.34 meters

            long totalMeters = Math.abs(mpRoute.getDistance());
            double totalMiles = (totalMeters / 1609.34d);
            if (descriptionBuilder.length() > 0) {
                descriptionBuilder.append(", ");
            }
            descriptionBuilder.append(String.format(Locale.getDefault(), "%.1f %s", totalMiles, getString((totalMiles != 1.0) ? R.string.miles : R.string.mile)));
        }
        if (mpRoute.getDuration() > 0) {
            long totalSeconds = Math.abs(mpRoute.getDuration());
            long totalMinutes = totalSeconds / 60;
            long totalHours = totalMinutes / 60;
            long minutes = totalMinutes % 60;

            if (descriptionBuilder.length() > 0) {
                descriptionBuilder.append(", ");
            }
            String formattedTime;
            if (totalHours < 1) {
                formattedTime = String.format(Locale.getDefault(), "%d %s", minutes, getString(R.string.minute));
            } else if (totalHours < 24) {
                formattedTime = String.format(Locale.getDefault(), "%d h %2d %s", totalHours, minutes, getString(R.string.minute));
            } else {
                formattedTime = String.format(Locale.getDefault(), "%d h", totalHours);
            }
            descriptionBuilder.append(formattedTime);
        }

        String routeSummary = mpRoute.getSummary();
        if (routeSummary != null && !routeSummary.isEmpty()) {
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
        List<RouteLeg> routeLegs = (mpRoute != null) ? mpRoute.getLegs() : null;
        int legsCount = (routeLegs != null && routeLegs.size() > 0) ? routeLegs.size() : 0;
        if (legsCount > 0) {
            RouteCoordinate origin = routeLegs.get(0).getStartLocation();
            RouteCoordinate destination = routeLegs.get(legsCount - 1).getEndLocation();
            int originFloor = (int) origin.getZIndex();
            int destinationFloor = (int) destination.getZIndex();
            originString = String.format(Locale.getDefault(), Constants.ANALYTICS_ROUTE_LOCATION_FORMAT, origin.getLat(), origin.getLng(), originFloor);
            destinationString = String.format(Locale.getDefault(), Constants.ANALYTICS_ROUTE_LOCATION_FORMAT, destination.getLat(), destination.getLng(), destinationFloor);
        }
        if (mpPositionResult != null) {
            Point locationPoint = mpPositionResult.getPoint();
            int locationFloor = mpPositionResult.getFloor();
            if (locationPoint != null) {
                locationString = String.format(Locale.getDefault(), Constants.ANALYTICS_USER_LOCATION_FORMAT, locationPoint.getLat(), locationPoint.getLng(), locationFloor, locationTimestamp);
            }
        }
        String analyticsParam = String.format(Locale.getDefault(), "{\"origin\":%s,\"destination\":%s,\"location\":%s}", originString, destinationString, locationString);
        MainActivity.invokeFlutterMethod(event, analyticsParam);
    }

    //endregion

    //region Utilities

    @Override
    protected String getLogTag() {
        return MapDirectionsActivity.class.getSimpleName();
    }

    private void showLoadingFrame(boolean show) {
        if (routeLoadingFrame != null) {
            routeLoadingFrame.setVisibility(show ? View.VISIBLE : View.GONE);
        }
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

    //region MPRouteSegmentPath

    private static class MPRouteSegmentPath {
        private int legIndex;
        private int stepIndex;

        private MPRouteSegmentPath(int legIndex, int stepIndex) {
            this.legIndex = legIndex;
            this.stepIndex = stepIndex;
        }
    }

    //endregion
}
