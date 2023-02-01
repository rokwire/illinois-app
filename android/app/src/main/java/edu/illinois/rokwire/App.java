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
import android.util.Log;

import androidx.lifecycle.Lifecycle;
import androidx.lifecycle.LifecycleObserver;
import androidx.lifecycle.OnLifecycleEvent;
import androidx.lifecycle.ProcessLifecycleOwner;
import edu.illinois.rokwire.mobile_access.MobileAccessKeysApiFactory;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.view.FlutterMain;

public class App extends Application implements LifecycleObserver, PluginRegistry.PluginRegistrantCallback {

    private static final String CHANNEL_ID = "Notifications_Channel_ID";

    private MobileAccessKeysApiFactory mobileKeysFactory;

    public boolean inBackground = true;

    @Override
    public void onCreate() {
        super.onCreate();
        FlutterMain.startInitialization(this);
        //FlutterFirebaseMessagingService.setPluginRegistrant(this);

        ProcessLifecycleOwner.get().getLifecycle().addObserver(this);

        mobileKeysFactory = new MobileAccessKeysApiFactory(this);
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

    public MobileAccessKeysApiFactory getMobileApiKeysFactory() {
        return mobileKeysFactory;
    }
}
