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

import com.google.android.gms.maps.model.LatLng;

public class Constants {

    //Flutter communication methods
    static final String APP_INIT_KEY = "init";
    static final String MAP_DIRECTIONS_KEY = "directions";
    static final String MAP_PICK_LOCATION_KEY = "pickLocation";
    static final String MAP_KEY = "map";
    static final String APP_DISMISS_LAUNCH_SCREEN_KEY = "dismissLaunchScreen";
    static final String APP_SET_LAUNCH_SCREEN_STATUS_KEY = "setLaunchScreenStatus";
    static final String APP_ENABLED_ORIENTATIONS_KEY = "enabledOrientations";
    static final String DEEPLINK_SCHEME_KEY = "deepLinkScheme";
    static final String MOBILE_ACCESS_KEYS_KEY = "mobileAccessKeys";
    static final String BARCODE_KEY = "barcode";
    static final String TEST_KEY = "test";

    //Maps
    public static final LatLng DEFAULT_INITIAL_CAMERA_POSITION = new LatLng(40.102116, -88.227129); //Illinois University: Center of Campus //(40.096230, -88.235899); // State Farm Center
    public static final float DEFAULT_CAMERA_ZOOM = 17.0f;
    public static final float MAP_NO_POI_THRESHOLD_ZOOM = 17.0f;
    public static final float MAP_THRESHOLD_ZOOM_UPDATE_STEP = 0.3f;
    public static final float MAP_MAX_ZOOM_LEVEL_FOR_THRESHOLD = 16f;
    public static final float FIRST_THRESHOLD_MARKER_ZOOM = 17.0f;
    public static final float SECOND_THRESHOLD_MARKER_ZOOM = 18.00f;
    public static final int SELECT_LOCATION_ACTIVITY_RESULT_CODE = 2;
    public static final String LOCATION_PICKER_DATA_FORMAT = "{\"location\":{\"latitude\":%f,\"longitude\":%f}}";
    public static final float INDOORS_BUILDING_ZOOM = 17.0f;
    public static final String ANALYTICS_ROUTE_LOCATION_FORMAT = "{\"latitude\":%f,\"longitude\":%f}";
    public static final String ANALYTICS_USER_LOCATION_FORMAT = "{\"latitude\":%f,\"longitude\":%f,\"timestamp\":%d}";

    // Shared Prefs
    static final String DEFAULT_SHARED_PREFS_FILE_NAME = "default_shared_prefs";
    static final String SECURE_SHARED_PREFS_FILE_NAME = "secure_shared_prefs";

    // HID / Origo
    static final int ORIGO_LOCK_SERVICE_CODE = 2; //TBD: what is this code? Where do we get it from? We put the same as in the sample app for simplicity.

}
