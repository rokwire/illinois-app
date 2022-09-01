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

import edu.illinois.rokwire.Utils;

public class NavBounds {
    private NavCoord northeast;
    private NavCoord southwest;

    public NavBounds(JSONObject json) {
        this.northeast = new NavCoord(Utils.Json.getJsonObjectForKey(json, "northeast"));
        this.southwest = new NavCoord(Utils.Json.getJsonObjectForKey(json, "southwest"));
    }

    public NavCoord getNortheast() {
        return northeast;
    }

    public NavCoord getSouthwest() {
        return southwest;
    }
}
