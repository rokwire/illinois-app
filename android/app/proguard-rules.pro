-keep class com.builttoroam.devicecalendar.** { *; }

-keep interface com.mapsindoors.mapssdk.** { *; }
-keep class com.mapsindoors.mapssdk.errors.** { *; }
-keepclassmembers class com.mapsindoors.mapssdk.models.** { <fields>; }
-keep class com.mapsindoors.mapssdk.dbglog

# Ignore all warnings from TapAndPay sdk
-dontwarn com.google.android.gms.tapandpay.**

# Ignore warnings from Origo Wallet packet,
# if the SDK has references to TapAndPay inside
-dontwarn com.hid.origo.wallet.**

# Keep callback interfaces, if the SDK requires
-keep class com.hid.origo.wallet.listener.** { *; }

# (Optional) If we want to be sure that Origo classes won't be removed:
-keep class com.hid.origo.wallet.** { *; }