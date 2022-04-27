
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/geo_fence.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class OnCampus with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.oncampus.state.changed";

  // Singletone instance

  static final OnCampus _service = OnCampus._internal();
  factory OnCampus() => _service;

  OnCampus._internal();

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Config.notifyConfigChanged,
      LocationServices.notifyStatusChanged,
      FlexUI.notifyChanged,
      Auth2.notifyPrefsChanged,
    ]);
  }

  @override
  Future<void> initService() async {
    super.initService();
    _update();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), Auth2(), FlexUI(), GeoFence(), LocationServices()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if ((name == Config.notifyConfigChanged) ||
        (name == LocationServices.notifyStatusChanged) ||
        (name == FlexUI.notifyChanged) ||
        (name == Auth2.notifyPrefsChanged))
    {
      if (isInitialized) {
        _update();
      }
    }
  }

  // Implementation

  bool get enabled => Auth2().privacyMatch(2) && (LocationServices().lastStatus != LocationServicesStatus.serviceDisabled);

  bool get isGies => FlexUI().hasFeature('gies');

  bool get defaultInsideCampusValue => isGies ? false : true;

  bool get monitorEnabled => enabled && (
    (Storage().onCampusRegionMonitorEnabled == true) ||
    ((Storage().onCampusRegionMonitorEnabled == null) && !isGies));

  set monitorEnabled(bool? value) {
    if (enabled && (Storage().onCampusRegionMonitorEnabled != value)) {
      Storage().onCampusRegionMonitorEnabled = value;
      _update();
    }
  }

  bool get monitorManualInside => !monitorEnabled &&
    (Storage().onCampusRegionManualInside ?? defaultInsideCampusValue);

  set monitorManualInside(bool? value) {
    if (!monitorEnabled && (Storage().onCampusRegionManualInside != value)) {
      Storage().onCampusRegionManualInside = value;
      _update();
    }
  }

  bool? get _regionOverride {
    if ((enabled == false) ||
        (Storage().onCampusRegionMonitorEnabled == false) ||
        ((Storage().onCampusRegionMonitorEnabled == null) && isGies)) {
      return Storage().onCampusRegionManualInside ?? defaultInsideCampusValue;
    }
    return null;
  }

  void _update() {
    Map<String, bool>? regionOverrides;
    Map<String, bool> geoFenceRegionOverrides = GeoFence().regionOverrides; 
    String? campusRegionId = JsonUtils.stringValue(Config().settings['campusRegionId']);
    
    // handle the case when settings.campusRegionId get changed
    String? currentCampusRegionId = Storage().onCampusRegionId;
    if ((currentCampusRegionId != null) && (campusRegionId != currentCampusRegionId) && (geoFenceRegionOverrides[currentCampusRegionId] != null)) {
      regionOverrides ??= Map<String, bool>.from(geoFenceRegionOverrides);
      regionOverrides.remove(currentCampusRegionId);
    }

    // evaluate and apply campus override
    if (campusRegionId != null) {
      bool? campusRegionOverride = _regionOverride;
      if (campusRegionOverride != geoFenceRegionOverrides[campusRegionId]) {
        regionOverrides ??= Map<String, bool>.from(geoFenceRegionOverrides);
        if (campusRegionOverride != null) {
          regionOverrides[campusRegionId] = campusRegionOverride;
          Storage().onCampusRegionId = campusRegionId;
        }
        else {
          regionOverrides.remove(campusRegionId);
        }
      }
    }

    // if we updatated anything from region overrides - apply it to GeoFence service.
    if (regionOverrides != null) {
      GeoFence().regionOverrides = regionOverrides;
      NotificationService().notify(notifyChanged);
    }
  }
}