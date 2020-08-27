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

import android.Manifest;
import android.annotation.SuppressLint;
import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothDevice;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.ScanRecord;
import android.bluetooth.le.ScanResult;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.content.pm.PackageManager;
import android.os.Binder;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.ParcelUuid;
import android.util.Log;

import androidx.core.content.ContextCompat;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

import edu.illinois.rokwire.Utils;
import edu.illinois.rokwire.poll.scan.OreoScanner;
import edu.illinois.rokwire.poll.scan.PreOreoScanner;

public class PollBleClient extends Service {

    private static final String TAG = "PollBleClient";

    class LocalBinder extends Binder {
        PollBleClient getService() {
            return PollBleClient.this;
        }
    }
    private final IBinder mBinder = new LocalBinder();

    private BluetoothAdapter mBluetoothAdapter;

    private PreOreoScanner preOreoScanner;
    private OreoScanner oreoScanner;

    private Callback callback;

    private List<String> founded;

    private AtomicBoolean waitBluetoothOn = new AtomicBoolean(false);
    private AtomicBoolean waitLocationPermissionGranted = new AtomicBoolean(false);

    @Override
    public IBinder onBind(Intent intent) {
        return mBinder;
    }

    @Override
    public void onCreate() {
        Object systemService = getSystemService(Context.BLUETOOTH_SERVICE);
        if (systemService instanceof BluetoothManager) {
            mBluetoothAdapter = ((BluetoothManager) systemService).getAdapter();
        }
        if (mBluetoothAdapter == null) {
            return;
        }

        founded = Collections.synchronizedList(new ArrayList<>());

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            oreoScanner = new OreoScanner(getApplicationContext(), mBluetoothAdapter);
        } else {
            preOreoScanner = new PreOreoScanner(mBluetoothAdapter);
        }

        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        registerReceiver(bluetoothReceiver, filter);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            Bundle extras = intent.getExtras();
            if (extras != null) {
                Object found = extras.get("edu.illinois.rokwire.poll.FOUND_DEVICE");
                if (found != null) {
                    if (found instanceof ScanResult) {
                        ScanResult scanResult = ((ScanResult) found);
                        onFoundDevice(scanResult);
                    } else {
                        Log.d(TAG, "found is not ScanResult");
                    }
                } else {
                    Log.d(TAG, "found is null");
                }
            } else {
                Log.d(TAG, "extras are null");
            }
        } else {
            Log.d(TAG, "The intent is null");
        }
        return START_STICKY;
    }

    @Override
    public void onDestroy() {
        unregisterReceiver(bluetoothReceiver);
    }

    public void setCallback(Callback callback) {
        this.callback = callback;
    }

    @SuppressLint("NewApi")
    public void startScan() {
        Log.d(TAG, "startScan");

        //check if bluetooth is on
        boolean needsWaitBluetooth = needsWaitBluetooth();
        if (needsWaitBluetooth) {
            waitBluetoothOn.set(true);
            return;
        }
        waitBluetoothOn.set(false);

        //check if location permission is granted
        boolean needsWaitLocationPermission = needsWaitLocationPermission();
        if (needsWaitLocationPermission) {
            waitLocationPermissionGranted.set(true);
            return;
        }
        waitLocationPermissionGranted.set(false);
        //////////////////////////

        if (preOreoScanner != null) {
            preOreoScanner.startScan(new PreOreoScanner.ScannerCallback() {
                @Override
                public void onDevice(ScanResult result) {
                    super.onDevice(result);

                    onFoundDevice(result);
                }
            });
        }
        if (oreoScanner != null) {
            oreoScanner.startScan();
        }
    }

    private boolean needsWaitBluetooth() {
        if (!mBluetoothAdapter.isEnabled()) {
            Log.d(TAG, "processBluetoothCheck needs to wait for bluetooth");
            return true;
        } else {
            Log.d(TAG, "processBluetoothCheck - bluetooth ready");
        }
        return false;
    }

    private boolean needsWaitLocationPermission() {
        if (ContextCompat.checkSelfPermission(this, android.Manifest.permission.ACCESS_COARSE_LOCATION) != PackageManager.PERMISSION_GRANTED  ||
                ContextCompat.checkSelfPermission(this, Manifest.permission.ACCESS_FINE_LOCATION) != PackageManager.PERMISSION_GRANTED) {
            Log.d(TAG, "needsWaitLocationPermission - location is not set");
            return true;
        } else {
            Log.d(TAG, "needsWaitLocationPermission - location ready");
        }
        return false;
    }

    @SuppressLint("NewApi")
    public void stopScan() {
        Log.d(TAG, "stopScan");

        if (preOreoScanner != null) {
            preOreoScanner.stopScan();
        }
        if (oreoScanner != null) {
            oreoScanner.stopScan();
        }

        waitBluetoothOn.set(false);
        waitLocationPermissionGranted.set(false);

        founded.clear();
    }

    public void onLocationPermissionGranted() {
        Log.d(TAG, "onLocationPermissionGranted");

        //start the advertising if it waits for location
        Handler handler = new Handler(Looper.getMainLooper());
        Runnable runnable = () -> {
            if (waitLocationPermissionGranted.get()) {
                startScan();
            }
        };
        handler.postDelayed(runnable, 2000);
    }

    private void onFoundDevice(ScanResult result) {
        if (result == null) {
            Log.d(TAG, "onFoundDevice - result is null");
            return;
        }
        BluetoothDevice device = result.getDevice();
        if (device == null || device.getName() == null) {
            return;
        }
        if (!"Poll".equals(device.getName())) {
            return;
        }
        ScanRecord scanRecord = result.getScanRecord();
        if (scanRecord == null) {
            Log.d(TAG, "onFoundDevice - scan record is null");
            return;
        }
        List<ParcelUuid> uuids = scanRecord.getServiceUuids();
        if (uuids == null || uuids.size() == 0) {
            Log.d(TAG, "onFoundDevice - uuids is null or empty");
            return;
        }

        UUID uuid = uuids.get(0).getUuid();

        //check if it is already processed
        if (founded.contains(uuid.toString()))
            return;

        Log.d(TAG, "onFoundDevice " + uuid);

        //add it to the list
        founded.add(uuid.toString());

        //process it
        processFoundUuid(uuid);
    }

    private void processFoundUuid(UUID uuid) {
        Log.d(TAG, "processFoundUuid - " + uuid);

        byte[] uuidBytes = Utils.Guid.bytesFromUUID(uuid);
        byte[] pollIdBytes = new byte[12];
        if (uuidBytes.length > 12) {
            System.arraycopy(uuidBytes,0, pollIdBytes,0, 12);
        }
        String convertedPollId = Utils.Str.byteArrayToHexString(pollIdBytes);

        Log.d(TAG, "processFoundUuid converted poll id " + convertedPollId);
        if (callback != null) {
            callback.onPollCreated(convertedPollId);
        }
    }

    // Bluetooth

    private final BroadcastReceiver bluetoothReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();

            if ((action != null) && action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
                final int bluetoothState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE,
                        BluetoothAdapter.ERROR);
                if (bluetoothState == BluetoothAdapter.STATE_ON) {
                    Log.d(TAG, "Bluetooth is on");
                    //start the advertising if it waits for bluetooth
                    Handler handler = new Handler(Looper.getMainLooper());
                    Runnable runnable = () -> {
                        if (waitBluetoothOn.get()) {
                            startScan();
                        }
                    };
                    handler.postDelayed(runnable, 2000);
                }
            }
        }
    };

    ////////////////////

    // Callback

    public static class Callback {
        public void onPollCreated(String pollId) {}
    }
}

