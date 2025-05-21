
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Game.dart';
import 'package:illinois/model/sport/Game.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/ui/events2/Even2SetupSuperEvent.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

import '../utils/Utils.dart';

// Event2

extension Event2Ext on Event2 {

  bool get hasSurvey => (attendanceDetails?.isNotEmpty ?? false) && (surveyDetails?.isNotEmpty ?? false);
  bool get hasLinkedEvents => (isSuperEvent || isRecurring);

  Color? get uiColor => Styles().colors.eventColor;

  String? get displayImageUrl => StringUtils.isNotEmpty(imageUrl) ? imageUrl : randomImageUrl;

  String? get randomImageUrl {
    if (assignedImageUrl == null) {
      dynamic category = (attributes != null) ? attributes!['category'] : null;
      assignedImageUrl = _randomImageUrlForAttribute('events', category);
    }
    if (assignedImageUrl == null) {
      dynamic sport = (attributes != null) ? attributes!['sport'] : null;
      assignedImageUrl = _randomImageUrlForAttribute('sports', sport, mapping: _sportCodes);
    }
    if (assignedImageUrl == null) {
      assignedImageUrl = Content().randomImageUrl('events.Other');
    }
    return assignedImageUrl;
  }

  String? _randomImageUrlForAttribute(String prefix, dynamic value, { Map<String, String>? mapping }) {
    if (value is String) {
      return (mapping != null) ?
        (Content().randomImageUrl('$prefix.${mapping[value]}') ?? Content().randomImageUrl('$prefix.$value')) :
        Content().randomImageUrl('$prefix.$value');
    }
    else if (value is List) {
      for (dynamic entry in value) {
        String? result = _randomImageUrlForAttribute(prefix, entry, mapping: mapping);
        if (result != null) {
          return result;
        }
      }
    }
    return null;
  }

  static const Map<String, String> _sportCodes = {
    "Baseball" : "baseball",
    "Men's Basketball" : "mbball",
    "Men's Cross Country" : "mcross",
    "Football" : "football",
    "Men's Golf" : "mgolf",
    "Men's Gymnastics" : "mgym",
    "Men's Tennis" : "mten",
    "Men's Track & Field" : "mtrack",
    "Wrestling" : "wrestling",
    "Women's Basketball" : "wbball",
    "Women's Cross Country" : "wcross",
    "Women's Golf" : "wgolf",
    "Women's Gymnastics" : "wgym",
    "Soccer" : "wsoc",
    "Softball" : "softball",
    "Swimming & Diving" : "wswim",
    "Women's Tennis" : "wten",
    "Women's Track & Field" : "wtrack",
    "Volleyball" : "wvball"
  };

  Map<String, dynamic>? get analyticsAttributes => {
    Analytics.LogAttributeEventId: id,
    Analytics.LogAttributeEventName: name,
    Analytics.LogAttributeEventAttributes: attributes,
    Analytics.LogAttributeLocation : location?.analyticsValue,
  };

  String? get shortDisplayDateAndTime => hasGame ? game!.displayTime : _buildDisplayDateAndTime(longFormat: false);
  String? get longDisplayDateAndTime => hasGame ? game!.displayTime : _buildDisplayDateAndTime(longFormat: true);

