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

import org.json.JSONObject;

import java.util.List;

import edu.illinois.rokwire.Utils;

public class NavCoord {
    private double lat;
    private double lng;

    public NavCoord(JSONObject json) {
        this.lat = Utils.Json.getDoubleValueForKey(json, "lat");
        this.lng = Utils.Json.getDoubleValueForKey(json, "lng");
    }

    public static List<NavCoord> createListFromEncodedString(String encodedString) {
        //TBD: implement
        return null;
    }

    public double getLat() {
        return lat;
    }

    public double getLng() {
        return lng;
    }
}
