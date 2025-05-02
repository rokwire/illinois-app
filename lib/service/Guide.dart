import 'dart:collection';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/app_lifecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/service/deep_link.dart';
import 'package:rokwire_plugin/service/network.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:timezone/timezone.dart';
import 'package:universal_io/io.dart';

enum GuideContentSource { Net, Debug }

class Guide with Service implements NotificationsListener {
  
  static const String notifyChanged  = "edu.illinois.rokwire.guide.changed";
  static const String notifyGuide = "edu.illinois.rokwire.guide";
  static const String notifyGuideDetail = "edu.illinois.rokwire.guide.detail";
  static const String notifyGuideList = "edu.illinois.rokwire.guide.list";

  static const String campusGuide = "For students";
  static const String campusReminderContentType = "campus-reminder";
  static const String campusHighlightContentType = "campus-highlight";
  static const String campusSafetyResourceContentType = "campus-safety-resource";
  static const String wellnessMentalHealthContentType = "mental-health";
  static const String wellnessCampusRecreationContentType = "campus-recreation";

  static const String _cacheFileName = "guide.json";

  List<dynamic>? _contentList;
  LinkedHashMap<String, Map<String, dynamic>?>? _contentMap;
  GuideContentSource? _contentSource;

  File?          _cacheFile;
  DateTime?      _pausedDateTime;

  static final Guide _service = Guide._internal();
  Guide._internal();

