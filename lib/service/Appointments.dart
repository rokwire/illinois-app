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

import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Config.dart';
import 'package:http/http.dart' as http;
import 'package:illinois/service/Auth2.dart';

class Appointments with Service implements ExploreJsonHandler, NotificationsListener {
  static const String notifyAppointmentDetail = "edu.illinois.rokwire.appointments.detail";
  static const String notifyAppointmentsAccountUpdated = "edu.illinois.rokwire.appointments.account.updated";
  
  static const String _appointmentRemindersNotificationsEnabledKey = 'edu.illinois.rokwire.settings.inbox.notification.appointments.reminders.notifications.enabled';
  
  DateTime? _pausedDateTime;
  
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
      AppLivecycle.notifyStateChanged,
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
    await _loadAccount();
    if ((account == null) && Auth2().isLoggedIn && (_isLastAccountResponseSuccessful == true)) { 
      // if the backend returns successful response without account, then populate the account with default values
      _initAccountOnFirstSignIn();
    }
    await super.initService();
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

  // APIs
  Future<List<Appointment>?> loadAppointments({bool? onlyUpcoming, AppointmentType? type}) async {
    List<Appointment>? appointments;
   appointments = await loadBBAppointments();
    List<Appointment>? resultAppointments;
    //TBD: Appointment - do this filtering on the backend
    if (CollectionUtils.isNotEmpty(appointments)) {
      resultAppointments = <Appointment>[];
      for (Appointment appointment in appointments!) {
        if ((onlyUpcoming == true) && !appointment.isUpcoming) {
          continue;
        }
        if ((type != null) && (type != appointment.type)) {
          continue;
        }
        resultAppointments.add(appointment);
      }
      _sortAppointments(resultAppointments);
    }
    return resultAppointments;
  }

  Future<List<Appointment>?> loadBBAppointments() async {
    if (StringUtils.isEmpty(Config().appointmentsUrl)) {
      Log.w('Failed to appointments. Missing appointments url.');
      return null;
    }
    String? url;
    url = "${Config().appointmentsUrl}/services/appointments";
    http.Response? response = await Network().get(url, auth: Auth2());
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      List<Appointment>? items = Appointment.listFromJson(JsonUtils.decodeList(responseString));
      return items;
    } else {
      Log.w('Failed to load Appointments. Response:\n$responseCode: $responseString');
      return null;
    }
  }

  //TBD remove when not needed for testing
  Future<List<Appointment>?> loadAssetsAppointments() async {
    return Appointment.listFromJson(JsonUtils.decodeList(await AppBundle.loadString('assets/appointments.json')));
  }

  //TBD: Appointment - load from backend
  Future<Appointment?> loadAppointment(String? appointmentId) async {
    if (StringUtils.isNotEmpty(appointmentId)) {
      List<Appointment>? allAppointments = await loadAppointments();
      if (CollectionUtils.isNotEmpty(allAppointments)) {
        for (Appointment appointment in allAppointments!) {
          if (appointment.id == appointmentId) {
            return appointment;
          }
        }
      }
    }
    return null;
  }

  void _sortAppointments(List<Appointment>? appointments) {
    if (CollectionUtils.isNotEmpty(appointments)) {
      appointments!.sort((first, second) {
        if (first.dateTimeUtc == null || second.dateTimeUtc == null) {
          return 0;
        } else {
          return (first.dateTimeUtc!.isBefore(second.dateTimeUtc!)) ? -1 : 1;
        }
      });
    }
  }

  Future<void> _loadAccount() async {
    if (Auth2().isLoggedIn) {
      String? url = "${Config().appointmentsUrl}/services/account";
      http.Response? response = await Network().get(url, auth: Auth2());
      int? responseCode = response?.statusCode;
      String? responseString = response?.body;
      if (responseCode == 200) {
        _isLastAccountResponseSuccessful = true;
        _account = AppointmentsAccount.fromJson(JsonUtils.decodeMap(responseString));
      } else {
        Log.w('Failed to load Appointments Account. Response:\n$responseCode: $responseString');
        _isLastAccountResponseSuccessful = false;
        _account = null;
      }
    } else {
      _isLastAccountResponseSuccessful = null;
      _account = null;
    }
    NotificationService().notify(notifyAppointmentsAccountUpdated);
  }

  Future<void> _initAccountOnFirstSignIn() async {
    // By Default
    AppointmentsAccount defaultNewAccount = AppointmentsAccount(
        notificationsAppointmentNew: true,
        notificationsAppointmentReminderMorning: true,
        notificationsAppointmentReminderNight: true);
    String? accountJsonString = JsonUtils.encode(defaultNewAccount.toJson());
    String? url = "${Config().appointmentsUrl}/services/account";
    http.Response? response = await Network().post(url, auth: Auth2(), body: accountJsonString);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      _isLastAccountResponseSuccessful = true;
      _account = AppointmentsAccount.fromJson(JsonUtils.decodeMap(responseString));
    } else {
      Log.w('Failed to init default Appointments Account. Response:\n$responseCode: $responseString');
      _isLastAccountResponseSuccessful = false;
      _account = null;
    }
    NotificationService().notify(notifyAppointmentsAccountUpdated);
  }

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
        _updateAccount();
      }
    }
  }

  Future<void> _updateAccount() async {
    String? accountJsonString = JsonUtils.encode(_account);
    String? url = "${Config().appointmentsUrl}/services/account";
    http.Response? response = await Network().post(url, auth: Auth2(), body: accountJsonString);
    int? responseCode = response?.statusCode;
    String? responseString = response?.body;
    if (responseCode == 200) {
      _isLastAccountResponseSuccessful = true;
      _account = AppointmentsAccount.fromJson(JsonUtils.decodeMap(responseString));
    } else {
      Log.w('Failed to init default Appointments Account. Response:\n$responseCode: $responseString');
      _isLastAccountResponseSuccessful = false;
      _account = null;
    }
    NotificationService().notify(notifyAppointmentsAccountUpdated);
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
    } else if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    } else if (name == Auth2.notifyLoginChanged) {
      _loadAccount();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _loadAccount();
        }
      }
    }
  }
}
