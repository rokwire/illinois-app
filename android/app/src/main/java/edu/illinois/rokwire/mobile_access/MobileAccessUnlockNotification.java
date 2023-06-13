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

import android.annotation.TargetApi;
import android.app.Notification;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.os.Build;

import androidx.core.app.NotificationCompat;
import androidx.core.content.ContextCompat;
import edu.illinois.rokwire.R;

import static androidx.core.app.NotificationCompat.VISIBILITY_SECRET;
import static java.util.Objects.requireNonNull;

public class MobileAccessUnlockNotification {

    public static final String MOBILE_ACCESS_UNLOCK_NOTIFICATION_CHANNEL_ID = "mobile_access_unlock";

    private MobileAccessUnlockNotification() {
    }

    public static Notification create(Context context) {
        if (Build.VERSION.SDK_INT >= 26) {
            // 26 requires a notification channel for notifications to appear
            createNotificationChannel(context);
        }

        final NotificationCompat.Builder builder = notificationBuilder(context, MOBILE_ACCESS_UNLOCK_NOTIFICATION_CHANNEL_ID)
                .setContentTitle(context.getString(R.string.mobile_access_notif_content_title))
                .setStyle(new NotificationCompat.BigTextStyle()
                        .setBigContentTitle(context.getString(R.string.mobile_access_notif_content_title)))
                .setOnlyAlertOnce(true)
                .setVisibility(VISIBILITY_SECRET);

        return builder.build();
    }

    @TargetApi(26)
    private static void createNotificationChannel(Context context) {
        NotificationChannel channel = new NotificationChannel(MOBILE_ACCESS_UNLOCK_NOTIFICATION_CHANNEL_ID,
                context.getString(R.string.mobile_access_notif_foreground_service_title),
                NotificationManager.IMPORTANCE_LOW);

        requireNonNull(context.getSystemService(NotificationManager.class))
                .createNotificationChannel(channel);
    }

    public static NotificationCompat.Builder notificationBuilder(Context context, String channelId) {
        return new NotificationCompat.Builder(context, channelId)
                .setColor(ContextCompat.getColor(context, R.color.white))
                .setSmallIcon(R.drawable.app_icon);
    }
}