  factory Guide() {
    return _service;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      Storage.notifySettingChanged,
      AppLifecycle.notifyStateChanged,
      DeepLink.notifyUiUri,
    ]);
    super.createService();
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();
    _contentList = await _loadContentJsonFromCache();
    _contentSource = guideContentSourceFromString(Storage().guideContentSource);
    if (_contentList != null) {
      _contentMap = _buildContentMap(_contentList);
      _updateContentFromNet();
    }
    else {
      String? contentString = await _loadContentStringFromNet();
      _contentList = JsonUtils.decodeList(contentString);
      if (_contentList != null) {
        _contentMap = _buildContentMap(_contentList);
        _contentSource = GuideContentSource.Net;
        Storage().guideContentSource = guideContentSourceToString(_contentSource);
        _saveContentStringToCache(contentString);
        _initDefaultFavorites();
      }
    }

    if (_contentMap != null) {
      await super.initService();
    }
    else {
      throw ServiceError(
        source: this,
        severity: ServiceErrorSeverity.nonFatal,
        title: 'Student Guide Initialization Failed',
        description: 'Failed to initialize Student Guide content.',
      );
    }

  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), Auth2()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2.notifyLoginChanged) {
      _initDefaultFavorites();
    } else if (name == Storage.notifySettingChanged) {
      if (param == Storage.onBoardingPassedKey) {
        _initDefaultFavorites();
      }
    } else if (name == AppLifecycle.notifyStateChanged) {
      _onAppLifecycleStateChanged(param);
    } else if (name == DeepLink.notifyUiUri) {
      _processDeepLinkUri(param);
    }
  }

  void _onAppLifecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      //TMP: _convertFile('student.guide.import.json', 'Illinois_Student_Guide_Final.json');
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateContentFromNet();
        }
      }
    }
  }

  // Implementation

  Future<File?> _getCacheFile() async {
    Directory? appDocDir = kIsWeb ? null : await getApplicationDocumentsDirectory();
    String? cacheFilePath = (appDocDir != null) ? join(appDocDir.path, _cacheFileName) : null;
    return (cacheFilePath != null) ? File(cacheFilePath) : null;
  }

  Future<String?> _loadContentStringFromCache() async {
    return (await _cacheFile?.exists() == true) ? await _cacheFile?.readAsString() : null;
  }

  Future<void> _saveContentStringToCache(String? value) async {
    try {
      if (value != null) {
        await _cacheFile?.writeAsString(value, flush: true);
      }
      else {
        await _cacheFile?.delete();
      }
    }
    catch(e) { print(e.toString()); }
  }

  Future<List<dynamic>?> _loadContentJsonFromCache() async {
    return await JsonUtils.decodeListAsync(await _loadContentStringFromCache());
  }

  Future<String?> _loadContentStringFromNet() async {
    // //TMP:
    // return AppBundle.loadString('assets/guide.json');
    try {
      Response? response = await Network().get("${Config().contentUrl}/student_guides", auth: Auth2());
      //TMP: Log.d("Campus Guide: ${response?.body}", lineLength: 812);
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    }
    catch (e) { print(e.toString()); }
    return null;
  }

  Future<void> _updateContentFromNet() async {
    if ((_contentSource == null) || (_contentSource == GuideContentSource.Net)) {
      String? contentString = await _loadContentStringFromNet();
      List<dynamic>? contentList = await JsonUtils.decodeListAsync(contentString);
      if ((contentList != null) && !await CollectionUtils.equalsAsync(_contentList, contentList)) {
        _contentList = contentList;
        _contentMap = _buildContentMap(_contentList);
        _contentSource = GuideContentSource.Net;
        Storage().guideContentSource = guideContentSourceToString(_contentSource);
        _saveContentStringToCache(contentString);
        _initDefaultFavorites();
        NotificationService().notify(notifyChanged);
      }
    }
  }

  static LinkedHashMap<String, Map<String, dynamic>?>? _buildContentMap(List<dynamic>? contentList) {
    LinkedHashMap<String, Map<String, dynamic>?>? contentMap;
    if (contentList != null) {
      contentMap = LinkedHashMap<String, Map<String, dynamic>?>();
      for (dynamic contentEntry in contentList) {
        Map<String, dynamic>? mapEntry = JsonUtils.mapValue(contentEntry);
        String? id = (mapEntry != null) ? JsonUtils.stringValue(mapEntry['content_id']) : null;
        if (id != null) {
          contentMap[id] = mapEntry;
        }
      }
    }
    return contentMap;
  }

  // Content

  List<dynamic>? get contentList {
    return _contentList;
  }

  GuideContentSource? get contentSource {
    return _contentSource;
  }

  Future<void> refresh() async {
    await _updateContentFromNet();
  }

  Map<String, dynamic>? entryById(String? id) {
    return ((_contentMap != null) && (id != null)) ? _contentMap![id] : null;
  }

  dynamic entryValue(Map<String, dynamic>? entry, String key) {
    while (entry != null) {
      dynamic value = entry[key];
      if (value != null) {
        return value;
      }
      entry = entryById(JsonUtils.stringValue(entry['content_ref']));
    }
    return null;
  }

  String? entryId(Map<String, dynamic>? entry) {
    return JsonUtils.stringValue(entryValue(entry, 'content_id'));
  }

  String? entryGuide(Map<String, dynamic>? entry) {
    return JsonUtils.stringValue(entryValue(entry, 'guide'));
  }

  String? entryCategory(Map<String, dynamic>? entry) {
    return JsonUtils.stringValue(entryValue(entry, 'category'));
  }

  String? entrySection(Map<String, dynamic>? entry) {
    return JsonUtils.stringValue(entryValue(entry, 'section'));
  }

  String? entryContentType(Map<String, dynamic>? entry) {
    return JsonUtils.stringValue(entryValue(entry, 'content_type'));
  }

  String? entryTitle(Map<String, dynamic>? entry, { bool? stripHtmlTags }) {
    String? result = JsonUtils.stringValue(entryValue(entry, 'title')) ?? JsonUtils.stringValue(entryValue(entry, 'list_title')) ?? JsonUtils.stringValue(entryValue(entry, 'detail_title'));
    return ((result != null) && (stripHtmlTags == true)) ? StringUtils.stripHtmlTags(result) : result;
    // Bidi.stripHtmlIfNeeded(result);
  }

  String? entryListTitle(Map<String, dynamic>? entry, { bool? stripHtmlTags }) {
    String? result = JsonUtils.stringValue(entryValue(entry, 'list_title')) ?? JsonUtils.stringValue(entryValue(entry, 'title'));
    return ((result != null) && (stripHtmlTags == true)) ? StringUtils.stripHtmlTags(result) : result;
    // Bidi.stripHtmlIfNeeded(result);
  }

  String? entryListDescription(Map<String, dynamic>? entry, { bool? stripHtmlTags }) {
    String? result = JsonUtils.stringValue(entryValue(entry, 'list_description')) ?? JsonUtils.stringValue(entryValue(entry, 'description'));
    return ((result != null) && (stripHtmlTags == true)) ? StringUtils.stripHtmlTags(result) : result;
    // Bidi.stripHtmlIfNeeded(result);
  }

  Map<String, dynamic>? entryAnalyticsAttributes(Map<String, dynamic>? entry) => (entry != null) ? {
    Analytics.LogAttributeGuideId : entryId(entry),
    Analytics.LogAttributeGuideTitle : Guide().entryTitle(entry, stripHtmlTags: true),
    Analytics.LogAttributeGuide : Guide().entryGuide(entry),
    Analytics.LogAttributeGuideCategory :  Guide().entryCategory(entry),
    Analytics.LogAttributeGuideSection :  Guide().entrySection(entry),
  } : null;

  bool isEntryReminder(Map<String, dynamic>? entry) {
    return entryContentType(entry) == campusReminderContentType;
  }

  bool isEntrySafetyResource(Map<String, dynamic>? entry) {
    return entryContentType(entry) == campusSafetyResourceContentType;
  }

  bool isEntryMentalHeatlh(Map<String, dynamic>? entry) {
    return entryContentType(entry) == wellnessMentalHealthContentType;
  }

  // Returns the date in:
  // A) if universityLocation exits => in Univerity timezone;
  // B) otherwise => in local timezone.
  DateTime? reminderDate(Map<String, dynamic>? entry) {
    DateTime? dateUtc = DateTimeUtils.dateTimeFromString(JsonUtils.stringValue(entryValue(entry, 'date')), format: "yyyy-MM-dd", isUtc: true);
    if (dateUtc != null) {
      Location? universityLocation = AppDateTime().universityLocation;
      return (universityLocation != null) ? TZDateTime(universityLocation, dateUtc.year, dateUtc.month, dateUtc.day) : DateTime(dateUtc.year, dateUtc.month, dateUtc.day);
    }
    return null;
  }

  DateTime? reminderSectionDate(Map<String, dynamic> entry) {
    DateTime? entryDate = Guide().reminderDate(entry);
    return (entryDate != null) ? DateTime(entryDate.year, entryDate.month) : null;
  }

  List<Map<String, dynamic>>? getContentList({String? guide, String? category, GuideSection? section}) {
    if (_contentList != null) {
      List<Map<String, dynamic>> guideList = <Map<String, dynamic>>[];
      for (dynamic contentEntry in _contentList!) {
        Map<String, dynamic>? guideEntry = JsonUtils.mapValue(contentEntry);
        if ((guideEntry != null) &&
            ((guide == null) || (Guide().entryGuide(guideEntry) == guide)) &&
            ((category == null) || (Guide().entryCategory(guideEntry)) == category) &&
            ((section == null) || (GuideSection.fromGuideEntry(guideEntry) == section)))
        {
          guideList.add(guideEntry);
        }
      }
      listSortDefault(guideList);
      return guideList;
    }
    return null;
  }

  List<Map<String, dynamic>>? get remindersList {
    if (_contentList != null) {

      // midnight's timezone is:
      // A) if universityLocation exits => the Univerity timezone;
      // B) otherwise => the local timezone.
      Location? universityLocation = AppDateTime().universityLocation;
      DateTime now = (universityLocation != null) ? TZDateTime.from(DateTime.now().toUtc(), universityLocation) : DateTime.now();
      DateTime midnight = (universityLocation != null) ? TZDateTime(universityLocation, now.year, now.month, now.day) : DateTime(now.year, now.month, now.day);

      List<Map<String, dynamic>> remindersList = <Map<String, dynamic>>[];
      for (dynamic entry in _contentList!) {
        Map<String, dynamic>? guideEntry = JsonUtils.mapValue(entry);
        if (isEntryReminder(guideEntry)) {
          DateTime? entryDate = reminderDate(guideEntry);
          if ((entryDate != null) && (midnight.compareTo(entryDate) <= 0)) {
            remindersList.add(guideEntry!);
          }
        }
      }

      remindersList.sort((Map<String, dynamic>? entry1, Map<String, dynamic>? entry2) {
        return SortUtils.compare(Guide().reminderDate(entry1), Guide().reminderDate(entry2));
      });

      return remindersList;
    }
    return null;
  }

  List<Map<String, dynamic>>? get safetyResourcesList {
    if (_contentList != null) {

      List<Map<String, dynamic>> safetyResourcesList = <Map<String, dynamic>>[];
      for (dynamic entry in _contentList!) {
        Map<String, dynamic>? guideEntry = JsonUtils.mapValue(entry);
        if (isEntrySafetyResource(guideEntry)) {
          safetyResourcesList.add(guideEntry!);
        }
      }

      listSortDefault(safetyResourcesList);

      return safetyResourcesList;
    }
    return null;
  }

  List<Map<String, dynamic>>? get mentalHealthList {
    if (_contentList != null) {

      List<Map<String, dynamic>> mentalHealthList = <Map<String, dynamic>>[];
      for (dynamic entry in _contentList!) {
        Map<String, dynamic>? guideEntry = JsonUtils.mapValue(entry);
        if (isEntryMentalHeatlh(guideEntry)) {
          mentalHealthList.add(guideEntry!);
        }
      }

      mentalHealthList.sort((Map<String, dynamic> entry1, Map<String, dynamic> entry2) {
        return SortUtils.compare(Guide().entryListTitle(entry1, stripHtmlTags: true), Guide().entryListTitle(entry2, stripHtmlTags: true));
      });

      return mentalHealthList;
    }
    return null;
  }

  List<Map<String, dynamic>>? get promotedList {
    if (_contentList != null) {
      List<Map<String, dynamic>> promotedList = <Map<String, dynamic>>[];
      for (dynamic contentEntry in _contentList!) {
        Map<String, dynamic>? guideEntry = JsonUtils.mapValue(contentEntry);
        if (_isEntryPromoted(guideEntry)) {
          promotedList.add(guideEntry!);
        }
      }

      listSortDefault(promotedList);
      return promotedList;
    }
    return null;
  }

  bool _isEntryPromoted(Map<String, dynamic>? entry) {
    Map<String, dynamic>? promotion = (entry != null) ? JsonUtils.mapValue(entryValue(entry, 'promotion')) : null;
    return (promotion != null) ?
      _checkPromotionInterval(promotion) &&
      _checkPromotionRoles(promotion) &&
      _checkPromotionCard(promotion) :
    false;
  }

  bool _isEntryPromotion(Map<String, dynamic>? entry) {
    Map<String, dynamic>? promotion = (entry != null) ? JsonUtils.mapValue(entryValue(entry, 'promotion')) : null;
    return (promotion != null);
  }

  static bool _checkPromotionInterval(Map<String, dynamic>? promotion) {
    Map<String, dynamic>? interval = (promotion != null) ? JsonUtils.mapValue(promotion['interval']) : null;
    if (interval != null) {
      DateTime now = DateTime.now().toUtc();
      
      String? startString = JsonUtils.stringValue(interval['start']);
      DateTime? startTime = (startString != null) ? DateTime.tryParse(startString)?.toUtc() : null;
      if ((startTime != null) && now.isBefore(startTime)) {
        return false;
      }
      
      String? endString = JsonUtils.stringValue(interval['end']);
      DateTime? endTime = (endString != null) ? DateTime.tryParse(endString)?.toUtc() : null;
      if ((endTime != null) && now.isAfter(endTime)) {
        return false;
      }
    }
    return true;
  }

  static bool _checkPromotionRoles(Map<String, dynamic>? promotion) {
    dynamic roles = (promotion != null) ? promotion['roles'] : null;
    return (roles != null) ? BoolExpr.eval(roles, (dynamic argument) {
      UserRole? userRole = (argument is String) ? UserRole.fromString(argument) : null;
      return (userRole != null) ? (Auth2().prefs?.roles?.contains(userRole) ?? false) : null;
    }) : true; 
  }

  static bool _checkPromotionCard(Map<String, dynamic>? promotion) {
    Map<String, dynamic>? card = (promotion != null) ? JsonUtils.mapValue(promotion['card']) : null;
    if (card != null) {
      dynamic cardRole = card['role'];
      if ((cardRole != null) && !BoolExpr.eval(cardRole, (dynamic role) { return (role is String) ? (Auth2().iCard?.role?.toLowerCase() == role.toLowerCase()) : null; })) {
        return false;
      }

      dynamic cardStudentLevel = card['student_level'];
      if ((cardStudentLevel != null) && !BoolExpr.eval(cardStudentLevel, (dynamic studentLevel) { return (studentLevel is String) ? (Auth2().iCard?.studentLevel?.toLowerCase() == studentLevel.toLowerCase()) : null; })) {
        return false;
      }
    }
    return true;
  }
  
  /////////////////////////
  // List Content Type

  String? listContentType(List<Map<String, dynamic>>? guideList) {
    String? listContentType;
    if (guideList != null) {
      for (Map<String, dynamic> guideEntry in guideList) {
        String? guideEntryContentType = entryContentType(guideEntry);
        if (guideEntryContentType != null) {
          if (listContentType == null) {
            listContentType = guideEntryContentType;
          }
          else if (listContentType != guideEntryContentType) {
            listContentType = null;
            break;
          }
        }
      }
    }
    return listContentType;
  }

  /////////////////////////
  // DefaultFavorites

  void _initDefaultFavorites() {

    if ((Storage().onBoardingPassed == true) && (_contentList != null)) {
      Set<String> modifiedFavoriteKeys = <String>{};
      Map<String, LinkedHashSet<String>> favorites = <String, LinkedHashSet<String>>{};
      for (dynamic contentEntry in _contentList!) {
        Map<String, dynamic>? guideEntry = JsonUtils.mapValue(contentEntry);
        bool? isFavorite = JsonUtils.boolValue(entryValue(guideEntry, 'content_type_favorite'));
        if (isFavorite == true) {
          String? guideEntryId = entryId(guideEntry);
          if (guideEntryId != null) {
            String? guideEntryContentType = entryContentType(guideEntry);
            if (guideEntryContentType != null) {
              _processDefaultFavorites(guideEntryId: guideEntryId, guideEntryContentType: guideEntryContentType, favorites: favorites, modifiedFavoriteKeys: modifiedFavoriteKeys);
            }
            if (_isEntryPromotion(guideEntry)) {
              _processDefaultFavorites(guideEntryId: guideEntryId, guideEntryContentType: campusHighlightContentType, favorites: favorites, modifiedFavoriteKeys: modifiedFavoriteKeys);
            }
          }
        }
      }

      for (String modifiedFavoriteKey in modifiedFavoriteKeys) {
        Auth2().prefs?.setFavorites(modifiedFavoriteKey, favorites[modifiedFavoriteKey]);
      }
    }
  }

  void _processDefaultFavorites({
    required String guideEntryId,
    required String guideEntryContentType,
    required Map<String, LinkedHashSet<String>> favorites,
    required Set<String> modifiedFavoriteKeys
  }) {
    String processedKeyName = GuideFavorite.constructFavoriteKeyName(contentType: guideEntryContentType, processed: true);
    LinkedHashSet<String> processedGuideEntryIds = (favorites[processedKeyName] ??= LinkedHashSet<String>.from(Auth2().prefs?.getFavorites(processedKeyName)?? LinkedHashSet<String>()));
    if (!processedGuideEntryIds.contains(guideEntryId)) {
      String favoriteKeyName = GuideFavorite.constructFavoriteKeyName(contentType: guideEntryContentType);
      LinkedHashSet<String> favoriteGuideEntryIds = (favorites[favoriteKeyName] ??= LinkedHashSet<String>.from(Auth2().prefs?.getFavorites(favoriteKeyName) ?? LinkedHashSet<String>()));
      favoriteGuideEntryIds.add(guideEntryId); // Mark guideEntryId as favorite
      processedGuideEntryIds.add(guideEntryId); // Mark guideEntryId as processed
      modifiedFavoriteKeys.add(favoriteKeyName);
      modifiedFavoriteKeys.add(processedKeyName);
    }
  }

  // Sort

  bool listSortDefault(List<Map<String, dynamic>>? guideList) {
    if (_listSortBySortOrder(guideList)) {
      return true;
    }
    else if (_listIsReminders(guideList) && _listSortByDate(guideList)) {
      return true;
    }
    else if (_listSortByListTitle(guideList)) {
      return true;
    }
    else {
      return false;
    }
  }

  bool _listSortBySortOrder(List<Map<String, dynamic>>? guideList) {
    if (_listHasSortOrder(guideList)) {
      guideList?.sort((Map<String, dynamic> guideItem1, Map<String, dynamic> guideItem2) {
        int? sortOrder1 = JsonUtils.intValue(entryValue(guideItem1, 'sort_order'));
        int? sortOrder2 = JsonUtils.intValue(entryValue(guideItem2, 'sort_order'));
        return SortUtils.compare(sortOrder1, sortOrder2);
      });
      return true;
    }
    return false;
  }

  bool _listHasSortOrder(List<Map<String, dynamic>>? guideList) {
    if (guideList == null) {
      return false;
    }
    else {
      for (Map<String, dynamic> guideItem in guideList) {
        int? sortOrder = JsonUtils.intValue(entryValue(guideItem, 'sort_order'));
        if (sortOrder == null) {
          return false;
        }
      }
      return true;
    }
  }

  bool _listSortByListTitle(List<Map<String, dynamic>>? guideList) {
    if (listHasListTitle(guideList)) {
      guideList?.sort((Map<String, dynamic> guideItem1, Map<String, dynamic> guideItem2) {
        String? listTitle1 = Guide().entryListTitle(guideItem1, stripHtmlTags: true);
        String? listTitle2 = Guide().entryListTitle(guideItem2, stripHtmlTags: true);
        return SortUtils.compare(listTitle1, listTitle2);
      });
      return true;
    }
    return false;
  }

  bool listHasListTitle(List<Map<String, dynamic>>? guideList) {
    if (guideList == null) {
      return false;
    }
    else {
      for (Map<String, dynamic> guideItem in guideList) {
        String? listTitle = Guide().entryListTitle(guideItem);
        if (listTitle == null) {
          return false;
        }
      }
      return true;
    }
  }

  bool _listSortByDate(List<Map<String, dynamic>>? guideList) {
    if (_listHasDate(guideList)) {
      guideList?.sort((Map<String, dynamic> guideItem1, Map<String, dynamic> guideItem2) {
        String? date1 = JsonUtils.stringValue(entryValue(guideItem1, 'date'));
        String? date2 = JsonUtils.stringValue(entryValue(guideItem2, 'date'));
        return SortUtils.compare(date1, date2);
      });
      return true;
    }
    return false;
  }

  bool _listHasDate(List<Map<String, dynamic>>? guideList) {
    if (guideList == null) {
      return false;
    }
    else {
      for (Map<String, dynamic> guideItem in guideList) {
        String? date = JsonUtils.stringValue(entryValue(guideItem, 'date'));
        if (date == null) {
          return false;
        }
      }
      return true;
    }
  }

  bool _listIsReminders(List<Map<String, dynamic>>? guideList) {
    if (guideList == null) {
      return false;
    }
    else {
      for (Map<String, dynamic> guideItem in guideList) {
        if (!isEntryReminder(guideItem)) {
          return false;
        }
      }
      return true;
    }
  }

  // Debug

  Future<String?> getContentString() async {
    return await _loadContentStringFromCache();
  }

  Future<String?> setDebugContentString(String? value) async {
    String? contentString;
    List<dynamic>? contentList;
    GuideContentSource contentSource;
    if (value != null) {
      contentString = value;
      contentSource = GuideContentSource.Debug;
    }
    else {
      contentString = await _loadContentStringFromNet();
      contentSource = GuideContentSource.Net;
    }

    contentList = JsonUtils.decodeList(contentString);
    if (contentList != null) {
      _contentSource = contentSource;
      Storage().guideContentSource = guideContentSourceToString(_contentSource);
      _saveContentStringToCache(contentString);

      if (!DeepCollectionEquality().equals(_contentList, contentList)) {
        _contentList = contentList;
        _contentMap = _buildContentMap(_contentList);
        NotificationService().notify(notifyChanged);
      }
      return contentString;
    }
    else {
      return null;
    }
  }

  /////////////////////////
  // DeepLinks

  String get listBaseUrl => '${DeepLink().appUrl}/guide_list';

  String get detailBaseUrl => '${DeepLink().appUrl}/guide_detail';

  String detailUrl(String? guideId, {AnalyticsFeature? analyticsFeature}) =>
    "$detailBaseUrl?guide_id=$guideId" + ((analyticsFeature != null) ? "&analytics_feature=$analyticsFeature" : "");

  String? detailIdFromUrl(String? url) {
    return (url != null) ? detailIdFromUri(Uri.tryParse(url)) : null;
  }

  String? detailIdFromUri(Uri? uri) {
    if (uri != null) {
      Uri? guideUri = Uri.tryParse('${DeepLink().appUrl}');
      if ((guideUri != null) &&
          (guideUri.scheme == uri.scheme) &&
          (guideUri.authority == uri.authority))
      {
        if (uri.path == '/guide_detail') {
          return JsonUtils.stringValue(uri.queryParameters['guide_id']);
        }
      }
    }
    return null;
  }

  void _processDeepLinkUri(Uri? uri) {
    if (uri != null) {
      Uri? guideUri = Uri.tryParse('${DeepLink().appUrl}');
      if ((guideUri != null) &&
          (guideUri.scheme == uri.scheme) &&
          (guideUri.authority == uri.authority))
      {

        if (uri.path == '/guide') {
          NotificationService().notify(notifyGuide, null);
        }
        else if (uri.path == '/guide_detail') {
          try { NotificationService().notify(notifyGuideDetail, uri.queryParameters.cast<String, dynamic>()); }
          catch (e) { print(e.toString()); }
        }
        else if (uri.path == '/guide_list') {
          try { NotificationService().notify(notifyGuideList, uri.queryParameters.cast<String, dynamic>()); }
          catch (e) { print(e.toString()); }
        }
      }
    }
  }
}

