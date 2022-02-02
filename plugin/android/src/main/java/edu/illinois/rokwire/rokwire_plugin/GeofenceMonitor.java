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

import android.Manifest;
import android.app.Activity;
import android.app.PendingIntent;
import android.content.Context;
import android.content.Intent;
import android.content.ServiceConnection;
import android.content.pm.PackageManager;
import android.os.RemoteException;
import android.util.Log;

import com.google.android.gms.location.Geofence;
import com.google.android.gms.location.GeofencingClient;
import com.google.android.gms.location.GeofencingEvent;
import com.google.android.gms.location.GeofencingRequest;
import com.google.android.gms.location.LocationServices;
import com.google.android.gms.tasks.OnFailureListener;
import com.google.android.gms.tasks.OnSuccessListener;

import org.altbeacon.beacon.Beacon;
import org.altbeacon.beacon.BeaconConsumer;
import org.altbeacon.beacon.BeaconManager;
import org.altbeacon.beacon.BeaconParser;
import org.altbeacon.beacon.Identifier;
import org.altbeacon.beacon.MonitorNotifier;
import org.altbeacon.beacon.Region;

import java.util.ArrayList;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;

import androidx.annotation.NonNull;
import androidx.core.content.ContextCompat;

import io.flutter.embedding.engine.plugins.FlutterPlugin;
import io.flutter.plugin.common.BinaryMessenger;
import io.flutter.plugin.common.EventChannel;
import io.flutter.plugin.common.MethodCall;
import io.flutter.plugin.common.MethodChannel;

public class GeofenceMonitor implements BeaconConsumer {

    private static final String TAG = GeofenceMonitor.class.getCanonicalName();
    private static final int BEACON_INVALID_VALUE = -420000;

    private static GeofenceMonitor instance = null;

    private GeofencingClient geofencingClient;
    private PendingIntent geofencePendingIntent;
    private List<String> currentRegionIds = new ArrayList<>();
    private Map<String, EntryGeofenceMap> geofenceRegions;

    // Beacons
    private BeaconManager beaconManager;
    private Map<String, Region> beaconRegions;
    private Map<String, Collection<Beacon>> currentRegionBeacons = new HashMap<>();

    public static GeofenceMonitor getInstance() {
        if (instance == null) {
            instance = new GeofenceMonitor();
        }
        return instance;
    }

    //region Public API

    public void init() {
        Context activityContext = RokwirePlugin.getInstance().getActivity();
        if ((activityContext != null) &&
            (ContextCompat.checkSelfPermission(activityContext, android.Manifest.permission.ACCESS_COARSE_LOCATION) == PackageManager.PERMISSION_GRANTED) &&
            (ContextCompat.checkSelfPermission(activityContext, Manifest.permission.ACCESS_FINE_LOCATION) == PackageManager.PERMISSION_GRANTED)) {
            Log.d(TAG, "Location Permissions Granted.");
            initGeofenceClient();
            initBeaconManager();
        }
    }

    public void unInit() {
        unInitGeofenceClient();
        unInitBeaconManager();
    }

    public boolean isInitialized() {
        return isGeofenceClientInitialized() && isBeaconManagerInitialized();
    }

    public void onLocationPermissionGranted() {
        initGeofenceClient();
        initBeaconManager();
    }

    public void monitorRegions(List<Map<String, Object>> regions) {
        monitor(regions);
    }

    public List<String> getCurrentIds() {
        return currentRegionIds;
    }

    public boolean startRangingBeaconsInRegion(String regionId) {
        if (Utils.Str.isEmpty(regionId)) {
            return false;
        }
        Region region = (beaconRegions != null) ? beaconRegions.get(regionId) : null;
        if ((region != null) && (beaconManager != null)) {
            Collection<Region> rangingRegions = beaconManager.getRangedRegions();
            if (!rangingRegions.contains(region)) {
                try {
                    beaconManager.startRangingBeaconsInRegion(region);
                    return true;
                } catch (RemoteException e) {
                    Log.e(TAG, "Failed to start ranging region with id: " + regionId);
                    e.printStackTrace();
                    return false;
                }
            }
        }
        return false;
    }

