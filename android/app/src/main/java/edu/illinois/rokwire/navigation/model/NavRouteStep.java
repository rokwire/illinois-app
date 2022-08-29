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

package edu.illinois.rokwire.navigation.model;

import org.json.JSONArray;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

import edu.illinois.rokwire.Utils;

public class NavRouteStep {
    private final NavIntVal distance;
    private final NavIntVal duration;
    private final NavCoord startLocation;
    private final NavCoord endLocation;
    private final String htmlInstructions;
    private final String maneuver;
    private final NavPolyline polyline;
    private final String travelMode;

    public NavRouteStep(JSONObject json) {
        this.distance = new NavIntVal(Utils.Json.getJsonObjectForKey(json, "distance"));
        this.duration = new NavIntVal(Utils.Json.getJsonObjectForKey(json, "duration"));
        this.startLocation = new NavCoord(Utils.Json.getJsonObjectForKey(json, "start_location"));
        this.endLocation = new NavCoord(Utils.Json.getJsonObjectForKey(json, "end_location"));
        this.htmlInstructions = Utils.Json.getStringValueForKey(json, "html_instructions");
        this.maneuver = Utils.Json.getStringValueForKey(json, "maneuver");
        this.polyline = new NavPolyline(Utils.Json.getJsonObjectForKey(json, "polyline"));
        this.travelMode = Utils.Json.getStringValueForKey(json, "travel_mode");
    }

    public static List<NavRouteStep> createNavRouteStepList(JSONArray jsonArray) {
        List<NavRouteStep> steps = null;
        if (jsonArray != null) {
            steps = new ArrayList<>();
            int count = jsonArray.length();
            for (int i = 0; i < count; i++) {
                JSONObject stepJson = Utils.Json.getJsonObjectForIndex(jsonArray, i);
                if (stepJson != null) {
                    steps.add(new NavRouteStep(stepJson));
                }
            }
        }
        return steps;
    }

    public NavIntVal getDistance() {
        return distance;
    }

    public NavIntVal getDuration() {
        return duration;
    }

    public NavCoord getStartLocation() {
        return startLocation;
    }

    public NavCoord getEndLocation() {
        return endLocation;
    }

    public String getHtmlInstructions() {
        return htmlInstructions;
    }

    public String getManeuver() {
        return maneuver;
    }

    public NavPolyline getPolyline() {
        return polyline;
    }

    public String getTravelMode() {
        return travelMode;
    }
}