class GuideSection {
  final String? name;
  final DateTime? date;
  
  GuideSection({this.name, this.date});

  static GuideSection? fromGuideEntry(Map<String, dynamic>? guideEntry) {
    return (guideEntry != null) ? GuideSection(
        name: Guide().entrySection(guideEntry),
        date: Guide().isEntryReminder(guideEntry) ? Guide().reminderSectionDate(guideEntry) : null,
    ) : null;
  }

  bool operator ==(o) =>
    (o is GuideSection) &&
      (o.name == name) &&
      (o.date == date);

  int get hashCode =>
    (name?.hashCode ?? 0) ^
    (date?.hashCode ?? 0);

  int compareTo(GuideSection section) {
    if (date != null) {
      if (section.date != null) {
        return date!.compareTo(section.date!);
      }
      else {
        return -1;
      }
    }
    else if (section.date != null) {
      return 1;
    }
    else if (name != null) {
      if (section.name != null) {
        return name!.compareTo(section.name!);
      }
      else {
        return -1;
      }
    }
    else if (section.name != null) {
      return 1;
    }
    else {
      return 0;
    }
  }
}


class GuideFavorite implements Favorite {
  
  final String? id;
  final String? contentType;
  GuideFavorite({this.id, this.contentType});

  bool operator == (o) => o is GuideFavorite && o.id == id;

