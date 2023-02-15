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

package edu.illinois.rokwire.mobile_access;

import android.app.Activity;
import android.content.Context;
import android.util.Log;
import android.widget.Toast;

import com.hid.origo.OrigoKeysApiFacade;
import com.hid.origo.OrigoKeysApiFactory;
import com.hid.origo.api.OrigoMobileKey;
import com.hid.origo.api.OrigoMobileKeys;
import com.hid.origo.api.OrigoMobileKeysCallback;
import com.hid.origo.api.OrigoMobileKeysException;
import com.hid.origo.api.OrigoMobileKeysProgressCallback;
import com.hid.origo.api.OrigoProgressEvent;
import com.hid.origo.api.OrigoReaderConnectionController;
import com.hid.origo.api.ble.OrigoScanConfiguration;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;

import edu.illinois.rokwire.App;

public class MobileAccessKeysApiFacade implements OrigoKeysApiFacade {

    private static final String TAG = "MobileAccessKeysApiFacade";

    private final OrigoMobileKeys mobileKeys;
    private final OrigoKeysApiFactory mobileKeysApiFactory;
    private final Context context;

    public MobileAccessKeysApiFacade(Activity context) {
        this.context = context;
        App application = (App) context.getApplication();
        this.mobileKeysApiFactory = application.getMobileApiKeysFactory();
        this.mobileKeys = mobileKeysApiFactory.getMobileKeys();
    }

    //region Public APIs

    public void onApplicationStartup() {
        getMobileKeys().applicationStartup(mobileKeysStartupCallBack);
    }

    public void setupEndpoint(String invitationCode) {
        if (!isEndpointSetUpComplete()) {
            getMobileKeys().endpointSetup(mobileKeysEndpointSetupCallBack, invitationCode);
        }
    }

    public void unregisterEndpoint() {
        if (isEndpointSetUpComplete()) {
            getMobileKeys().unregisterEndpoint(mobileKeysUnregisterEndpointCallBack);
        }
    }

    public List<HashMap<String, Object>> getKeysDetails() {
        if (!isEndpointSetUpComplete()) {
            Log.d(TAG, "getKeysDetails: Mobile Access Keys endpoint is not set up.");
            return null;
        }
        if (getMobileKeys() != null) {
            SimpleDateFormat dateFormat = new SimpleDateFormat("yyyy-MM-dd", Locale.getDefault());
            try {
                List<OrigoMobileKey> origoMobileKeys = getMobileKeys().listMobileKeys();
                if ((origoMobileKeys != null) && !origoMobileKeys.isEmpty()) {
                    List<HashMap<String, Object>> keysJson = new ArrayList<>();
                    for (OrigoMobileKey key : origoMobileKeys) {
                        Calendar endCalendarDate = key.getEndDate();
                        HashMap<String, Object> keyJson = new HashMap<>();
                        keyJson.put("label", key.getLabel());
                        keyJson.put("card_number", key.getCardNumber());
                        keyJson.put("issuer", key.getIssuer());
                        keyJson.put("type", key.getType());
                        keyJson.put("external_id", key.getExternalId());
                        if (endCalendarDate != null) {
                            keyJson.put("expiration_date", dateFormat.format(endCalendarDate.getTime()));
                        }
                        keysJson.add(keyJson);
                    }
                    return keysJson;
                }
            } catch (OrigoMobileKeysException e) {
                Log.e(TAG, String.format("Failed to list mobile keys. Cause message: %s \nError code: %s", e.getCauseMessage(), e.getErrorCode()));
                e.printStackTrace();
            }
        }
        return null;
    }

    //endregion

    //region OrigoKeysApiFacade implementation

    @Override
    public void onStartUpComplete() {
        Log.d(TAG, "onStartUpComplete");
        if (isEndpointSetUpComplete()) {
            getMobileKeys().endpointUpdate(mobileKeysEndpointUpdateCallBack);
        }
    }

