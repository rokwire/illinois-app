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

import android.app.Service;
import android.bluetooth.BluetoothAdapter;
import android.bluetooth.BluetoothManager;
import android.bluetooth.le.AdvertiseCallback;
import android.bluetooth.le.AdvertiseData;
import android.bluetooth.le.AdvertiseSettings;
import android.bluetooth.le.BluetoothLeAdvertiser;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import android.os.Binder;
import android.os.Handler;
import android.os.IBinder;
import android.os.Looper;
import android.os.ParcelUuid;
import android.util.Log;
import android.widget.Toast;

import java.util.Timer;
import java.util.TimerTask;
import java.util.UUID;
import java.util.concurrent.atomic.AtomicBoolean;

import edu.illinois.rokwire.BuildConfig;
import edu.illinois.rokwire.Utils;

public class PollBleServer extends Service {

    private static final String TAG = "PollBleServer";

    class LocalBinder extends Binder {
        PollBleServer getService() {
            return PollBleServer.this;
        }
    }
    private final IBinder binder = new PollBleServer.LocalBinder();
    private BluetoothAdapter bluetoothAdapter;

    private AtomicBoolean isAdvertising = new AtomicBoolean(false);
    private AtomicBoolean waitBluetoothOn = new AtomicBoolean(false);
    private Timer advertiseTimer;

    private String pollId;

    private Callback callbackService;

    @Override
    public IBinder onBind(Intent intent) {
        return binder;
    }

    @Override
    public void onCreate() {
        Object systemService = getSystemService(Context.BLUETOOTH_SERVICE);
        if (systemService instanceof BluetoothManager) {
            bluetoothAdapter = ((BluetoothManager) systemService).getAdapter();
        }
        if (bluetoothAdapter == null) {
            Log.d(TAG, "onCreate - bluetoothAdapter is null or not supported multi advertisement");
            return;
        }

        IntentFilter filter = new IntentFilter(BluetoothAdapter.ACTION_STATE_CHANGED);
        registerReceiver(bluetoothReceiver, filter);
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) { return START_STICKY;  }

    @Override
    public void onDestroy() {
        stopAdvertising();
        unregisterReceiver(bluetoothReceiver);
    }

    public void setCallback(Callback callback) {
        this.callbackService = callback;
    }

    public void createPoll(String pollId) {
        Log.d(TAG, "createPoll " + pollId);

        this.pollId = pollId;

        if (bluetoothAdapter == null) {
            Log.d(TAG, "createPoll - bluetoothAdapter is null");
            return;
        }

        // ask for bluetooth if not set
        if (!bluetoothAdapter.isEnabled()) {
            if (callbackService != null)
                callbackService.onRequestBluetoothOn();
        }

        // advertise for 5 minutes for new devices to connect
        if (isAdvertising.get()) {
            //stop it if there is active
            stopAdvertising();
        }
        startAdvertising(this.pollId);
    }

    private void startAdvertising(String poll) {
        if (!bluetoothAdapter.isEnabled()) {
            Log.d(TAG, "startAdvertising needs to wait for bluetooth");
            waitBluetoothOn.set(true);
            return;
        }
        waitBluetoothOn.set(false);

        Log.d(TAG, "startAdvertising not needs to wait for bluetooth");
        showToast("Request start advertising");

        bluetoothAdapter.setName("Poll");
        BluetoothLeAdvertiser advertiser = bluetoothAdapter.getBluetoothLeAdvertiser();
        AdvertiseData.Builder dataBuilder = new AdvertiseData.Builder();
        AdvertiseSettings.Builder settingsBuilder = new AdvertiseSettings.Builder();

        //dataBuilder.setIncludeTxPowerLevel(true);
        dataBuilder.setIncludeDeviceName(true);

        dataBuilder.addServiceUuid(new ParcelUuid(prepareUuid(poll)));
        settingsBuilder.setAdvertiseMode(AdvertiseSettings.ADVERTISE_MODE_BALANCED);
        settingsBuilder.setTxPowerLevel(AdvertiseSettings.ADVERTISE_TX_POWER_HIGH);

        settingsBuilder.setConnectable(false);

        advertiser.startAdvertising(settingsBuilder.build(), dataBuilder.build(), advertiseCallback);
    }

    private UUID prepareUuid(String pollId) {
        byte[] pollIdBytes = Utils.Str.hexStringToByteArray(pollId);
        byte[] newPollIdBytes = new byte[16];
        System.arraycopy(pollIdBytes,0, newPollIdBytes,0, pollIdBytes.length);
        return Utils.Guid.UUIDFromBytes(newPollIdBytes);
    }

    private void stopAdvertising() {
        showToast("Stop advertising");
        waitBluetoothOn.set(false);

        if (advertiseTimer != null) {
            advertiseTimer.cancel();
            advertiseTimer = null;
        }

        if (bluetoothAdapter != null) {
            BluetoothLeAdvertiser advertiser = bluetoothAdapter.getBluetoothLeAdvertiser();

            if (advertiser != null) {
                advertiser.stopAdvertising(advertiseCallback);
            }
        }

        isAdvertising.set(false);
    }

    private AdvertiseCallback advertiseCallback = new AdvertiseCallback() {

        @Override
        public void onStartSuccess(AdvertiseSettings settingsInEffect) {
            super.onStartSuccess(settingsInEffect);
            Log.d(TAG, "AdvertiseCallback onStartSuccess ");

            showToast("Start advertising Succeed");

            isAdvertising.set(true);

            //stop the advertising after 5 minutes
            advertiseTimer = new Timer();
            advertiseTimer.schedule(new TimerTask() {
                @Override
                public void run() {
                    stopAdvertising();
                }

            }, 5 * 60000);
        }

        @Override
        public void onStartFailure(int errorCode) {
            super.onStartFailure(errorCode);
            Log.d(TAG, "AdvertiseCallback onStartFailure " + errorCode);

            showToast("Start advertising failed " + errorCode);

            isAdvertising.set(false);
        }
    };

    private void showToast(String message) {
        if (BuildConfig.DEBUG) {
            new Handler(Looper.getMainLooper()).post(() -> Toast.makeText(getApplicationContext(), message, Toast.LENGTH_SHORT).show());
        }
    }

    // Bluetooth

    private final BroadcastReceiver bluetoothReceiver = new BroadcastReceiver() {
        @Override
        public void onReceive(Context context, Intent intent) {
            final String action = intent.getAction();

            if ((action != null) && action.equals(BluetoothAdapter.ACTION_STATE_CHANGED)) {
                final int bluetoothState = intent.getIntExtra(BluetoothAdapter.EXTRA_STATE, BluetoothAdapter.ERROR);
                if (bluetoothState == BluetoothAdapter.STATE_ON) {
                    Log.d(TAG, "Bluetooth is on");
                    //start the advertising if it waits for bluetooth
                    Handler handler = new Handler(Looper.getMainLooper());
                    Runnable runnable = () -> {
                        if (waitBluetoothOn.get()) {
                            startAdvertising(pollId);
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
        public void onRequestBluetoothOn() {}
    }
}