    public boolean stopRangingBeaconsInRegion(String regionId) {
        if (!Utils.Str.isEmpty(regionId)) {
            Region region = (beaconRegions != null) ? beaconRegions.get(regionId) : null;
            return stopRangingBeaconsInRegion(region);
        } else {
            stopAllRangingBeacons();
            return true;
        }
    }

    public List<HashMap> getBeaconsInRegion(String regionId) {
        if (Utils.Str.isEmpty(regionId)) {
            return null;
        }
        Collection<Beacon> regionBeacons = currentRegionBeacons.get(regionId);
        if (regionBeacons == null || regionBeacons.isEmpty()) {
            return null;
        }
        return Utils.Beacons.toListMap(regionBeacons);
    }

    //endregion

    void handleGeofenceTransition(@NonNull GeofencingEvent geofencingEvent) {
        if (geofencingEvent.hasError()) {
            Log.e(TAG, "GeofencingEvent error code: " + geofencingEvent.getErrorCode());
            return;
        }
        List<Geofence> triggeringGeofences = geofencingEvent.getTriggeringGeofences();
        if (triggeringGeofences == null || triggeringGeofences.isEmpty()) {
            Log.e(TAG, "There are no triggering geofences!");
            return;
        }
        int transitionCode = geofencingEvent.getGeofenceTransition();
        boolean notifyForGeofencesUpdate = false;
        switch (transitionCode) {
            case Geofence.GEOFENCE_TRANSITION_ENTER: {
                for (Geofence triggeringGeofence : triggeringGeofences) {
                    String geofenceId = triggeringGeofence.getRequestId();
                    if (!currentRegionIds.contains(geofenceId)) {
                        currentRegionIds.add(geofenceId);
                        notifyForGeofencesUpdate = true;
                        notifyRegionEnter(geofenceId);
                    }
                }
            }
            break;
            case Geofence.GEOFENCE_TRANSITION_EXIT: {
                for (Geofence triggeringGeofence : triggeringGeofences) {
                    String geofenceId = triggeringGeofence.getRequestId();
                    if (currentRegionIds.contains(geofenceId)) {
                        currentRegionIds.remove(geofenceId);
                        notifyForGeofencesUpdate = true;
                        notifyRegionExit(geofenceId);
                    }
                }
            }
            break;
            default:
                Log.e(TAG, "Invalid geofence transition code: " + transitionCode);
                break;
        }
        if (notifyForGeofencesUpdate) {
            notifyCurrentGeofencesUpdated();
        }
    }

    private void initGeofenceClient() {
        if (geofencingClient != null) {
            Log.d(TAG, "initGeofenceClient() -> Monitoring already started");
            return;
        }

        Activity activity = RokwirePlugin.getInstance().getActivity();
        if (activity == null) {
            Log.d(TAG, "initGeofenceClient() -> No binded activity");
            return;
        }

        geofencingClient = LocationServices.getGeofencingClient(activity);
        if (geofenceRegions != null && !geofenceRegions.isEmpty()) {
            List<EntryGeofenceMap> entryGeofenceMaps = new ArrayList<>(geofenceRegions.values());
            if (!entryGeofenceMaps.isEmpty()) {
                List<Geofence> geofenceList = new ArrayList<>();
                for (EntryGeofenceMap geofenceMapEntry : entryGeofenceMaps) {
                    geofenceList.add(geofenceMapEntry.geofence);
                }
                startMonitorGeofenceRegions(geofenceList);
            }
        }
    }

    private void unInitGeofenceClient() {
        if (geofencingClient != null) {
            geofencingClient.removeGeofences(getGeofencePendingIntent());
            geofencingClient = null;
        }
    }

    private boolean isGeofenceClientInitialized() {
        return (geofencingClient != null);
    }

