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

package edu.illinois.rokwire;

import android.app.Application;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.os.Build;
import android.util.Log;

import com.hid.origo.OrigoKeysApiFactory;
import com.hid.origo.api.OrigoApiConfiguration;
import com.hid.origo.api.OrigoMobileKeys;
import com.hid.origo.api.OrigoMobileKeysApi;
import com.hid.origo.api.OrigoReaderConnectionController;
import com.hid.origo.api.ble.OrigoBluetoothMode;
import com.hid.origo.api.ble.OrigoOpeningTrigger;
import com.hid.origo.api.ble.OrigoScanConfiguration;
import com.hid.origo.api.ble.OrigoSeamlessOpeningTrigger;
import com.hid.origo.api.ble.OrigoTapOpeningTrigger;
import com.hid.origo.api.ble.OrigoTwistAndGoOpeningTrigger;
import com.hid.origo.api.hce.OrigoNfcConfiguration;

import androidx.core.app.NotificationCompat;
import androidx.core.app.NotificationManagerCompat;
import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleObserver;
import androidx.lifecycle.OnLifecycleEvent;
import androidx.lifecycle.ProcessLifecycleOwner;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterMain;

public class App extends Application implements LifecycleObserver, PluginRegistry.PluginRegistrantCallback, OrigoKeysApiFactory {

    private static final String CHANNEL_ID = "Notifications_Channel_ID";

    private OrigoMobileKeysApi mobileKeysFactory;

    public boolean inBackground = true;

    @Override
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);
        //FlutterFirebaseMessagingService.setPluginRegistrant(this);

        ProcessLifecycleOwner.get().getLifecycle().addObserver(this);

        initializeOrigo();
    }


    @OnLifecycleEvent(Lifecycle.Event.ON_START)
    public void onMoveToForeground() {
        Log.d("App", "ON_START");
        inBackground = false;
    }

    @OnLifecycleEvent(Lifecycle.Event.ON_STOP)
    public void onMoveToBackground() {
        Log.d("App", "ON_STOP");
        inBackground = true;
    }

    @Override
    public void registerWith(PluginRegistry registry) {
       // FirebaseMessagingPlugin.registerWith(registry.registrarFor("io.flutter.plugins.firebasemessaging.FirebaseMessagingPlugin"));
    }

    //region HID / Origo

    private void initializeOrigo() {
        String appId = ""; //TBD place here application id and do not commit it. Instead read it from config
        String appDescription = ""; //TBD place here application description and do not commit it.

        OrigoScanConfiguration origoScanConfiguration = new OrigoScanConfiguration.Builder(
                new OrigoOpeningTrigger[]{new OrigoTapOpeningTrigger(this),
                        new OrigoTwistAndGoOpeningTrigger(this),
                        new OrigoSeamlessOpeningTrigger()}, Constants.ORIGO_LOCK_SERVICE_CODE)
                .setAllowBackgroundScanning(true)
                .setBluetoothModeIfSupported(OrigoBluetoothMode.DUAL)
                .build();

        OrigoApiConfiguration origoApiConfiguration = new OrigoApiConfiguration.Builder().setApplicationId(appId)
                .setApplicationDescription(appDescription)
                .setNfcParameters(new OrigoNfcConfiguration.Builder().build())
                .build();

        mobileKeysFactory = OrigoMobileKeysApi.getInstance();
        mobileKeysFactory.initialize(this, origoApiConfiguration, origoScanConfiguration, appId);
        if (!mobileKeysFactory.isInitialized()) {
            throw new IllegalStateException();
        }
    }

    @Override
    public OrigoMobileKeys getMobileKeys() {
        return mobileKeysFactory.getMobileKeys();
    }

    @Override
    public OrigoReaderConnectionController getReaderConnectionController() {
        return mobileKeysFactory.getOrigiReaderConnectionController();
    }

    @Override
    public OrigoScanConfiguration getOrigoScanConfiguration() {
        return getReaderConnectionController().getScanConfiguration();
    }

    //endregion
}
