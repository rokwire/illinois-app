
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Storage.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/app_notification.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AppReview with Service implements NotificationsListener {

  DateTime? _sessionStartDateTime;
  Timer? _requestTimer;

  // Singleton Factory

  static final AppReview _instance = AppReview._internal();
  factory AppReview() => _instance;
  AppReview._internal();

  // Service

  void createService() {
    super.createService();
    NotificationService().subscribe(this,[
      AppLivecycle.notifyStateChanged,
      AppNotification.notify,
      Analytics.notifyEvent,
      Auth2.notifyAccountChanged,
    ]);
  }

  @override
  void destroyService() {
    super.destroyService();
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _startSession();
    await super.initService();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Config(), Storage(), AppLivecycle()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == AppNotification.notify) {
      _onAppNotification(param);
    }
    else if (name == Analytics.notifyEvent) {
      _onAnalyticsEvent(param);
    }
    else if (name == Auth2.notifyAccountChanged) {

    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {

    if (state == AppLifecycleState.resumed) {
      _startSession();
    }
    else if ((state == AppLifecycleState.paused) || (state == AppLifecycleState.detached)) {
      _endSession();
    }
  }

  void _startSession() {
    _sessionStartDateTime = DateTime.now();
  }

  void _endSession() {
    _requestTimer?.cancel();
    _requestTimer = null;

    if (_isValidSession) {
      Storage().appReviewSessionsCount++;
    }
  }

  void _onAppNotification(Notification notification) {
    _scheduleReviewRequest();
  }

  void _onAnalyticsEvent(Map<String, dynamic>? event) {
    _scheduleReviewRequest();
  }

  void _scheduleReviewRequest() {
    if (_canRequestReview) {
      _requestTimer?.cancel();
      _requestTimer = Timer(Duration(seconds: Config().appReviewActivityTimeout), () {
        _requestTimer = null;
        if (_isValidSession) {
          _requestReview();
        }
      });
    }
  }

  bool get _isValidSession {
    if (_sessionStartDateTime != null) {
      Duration sessionDuration = DateTime.now().difference(_sessionStartDateTime!);
      if (Config().appReviewSessionDuration < sessionDuration.inSeconds) {
        return true;
      }
    }
    return false;
  }

  String? get _appVersion  => AppVersion.majorVersion(Config().appVersion, 2);
  String? get _appPlatform  => Platform.operatingSystem.toLowerCase();
  String get _appReviewRequestTimeKey  => 'edu.illinois.rokwire.$_appPlatform.$_appVersion.app_review.request.time';
  int? get _appReviewRequestTime => Auth2().prefs?.getIntSetting(_appReviewRequestTimeKey);
  set _appReviewRequestTime(int? value) => Auth2().prefs?.applySetting(_appReviewRequestTimeKey, value);

  bool get _canRequestReview {
    if (!(Auth2().account?.isAnalyticsProcessed ?? false)) {
      // Account not enabled for review
      return false;
    }

    if (Storage().appReviewSessionsCount < Config().appReviewSessionsCount) {
      // Number of sessions is not enough.
      return false;
    }

    if (!_isValidSession) {
      // Session is less than Config().appReviewSessionDuration.
      return false; 
    }

    int? lastRequestTime = _appReviewRequestTime;
    if (lastRequestTime != null) {
      DateTime lastRequestDate = DateTime.fromMillisecondsSinceEpoch(lastRequestTime);
      if (_sessionStartDateTime?.isBefore(lastRequestDate) ?? false) {
        // Review allready requested in this session
        return false;
      }

      DateTime lastRequestMidnight = DateTimeUtils.midnight(lastRequestDate)!;
      DateTime todayMidnight = DateTimeUtils.midnight(DateTime.now())!;
      int lastRequestDelay = todayMidnight.difference(lastRequestMidnight).inDays;
      if (lastRequestDelay < Config().appReviewRequestTimeout) {
        // Config().appReviewRequestTimeout not passed since the last request date
        return false;
      }
    }

    // Everything seems OK now.
    return true;
  }

  void _requestReview() {
    final InAppReview inAppReview = InAppReview.instance;
    inAppReview.isAvailable().then((bool result) {
      if (result && _isValidSession) {
        _appReviewRequestTime = DateTime.now().millisecondsSinceEpoch;
        inAppReview.requestReview();
      }
    });
  }
}