    private void monitor(List<Map<String, Object>> geofenceEntries) {
        List<String> newGeofenceIds = new ArrayList<>();
        List<Geofence> newGeofences = new ArrayList<>();
        List<String> newBeaconRegionIds = new ArrayList<>();
        List<Region> newBeaconRegions = new ArrayList<>();
        if ((geofenceEntries != null) && !geofenceEntries.isEmpty()) {
            if (geofenceRegions == null) {
                geofenceRegions = new HashMap<>();
            }
            if (beaconRegions == null) {
                beaconRegions = new HashMap<>();
            }
            for (Map<String, Object> regionEntry : geofenceEntries) {
                if (regionEntry != null) {
                    String id = Utils.Map.getValueFromPath(regionEntry, "id", null);
                    // Geofence regions
                    if (regionEntry.containsKey("location")) {
                        double lat = Utils.Map.getValueFromPath(regionEntry, "location.latitude", 0.0);
                        double lng = Utils.Map.getValueFromPath(regionEntry, "location.longitude", 0.0);
                        double radius = Utils.Map.getValueFromPath(regionEntry, "location.radius", 0.0);
                        Geofence geofence = new Geofence.Builder().
                                setRequestId(id).
                                setCircularRegion(lat, lng, (int) radius).
                                setExpirationDuration(Geofence.NEVER_EXPIRE).
                                setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER | Geofence.GEOFENCE_TRANSITION_EXIT).
                                build();
                        geofenceRegions.put(id, new EntryGeofenceMap(regionEntry, geofence));

                        newGeofenceIds.add(id);
                        newGeofences.add(geofence);
                    }
                    // Beacon Regions
                    else if (regionEntry.containsKey("beacon")) {
                        String uuidString = Utils.Map.getValueFromPath(regionEntry, "beacon.uuid", null);
                        int major = Utils.Map.getValueFromPath(regionEntry, "beacon.major", BEACON_INVALID_VALUE);
                        int minor = Utils.Map.getValueFromPath(regionEntry, "beacon.minor", BEACON_INVALID_VALUE);
                        Region beaconRegion = null;
                        if ((uuidString != null) && (major != BEACON_INVALID_VALUE) && (minor != BEACON_INVALID_VALUE)) {
                            beaconRegion = new Region(id, Identifier.fromUuid(UUID.fromString(uuidString)), Identifier.fromInt(major), Identifier.fromInt(minor));
                        } else if ((uuidString != null) && (major != BEACON_INVALID_VALUE)) {
                            beaconRegion = new Region(id, Identifier.fromUuid(UUID.fromString(uuidString)), Identifier.fromInt(major), null);
                        } else if ((uuidString != null)) {
                            beaconRegion = new Region(id, Identifier.fromUuid(UUID.fromString(uuidString)), null, null);
                        }
                        if (beaconRegion != null) {
                            beaconRegions.put(id, beaconRegion);
                            newBeaconRegionIds.add(id);
                            newBeaconRegions.add(beaconRegion);
                        }
                    }
                }
            }
            boolean regionsChanged = false;

            // Geofence regions
            startMonitorGeofenceRegions(newGeofences);
            List<String> removeGeofenceIds = new ArrayList<>();
            for (String geofenceId : geofenceRegions.keySet()) {
                if (!newGeofenceIds.contains(geofenceId)) {
                    removeGeofenceIds.add(geofenceId);
                }
            }
            for (String geofenceId : removeGeofenceIds) {
                geofenceRegions.remove(geofenceId);
                currentRegionIds.remove(geofenceId);
            }
            stopMonitorGeofenceRegions(removeGeofenceIds);
            if (removeGeofenceIds.size() > 0) {
                regionsChanged = true;
            }

            // Beacon Regions
            startMonitorBeaconRegions(newBeaconRegions);
            List<Region> removeBeaconRegions = new ArrayList<>();
            for (Region beaconRegion : beaconRegions.values()) {
                if (!newBeaconRegionIds.contains(beaconRegion.getUniqueId())) {
                    removeBeaconRegions.add(beaconRegion);
                    stopRangingBeaconsInRegion(beaconRegion);
                }
            }
            for (Region beaconRegion : removeBeaconRegions) {
                beaconRegions.remove(beaconRegion.getUniqueId());
                currentRegionIds.remove(beaconRegion.getUniqueId());
            }
            stopMonitorBeaconRegions(removeBeaconRegions);
            if (removeBeaconRegions.size() > 0) {
                regionsChanged = true;
            }

            // Notify if changed
            if (regionsChanged) {
                notifyCurrentGeofencesUpdated();
            }
        }
    }

    private void startMonitorGeofenceRegions(List<Geofence> geofenceList) {
        if (geofenceList == null || geofenceList.isEmpty()) {
            return;
        }
        if (geofencingClient == null) {
            return;
        }
        GeofencingRequest.Builder builder = new GeofencingRequest.Builder();
        builder.setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER);
        builder.addGeofences(geofenceList);
        GeofencingRequest geofencingRequest = builder.build();
        geofencingClient.addGeofences(geofencingRequest, getGeofencePendingIntent()).
                addOnSuccessListener(addGeofencesSuccessListener).
                addOnFailureListener(addGeofencesFailureListener);
    }

    private void stopMonitorGeofenceRegions(List<String> geofenceIdList) {
        if (geofenceIdList == null || geofenceIdList.isEmpty()) {
            return;
        }
        if (geofencingClient == null) {
            return;
        }
        geofencingClient.removeGeofences(geofenceIdList).
                addOnSuccessListener(removeGeofencesSuccessListener).
                addOnFailureListener(removeGeofencesFailureListener);
    }

    private PendingIntent getGeofencePendingIntent() {
        if (geofencePendingIntent != null) {
            return geofencePendingIntent;
        }
        Intent intent = new Intent(RokwirePlugin.getInstance().getActivity(), GeofenceBroadcastReceiver.class);
        geofencePendingIntent = PendingIntent.getBroadcast(RokwirePlugin.getInstance().getActivity(), 0,
                intent, PendingIntent.FLAG_UPDATE_CURRENT);
        return geofencePendingIntent;
    }

    private void notifyCurrentGeofencesUpdated() {
        //TBD
        RokwirePlugin.getInstance().notifyGeoFence​("onCurrentRegionsChanged", getCurrentIds());
    }

    private void notifyRegionEnter(String regionId) {
        RokwirePlugin.getInstance().notifyGeoFence​("onEnterRegion", regionId);
    }

    private void notifyRegionExit(String regionId) {
        RokwirePlugin.getInstance().notifyGeoFence​("onExitRegion", regionId);
    }

    //region Add Geofences Listeners

    private OnSuccessListener<Void> addGeofencesSuccessListener = aVoid -> Log.i(TAG, "Add Geofences -> onSuccess");

    private OnFailureListener addGeofencesFailureListener = e -> {
        Log.e(TAG, "Add Geofences -> onFailure");
        Log.e(TAG, e.getLocalizedMessage());
    };

    //endregion

    //region Remove Geofences Listeners

    private OnSuccessListener<Void> removeGeofencesSuccessListener = aVoid -> Log.i(TAG, "Remove Geofences -> onSuccess");

    private OnFailureListener removeGeofencesFailureListener = e -> {
        Log.e(TAG, "Remove Geofences -> onFailure");
        Log.e(TAG, e.getLocalizedMessage());
    };

    //endregion

    //region Beacon scanner

    private void initBeaconManager() {
        if (beaconManager != null) {
            Log.d(TAG, "initBeaconManager() -> Monitoring already started");
            return;
        }
        Context context = RokwirePlugin.getInstance().getActivity();
        if (context == null) {
            Log.d(TAG, "initBeaconManager() -> No binded activity");
            return;
        }
        beaconManager = BeaconManager.getInstanceForApplication(context);
        // Layout for iBeacons
        beaconManager.getBeaconParsers().add(new BeaconParser().setBeaconLayout("m:2-3=0215,i:4-19,i:20-21,i:22-23,p:24-24"));
        beaconManager.bind(this);

        if (beaconRegions != null && !beaconRegions.isEmpty()) {
            List<Region> beaconRegionList = new ArrayList<>(beaconRegions.values());
            if (!beaconRegionList.isEmpty()) {
                startMonitorBeaconRegions(beaconRegionList);
            }
        }
    }

    private void unInitBeaconManager() {
        if (beaconManager != null) {
            beaconManager.removeAllMonitorNotifiers();
            beaconManager.removeAllRangeNotifiers();
            beaconManager.unbind(this);
            beaconManager = null;
        }
    }

    private boolean isBeaconManagerInitialized() {
        return (beaconManager != null);
    }

    private void startMonitorBeaconRegions(List<Region> beaconRegions) {
        if (beaconRegions == null || beaconRegions.isEmpty()) {
            return;
        }
        if (beaconManager == null) {
            return;
        }
        for (Region region : beaconRegions) {
            try {
                beaconManager.startMonitoringBeaconsInRegion(region);
            } catch (RemoteException e) {
                Log.e(TAG, "Failed to start monitor beacon region with id: " + region.getUniqueId());
                e.printStackTrace();
            }
        }
    }

    private void stopMonitorBeaconRegions(List<Region> beaconRegions) {
        if (beaconRegions == null || beaconRegions.isEmpty()) {
            return;
        }
        if (beaconManager == null) {
            return;
        }
        for (Region region : beaconRegions) {
            try {
                beaconManager.stopMonitoringBeaconsInRegion(region);
            } catch (RemoteException e) {
                Log.e(TAG, "Failed to stop monitor beacon region with id: " + region.getUniqueId());
                e.printStackTrace();
            }
        }
    }

    private void rangedBeaconsInRegion(Collection<Beacon> beacons, String regionId) {
        if (Utils.Str.isEmpty(regionId)) {
            return;
        }
        Collection<Beacon> currentBeacons = currentRegionBeacons.get(regionId);
        if (!Utils.Beacons.equalCollections(currentBeacons, beacons)) {
            if (beacons != null) {
                currentRegionBeacons.put(regionId, beacons);
            } else {
                currentRegionBeacons.remove(regionId);
            }
            List<HashMap> beaconsList = null;
            if (beacons != null && !beacons.isEmpty()) {
                beaconsList = Utils.Beacons.toListMap(beacons);
            }
            notifyBeacons(beaconsList, regionId);
        }
    }

    private boolean stopRangingBeaconsInRegion(Region region) {
        String regionId = (region != null) ? region.getUniqueId() : null;
        if (Utils.Str.isEmpty(regionId)) {
            return false;
        }
        if (beaconManager != null) {
            try {
                beaconManager.stopRangingBeaconsInRegion(region);
            } catch (RemoteException e) {
                Log.e(TAG, "Failed to stop ranging beacons in region with id: " + regionId);
                e.printStackTrace();
                return false;
            }
            if (currentRegionBeacons.get(regionId) != null) {
                currentRegionBeacons.remove(regionId);
                notifyBeacons(null, regionId);
            }
            return true;
        }
        return false;
    }

    private void stopAllRangingBeacons() {
        if (beaconRegions != null && !beaconRegions.isEmpty()) {
            for (String regionId : beaconRegions.keySet()) {
                stopRangingBeaconsInRegion(regionId);
            }
        }
    }

    private void notifyBeacons(List<HashMap> beaconsList, String regionId) {
        HashMap<String, Object> parameters = new HashMap<>();
        parameters.put("regionId", regionId);
        parameters.put("beacons", beaconsList);
        RokwirePlugin.getInstance().notifyGeoFence​("onBeaconsInRegionChanged", parameters);
    }

    @Override
    public void onBeaconServiceConnect() {
        if (beaconManager != null) {
            beaconManager.removeAllMonitorNotifiers();
            beaconManager.removeAllRangeNotifiers();

            // Monitor Listener
            beaconManager.addMonitorNotifier(new MonitorNotifier() {
                @Override
                public void didEnterRegion(Region region) {
                    String beaconRegionId = region.getUniqueId();
                    Log.i(TAG, "BeaconScanner.didEnterRegion with id: " + beaconRegionId);
                    if (!currentRegionIds.contains(beaconRegionId)) {
                        currentRegionIds.add(beaconRegionId);
                        notifyRegionEnter(beaconRegionId);
                        notifyCurrentGeofencesUpdated();
                    }
                }

                @Override
                public void didExitRegion(Region region) {
                    String beaconRegionId = region.getUniqueId();
                    Log.i(TAG, "BeaconScanner.didExitRegion with id: " + beaconRegionId);
                    if (currentRegionIds.contains(beaconRegionId)) {
                        currentRegionIds.remove(beaconRegionId);
                        notifyRegionExit(beaconRegionId);
                        notifyCurrentGeofencesUpdated();
                        stopRangingBeaconsInRegion(region);
                    }
                }

                @Override
                public void didDetermineStateForRegion(int state, Region region) {
                    String regionId = region.getUniqueId();
                    Log.i(TAG, "BeaconScanner.didDetermineStateForRegion with id: " + regionId + " and state: " + state);
                    boolean changed;
                    if (state == INSIDE) {
                        Log.i(TAG, "BeaconScanner.INSIDE region with id: " + regionId);
                        changed = !currentRegionIds.contains(regionId);
                        currentRegionIds.add(regionId);
                        if (changed) {
                            notifyRegionEnter(regionId);
                            notifyCurrentGeofencesUpdated();
                        }
                    } else if (state == OUTSIDE) {
                        Log.i(TAG, "BeaconScanner.OUTSIDE region with id: " + regionId);
                        changed = currentRegionIds.contains(regionId);
                        currentRegionIds.remove(regionId);
                        if (changed) {
                            notifyRegionExit(regionId);
                            notifyCurrentGeofencesUpdated();
                        }
                        stopRangingBeaconsInRegion(region);
                    }
                }
            });

            // Ranging Listener
            beaconManager.addRangeNotifier((collection, region) -> {
                int beaconsCount = (collection != null) ? collection.size() : 0;
                String regionId = region.getUniqueId();
                Log.i(TAG, String.format(Locale.getDefault(), "BeaconScanner.didRangeBeaconsInRegion: [%d] in region with id '%s'", beaconsCount, regionId));
                rangedBeaconsInRegion(collection, regionId);
            });
        }
    }

    @Override
    public Context getApplicationContext() {
        Log.i(TAG, "BeaconScanner.getApplicationContext");
        if (RokwirePlugin.getInstance() != null) {
            return RokwirePlugin.getInstance().getApplicationContext();
        }
        return null;
    }

    @Override
    public void unbindService(ServiceConnection serviceConnection) {
        Log.i(TAG, "BeaconScanner.unbindService");
    }

    @Override
    public boolean bindService(Intent intent, ServiceConnection serviceConnection, int i) {
        Log.i(TAG, "BeaconScanner.bindService");
        return false;
    }

    //endregion

    public void handleMethodCall(String name, Object params, MethodChannel.Result result) {
        try {
            if ("currentRegions".equals(name)) {
                result.success(getCurrentIds());
            }
            else if ("monitorRegions".equals(name)) {
                List<Map<String, Object>> geoFencesList = (params instanceof List) ? (List<Map<String, Object>>) params : null;
                monitorRegions(geoFencesList);
                result.success(null);
            }
            else if ("startRangingBeaconsInRegion".equals(name)) {
                String regionId = (params instanceof String) ? (String) params : null;
                result.success(startRangingBeaconsInRegion(regionId));
            }
            else if ("stopRangingBeaconsInRegion".equals(name)) {
                String regionId = (params instanceof String) ? (String) params : null;
                result.success(stopRangingBeaconsInRegion(regionId));
            }
            else if("beaconsInRegion".equals(name)) {
                String regionId = (params instanceof String) ? (String) params : null;
                result.success(getBeaconsInRegion(regionId));
            }
            else {
                result.success(null);
            }
        } catch (IllegalStateException exception) {
            String errorMsg = String.format("Ignoring exception '%s'. See https://github.com/flutter/flutter/issues/29092 for details.", exception.toString());
            Log.e(TAG, errorMsg);
            exception.printStackTrace();
        }
    }


    private static class EntryGeofenceMap {
        private Map<String, Object> entry;
        private Geofence geofence;

        private EntryGeofenceMap(Map<String, Object> entry, Geofence geofence) {
            this.entry = entry;
            this.geofence = geofence;
        }
    }
}
