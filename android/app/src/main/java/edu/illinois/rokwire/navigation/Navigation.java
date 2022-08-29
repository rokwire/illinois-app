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

package edu.illinois.rokwire.navigation;

import android.content.Context;
import android.os.Build;
import android.util.Log;

import com.android.volley.Request;
import com.android.volley.RequestQueue;
import com.android.volley.VolleyError;
import com.android.volley.toolbox.StringRequest;
import com.android.volley.toolbox.Volley;
import com.google.android.gms.maps.model.LatLng;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.List;
import java.util.Locale;

import androidx.annotation.NonNull;
import edu.illinois.rokwire.MainActivity;
import edu.illinois.rokwire.R;
import edu.illinois.rokwire.Utils;
import edu.illinois.rokwire.navigation.model.NavRoute;

public class Navigation {

    private static final String TAG = Navigation.class.getCanonicalName();

    private final Context context;
    private final NavigationListener listener;
    private final RequestQueue requestQueue;

    public Navigation(Context context, NavigationListener listener) {
        this.context = context;
        this.listener = listener;
        this.requestQueue = Volley.newRequestQueue(context);
    }

    public void dismiss() {
        if (requestQueue != null) {
            requestQueue.cancelAll(TAG);
        }
    }

    public void findRoutesFromOrigin(@NonNull LatLng origin, @NonNull LatLng destination, @NonNull String travelMode, boolean alternatives) {
        String apiUrl = null;
        String apiKey = null;
        if (MainActivity.getInstance() != null) {
            apiUrl = Utils.Map.getStringValueForKey(MainActivity.getInstance().getThirdPartyServices(), "google_directions_url");
            apiKey = Utils.Map.getValueFromPath(MainActivity.getInstance().getSecretKeys(), "google.maps.api_key", null);
        }
        String url = String.format(getCurrentLocale(), "%s?origin=%.6f,%.6f&destination=%.6f,%.6f&mode=%s&alternatives=%s&language=%s&key=%s",
                apiUrl, origin.latitude, origin.longitude, destination.latitude, destination.longitude, travelMode, (alternatives ? "true" : "false"), getCurrentLocale().getLanguage(), apiKey);

        StringRequest stringRequest = new StringRequest(Request.Method.GET, url,
                response -> notifyResponse(response, null),
                error -> notifyResponse(null, error));
        stringRequest.setTag(TAG);
        requestQueue.add(stringRequest);
    }

    private void notifyResponse(String apiResponse, VolleyError volleyError) {
        List<NavRoute> routes = null;
        String errorResponse = null;
        if (volleyError != null) {
            errorResponse = volleyError.getLocalizedMessage();
        } else if (!Utils.Str.isEmpty(apiResponse)) {
            JSONObject jsonResponse = null;
            try {
                jsonResponse = new JSONObject(apiResponse);
            } catch (JSONException e) {
                Log.e(TAG, "Failed to parse Directions API response. Print stacktrace:");
                e.printStackTrace();
            }
            if (jsonResponse != null) {
                String status = Utils.Json.getStringValueForKey(jsonResponse, "status");
                if ("OK".equalsIgnoreCase(status)) {
                    JSONArray routesJson = Utils.Json.getJsonArrayForKey(jsonResponse, "routes");
                    if (routesJson != null) {
                        routes = NavRoute.createNavRouteList(routesJson);
                    }
                } else {
                    String serverErrMsg = Utils.Json.getStringValueForKey(jsonResponse, "error_message");
                    errorResponse = String.format(getCurrentLocale(), "%s: %s", status, serverErrMsg);
                }
            } else {
                errorResponse = context.getString(R.string.invalid_server_response);
            }
        }

        if (listener != null) {
            listener.onNavigationResponse(routes, errorResponse);
        }
    }

    private Locale getCurrentLocale() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            return context.getResources().getConfiguration().getLocales().get(0);
        } else {
            // We still support apiLevel 23 so we have to be compatible
            //noinspection deprecation
            return context.getResources().getConfiguration().locale;
        }
    }

    public interface NavigationListener {
        void onNavigationResponse(List<NavRoute> routes, String errorResponse);
    }
}