  int get hashCode => (id?.hashCode ?? 0);

  static const String favoriteKeyName = "studentGuideIds";
  static String constructFavoriteKeyName({String? contentType, bool processed = false}) => (contentType != null) ? "${_favoriteContentTypeKey(contentType, processed)}GuideIds" : favoriteKeyName;
  @override String get favoriteKey => constructFavoriteKeyName(contentType: contentType);
  @override String? get favoriteId => id;

  static String _favoriteContentTypeKey(String contentType, bool processed) {
    String favoriteKey = '';
    List<String> items = contentType.split('-');
    for (String item in items) {
      if (favoriteKey.isEmpty) {
        favoriteKey = item;
      }
      else {
        favoriteKey += StringUtils.capitalize(item);
      }
    }
    if (processed) {
      favoriteKey += 'Processed';
    }
    return favoriteKey;
  }
}

GuideContentSource? guideContentSourceFromString(String? value) {
  if (value == 'Net') {
    return GuideContentSource.Net;
  }
  else if (value == 'Debug') {
    return GuideContentSource.Debug;
  }
  else {
    return null;
  }
}

String? guideContentSourceToString(GuideContentSource? value) {
  switch (value) {
    case GuideContentSource.Net:   return 'Net';
    case GuideContentSource.Debug: return 'Debug';
    default: break;
  }
  return null;
}