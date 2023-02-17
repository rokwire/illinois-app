/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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

import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Config.dart';
import 'package:http/http.dart' as http;
import 'package:illinois/service/Auth2.dart';

enum AppointmentsTimeSource { upcoming, past }

class Appointments with Service implements ExploreJsonHandler, NotificationsListener {
  static const String notifyAppointmentDetail = "edu.illinois.rokwire.appointments.detail";
  static const String notifyPastAppointmentsChanged = "edu.illinois.rokwire.appointments.past.changed";
  static const String notifyUpcomingAppointmentsChanged = "edu.illinois.rokwire.appointments.upcoming.changed";
  static const String notifyAppointmentsAccountChanged = "edu.illinois.rokwire.appointments.account.changed";
  
  static const String _appointmentRemindersNotificationsEnabledKey = 'edu.illinois.rokwire.settings.inbox.notification.appointments.reminders.notifications.enabled';
  
  DateTime? _pausedDateTime;
  late Directory _appDocDir;

  static const String _upcomingAppointmentsCacheDocName = "upcoming_appointments.json";
  static const String _pastAppointmentsCacheDocName = "past_appointments.json";
  static const String _accountCacheDocName = "appointments_account.json";
  
  List<Appointment>? _upcomingAppointments;
  List<Appointment>? _pastAppointments;
  AppointmentsAccount? _account;
  bool? _isLastAccountResponseSuccessful;

  List<Map<String, dynamic>>? _appointmentDetailsCache;

  // Singleton
  static final Appointments _service = Appointments._internal();
  factory Appointments() => _service;
  Appointments._internal();

