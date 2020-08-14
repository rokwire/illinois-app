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

import android.app.PendingIntent;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.ScanSettings;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import androidx.annotation.RequiresApi;

import static android.bluetooth.le.ScanSettings.SCAN_MODE_BALANCED;

public class OreoScanner {
    private Context context;
    private BluetoothAdapter bluetoothAdapter;

    private PendingIntent pendingIntent;

    public OreoScanner(Context context, BluetoothAdapter bluetoothAdapter) {
        this.context = context;
        this.bluetoothAdapter = bluetoothAdapter;
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    public void startScan() {
        ScanSettings settings = getScanSettings();

        Intent intent = new Intent(context, PollBleReceiver.class);
        intent.setAction("edu.illinois.rokwire.poll.ACTION_FOUND");
        pendingIntent = PendingIntent.getBroadcast(context, 1, intent, PendingIntent.FLAG_UPDATE_CURRENT);

        int oper = bluetoothAdapter.getBluetoothLeScanner().startScan(null, settings, pendingIntent);
        if (oper != 0) {
            Log.d("Scanner", "Error on start scan");
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.O)
    public void stopScan() {
        if (pendingIntent != null && bluetoothAdapter != null) {
            bluetoothAdapter.getBluetoothLeScanner().stopScan(pendingIntent);
            pendingIntent = null;
        }
    }

    @RequiresApi(api = Build.VERSION_CODES.M)
    private ScanSettings getScanSettings() {
        ScanSettings.Builder builder = new ScanSettings.Builder();
        builder.setScanMode(SCAN_MODE_BALANCED);
        //builder.setCallbackType(CALLBACK_TYPE_FIRST_MATCH);
        return builder.build();
    }
}
