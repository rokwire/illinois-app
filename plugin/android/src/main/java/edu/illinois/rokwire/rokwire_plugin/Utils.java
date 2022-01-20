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

package edu.illinois.rokwire.rokwire_plugin;

import android.app.AlertDialog;
import android.content.Context;
import android.content.DialogInterface;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.drawable.Drawable;
import android.graphics.drawable.GradientDrawable;
import android.text.format.DateUtils;
import android.util.Log;
import android.view.View;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.TextView;

import org.json.JSONException;
import org.json.JSONObject;

import java.nio.ByteBuffer;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Calendar;
import java.util.Collection;
import java.util.Date;
import java.util.Formatter;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Locale;
import java.util.UUID;
import java.lang.Exception;

import androidx.core.content.ContextCompat;
import androidx.security.crypto.MasterKeys;
import androidx.security.crypto.EncryptedSharedPreferences;

import static android.view.View.GONE;
import static android.view.View.VISIBLE;

public class Utils {

    public static class Str {
        public static boolean isEmpty(String value) {
            return (value == null) || value.isEmpty();
        }

        public static String nullIfEmpty(String value) {
            if (isEmpty(value)) {
                return null;
            }
            return value;
        }

        public static byte[] hexStringToByteArray(String s) {
            if(s != null) {
                int len = s.length();
                byte[] data = new byte[len / 2];
                for (int i = 0; i < len; i += 2) {
                    data[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4)
                            + Character.digit(s.charAt(i + 1), 16));
                }
                return data;
            }
            return null;
        }

        public static String byteArrayToHexString(byte[] bytes){
            if(bytes != null) {
                Formatter formatter = new Formatter();
                for (byte b : bytes) {
                    formatter.format("%02x", b);
                }
                return formatter.toString();
            }
            return null;
        }
    }

    public static class AppSharedPrefs {

        public static final String DEFAULT_SHARED_PREFS_FILE_NAME = "default_shared_prefs";

        public static boolean getBool(Context context, String key, boolean defaults) {
            if ((context == null) || Str.isEmpty(key)) {
                return defaults;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            return sharedPreferences.getBoolean(key, defaults);
        }

        public static void saveBool(Context context, String key, boolean value) {
            if ((context == null) || Str.isEmpty(key)) {
                return;
            }
            SharedPreferences sharedPreferences = context.getSharedPreferences(DEFAULT_SHARED_PREFS_FILE_NAME, Context.MODE_PRIVATE);
            SharedPreferences.Editor editor = sharedPreferences.edit();
            editor.putBoolean(key, value);
            editor.apply();
        }
    }

    public static class AppSecureSharedPrefs {

        public static final String SECURE_SHARED_PREFS_FILE_NAME = "secure_shared_prefs";

        public static String getString(Context context, String key, String defaults) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        SECURE_SHARED_PREFS_FILE_NAME,
                        MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC),
                        context,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    return sharedPreferences.getString(key, defaults);
                }
                catch (Exception e) {
                    Log.e("Error", "Failed to create EncryptedSharedPreferences");
                    e.printStackTrace();
                }
            }
            return defaults;
        }

        public static void saveString(Context context, String key, String value) {
            if ((context != null) && !Str.isEmpty(key)) {
                try {
                    SharedPreferences sharedPreferences = EncryptedSharedPreferences.create(
                        SECURE_SHARED_PREFS_FILE_NAME,
                        MasterKeys.getOrCreate(MasterKeys.AES256_GCM_SPEC),
                        context,
                        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
                        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
                    );
                    SharedPreferences.Editor editor = sharedPreferences.edit();
                    editor.putString(key, value);
                    editor.apply();
                }
                catch (Exception e) {
                    Log.e("Error", "Failed to create EncryptedSharedPreferences");
                    e.printStackTrace();
                }
            }
        }

    }
}
