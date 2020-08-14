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

package edu.illinois.rokwire.poll.scan;

import android.annotation.TargetApi;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.le.ScanResult;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.util.Log;

import java.util.ArrayList;

import edu.illinois.rokwire.App;
import edu.illinois.rokwire.MainActivity;
import edu.illinois.rokwire.poll.PollBleClient;

public class PollBleReceiver extends BroadcastReceiver {

    @TargetApi(Build.VERSION_CODES.O)
    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent == null) {
            Log.d("BleReceiver", "onReceive - intent is null");
            return;
        }

        // Too floody
        //Log.d("BleReceiver", "onReceive - " + intent.getAction());

        App app = (MainActivity.getInstance() != null) ? MainActivity.getInstance().getApp() : null;
        if ((app == null) || app.inBackground) {
            // Too floody
            // Log.d("BleReceiver", "onReceive - App is null or in background");
            return;
        }

        if ("edu.illinois.rokwire.poll.ACTION_FOUND".equals(intent.getAction())) {

            ScanResult scanResult = extractData(intent.getExtras());
            if (scanResult == null) {
                Log.d("BleReceiver", "The scan result is null");
                return;
            }
            BluetoothDevice device = scanResult.getDevice();
            if (device == null) {
                Log.d("BleReceiver", "The device is null");
                return;
            }

            Intent bleClientIntent = new Intent(context, PollBleClient.class);
            bleClientIntent.putExtra("edu.illinois.rokwire.poll.FOUND_DEVICE", scanResult);
            context.startService(bleClientIntent);
        }
    }

    private ScanResult extractData(Bundle extras) {
        if (extras != null) {
            Object list = extras.get("android.bluetooth.le.extra.LIST_SCAN_RESULT");
            if (list != null) {
                ArrayList l = (ArrayList) list;
                if (l.size() > 0) {
                    Object firstItem = l.get(0);
                    if (firstItem instanceof ScanResult) {
                       return (ScanResult) firstItem;
                    } else {
                        Log.d("BleReceiver", "first item is not ScanResult");
                    }
                } else {
                    Log.d("BleReceiver", "list is empty");
                }
            } else {
                Log.d("BleReceiver", "list is null");
            }
        } else {
            Log.d("BleReceiver", "extras are null");
        }
        return null;
    }
}
