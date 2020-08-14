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

package edu.illinois.rokwire.poll;

import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.util.Log;

import androidx.annotation.NonNull;
import edu.illinois.rokwire.MainActivity;
import edu.illinois.rokwire.Utils;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.PluginRegistry;

public class PollPlugin implements MethodChannel.MethodCallHandler {

    private static final String TAG = "PollPlugin";

    private MainActivity context;
    private MethodChannel methodChannel;

    private PollBleServer blePollServer;
    private PollBleClient bleClient;

    public static PollPlugin registerWith(PluginRegistry.Registrar registrar) {
        final MethodChannel channel = new MethodChannel(registrar.messenger(), "edu.illinois.rokwire/polls");
        PollPlugin pollPlugin = new PollPlugin((MainActivity)registrar.activity(), channel);
        channel.setMethodCallHandler(pollPlugin);
        return pollPlugin;
    }

    private PollPlugin(MainActivity activity, MethodChannel methodChannel) {
        this.context = activity;
        this.methodChannel = methodChannel;
        this.methodChannel.setMethodCallHandler(this);

        bindPollServer();
        bindPollClient();
    }

    @Override
    public void onMethodCall(MethodCall call, @NonNull MethodChannel.Result result) {
        try {
            if ("create_poll".equals(call.method)) {
                if (blePollServer != null) {
                    Object arguments = call.arguments;
                    if (arguments instanceof String) {
                        String pollID = (String) arguments;
                        blePollServer.createPoll(pollID);
                    } else {
                        Log.d(TAG, "arguments is null or not in the correct type");
                    }
                }
            } else if ("start_scan".equals(call.method)) {
                if (bleClient != null) {
                    bleClient.startScan();
                }
            }
            else if ("stop_scan".equals(call.method)) {
                if (bleClient != null) {
                    bleClient.stopScan();
                }
            }
            else if("enable".equals(call.method)){
                // Implement if need
                if (bleClient != null) {
                    bleClient.startScan();
                }
            }
            else if("disable".equals(call.method)){
                // Implement if need
                if (bleClient != null) {
                    bleClient.stopScan();
                }
            }
            result.success(null);
        } catch (IllegalStateException exception) {
            String errorMsg = String.format("Ignoring exception '%s'. See https://github.com/flutter/flutter/issues/29092 for details.", exception.toString());
            Log.e(TAG, errorMsg);
            exception.printStackTrace();
        }
    }

    public void onLocationPermissionGranted() {
        Log.d(TAG, "onLocationPermissionGranted");
        if (bleClient != null)
            bleClient.onLocationPermissionGranted();
    }

    private void requestBluetoothOn() {
        Log.d(TAG, "requestBluetoothOn");

        Utils.showDialog(context, "Illinois app",
                "Using bluetooth nearby devices can receive your poll. Do you want to turn the bluetooth on? ",
                (dialog, which) -> {
                    //Turn bluetooth on
                    Utils.enabledBluetooth();

                }, "Yes",
                (dialog, which) -> {}, "No",
                true);
    }

    // Poll server

    private void bindPollServer() {
        Intent intent = new Intent(context, PollBleServer.class);
        context.bindService(intent, mConnection, Context.BIND_AUTO_CREATE);
    }

    private ServiceConnection mConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder service) {
            blePollServer = ((PollBleServer.LocalBinder)service).getService();
            if (blePollServer == null) {
                return;
            }
            blePollServer.setCallback(serverCallback);
        }
        public void onServiceDisconnected(ComponentName className) {
            blePollServer = null;
        }
    };

    private PollBleServer.Callback serverCallback = new PollBleServer.Callback() {
        @Override
        public void onRequestBluetoothOn() {
            PollPlugin.this.requestBluetoothOn();
        }
    };

    /////////////////////

    // Poll client

    private void bindPollClient() {
        Intent intent = new Intent(context, PollBleClient.class);
        context.bindService(intent, clientConnection, Context.BIND_AUTO_CREATE);
    }

    private ServiceConnection clientConnection = new ServiceConnection() {
        public void onServiceConnected(ComponentName className, IBinder service) {
            bleClient = ((PollBleClient.LocalBinder)service).getService();
            if (bleClient == null) {
                return;
            }
            bleClient.setCallback(clientCallback);
        }
        public void onServiceDisconnected(ComponentName className) {
            bleClient = null;
        }
    };

    private PollBleClient.Callback clientCallback = new PollBleClient.Callback() {
        @Override
        public void onPollCreated(String pollId) {
            Log.d(TAG, "onPollCreated - " + pollId);

            //run it on the ui thread
            Handler handler = new Handler(Looper.getMainLooper());
            handler.post(() -> methodChannel.invokeMethod("on_poll_created", pollId));
        }
    };

    /////////////////////
}
