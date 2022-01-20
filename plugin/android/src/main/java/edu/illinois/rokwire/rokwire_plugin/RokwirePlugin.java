package edu.illinois.rokwire.rokwire_plugin;

import android.app.Activity;
import android.app.Application;
import android.app.Notification;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;

import androidx.annotation.NonNull;
import java.lang.ref.WeakReference;
import android.util.Log;

import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;
import io.flutter.plugin.common.MethodChannel.MethodCallHandler;
import io.flutter.plugin.common.MethodChannel.Result;
import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.embedding.engine.plugins.activity.ActivityAware;
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.PluginRegistry;
import io.flutter.plugin.common.MethodChannel;

/** RokwirePlugin */
public class RokwirePlugin implements FlutterPlugin, MethodCallHandler, ActivityAware, PluginRegistry.ActivityResultListener, PluginRegistry.RequestPermissionsResultListener {
  private static final String TAG = "RokwirePlugin";

  private static RokwirePlugin _instance = null;

  public RokwirePlugin() {
    if (_instance == null) {
      _instance = this;
    }
  }

  public static RokwirePlugin getInstance() {
    return (_instance != null) ? _instance : new RokwirePlugin();
  }

  private ActivityPluginBinding _activityBinding;
  private FlutterPluginBinding _flutterBinding;

  // FlutterPlugin

  @Override
  public void onAttachedToEngine(@NonNull FlutterPluginBinding flutterPluginBinding) {
    _channel = new MethodChannel(flutterPluginBinding.getBinaryMessenger(), "edu.illinois.rokwire/plugin");
    _channel.setMethodCallHandler(this);
    _flutterBinding = flutterPluginBinding;
  }

  @Override
  public void onDetachedFromEngine(@NonNull FlutterPluginBinding binding) {
    _channel.setMethodCallHandler(null);
    _flutterBinding = null;
  }

  // ActivityAware

  @Override
  public void onAttachedToActivity​(ActivityPluginBinding binding) {
    _applyActivityBinding(binding);
  }

  @Override
  public void	onDetachedFromActivity() {
    _applyActivityBinding(null);
  }

  @Override
  public void	onReattachedToActivityForConfigChanges​(ActivityPluginBinding binding) {
    _applyActivityBinding(binding);
  }

  @Override
  public void	onDetachedFromActivityForConfigChanges() {
    _applyActivityBinding(null);
  }

  // MethodCallHandler

  /// The MethodChannel that will the communication between Flutter and native Android
  ///
  /// This local reference serves to register the plugin with the Flutter Engine and unregister it
  /// when the Flutter Engine is detached from the Activity
  private MethodChannel _channel;
  
  @Override
  public void onMethodCall(@NonNull MethodCall call, @NonNull Result result) {

    String firstMethodComponent = call.method, nextMethodComponents = null;
    int pos = call.method.indexOf(".");
    if (0 <= pos) {
      firstMethodComponent = call.method.substring(0, pos);
      nextMethodComponents = call.method.substring(pos + 1);
    }

    if (firstMethodComponent.equals("getPlatformVersion")) {
      result.success("Android " + android.os.Build.VERSION.RELEASE);
    }
    else if (firstMethodComponent.equals("locationServices")) {
      LocationServices.getInstance().handleMethodCall(nextMethodComponents, call.arguments, result);
    }
    else {
      result.notImplemented();
    }
  }

  // PluginRegistry.ActivityResultListener
  
  @Override
  public boolean onActivityResult(int requestCode, int resultCode, Intent data) {
    return false;
  }

  // PluginRegistry.RequestPermissionsResultListener

  @Override
  public boolean onRequestPermissionsResult(int requestCode, String[] permissions, int[] grantResults) {
    if (requestCode == LocationServices.LOCATION_PERMISSION_REQUEST_CODE) {
      return LocationServices.getInstance().onRequestPermissionsResult(requestCode, permissions, grantResults);
    }
    else {
      return false;
    }
  }

  // API

  public Context getApplicationContext() {
    return (_flutterBinding != null) ? _flutterBinding.getApplicationContext() : null;
  }

  public Activity getActivity() {
    return (_activityBinding != null) ? _activityBinding.getActivity() : null;
  }

  // Helpers

  private void _applyActivityBinding(ActivityPluginBinding binding) {
    if (_activityBinding != binding) {
      if (_activityBinding != null) {
        _activityBinding.removeActivityResultListener(this);
        _activityBinding.removeRequestPermissionsResultListener(this);
      }
      _activityBinding = binding;
      if (_activityBinding != null) {
        _activityBinding.addActivityResultListener(this);
        _activityBinding.addRequestPermissionsResultListener(this);
      }
    }
  }

}