    @Override
    public void onEndpointSetUpComplete() {
        Log.d(TAG, "onEndpointSetUpComplete");
    }

    @Override
    public void endpointNotPersonalized() {
        Log.d(TAG, "endpointNotPersonalized");
    }

    @Override
    public boolean isEndpointSetUpComplete() {
        boolean isEndpointSetup = false;
        try {
            isEndpointSetup = mobileKeys.isEndpointSetupComplete();
        } catch (OrigoMobileKeysException e) {
            Log.d(TAG, "isEndpointSetUpComplete: exception: " + e.getCauseMessage() + "\n\n" + e.getMessage());
            e.printStackTrace();
        }
        return isEndpointSetup;
    }

    @Override
    public OrigoMobileKeys getMobileKeys() {
        return mobileKeysApiFactory.getMobileKeys();
    }

    @Override
    public OrigoReaderConnectionController getReaderConnectionController() {
        return mobileKeysApiFactory.getReaderConnectionController();
    }

    @Override
    public OrigoScanConfiguration getOrigoScanConfiguration() {
        return mobileKeysApiFactory.getOrigoScanConfiguration();
    }

    //endregion

    //region OrigoMobileKeysCallback implementation

    private final OrigoMobileKeysCallback mobileKeysStartupCallBack = new OrigoMobileKeysCallback() {
        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysStartupCallBack: handleMobileKeysTransactionCompleted");
            onStartUpComplete();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysStartupCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
        }
    };

    private final OrigoMobileKeysCallback mobileKeysEndpointSetupCallBack = new OrigoMobileKeysCallback() {
        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysEndpointSetupCallBack: handleMobileKeysTransactionCompleted");
            Toast.makeText(context, "Mobile Access: Register Endpoint - succeeded", Toast.LENGTH_SHORT).show();
            onEndpointSetUpComplete();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysEndpointSetupCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
            Toast.makeText(context, "Mobile Access: Register Endpoint - failed: " + e.getErrorCode(), Toast.LENGTH_SHORT).show();
        }
    };

    //endregion

    //region OrigoMobileKeysProgressCallback implementation

    private final OrigoMobileKeysProgressCallback mobileKeysEndpointUpdateCallBack = new OrigoMobileKeysProgressCallback() {

        @Override
        public void handleMobileKeysTransactionProgress(OrigoProgressEvent origoProgressEvent) {
            Log.d(TAG, "mobileKeysEndpointUpdateCallBack: handleMobileKeysTransactionProgress: OrigoProgressEvent: " + origoProgressEvent.progressType());

        }

        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysEndpointUpdateCallBack: handleMobileKeysTransactionCompleted");
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysEndpointUpdateCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
        }
    };

    private final OrigoMobileKeysProgressCallback mobileKeysUnregisterEndpointCallBack = new OrigoMobileKeysProgressCallback() {

        @Override
        public void handleMobileKeysTransactionProgress(OrigoProgressEvent origoProgressEvent) {
            Log.d(TAG, "mobileKeysUnregisterEndpointCallBack: handleMobileKeysTransactionProgress: OrigoProgressEvent: " + origoProgressEvent.progressType());

        }

        @Override
        public void handleMobileKeysTransactionCompleted() {
            Log.d(TAG, "mobileKeysUnregisterEndpointCallBack: handleMobileKeysTransactionCompleted");
            Toast.makeText(context, "Mobile Access: Unregister Endpoint - succeeded", Toast.LENGTH_SHORT).show();
        }

        @Override
        public void handleMobileKeysTransactionFailed(OrigoMobileKeysException e) {
            Log.d(TAG, "mobileKeysUnregisterEndpointCallBack: handleMobileKeysTransactionFailed: " + e.getErrorCode(), e);
            Toast.makeText(context, "Mobile Access: Unregister Endpoint - failed: " + e.getErrorCode(), Toast.LENGTH_SHORT).show();
        }
    };

    //endregion
}
