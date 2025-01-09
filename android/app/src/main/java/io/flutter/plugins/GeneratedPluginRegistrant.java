package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.Log;

import io.flutter.embedding.engine.FlutterEngine;

/**
 * Generated file. Do not edit.
 * This file is generated by the Flutter tool based on the
 * plugins that support the Android platform.
 */
@Keep
public final class GeneratedPluginRegistrant {
  private static final String TAG = "GeneratedPluginRegistrant";
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    try {
      flutterEngine.getPlugins().add(new com.spencerccf.app_settings.AppSettingsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin app_settings, com.spencerccf.app_settings.AppSettingsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.ryanheise.audio_session.AudioSessionPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin audio_session, com.ryanheise.audio_session.AudioSessionPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.connectivity.ConnectivityPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin connectivity_plus, dev.fluttercommunity.plus.connectivity.ConnectivityPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.builttoroam.devicecalendar.DeviceCalendarPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin device_calendar, com.builttoroam.devicecalendar.DeviceCalendarPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin device_info_plus, dev.fluttercommunity.plus.device_info.DeviceInfoPlusPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.fintasys.emoji_picker_flutter.EmojiPickerFlutterPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin emoji_picker_flutter, com.fintasys.emoji_picker_flutter.EmojiPickerFlutterPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin firebase_core, io.flutter.plugins.firebase.core.FlutterFirebaseCorePlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.crashlytics.FlutterFirebaseCrashlyticsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin firebase_crashlytics, io.flutter.plugins.firebase.crashlytics.FlutterFirebaseCrashlyticsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin firebase_messaging, io.flutter.plugins.firebase.messaging.FlutterFirebaseMessagingPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.amolg.flutterbarcodescanner.FlutterBarcodeScannerPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_barcode_scanner, com.amolg.flutterbarcodescanner.FlutterBarcodeScannerPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.gonoter.flutter_beep.FlutterBeepPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_beep, com.gonoter.flutter_beep.FlutterBeepPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.flutterexifrotation.FlutterExifRotationPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_exif_rotation, io.flutter.plugins.flutterexifrotation.FlutterExifRotationPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.kineapps.flutter_file_dialog.FlutterFileDialogPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_file_dialog, com.kineapps.flutter_file_dialog.FlutterFileDialogPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_local_notifications, com.dexterous.flutterlocalnotifications.FlutterLocalNotificationsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.authentrend.flutter_passkey.FlutterPasskeyPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_passkey, com.authentrend.flutter_passkey.FlutterPasskeyPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.endigo.plugins.pdfviewflutter.PDFViewFlutterPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_pdfview, io.endigo.plugins.pdfviewflutter.PDFViewFlutterPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_plugin_android_lifecycle, io.flutter.plugins.flutter_plugin_android_lifecycle.FlutterAndroidLifecyclePlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_secure_storage, com.it_nomads.fluttersecurestorage.FlutterSecureStoragePlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new net.wolverinebeach.flutter_timezone.FlutterTimezonePlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_timezone, net.wolverinebeach.flutter_timezone.FlutterTimezonePlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.linusu.flutter_web_auth_2.FlutterWebAuth2Plugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin flutter_web_auth_2, com.linusu.flutter_web_auth_2.FlutterWebAuth2Plugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.github.ponnamkarthik.toast.fluttertoast.FlutterToastPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin fluttertoast, io.github.ponnamkarthik.toast.fluttertoast.FlutterToastPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new studio.midoridesign.gal.GalPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin gal, studio.midoridesign.gal.GalPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.baseflow.geolocator.GeolocatorPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin geolocator_android, com.baseflow.geolocator.GeolocatorPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.googlemaps.GoogleMapsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin google_maps_flutter_android, io.flutter.plugins.googlemaps.GoogleMapsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.imagepicker.ImagePickerPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin image_picker_android, io.flutter.plugins.imagepicker.ImagePickerPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.britannio.in_app_review.InAppReviewPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin in_app_review, dev.britannio.in_app_review.InAppReviewPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.ryanheise.just_audio.JustAudioPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin just_audio, com.ryanheise.just_audio.JustAudioPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin package_info_plus, dev.fluttercommunity.plus.packageinfo.PackageInfoPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.pathprovider.PathProviderPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin path_provider_android, io.flutter.plugins.pathprovider.PathProviderPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.baseflow.permissionhandler.PermissionHandlerPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin permission_handler_android, com.baseflow.permissionhandler.PermissionHandlerPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.quickactions.QuickActionsPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin quick_actions_android, io.flutter.plugins.quickactions.QuickActionsPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.llfbandit.record.RecordPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin record_android, com.llfbandit.record.RecordPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new edu.illinois.rokwire.rokwire_plugin.RokwirePlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin rokwire_plugin, edu.illinois.rokwire.rokwire_plugin.RokwirePlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.share.SharePlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin share, io.flutter.plugins.share.SharePlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin shared_preferences_android, io.flutter.plugins.sharedpreferences.SharedPreferencesPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.csdcorp.speech_to_text.SpeechToTextPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin speech_to_text, com.csdcorp.speech_to_text.SpeechToTextPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new com.tekartik.sqflite.SqflitePlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin sqflite, com.tekartik.sqflite.SqflitePlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new name.avioli.unilinks.UniLinksPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin uni_links, name.avioli.unilinks.UniLinksPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.urllauncher.UrlLauncherPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin url_launcher_android, io.flutter.plugins.urllauncher.UrlLauncherPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.videoplayer.VideoPlayerPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin video_player_android, io.flutter.plugins.videoplayer.VideoPlayerPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new dev.fluttercommunity.plus.wakelock.WakelockPlusPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin wakelock_plus, dev.fluttercommunity.plus.wakelock.WakelockPlusPlugin", e);
    }
    try {
      flutterEngine.getPlugins().add(new io.flutter.plugins.webviewflutter.WebViewFlutterPlugin());
    } catch (Exception e) {
      Log.e(TAG, "Error registering plugin webview_flutter_android, io.flutter.plugins.webviewflutter.WebViewFlutterPlugin", e);
    }
  }
}
