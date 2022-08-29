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

public class NavRoute {
    //TBD: implement
    private NavBounds bounds;
    private String copyrights;
    private String summary;
    private List<NavRouteLeg> legs;
    private NavPolyline polyline;

    public NavRoute(JSONObject json) {
        if (json != null) {
            this.bounds = new NavBounds(Utils.Json.getJsonObjectForKey(json, "bounds"));
            this.copyrights = Utils.Json.getStringValueForKey(json, "copyrights");
            this.summary = Utils.Json.getStringValueForKey(json, "summary");
            this.legs = NavRouteLeg.createNavRouteLegList(Utils.Json.getJsonArrayForKey(json, "legs"));
            this.polyline = new NavPolyline(Utils.Json.getJsonObjectForKey(json, "overview_polyline"));
        }
    }

    public static List<NavRoute> createNavRouteList(JSONArray jsonArray) {
        List<NavRoute> routes = null;
        if (jsonArray != null) {
            routes = new ArrayList<>();
            int count = jsonArray.length();
            for (int i = 0; i < count; i++) {
                JSONObject routeJson = Utils.Json.getJsonObjectForIndex(jsonArray, i);
                if (routeJson != null) {
                    routes.add(new NavRoute(routeJson));
                }
            }
        }
        return routes;
    }

    public NavBounds getBounds() {
        return bounds;
    }

    public String getCopyrights() {
        return copyrights;
    }

    public String getSummary() {
        return summary;
    }

    public List<NavRouteLeg> getLegs() {
        return legs;
    }

    public NavPolyline getPolyline() {
        return polyline;
    }
}