  String? _buildDisplayDateAndTime({bool longFormat = false}) {
    if (startTimeUtc != null) {
      TZDateTime nowLocal = DateTimeLocal.nowLocalTZ();
      TZDateTime nowMidnightLocal = TZDateTimeUtils.dateOnly(nowLocal);

      TZDateTime startDateTimeLocal = startTimeUtc!.toLocalTZ();
      TZDateTime startDateTimeMidnightLocal = TZDateTimeUtils.dateOnly(startDateTimeLocal);
      int statDaysDiff = startDateTimeMidnightLocal.difference(nowMidnightLocal).inDays;

      TZDateTime? endDateTimeLocal = endTimeUtc?.toLocalTZ();
      TZDateTime? endDateTimeMidnightLocal = (endDateTimeLocal != null) ? TZDateTimeUtils.dateOnly(endDateTimeLocal) : null;
      int? endDaysDiff = (endDateTimeMidnightLocal != null) ? endDateTimeMidnightLocal.difference(nowMidnightLocal).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      bool showStartYear = (nowLocal.year != startDateTimeLocal.year);
      String startDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showStartYear ? ', yyyy' : '');

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {

        String displayDay;
        switch(statDaysDiff) {
          case 0: displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today'); break;
          case 1: displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow'); break;
          default: displayDay = DateFormat(startDateFormat).format(startDateTimeLocal);
        }

        if (allDay != true) {
          String displayStartTime = DateFormat((startDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeLocal).toLowerCase();
          if ((endDateTimeLocal != null) && (TimeOfDay.fromDateTime(startDateTimeLocal) != TimeOfDay.fromDateTime(endDateTimeLocal))) {
            String displayEndTime = DateFormat((endDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeLocal).toLowerCase();
            return Localization().getStringEx('model.explore.date_time.from_to.format', '{{day}} from {{start_time}} to {{end_time}}').
            replaceAll('{{day}}', displayDay).
            replaceAll('{{start_time}}', displayStartTime).
            replaceAll('{{end_time}}', displayEndTime);
          }
          else {
            return Localization().getStringEx('model.explore.date_time.at.format', '{{day}} at {{time}}').
            replaceAll('{{day}}', displayDay).
            replaceAll('{{time}}', displayStartTime);
          }
        }
        else {
          return displayDay;
        }
      }
      else {
        String displayDateTime = DateFormat(startDateFormat).format(startDateTimeLocal);
        if (allDay != true) {
          displayDateTime += showStartYear ? ' ' : ', ';
          displayDateTime += DateFormat((startDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeLocal).toLowerCase();
        }

        if ((endDateTimeLocal != null) && (differentStartAndEndDays || (allDay != true))) {
          bool showEndYear = (nowLocal.year != endDateTimeLocal.year);
          String endDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showEndYear ? ', yyyy' : '');

          displayDateTime += ' - ';
          if (differentStartAndEndDays) {
            displayDateTime += DateFormat(endDateFormat).format(endDateTimeLocal);
          }
          if (allDay != true) {
            displayDateTime += differentStartAndEndDays ? ', ' : '';
            displayDateTime += DateFormat((endDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeLocal).toLowerCase();
          }
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? get shortDisplayStartDateTime => hasGame ? game!.displayTime : _buildDisplayStartDateTime(longFormat: false);
  String? get longDisplayStartDateTime => hasGame ? game!.displayTime : _buildDisplayStartDateTime(longFormat: true);

  String? _buildDisplayStartDateTime({bool longFormat = false}) {
    if (startTimeUtc != null) {
      TZDateTime startDateTimeLocal = startTimeUtc!.toLocalTZ();
      String startDateFormat = (longFormat ? 'EEEE, MMMM d, yyyy' : 'MMM d, yyyy');
      String displayStartDate = DateFormat(startDateFormat).format(startDateTimeLocal);
      String startTimeFormat = 'h:mma';
      String displayStartTime = DateFormat(startTimeFormat).format(startDateTimeLocal).toLowerCase();
      return Localization().getStringEx('model.explore.date_time.at.format', '{{day}} at {{time}}').
        replaceAll('{{day}}', displayStartDate).
        replaceAll('{{time}}', displayStartTime);
    }
    else {
      return null;
    }
  }

  String? get shortDisplayDate => hasGame ? game!.displayTime : _buildDisplayDate(longFormat: false);
  String? get longDisplayDate => hasGame ? game!.displayTime : _buildDisplayDate(longFormat: true);

  String? _buildDisplayDate({bool longFormat = false}) {
    if (startTimeUtc != null) {
      TZDateTime nowLocal = DateTimeLocal.nowLocalTZ();
      TZDateTime nowMidnightLocal = TZDateTimeUtils.dateOnly(nowLocal);

      TZDateTime startDateTimeLocal = startTimeUtc!.toLocalTZ();
      TZDateTime startDateTimeMidnightLocal = TZDateTimeUtils.dateOnly(startDateTimeLocal);
      int statDaysDiff = startDateTimeMidnightLocal.difference(nowMidnightLocal).inDays;

      TZDateTime? endDateTimeLocal = endTimeUtc?.toLocalTZ();
      TZDateTime? endDateTimeMidnightLocal = (endDateTimeLocal != null) ? TZDateTimeUtils.dateOnly(endDateTimeLocal) : null;
      int? endDaysDiff = (endDateTimeMidnightLocal != null) ? endDateTimeMidnightLocal.difference(nowMidnightLocal).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      bool showStartYear = (nowLocal.year != startDateTimeLocal.year);
      String startDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showStartYear ? ', yyyy' : '');

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {

        String displayDay;
        switch(statDaysDiff) {
          case 0: displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today'); break;
          case 1: displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow'); break;
          default: displayDay = DateFormat(startDateFormat).format(startDateTimeLocal);
        }

        return displayDay;
      }
      else {
        String displayDateTime = DateFormat(startDateFormat).format(startDateTimeLocal);
        if ((endDateTimeLocal != null) && differentStartAndEndDays) {
          bool showEndYear = (nowLocal.year != endDateTimeLocal.year);
          String endDateFormat = (longFormat ? 'EEE, MMM d' : 'MMM d') + (showEndYear ? ', yyyy' : '');

          displayDateTime += ' - ';
          if (differentStartAndEndDays) {
            displayDateTime += DateFormat(endDateFormat).format(endDateTimeLocal);
          }
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? get shortDisplayTime => hasGame ? game!.displayTime : _buildDisplayTime(longFormat: false);
  String? get longDisplayTime => hasGame ? game!.displayTime : _buildDisplayTime(longFormat: true);

  String? _buildDisplayTime({bool longFormat = false}) {
    if (startTimeUtc != null) {
      TZDateTime nowLocal = DateTimeLocal.nowLocalTZ();
      TZDateTime nowMidnightLocal = TZDateTimeUtils.dateOnly(nowLocal);

      TZDateTime startDateTimeLocal = startTimeUtc!.toLocalTZ();
      TZDateTime startDateTimeMidnightLocal = TZDateTimeUtils.dateOnly(startDateTimeLocal);
      int statDaysDiff = startDateTimeMidnightLocal.difference(nowMidnightLocal).inDays;

      TZDateTime? endDateTimeLocal =  endTimeUtc?.toLocalTZ();
      TZDateTime? endDateTimeMidnightLocal = (endDateTimeLocal != null) ? TZDateTimeUtils.dateOnly(endDateTimeLocal) : null;
      int? endDaysDiff = (endDateTimeMidnightLocal != null) ? endDateTimeMidnightLocal.difference(nowMidnightLocal).inDays : null;

      bool differentStartAndEndDays = (statDaysDiff != endDaysDiff);

      if ((endDaysDiff == null) || (endDaysDiff == statDaysDiff)) /* no end time or start date == end date */ {

        if (allDay != true) {
          String displayStartTime = DateFormat((startDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeLocal).toLowerCase();
          if ((endDateTimeLocal != null) && (TimeOfDay.fromDateTime(startDateTimeLocal) != TimeOfDay.fromDateTime(endDateTimeLocal))) {
            String displayEndTime = DateFormat((endDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeLocal).toLowerCase();
            return Localization().getStringEx('model.explore.time.from_to.format', '{{start_time}} to {{end_time}}').
            replaceAll('{{start_time}}', displayStartTime).
            replaceAll('{{end_time}}', displayEndTime);
          }
          else {
            return Localization().getStringEx('model.explore.time.at.format', '{{time}}').
            replaceAll('{{time}}', displayStartTime);
          }
        }
        else {
          return null;
        }
      }
      else {
        String displayDateTime = DateFormat((startDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(startDateTimeLocal).toLowerCase();
        if ((endDateTimeLocal != null) && (differentStartAndEndDays || (allDay != true))) {
          displayDateTime += ' - ';
          displayDateTime += DateFormat((endDateTimeLocal.minute == 0) ? 'ha' : 'h:mma').format(endDateTimeLocal).toLowerCase();
        }
        return displayDateTime;
      }
    }
    else {
      return null;
    }
  }

  String? getDisplayDistance(Position? userLocation) {
    double? latitude = location?.latitude;
    double? longitude = location?.longitude;
    if ((latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0) && (userLocation != null)) {
      double distanceInMeters = Geolocator.distanceBetween(latitude, longitude, userLocation.latitude, userLocation.longitude);
      double distanceInMiles = distanceInMeters / 1609.344;
      //int whole = (((distanceInMiles * 10) + 0.5).toInt() % 10);
      int displayPrecision = ((distanceInMiles < 10) && ((((distanceInMiles * 10) + 0.5).toInt() % 10) != 0)) ? 1 : 0;
      return Localization().getStringEx('model.explore.distance.format', '{{distance}} mi away').
        replaceAll('{{distance}}', distanceInMiles.toStringAsFixed(displayPrecision));
    }
    else {
      return null;
    }
  }

  bool get isSurveyAvailable {
    int? hours = surveyDetails?.hoursAfterEvent ?? 0;
    DateTime? eventTime = endTimeUtc ?? startTimeUtc;
    return (eventTime == null) || eventTime.toUtc().add(Duration(hours: hours)).isBefore(DateTime.now().toUtc());
  }

  bool get isFavorite =>
    //isRecurring //TBD Recurring id
    // ? Auth2().isListFavorite(recurringEvents?.cast<Favorite>());
    Auth2().isFavorite(this);

  bool get canUserEdit =>
    userRole == Event2UserRole.admin;

  bool get canUserDelete =>
    userRole == Event2UserRole.admin;

  bool get hasGame =>
    game != null;

  Game? get game =>
    isSportEvent ? Game.fromJson(data) : null;

  List<Event2Grouping>? get linkedEventsGroupingQuery {
    if (isSuperEvent) {
      return Event2Grouping.superEvents(superEventId: id);
    }
    else if (isRecurring) {
      return Event2Grouping.recurringEvents(groupId: grouping?.recurrenceId, individual: false);
    }
    else {
      return null;
    }
  }

  Event2 get duplicate => duplicateWith();

  Event2 get copy => copyWithNullable();

  Event2 duplicateWith({Event2Grouping? grouping}) => copyWithNullable(
    id: NullableValue.empty(),
    name: NullableValue('${name} copy'),
    published: NullableValue(false), //Explicitly set published to false - #612. This is comment from Admin app
    grouping: grouping != null ? NullableValue(grouping) : null, //Expose nullable if we want to be able to clear(pass null) not just update
  );

  Event2 copyWithNullable({ // We can pass null to skip the value, NullableValue(null) to explicitly pass null
    NullableValue<String>? id,
    NullableValue<String>? name,
    NullableValue<String>? description,
    NullableValue<String>? instructions,
    NullableValue<String>? imageUrl,
    NullableValue<String>? eventUrl,
    NullableValue<bool>? canceled,
    NullableValue<bool>? published,
    NullableValue<String>? timezone,
    NullableValue<DateTime>? startTimeUtc,
    NullableValue<DateTime>? endTimeUtc,
    NullableValue<bool>? allDay,
    NullableValue<bool>? free,
    NullableValue<Event2Type>? eventType,
    NullableValue<Event2OnlineDetails>? onlineDetails,
    NullableValue<Event2Grouping>? grouping,
    NullableValue<Event2RegistrationDetails>? registrationDetails,
    NullableValue<Event2AttendanceDetails>? attendanceDetails,
    NullableValue<Event2SurveyDetails>? surveyDetails,
    NullableValue<Event2AuthorizationContext>? authorizationContext,
    NullableValue<Event2Context>? context,
    NullableValue<Map<String, dynamic>>? attributes,
    NullableValue<ExploreLocation>? location,
    NullableValue<String>? sponsor,
    NullableValue<String>? speaker,
    NullableValue<List<Event2Contact>>? contacts,
    NullableValue<Event2UserRole>? userRole,
    NullableValue<String>? cost,
    NullableValue<List<Event2NotificationSetting>>? notificationSettings,
  }){
    return Event2(
      id: id != null ?  id.value : this.id,
      name: name != null ? name.value : this.name,
      description: description != null ? description.value : this.description,
      instructions: instructions  != null ? instructions.value : this.instructions,
      imageUrl: imageUrl != null ? imageUrl.value : this.imageUrl,
      eventUrl: eventUrl != null ? eventUrl.value : this.eventUrl,
      canceled: canceled  != null ? canceled.value : this.canceled,
      published: published  != null ? published.value : this.published,
      timezone: timezone != null ?  timezone.value : this.timezone,
      startTimeUtc: startTimeUtc != null ? startTimeUtc.value : this.startTimeUtc,
      endTimeUtc: endTimeUtc != null ? endTimeUtc.value : this.endTimeUtc,
      allDay: allDay != null ? allDay.value : this.allDay,
      free: free != null ? free.value : this.free,
      eventType: eventType != null ? eventType.value : this.eventType,
      onlineDetails: onlineDetails != null ? onlineDetails.value : this.onlineDetails,
      grouping: grouping != null ? grouping.value : this.grouping,
      registrationDetails: registrationDetails != null ? registrationDetails.value : this.registrationDetails,
      attendanceDetails: attendanceDetails != null ? attendanceDetails.value : this.attendanceDetails,
      surveyDetails: surveyDetails != null ? surveyDetails.value : this.surveyDetails,
      authorizationContext: authorizationContext != null ? authorizationContext.value : this.authorizationContext,
      context: context != null ? context.value : this.context,
      attributes: attributes != null ? attributes.value : this.attributes,
      location: location != null ? location.value : this.location,
      sponsor: sponsor != null ? sponsor.value : this.sponsor,
      speaker: speaker != null ? speaker.value : this.speaker,
      contacts: contacts != null ? contacts.value : this.contacts,
      userRole: userRole != null ? userRole.value : this.userRole,
      cost: cost != null ? cost.value : this.cost,
      notificationSettings: notificationSettings != null ? notificationSettings.value : this.notificationSettings,
      source: this.source,
      data: this.data,
    );
  }

  Event2 toRecurringEvent({required DateTime startDateTimeUtc, DateTime? endDateTimeUtc}) => Event2(
    name: this.name,
    description: this.description,
    instructions: this.instructions,
    imageUrl: this.imageUrl,
    eventUrl: this.eventUrl,

    timezone: this.timezone,
    startTimeUtc: startDateTimeUtc,
    endTimeUtc: endDateTimeUtc,
    allDay: this.allDay,

    eventType: this.eventType,
    location: this.location,
    onlineDetails: this.onlineDetails,

    grouping: Event2Grouping.recurrence(this.grouping?.recurrenceId, individual: false), // set "sub-events" not to show as individuals
    attributes: this.attributes,
    authorizationContext: this.authorizationContext,
    context: this.context,

    canceled: this.canceled,
    published: this.published,
    userRole: this.userRole,

    free: this.free,
    cost: this.cost,

    registrationDetails: this.registrationDetails,
    attendanceDetails: this.attendanceDetails,
    surveyDetails: this.surveyDetails,
    notificationSettings: this.notificationSettings,

    sponsor: this.sponsor,
    speaker: this.speaker,
    contacts: this.contacts,

    source: this.source,
    data: this.data,

  );

  Future<List<Event2PersonIdentifier>?> get asyncAdminIdentifiers async =>
      Events2().loadAdminIdentifiers(this);
}

extension Event2GroupingExt on Event2Grouping{

    bool? get canDisplayAsIndividual => displayAsIndividual is bool ? displayAsIndividual : null;

    Event2Grouping copyWith({Event2GroupingType? type, String? superEventId, String? recurrenceId, displayAsIndividual}) =>
      Event2Grouping(
        type: type ?? this.type,
        recurrenceId: recurrenceId ?? this.recurrenceId,
        displayAsIndividual: displayAsIndividual ?? this.displayAsIndividual,
        superEventId: superEventId ?? this.superEventId
      );
}

extension Event2ContactExt on Event2Contact {
  
  String get fullName {
    if (StringUtils.isNotEmpty(firstName)) {
      if (StringUtils.isNotEmpty(lastName)) {
        return '$firstName $lastName';
      }
      else {
        return firstName ?? '';
      }
    }
    else {
        return lastName ?? '';
    }
  }
}

extension Event2RegistrationDetailsExt on Event2RegistrationDetails {
  
  bool get requiresRegistration =>  (type == Event2RegistrationType.internal) /*|| (type == Event2RegistrationType.external)*/;

  bool? isRegistrationCapacityReached(int? participantsCount) =>
    ((type == Event2RegistrationType.internal) && (eventCapacity != null) && (participantsCount != null)) ? (eventCapacity! <= participantsCount) : null;

  bool? isRegistrationAvailable(int? participantsCount) =>
    ((type == Event2RegistrationType.internal) && (eventCapacity != null) && (participantsCount != null)) ? (participantsCount < eventCapacity!) : null;
}


// Event2SortType

String? event2SortTypeToDisplayString(Event2SortType? value) {
  switch (value) {
    case Event2SortType.dateTime: return Localization().getStringEx('model.event2.sort_type.date_time', 'Date & Time');
    case Event2SortType.alphabetical: return Localization().getStringEx('model.event2.sort_type.alphabetical', 'Alphabetical');
    case Event2SortType.proximity: return Localization().getStringEx('model.event2.sort_type.proximity', 'Proximity');
    default: return null;
  }
}

String? event2SortTypeDisplayStatusString(Event2SortType? value) {
  switch (value) {
    case Event2SortType.dateTime: return Localization().getStringEx('model.event2.sort_type.status.date_time', 'Date');
    case Event2SortType.alphabetical: return Localization().getStringEx('model.event2.sort_type.status.alphabetical', 'Alpha');
    case Event2SortType.proximity: return Localization().getStringEx('model.event2.sort_type.status.proximity', 'Proximity');
    default: return null;
  }
}

// Event2SortOrder

String? event2SortOrderIndicatorDisplayString(Event2SortOrder? value) {
  switch (value) {
    case Event2SortOrder.ascending: return Localization().getStringEx('model.event2.sort_order.indicator.ascending', '⇩');
    case Event2SortOrder.descending: return Localization().getStringEx('model.event2.sort_order.indicator.descending', '⇧');
    default: return null;
  }
}

String? event2SortOrderStatusDisplayString(Event2SortOrder? value) {
  switch (value) {
    case Event2SortOrder.ascending: return Localization().getStringEx('model.event2.sort_order.status.ascending', 'Asc');
    case Event2SortOrder.descending: return Localization().getStringEx('model.event2.sort_order.status.descending', 'Desc');
    default: return null;
  }
}

// Event2TypeFilter

String? event2TypeFilterToDisplayString(Event2TypeFilter? value) {
  switch (value) {
    case Event2TypeFilter.free: return Localization().getStringEx('model.event2.event_type.free', 'Free');
    case Event2TypeFilter.paid: return Localization().getStringEx('model.event2.event_type.paid', 'Paid');
    case Event2TypeFilter.inPerson: return Localization().getStringEx('model.event2.event_type.in_person', 'In-person');
    case Event2TypeFilter.online: return Localization().getStringEx('model.event2.event_type.online', 'Online');
    case Event2TypeFilter.hybrid: return Localization().getStringEx('model.event2.event_type.hybrid', 'Hybrid');
    case Event2TypeFilter.public: return Localization().getStringEx('model.event2.event_type.public', 'Public');
    case Event2TypeFilter.private: return Localization().getStringEx('model.event2.event_type.private', 'Uploaded Guest List Only');
    case Event2TypeFilter.nearby: return Localization().getStringEx('model.event2.event_type.nearby', 'Nearby');
    case Event2TypeFilter.superEvent: return Localization().getStringEx('model.event2.event_type.super_event', 'Multi-event');
    case Event2TypeFilter.favorite: return Localization().getStringEx('model.event2.event_type.favorite', 'Starred');
    case Event2TypeFilter.admin: return Localization().getStringEx('model.event2.event_type.admin', 'Аdministered');
    default: return null;
  }
}

String? event2TypeFilterToSelectDisplayString(Event2TypeFilter? value) {
  switch (value) {
    case Event2TypeFilter.nearby: return Localization().getStringEx('model.event2.event_type.nearby.select', 'Nearby Events');
    case Event2TypeFilter.superEvent: return Localization().getStringEx('model.event2.event_type.super_event.select', 'Multi-event series');
    case Event2TypeFilter.favorite: return Localization().getStringEx('model.event2.event_type.favorite.select', 'My starred events');
    case Event2TypeFilter.admin: return Localization().getStringEx('model.event2.event_type.admin.select', 'Events I administer');
    default: return null;
  }
}

// Event2TypeGroup

String? event2TypeGroupToDisplayString(Event2TypeGroup? value, {String? language}) {
  switch (value) {
    case Event2TypeGroup.cost: return Localization().getStringEx('model.event2.event_type_group.cost', 'Cost', language: language);
    case Event2TypeGroup.format: return Localization().getStringEx('model.event2.event_type_group.format', 'Format', language: language);
    case Event2TypeGroup.access: return Localization().getStringEx('model.event2.event_type_group.access', 'Access', language: language);
    case Event2TypeGroup.limits: return Localization().getStringEx('model.event2.event_type_group.limits', 'Limit Results To', language: language);
    default: return null;
  }
}

Map<String, dynamic> event2TypeGroupToTranslationsMap() {
  Map<String, dynamic> translations = <String, dynamic>{};
  for (String language in Localization().supportedLanguages) {
    translations[language] = Map.fromEntries(Event2TypeGroup.values.map((group) => MapEntry(group.name, event2TypeGroupToDisplayString(group, language: language))));
  }
  return translations;
}

// Event2TimeFilter

String? event2TimeFilterToDisplayString(Event2TimeFilter? value) {
  switch (value) {
    case Event2TimeFilter.past: return Localization().getStringEx("model.event2.event_time.past", "Past");
    case Event2TimeFilter.upcoming: return Localization().getStringEx("model.event2.event_time.upcoming", "Upcoming");
    case Event2TimeFilter.today: return Localization().getStringEx("model.event2.event_time.today", "Today");
    case Event2TimeFilter.tomorrow: return Localization().getStringEx("model.event2.event_time.tomorrow", "Tomorrow");
    case Event2TimeFilter.thisWeek: return Localization().getStringEx("model.event2.event_time.this_week", "This week");
    case Event2TimeFilter.thisWeekend: return Localization().getStringEx("model.event2.event_time.this_weekend", "This weekend");
    case Event2TimeFilter.nextWeek: return Localization().getStringEx("model.event2.event_time.next_week", "Next week");
    case Event2TimeFilter.nextWeekend: return Localization().getStringEx("model.event2.event_time.next_weekend", "Next weekend");
    case Event2TimeFilter.thisMonth: return Localization().getStringEx("model.event2.event_time.this_month", "This month");
    case Event2TimeFilter.nextMonth: return Localization().getStringEx("model.event2.event_time.next_month", "Next month");
    case Event2TimeFilter.customRange: return Localization().getStringEx("model.event2.event_time.custom_range.select", "Choose");
    default: return null;
  }
}

String? event2TimeFilterDisplayInfo(Event2TimeFilter? value, { TZDateTime? customStartTime, TZDateTime? customEndTime }) {
  final String dateFormat = 'MM/dd';
  Map<String, dynamic> options = <String, dynamic>{};
  Events2Query.buildTimeLoadOptions(options, value, customStartTimeUtc: customStartTime?.toUtc(), customEndTimeUtc: customEndTime?.toUtc());

  int? startTimeEpoch = JsonUtils.intValue(options['end_time_after']);
  TZDateTime? startTimeLocal = (startTimeEpoch != null) ? TZDateTime.fromMillisecondsSinceEpoch(customStartTime?.location ?? DateTimeLocal.timezoneLocal, startTimeEpoch * 1000) : null;

  int? endTimeEpoch = JsonUtils.intValue(options['start_time_before']);
  TZDateTime? endTimeLocal = (endTimeEpoch != null) ? TZDateTime.fromMillisecondsSinceEpoch(customEndTime?.location ?? DateTimeLocal.timezoneLocal, endTimeEpoch * 1000) : null;

  if (value == Event2TimeFilter.upcoming) {
    return null;
  }
  else if ((value == Event2TimeFilter.today) || (value == Event2TimeFilter.tomorrow)) {
    return (startTimeLocal != null) ? DateFormat(dateFormat).format(startTimeLocal) : null;
  }
  else {
    String? displayStartTime = (startTimeLocal != null) ? DateFormat(dateFormat).format(startTimeLocal) : null;
    String? displayEndTime = (endTimeLocal != null) ? DateFormat(dateFormat).format(endTimeLocal) : null;
    if (displayStartTime != null) {
      return (displayEndTime != null) ? '$displayStartTime - $displayEndTime' : '$displayStartTime ⇧';  
    }
    else {
      return (displayEndTime != null) ? '$displayEndTime ⇩' : null;
    }
  }

}

// Event2Type

String? event2TypeToDisplayString(Event2Type? value) {
  switch (value) {
    case Event2Type.inPerson: return Localization().getStringEx("model.event2.event_type.in_person", "In-person");
    case Event2Type.online: return Localization().getStringEx("model.event2.event_type.online", "Online");
    case Event2Type.hybrid: return Localization().getStringEx("model.event2.event_type.hybrid", "Hybrid");
    default: return null;
  }
}

String? event2ContactToDisplayString(Event2Contact? value){
  if(value == null)
    return null;

  String contactDetails = '';

  if (StringUtils.isNotEmpty(value.firstName)) {
    contactDetails += value.firstName!;
  }
  if (StringUtils.isNotEmpty(value.lastName)) {
    if (StringUtils.isNotEmpty(contactDetails)) {
      contactDetails += ' ';
    }
    contactDetails += value.lastName!;
  }
  if (StringUtils.isNotEmpty(value.organization)) {
    contactDetails += ' (${value.organization})';
  }
  if (StringUtils.isNotEmpty(value.email)) {
    if (StringUtils.isNotEmpty(contactDetails)) {
      contactDetails += ', ';
    }
    contactDetails += value.email!;
  }
  if (StringUtils.isNotEmpty(value.phone)) {
    if (StringUtils.isNotEmpty(contactDetails)) {
      contactDetails += ', ';
    }
    contactDetails += value.phone!;
  }

  return contactDetails;
}

// Event2RegistrationType

String event2RegistrationToDisplayString(Event2RegistrationType value) {
  switch (value) {
    case Event2RegistrationType.none: return Localization().getStringEx("model.event2.registration_type.none", "None");
    case Event2RegistrationType.internal: return Localization().getStringEx("model.event2.registration_type.internal", "Via the app");
    case Event2RegistrationType.external: return Localization().getStringEx("model.event2.registration_type.external", "Via external link");
  }
}

// Event2UserRegistrationType

String? event2UserRegistrationToDisplayString(Event2UserRegistrationType? value) {
  switch (value) {
    case Event2UserRegistrationType.self: return Localization().getStringEx("model.event2.registrant_type.self", "Self-Registered");
    case Event2UserRegistrationType.registrants: return Localization().getStringEx("model.event2.registrant_type.registrants", "Guest List");
    case Event2UserRegistrationType.creator: return Localization().getStringEx("model.event2.registrant_type.creator", "Creator");
    default: return null;
  }
}

extension Event2PersonIdentifierExt on Event2PersonIdentifier{
  static List<Event2PersonIdentifier>? constructAdminIdentifiersFromIds(List<String>? ids) =>
      CollectionUtils.isEmpty(ids) ? null :
        ids!.map((_id) => Event2PersonIdentifier(externalId: _id)
      ).toList();

  static List<String>? extractNetIds(List<Event2PersonIdentifier>? identifiers) =>
      identifiers?.fold<List<String>?>([],
              (ids,identifier) =>  ListUtils.append(ids, identifier.netId));

  static String? extractNetIdsString(List<Event2PersonIdentifier>? identifiers) =>
      extractNetIds(identifiers)?.join(", ");
}

extension Event2PersonsResultExt on Event2PersonsResult{
  List<Event2PersonIdentifier>? get adminIdentifiers =>
    registrants?.fold<List<Event2PersonIdentifier>?>([], (_admins, person) =>
      (person.role == Event2UserRole.admin) ?
          ListUtils.append(_admins, person.identifier) :
          _admins
      );
}

extension Events2Ext on Events2 {
    Future<List<Event2PersonIdentifier>?> loadAdminIdentifiers(Event2? event) async =>
      event?.id == null ? null :
        (await Events2().loadEventPeople(event!.id!))?.adminIdentifiers;

  Future<Event2Result> duplicateEvent(Event2? event, /*{List<Event2PersonIdentifier>? admins}*/) async {
    List<Event2PersonIdentifier>? _admins = await loadAdminIdentifiers(event);
    _admins?.removeWhere((identifier) =>  identifier.externalId == Auth2().netId); //exclude self otherwise the BB duplicates it
    return Events2().createEvent(event!.duplicate, adminIdentifiers: _admins).then((createdEvent) async {
      if (createdEvent is Event2) {

        if(event.isSuperEvent == false){
          return Event2Result.success(); //success
        }

        Events2ListResult? subEventsLoad = await Events2().loadEvents(Events2Query(groupings: event.linkedEventsGroupingQuery));
        if(CollectionUtils.isEmpty(subEventsLoad?.events)){
          return Event2Result.fail("Unable to load sub events");
        }
        //Duplicate sub events
        Event2SuperEventResult<int> updateResult = await  SuperEventsController.multiUpload(
            events: SuperEventsController.applyCollectionChange(
                collection: subEventsLoad?.events,
                change: (subEvent) {
                  Event2Grouping subGrouping = subEvent.grouping?.copyWith(superEventId:  createdEvent.id) ?? Event2Grouping.superEvent(createdEvent.id);
                  return subEvent.duplicateWith(grouping: subGrouping);}),
            uploadAPI: (event) => Events2().createEvent(event, adminIdentifiers: _admins));

        return updateResult.successful ? Event2Result.success(data: updateResult.data) : Event2Result.fail(updateResult.error);
      }

      return Event2Result.fail("Unable to duplicate main event");
    });
  }
}

class Event2Result<T>{
  String? error;
  T? data;

  Event2Result({String? this.error, this.data});

  static Event2Result<T> fail<T>(String? error) => Event2Result(error: error ?? "error");
  static Event2Result<T> success<T>({T? data}) => Event2Result(data: data);

  bool get successful => this.error == null;
}