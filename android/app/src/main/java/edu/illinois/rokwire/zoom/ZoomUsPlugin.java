/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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

package edu.illinois.rokwire.zoom;

import android.app.Activity;
import android.util.Log;

import java.util.HashMap;
import java.util.List;

import androidx.annotation.NonNull;
import edu.illinois.rokwire.Constants;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class ZoomUsPlugin implements MethodChannel.MethodCallHandler, FlutterPlugin {

    private static final String TAG = "ZoomUsPlugin";

    private MethodChannel methodChannel;

    public ZoomUsPlugin(Activity activity) {
    }

    //region Method Handler

    @Override
    public void onMethodCall(@NonNull MethodCall call, @NonNull MethodChannel.Result result) {
        String method = call.method;
        try {
            switch (method) {
                case "test":
                    result.success("works");
                    break;
            }
        } catch (IllegalStateException exception) {
            String errorMsg = String.format("Ignoring exception '%s'. See https://github.com/flutter/flutter/issues/29092 for details.", exception);
            Log.e(TAG, errorMsg);
            exception.printStackTrace();
        }
    }

    //endregion


    //region Flutter Plugin implementation

    @Override
    public void onAttachedToEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel = new MethodChannel(binding.getBinaryMessenger(), "edu.illinois.rokwire/zoom_us");
        methodChannel.setMethodCallHandler(this);
    }

    @Override
    public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
        methodChannel.setMethodCallHandler(null);
        methodChannel = null;
    }

    //endregion
}
