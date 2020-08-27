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

import android.bluetooth.BluetoothAdapter;
import android.bluetooth.le.ScanCallback;
import android.bluetooth.le.ScanResult;
import android.bluetooth.le.ScanSettings;

import java.util.List;

import static android.bluetooth.le.ScanSettings.SCAN_MODE_BALANCED;

public class PreOreoScanner {
    private BluetoothAdapter bluetoothAdapter;

    private ScannerCallback mDiscoverCallback;

    public PreOreoScanner(BluetoothAdapter bluetoothAdapter) {
        this.bluetoothAdapter = bluetoothAdapter;
    }

    public void startScan(ScannerCallback callback) {
        if (mDiscoverCallback == null) {

            mDiscoverCallback = callback;

            ScanSettings settings = getScanSettings();
            bluetoothAdapter.getBluetoothLeScanner().startScan(null, settings, mScanCallback);
        }
    }

    public void stopScan() {
        if (mDiscoverCallback != null) {
            bluetoothAdapter.getBluetoothLeScanner().stopScan(mScanCallback);
            mDiscoverCallback = null;
        }
    }

    private void NewResult(final ScanResult result) {
        if (mDiscoverCallback != null)
            mDiscoverCallback.onDevice(result);
    }

    private ScanSettings getScanSettings() {
        return new ScanSettings.Builder().setScanMode(SCAN_MODE_BALANCED).build();
    }

    private ScanCallback mScanCallback = new ScanCallback() {
        @Override
        public void onScanResult(int callbackType, final ScanResult result) {
            super.onScanResult(callbackType, result);
            NewResult(result);
        }

        @Override
        public void onBatchScanResults(List<ScanResult> results) {
            super.onBatchScanResults(results);
            for (ScanResult result : results) {
                NewResult(result);
            }
        }

        @Override
        public void onScanFailed(int errorCode) {
            super.onScanFailed(errorCode);
        }

    };

    //ScannerCallback

    public static abstract class ScannerCallback {
        public void onDevice(ScanResult result) {}
    }
}