  // Service
  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
      AppLifecycle.notifyStateChanged,
      Auth2.notifyLoginChanged
    ]);
    Explore.addJsonHandler(this);
    _appointmentDetailsCache = <Map<String, dynamic>>[];
    super.createService();
  }

  @override
  void destroyService() {
    Explore.removeJsonHandler(this);
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _appDocDir = await getApplicationDocumentsDirectory();

    await Future.wait([
      _initAppointments(timeSource: AppointmentsTimeSource.upcoming).then((appts) => _upcomingAppointments = appts),
      _initAppointments(timeSource: AppointmentsTimeSource.past).then((appts) => _pastAppointments = appts),
      _initAccount()
    ]);
    
    super.initService();
  }

  @override
  void initServiceUI() {
    _processCachedAppointmentDetails();
  }

  // Getters & Setters

  AppointmentsAccount? get account => _account;

  bool get isAccountValid => (account != null) && (_isLastAccountResponseSuccessful == true);

  bool get reminderNotificationsEnabled =>
      isAccountValid &&
      (Auth2().isLoggedIn) &&
      (Auth2().prefs?.getBoolSetting(_appointmentRemindersNotificationsEnabledKey, defaultValue: true) ?? true);

  set reminderNotificationsEnabled(bool value) {
    if (Auth2().isLoggedIn) {
      Auth2().prefs?.applySetting(_appointmentRemindersNotificationsEnabledKey, value);
    }
  }

  Future<Appointment?> loadAppointment(String? appointmentId) async {
    if (StringUtils.isNotEmpty(appointmentId) && StringUtils.isNotEmpty(Config().appointmentsUrl)) {
      if (StringUtils.isNotEmpty(Config().appointmentsUrl)) {
        String? url = "${Config().appointmentsUrl}/services/appointments?_ids=$appointmentId";
        http.Response? response = await Network().get(url, auth: Auth2());
        int? responseCode = response?.statusCode;
        String? responseString = response?.body;
        if (responseCode == 200) {
          return Appointment.listFromJson(JsonUtils.decodeList(responseString))?.first;
        } else {
          debugPrint('Failed to load appointment with id {$appointmentId}. Reason: $responseCode, $responseString');
          return null;
        }
      }
    }
    return null;
  }

  List<Appointment>? getAppointments({required AppointmentsTimeSource timeSource, AppointmentType? type}) {
    List<Appointment>? srcAppts;
    switch (timeSource) {
      case AppointmentsTimeSource.past:
        srcAppts = _pastAppointments;
        break;
      case AppointmentsTimeSource.upcoming:
        srcAppts = _upcomingAppointments;
        break;
    }
    if (CollectionUtils.isNotEmpty(srcAppts)) {
      if (type != null) {
        List<Appointment>? result = <Appointment>[];
        for (Appointment appt in srcAppts!) {
          if (type == appt.type) {
            result.add(appt);
          }
        }
        return result;
      }
    }
    return srcAppts;
  }

  Future<void> refreshAppointments() => _updateAllAppointments();

  File _getAppointmentsCacheFile({required AppointmentsTimeSource timeSource}) {
    late String docName;
    switch (timeSource) {
      case AppointmentsTimeSource.past:
        docName = _pastAppointmentsCacheDocName;
        break;
      case AppointmentsTimeSource.upcoming:
        docName = _upcomingAppointmentsCacheDocName;
        break;
    }
    return File(join(_appDocDir.path, docName));
  }

  Future<String?> _loadAppointmentsStringFromCache({required AppointmentsTimeSource timeSource}) async {
    File appointmentsFile = _getAppointmentsCacheFile(timeSource: timeSource);
    return await appointmentsFile.exists() ? await appointmentsFile.readAsString() : null;
  }

  Future<void> _saveAppointmentsStringToCache(String? value, AppointmentsTimeSource timeSource) async {
    await _getAppointmentsCacheFile(timeSource: timeSource).writeAsString(value ?? '', flush: true);
  }

  Future<List<Appointment>?> _loadAppointmentsFromCache({required AppointmentsTimeSource timeSource}) async {
    return Appointment.listFromJson(JsonUtils.decodeList(await _loadAppointmentsStringFromCache(timeSource: timeSource)));
  }

  Future<String?> _loadAppointmentsStringFromNet({required AppointmentsTimeSource timeSource}) async {
    //TMP: assets shortcut
    //return await AppBundle.loadString('assets/appointments.json');
    if (StringUtils.isNotEmpty(Config().appointmentsUrl) && Auth2().isLoggedIn) {
      String url = "${Config().appointmentsUrl}/services/appointments";
      switch (timeSource) {
        case AppointmentsTimeSource.upcoming:
          url += '?start-date=${DateTime.now().toUtc().millisecondsSinceEpoch}&order=asc';
          break;
        case AppointmentsTimeSource.past:
          url += '?end-date=${DateTime.now().toUtc().millisecondsSinceEpoch}&order=desc';
          break;
      }
      http.Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        return responseString;
      } else {
        debugPrint('Failed to load appointments ($url) from net. Reason: $responseCode, $responseString');
        return null;
      }
    }
    return null;
  }

  Future<List<Appointment>?> _initAppointments({required AppointmentsTimeSource timeSource}) async {
    List<Appointment>? appointments;
    appointments = await _loadAppointmentsFromCache(timeSource: timeSource);
    if (appointments != null) {
      _updateAppointments(timeSource: timeSource);
    } else {
      String? appointmentsJsonString = await _loadAppointmentsStringFromNet(timeSource: timeSource);
      appointments = Appointment.listFromJson(JsonUtils.decodeList(appointmentsJsonString));
      if (appointments != null) {
        _saveAppointmentsStringToCache(appointmentsJsonString, timeSource);
      }
    }
    return appointments;
  }

  Future<void> _updateAllAppointments() async {
    await Future.wait([
      _updateAppointments(timeSource: AppointmentsTimeSource.upcoming),
      _updateAppointments(timeSource: AppointmentsTimeSource.past),
    ]);
  }

  Future<void> _updateAppointments({required AppointmentsTimeSource timeSource}) async {
    String? appointmentsJsonString = await _loadAppointmentsStringFromNet(timeSource: timeSource);
    List<Appointment>? appointments = Appointment.listFromJson(JsonUtils.decodeList(appointmentsJsonString));
    bool apptsChanged = false;
    switch (timeSource) {
      case AppointmentsTimeSource.past:
        if (!DeepCollectionEquality().equals(_pastAppointments, appointments)) {
          _pastAppointments = appointments;
          apptsChanged = true;
        }
        break;
      case AppointmentsTimeSource.upcoming:
        if (!DeepCollectionEquality().equals(_upcomingAppointments, appointments)) {
          _upcomingAppointments = appointments;
          apptsChanged = true;
        }
        break;
    }
    if (apptsChanged) {
      _saveAppointmentsStringToCache(appointmentsJsonString, timeSource);
      _notifyAppointmentsChanged(timeSource: timeSource);
    }
  }

  void _notifyAppointmentsChanged({required AppointmentsTimeSource timeSource}) {
    switch (timeSource) {
      case AppointmentsTimeSource.past:
        NotificationService().notify(notifyPastAppointmentsChanged);
        break;
      case AppointmentsTimeSource.upcoming:
        NotificationService().notify(notifyUpcomingAppointmentsChanged);
        break;
    }
  }

  // Appointments Account

  void changeAccountPreferences({bool? newAppointment, bool? morningReminder, bool? nightReminder}) {
    if (_account != null) {
      bool changed = false;
      if (newAppointment != null) {
        _account!.notificationsAppointmentNew = newAppointment;
        changed = true;
      }
      if (morningReminder != null) {
        _account!.notificationsAppointmentReminderMorning = morningReminder;
        changed = true;
      }
      if (nightReminder != null) {
        _account!.notificationsAppointmentReminderNight = nightReminder;
        changed = true;
      }
      if (changed) {
        _updateAccountPreferences();
      }
    }
  }

  Future<void> _initAccount() async {
    _account = await _loadAccountFromCache();
    if (_account != null) {
      _updateAccount();
    } else {
      String? accountJsonString = await _loadAccountStringFromNet();
      _account = AppointmentsAccount.fromJson(JsonUtils.decodeMap(accountJsonString));
      if (_account != null) {
        _saveAccountStringToCache(accountJsonString);
        NotificationService().notify(notifyAppointmentsAccountChanged);
      } else if (Auth2().isLoggedIn && (_isLastAccountResponseSuccessful == true)) {
        // if the backend returns successful response without account, then populate the account with default values
        _initAccountOnFirstSignIn();
      }
    }
  }

  File _getAccountCacheFile() => File(join(_appDocDir.path, _accountCacheDocName));

  Future<String?> _loadAccountStringFromCache() async {
    File accountFile = _getAccountCacheFile();
    return await accountFile.exists() ? await accountFile.readAsString() : null;
  }

  Future<void> _saveAccountStringToCache(String? value) async {
    await _getAccountCacheFile().writeAsString(value ?? '', flush: true);
  }

  Future<AppointmentsAccount?> _loadAccountFromCache() async {
    return AppointmentsAccount.fromJson(JsonUtils.decodeMap(await _loadAccountStringFromCache()));
  }

  Future<String?> _loadAccountStringFromNet() async {
    if (StringUtils.isNotEmpty(Config().appointmentsUrl) && Auth2().isLoggedIn) {
      String? url = "${Config().appointmentsUrl}/services/account";
      http.Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        _isLastAccountResponseSuccessful = true;
        return responseString;
      } else {
        Log.w('Failed to load Appointments Account. Response:\n$responseCode: $responseString');
        _isLastAccountResponseSuccessful = false;
        return null;
      }
    } else {
      _isLastAccountResponseSuccessful = null;
      return null;
    }
  }

  Future<void> _updateAccount() async {
    String? accountJsonString = await _loadAccountStringFromNet();
    AppointmentsAccount? apptsAccount = AppointmentsAccount.fromJson(JsonUtils.decodeMap(accountJsonString));
    if (_account != apptsAccount) {
      _account = apptsAccount;
      _saveAccountStringToCache(accountJsonString);
      NotificationService().notify(notifyAppointmentsAccountChanged);
    }
  }

  Future<void> _initAccountOnFirstSignIn() async {
    // By Default
    AppointmentsAccount defaultNewAccount = AppointmentsAccount(
        notificationsAppointmentNew: true, notificationsAppointmentReminderMorning: true, notificationsAppointmentReminderNight: true);
    Map<String, String> headers = {'Content-Type': 'application/json'};
    String? accountJsonString = JsonUtils.encode(defaultNewAccount.toJson());
    String? url = "${Config().appointmentsUrl}/services/account";
    http.Response? response = await Network().post(url, auth: Auth2(), body: accountJsonString, headers: headers);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      _isLastAccountResponseSuccessful = true;
      _account = AppointmentsAccount.fromJson(JsonUtils.decodeMap(responseString));
      _saveAccountStringToCache(responseString);
    } else {
      Log.w('Failed to init default Appointments Account. Response:\n$responseCode: $responseString');
      _isLastAccountResponseSuccessful = false;
      _account = null;
      _saveAccountStringToCache(null);
    }
    NotificationService().notify(notifyAppointmentsAccountChanged);
  }

  Future<void> _updateAccountPreferences() async {
    String? accountJsonString = JsonUtils.encode(_account);
    Map<String, String> headers = {'Content-Type': 'application/json'};
    String? url = "${Config().appointmentsUrl}/services/account";
    http.Response? response = await Network().post(url, auth: Auth2(), body: accountJsonString, headers: headers);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      _isLastAccountResponseSuccessful = true;
      _account = AppointmentsAccount.fromJson(JsonUtils.decodeMap(responseString));
      _saveAccountStringToCache(responseString);
    } else {
      Log.w('Failed to init default Appointments Account. Response:\n$responseCode: $responseString');
      _isLastAccountResponseSuccessful = false;
      _account = null;
      _saveAccountStringToCache(null);
    }
    NotificationService().notify(notifyAppointmentsAccountChanged);
  }

  // ExploreJsonHandler
  @override bool exploreCanJson(Map<String, dynamic>? json) => Appointment.canJson(json);
  @override Explore? exploreFromJson(Map<String, dynamic>? json) => Appointment.fromJson(json);

  // DeepLinks
  String get appointmentDetailUrl => '${DeepLink().appUrl}/appointment';

  void _onDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? appointmentUri = Uri.tryParse(appointmentDetailUrl);
      if ((appointmentUri != null) &&
          (appointmentUri.scheme == uri.scheme) &&
          (appointmentUri.authority == uri.authority) &&
          (appointmentUri.path == uri.path)) {
        try {
          _handleAppointmentDetail(uri.queryParameters.cast<String, dynamic>());
        } catch (e) {
          print(e.toString());
        }
      }
    }
  }

  void _handleAppointmentDetail(Map<String, dynamic>? params) {
    if ((params != null) && params.isNotEmpty) {
      if (_appointmentDetailsCache != null) {
        _cacheAppointmentDetail(params);
      } else {
        _processAppointmentDetail(params);
      }
    }
  }

  void _processAppointmentDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyAppointmentDetail, params);
  }

  void _cacheAppointmentDetail(Map<String, dynamic> params) {
    _appointmentDetailsCache?.add(params);
  }

  void _processCachedAppointmentDetails() {
    if (_appointmentDetailsCache != null) {
      List<Map<String, dynamic>> appointmentDetailsCache = _appointmentDetailsCache!;
      _appointmentDetailsCache = null;

      for (Map<String, dynamic> appointmentDetail in appointmentDetailsCache) {
        _processAppointmentDetail(appointmentDetail);
      }
    }
  }

  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    } else if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    } else if (name == Auth2.notifyLoginChanged) {
      _initAccount();
      _updateAllAppointments();
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateAccount();
          _updateAllAppointments();
        }
      }
    }
  }
}