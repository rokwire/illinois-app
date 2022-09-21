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
import android.util.Log;
import android.view.View;

import java.util.ArrayList;
import java.util.HashMap;

import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.platform.PlatformView;

public class MapViewController implements PlatformView, MethodChannel.MethodCallHandler {

    private Context context;
    private MapView mapView;
    private MethodChannel channel;
    private BinaryMessenger messenger;

    MapViewController(Context activityContext, BinaryMessenger messenger, int id, Object args) {
        this.context = activityContext;
        this.messenger = messenger;
        mapView = new MapView(context, id, args);
        channel = new MethodChannel(messenger, "mapview_" + id);

        channel.setMethodCallHandler(this);
    }

    @Override
    public void onMethodCall(MethodCall methodCall, MethodChannel.Result result) {
        try {
            if ("placePOIs".equals(methodCall.method)) {
                showExploresOnMap(methodCall.arguments);
                result.success(true);
            } else if ("enable".equals(methodCall.method)) {
                enableMap(methodCall.arguments);
                result.success(true);
            } else if ("enableMyLocation".equals(methodCall.method)) {
                enableMyLocation(methodCall.arguments);
                result.success(true);
            } else if ("viewPoi".equals(methodCall.method)) {
                Object target = methodCall.argument("target");
                viewPoi(target);
                result.success(true);
            } else {
                result.notImplemented();
            }
        } catch (IllegalStateException exception) {
            String errorMsg = String.format("Ignoring exception '%s'. See https://github.com/flutter/flutter/issues/29092 for details.", exception.toString());
            Log.e("MapView", errorMsg);
            exception.printStackTrace();
        }
    }

    @Override
    public View getView() {
        return mapView;
    }

    @Override
    public void dispose() {
        if(mapView != null) {
            mapView.onDestroy();
        }
    }

    private void enableMap(Object enableObject) {
        // Do not hide mapView, as initially GoogleMap shows blue screen for few seconds.

        //Boolean enableBool = ((enableObject instanceof Boolean)) ? ((Boolean) enableObject) : null;
        //boolean enable = (enableBool != null) && enableBool;
        //mapView.setVisibility(enable ? View.VISIBLE : View.INVISIBLE);
    }

    private void enableMyLocation(Object enableObject) {
        Boolean enableBool = ((enableObject instanceof Boolean)) ? ((Boolean) enableObject) : null;
        boolean enable = (enableBool != null) && enableBool;
        mapView.enableMyLocation(enable);
    }

    private void showExploresOnMap(Object params) {
        ArrayList explores = null;
        HashMap options = null;
        if (params instanceof HashMap) {
            HashMap map = (HashMap) params;
            explores = (ArrayList) map.get("explores");
            options = (HashMap) map.get("options");
        }
        if (mapView != null) {
            mapView.applyExplores(explores, options);
        }
    }

    private void viewPoi(Object target) {
        HashMap targetMap = (target instanceof HashMap) ? (HashMap) target : null;
        if (mapView != null) {
            mapView.viewPoi(targetMap);
        }
    }
}
