import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/Auth2.dart';
import 'package:illinois/service/AppDateTime.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

enum GuideContentSource { Net, Debug }

class Guide with Service implements NotificationsListener {
  
  static const String GUIDE_URI = '${DeepLink.ROKWIRE_URL}/guide_detail';

  static const String notifyChanged  = "edu.illinois.rokwire.guide.changed";
  static const String notifyGuideDetail = "edu.illinois.rokwire.guide.detail";

  static const String campusGuide = "For students";
  static const String campusReminderContentType = "campus-reminder";

  static const String _cacheFileName = "guide.json";

  List<dynamic> _contentList;
  LinkedHashMap<String, Map<String, dynamic>> _contentMap;
  GuideContentSource _contentSource;

  File          _cacheFile;
  DateTime      _pausedDateTime;

  List<Map<String, dynamic>> _guideDetailsCache;

  static final Guide _service = Guide._internal();
  Guide._internal();

  factory Guide() {
    return _service;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      DeepLink.notifyUri,
      AppLivecycle.notifyStateChanged,
    ]);
    _guideDetailsCache = [];
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
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
      String contentString = await _loadContentStringFromNet();
      _contentList = AppJson.decodeList(contentString);
      if (_contentList != null) {
        _contentMap = _buildContentMap(_contentList);
        _contentSource = GuideContentSource.Net;
        Storage().guideContentSource = guideContentSourceToString(_contentSource);
        _saveContentStringToCache(contentString);
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
  void initServiceUI() {
    _processCachedGuideDetails();
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config(), Auth2()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    } else if (name == DeepLink.notifyUri) {
      _onDeepLinkUri(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      //TMP: _convertFile('student.guide.import.json', 'Illinois_Student_Guide_Final.json');
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _updateContentFromNet();
        }
      }
    }
  }

  // Implementation

  Future<File> _getCacheFile() async {
    Directory appDocDir = await getApplicationDocumentsDirectory();
    String cacheFilePath = join(appDocDir.path, _cacheFileName);
    return File(cacheFilePath);
  }

  Future<String> _loadContentStringFromCache() async {
    return (await _cacheFile?.exists() == true) ? await _cacheFile.readAsString() : null;
  }

  Future<void> _saveContentStringToCache(String value) async {
    try {
      if (value != null) {
        await _cacheFile?.writeAsString(value, flush: true);
      }
      else {
        await _cacheFile?.delete();
      }
    }
    catch(e) { print(e?.toString()); }
  }

  Future<List<dynamic>> _loadContentJsonFromCache() async {
    return AppJson.decodeList(await _loadContentStringFromCache());
  }

  Future<String> _loadContentStringFromNet() async {
    try {
      Response response = await Network().get("${Config().contentUrl}/student_guides", auth: NetworkAuth.Auth2);
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    }
    catch (e) { print(e.toString()); }
    return null;
  }

  Future<void> _updateContentFromNet() async {
    if ((_contentSource == null) || (_contentSource == GuideContentSource.Net)) {
      String contentString = await _loadContentStringFromNet();
      List<dynamic> contentList = AppJson.decodeList(contentString);
      if ((contentList != null) && !DeepCollectionEquality().equals(_contentList, contentList)) {
        _contentList = contentList;
        _contentMap = _buildContentMap(_contentList);
        _contentSource = GuideContentSource.Net;
        Storage().guideContentSource = guideContentSourceToString(_contentSource);
        _saveContentStringToCache(contentString);
        NotificationService().notify(notifyChanged);
      }
    }
  }

  static LinkedHashMap<String, Map<String, dynamic>> _buildContentMap(List<dynamic> contentList) {
    LinkedHashMap<String, Map<String, dynamic>> contentMap;
    if (contentList != null) {
      contentMap = LinkedHashMap<String, Map<String, dynamic>>();
      for (dynamic contentEntry in contentList) {
        Map<String, dynamic> mapEntry = AppJson.mapValue(contentEntry);
        String id = (mapEntry != null) ? AppJson.stringValue(mapEntry['_id']) : null;
        if (id != null) {
          contentMap[id] = mapEntry;
        }
      }
    }
    return contentMap;
  }

  // Content

  List<dynamic> get contentList {
    return _contentList;
  }

  GuideContentSource get contentSource {
    return _contentSource;
  }

  Future<void> refresh() async {
    await _updateContentFromNet();
  }

  Map<String, dynamic> entryById(String id) {
    return (_contentMap != null) ? _contentMap[id] : null;
  }

  dynamic entryValue(Map<String, dynamic> entry, String key) {
    while (entry != null) {
      dynamic value = entry[key];
      if (value != null) {
        return value;
      }
      entry = entryById(AppJson.stringValue(entry['content_ref']));
    }
    return null;
  }

  String entryId(Map<String, dynamic> entry) {
    return AppJson.stringValue(entryValue(entry, '_id'));
  }

  String entryTitle(Map<String, dynamic> entry, { bool stripHtmlTags = true }) {
    String result = AppJson.stringValue(entryValue(entry, 'title')) ?? AppJson.stringValue(entryValue(entry, 'list_title')) ?? AppJson.stringValue(entryValue(entry, 'detail_title'));
    return ((result != null) && (stripHtmlTags == true)) ? AppString.stripHtmlTags(result) : result;
    // Bidi.stripHtmlIfNeeded(result);
  }

  String entryListTitle(Map<String, dynamic> entry, { bool stripHtmlTags }) {
    String result = AppJson.stringValue(entryValue(entry, 'list_title')) ?? AppJson.stringValue(entryValue(entry, 'title'));
    return ((result != null) && (stripHtmlTags == true)) ? AppString.stripHtmlTags(result) : result;
    // Bidi.stripHtmlIfNeeded(result);
  }

  String entryListDescription(Map<String, dynamic> entry, { bool stripHtmlTags }) {
    String result = AppJson.stringValue(entryValue(entry, 'list_description')) ?? AppJson.stringValue(entryValue(entry, 'description'));
    return ((result != null) && (stripHtmlTags == true)) ? AppString.stripHtmlTags(result) : result;
    // Bidi.stripHtmlIfNeeded(result);
  }

  bool isEntryReminder(Map<String, dynamic> entry) {
    return AppJson.stringValue(entryValue(entry, 'content_type')) == campusReminderContentType;
  }

  DateTime reminderDate(Map<String, dynamic> entry) {
    return AppDateTime().dateTimeFromString(AppJson.stringValue(entryValue(entry, 'date')), format: "yyyy-MM-dd", isUtc: true);
  }

  DateTime reminderSectionDate(Map<String, dynamic> entry) {
    DateTime entryDate = Guide().reminderDate(entry);
    return (entryDate != null) ? DateTime(entryDate.year, entryDate.month) : null;
  }

  List<Map<String, dynamic>> getContentList({String guide, String category, GuideSection section}) {
    if (_contentList != null) {
      List<Map<String, dynamic>> guideList = <Map<String, dynamic>>[];
      for (dynamic contentEntry in _contentList) {
        Map<String, dynamic> guideEntry = AppJson.mapValue(contentEntry);
        if ((guideEntry != null) &&
            ((guide == null) || (Guide().entryValue(guideEntry, 'guide') == guide)) &&
            ((category == null) || (Guide().entryValue(guideEntry, 'category')) == category) &&
            ((section == null) || (GuideSection.fromGuideEntry(guideEntry) == section)))
        {
          guideList.add(guideEntry);
        }
      }
      return guideList;
    }
    return null;
  }

  List<Map<String, dynamic>> get remindersList {
    if (_contentList != null) {
      List<Map<String, dynamic>> remindersList = <Map<String, dynamic>>[];
      DateTime nowUtc = DateTime.now().toUtc();
      DateTime midnightUtc = DateTime(nowUtc.year, nowUtc.month, nowUtc.day);
      for (dynamic entry in _contentList) {
        Map<String, dynamic> guideEntry = AppJson.mapValue(entry);
        if (isEntryReminder(guideEntry)) {
          DateTime entryDate = reminderDate(guideEntry);
          if ((entryDate != null) && (midnightUtc.compareTo(entryDate) <= 0)) {
            remindersList.add(guideEntry);
          }
        }
      }

      remindersList.sort((Map<String, dynamic> entry1, Map<String, dynamic> entry2) {
        return AppSort.compareDateTimes(Guide().reminderDate(entry1), Guide().reminderDate(entry2));
      });

      return remindersList;
    }
    return null;
  }

  List<Map<String, dynamic>> get promotedList {
    if (_contentList != null) {
      List<Map<String, dynamic>> promotedList = <Map<String, dynamic>>[];
      for (dynamic contentEntry in _contentList) {
        Map<String, dynamic> guideEntry = AppJson.mapValue(contentEntry);
        if (_isEntryPromoted(guideEntry)) {
          promotedList.add(guideEntry);
        }
      }
      return promotedList;
    }
    return null;
  }

  bool _isEntryPromoted(Map<String, dynamic> entry) {
    Map<String, dynamic> promotion = (entry != null) ? AppJson.mapValue(entryValue(entry, 'promotion')) : null;
    return (promotion != null) ?
      _checkPromotionInterval(promotion) &&
      _checkPromotionRoles(promotion) &&
      _checkPromotionCard(promotion) :
    false;
  }

  static bool _checkPromotionInterval(Map<String, dynamic> promotion) {
    Map<String, dynamic> interval = (promotion != null) ? AppJson.mapValue(promotion['interval']) : null;
    if (interval != null) {
      DateTime now = DateTime.now().toUtc();
      
      String startString = AppJson.stringValue(interval['start']);
      DateTime startTime = (startString != null) ? DateTime.tryParse(startString)?.toUtc() : null;
      if ((startTime != null) && now.isBefore(startTime)) {
        return false;
      }
      
      String endString = AppJson.stringValue(interval['end']);
      DateTime endTime = (endString != null) ? DateTime.tryParse(endString)?.toUtc() : null;
      if ((endTime != null) && now.isAfter(endTime)) {
        return false;
      }
    }
    return true;
  }

  static bool _checkPromotionRoles(Map<String, dynamic> promotion) {
    dynamic roles = (promotion != null) ? promotion['roles'] : null;
    return (roles != null) ? AppBoolExpr.eval(roles, (String argument) {
      UserRole userRole = UserRole.fromString(argument);
      return (userRole != null) ? (Auth2().prefs?.roles?.contains(userRole) ?? false) : null;
    }) : true; 
  }

  static bool _checkPromotionCard(Map<String, dynamic> promotion) {
    Map<String, dynamic> card = (promotion != null) ? AppJson.mapValue(promotion['card']) : null;
    if (card != null) {
      dynamic cardRole = card['role'];
      if ((cardRole != null) && !AppBoolExpr.eval(cardRole, (String role) { return Auth2().authCard?.role?.toLowerCase() == role?.toLowerCase(); })) {
        return false;
      }

      dynamic cardStudentLevel = card['student_level'];
      if ((cardStudentLevel != null) && !AppBoolExpr.eval(cardStudentLevel, (String studentLevel) { return Auth2().authCard?.studentLevel?.toLowerCase() == studentLevel?.toLowerCase(); })) {
        return false;
      }
    }
    return true;
  }
  
  // Debug

  Future<String> getContentString() async {
    return await _loadContentStringFromCache();
  }

  Future<String> setDebugContentString(String value) async {
    String contentString;
    List<dynamic> contentList;
    GuideContentSource contentSource;
    if (value != null) {
      contentString = value;
      contentSource = GuideContentSource.Debug;
    }
    else {
      contentString = await _loadContentStringFromNet();
      contentSource = GuideContentSource.Net;
    }

    contentList = AppJson.decodeList(contentString);
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

  void _onDeepLinkUri(Uri uri) {
    if (uri != null) {
      Uri guideUri = Uri.tryParse(GUIDE_URI);
      if ((guideUri != null) &&
          (guideUri.scheme == uri.scheme) &&
          (guideUri.authority == uri.authority) &&
          (guideUri.path == uri.path))
      {
        try { _handleGuideDetail(uri.queryParameters?.cast<String, dynamic>()); }
        catch (e) { print(e?.toString()); }
      }
    }
  }

  void _handleGuideDetail(Map<String, dynamic> params) {
    if ((params != null) && params.isNotEmpty) {
      if (_guideDetailsCache != null) {
        _cacheGuideDetail(params);
      }
      else {
        _processGuideDetail(params);
      }
    }
  }

  void _processGuideDetail(Map<String, dynamic> params) {
    NotificationService().notify(notifyGuideDetail, params);
  }

  void _cacheGuideDetail(Map<String, dynamic> params) {
    _guideDetailsCache?.add(params);
  }

  void _processCachedGuideDetails() {
    if (_guideDetailsCache != null) {
      List<Map<String, dynamic>> guideDetailsCache = _guideDetailsCache;
      _guideDetailsCache = null;

      for (Map<String, dynamic> guideDetail in guideDetailsCache) {
        _processGuideDetail(guideDetail);
      }
    }
  }

  /*static Future<void> _convertFile(String contentFileName, String sourceFileName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    String sourceFilePath = join(appDocDir.path, sourceFileName);
    File sourceFile = File(sourceFilePath);
    String sourceString = await sourceFile.exists() ? await sourceFile.readAsString() : null;
    List<dynamic> sourceList = AppJson.decodeList(sourceString);
    
    List<dynamic> contentList = _convertContent(sourceList);
    String contentString = AppJson.encode(contentList, /*prettify: true*/);
    if (contentString != null) {
      String contentFilePath = join(appDocDir.path, contentFileName);
      File contentFile = File(contentFilePath);
      await contentFile.writeAsString(contentString, flush: true);
    }
  }

  static List<dynamic> _convertContent(List<dynamic> sourceList) {
    List<dynamic> contentList;
    if (sourceList != null) {
      contentList = <dynamic>[];
      for (dynamic sourceEntry in sourceList) {
        dynamic contentEntry = _convertContentEntry(sourceEntry);
        if (contentEntry != null) {
          contentList.add(contentEntry);
        }
      }
    }
    return contentList;
  }

  static Map<String, dynamic> _convertContentEntry(Map<String, dynamic> sourceEntry) {
    Map<String, dynamic> contentEntry = Map<String, dynamic>();

    // ID
    dynamic sourceValue = sourceEntry['id'];
    if (sourceValue != null) {
      contentEntry['_id'] = sourceValue;
    }

    // Shared Fields
    for (String key in ['guide', 'category', 'section', 'list_title', 'list_description', 'detail_title', 'detail_description', 'image', 'sub_details_title', 'sub_details_description']) {
      dynamic sourceValue = sourceEntry[key];
      if (sourceValue != null) {
        contentEntry[key] = sourceValue;
      }
    }

    // Features
    List<dynamic> features = <dynamic>[];
    String sourceFeaturesString = AppJson.stringValue(sourceEntry['features']);
    if (sourceFeaturesString != null) {
      List<String> sourceFeatures = sourceFeaturesString.split(RegExp('[;,\n]'));
      for (String sourceFeature in sourceFeatures) {
        sourceFeature = sourceFeature.trim();
        if (sourceFeature.isNotEmpty) {
          features.add(sourceFeature.toLowerCase().replaceAll(' ', '-'));
        }
      }
    }
    if (features.isNotEmpty) {
      contentEntry['features'] = features;
    }

    // Links
    List<dynamic> contentLinks = <dynamic>[];

    String phoneLinksString = AppJson.stringValue(sourceEntry['phone_links']);
    if (phoneLinksString != null) {
      List<String> phoneLinks = phoneLinksString.split(RegExp('[;,\n ]'));
      for (String phoneLink in phoneLinks) {
        if (phoneLink.isNotEmpty) {
          contentLinks.add({ "text": phoneLink, "icon": "https://rokwire-images.s3.us-east-2.amazonaws.com/guide/icon-link-phone.webp", "url": "tel:+1-$phoneLink" });
        }
      }
    }
    String emailLinksString = AppJson.stringValue(sourceEntry['email_links']);
    if (emailLinksString != null) {
      List<String> emailLinks = emailLinksString.split(RegExp('[;,\n ]'));
      for (String emailLink in emailLinks) {
        if (emailLink.isNotEmpty) {
          contentLinks.add({ "text": emailLink, "icon": "https://rokwire-images.s3.us-east-2.amazonaws.com/guide/icon-link-mail.webp", "url": "mailto:$emailLink" });
        }
      }
    }
    String webLinksString = AppJson.stringValue(sourceEntry['web_links']);
    if (webLinksString != null) {
      List<String> webLinks = webLinksString.split(RegExp('[;,\n ]'));
      for (String webLink in webLinks) {
        if (webLink.isNotEmpty) {
          contentLinks.add({ "text": webLink, "icon": "https://rokwire-images.s3.us-east-2.amazonaws.com/guide/icon-link-web.webp", "url": webLink });
        }
      }
    }
    String locationLinkString = AppJson.stringValue(sourceEntry['location_links']);
    if (locationLinkString != null) {
      List<String> locationItems = locationLinkString.split(RegExp('[\n]'));
      String locationTitle = locationLinkString;
      for (String locationItem in locationItems) {
        if (locationItem.isNotEmpty) {
          locationTitle = locationItem;
          break;
        }
      }
      contentLinks.add({ "text": locationLinkString, "icon": "https://rokwire-images.s3.us-east-2.amazonaws.com/guide/icon-link-location.webp", "location": { "location": { "latitude": 0.00, "longitude": 0.00}, "title": locationTitle } });

    }
    
    if (contentLinks.isNotEmpty) {
      contentEntry['links'] = contentLinks;
    }

    // Buttons
    String buttonText = AppJson.stringValue(sourceEntry['button_text']);
    String buttonUrl = AppJson.stringValue(sourceEntry['button_link']);
    if ((buttonText != null) && (0 < buttonText.length) || (buttonUrl != null) && (0 < buttonUrl.length)) {
      contentEntry['buttons'] = [{ "text": buttonText, "url": buttonUrl }];
    }

    // Sub Details
    List<dynamic> subDetails = <dynamic>[];
    for (int index = 1; index <= 5; index++) {
      
      Map<String, dynamic> subDetail = <String, dynamic>{};
      String sectionTitle = AppJson.stringValue(sourceEntry['sub_details_section${index}_title'])?.replaceAll('\n', '');
      if (sectionTitle != null) {
        subDetail['section'] = sectionTitle;
      }

      Map<String, dynamic> sectionEntry = <String, dynamic>{};
      
      String sectionHeading = AppJson.stringValue(sourceEntry['sub_details_section${index}_headings'])?.replaceAll('\n', '');
      if (sectionHeading != null) {
        sectionEntry['heading'] = sectionHeading;
      }

      List<dynamic> numbers = <dynamic>[];
      String sectionNumbersString = AppJson.stringValue(sourceEntry['sub_details_section${index}_numbers']);
      if (sectionNumbersString != null) {
        List<String> sectionNumers = sectionNumbersString.split(RegExp('[;\n]'));
        if (sectionNumers.length < 2) {
          sectionNumers = _splitByCommas(sectionNumbersString);
        }
        for (String sectionNumer in sectionNumers) {
          sectionNumer = sectionNumer.trim();
          if (sectionNumer.isNotEmpty) {
            numbers.add(sectionNumer);
          }
        }
      }
      if (numbers.isNotEmpty) {
        sectionEntry['numbers'] = numbers;
      }

      List<dynamic> bullets = <dynamic>[];
      String sectionBulletsString = AppJson.stringValue(sourceEntry['sub_details_section${index}_bullets']);
      if (sectionBulletsString != null) {
        List<String> sectionBullets = sectionBulletsString.split(RegExp('[;\n]'));
        if (sectionBullets.length < 2) {
          sectionBullets = _splitByCommas(sectionBulletsString);
        }
        for (String sectionBullet in sectionBullets) {
          sectionBullet = sectionBullet.trim();
          if (sectionBullet.isNotEmpty) {
            bullets.add(sectionBullet);
          }
        }
      }
      if (bullets.isNotEmpty) {
        sectionEntry['bullets'] = bullets;
      }

      if (sectionEntry.isNotEmpty) {
        subDetail['entries'] = [ sectionEntry ];
      }

      if (subDetail.isNotEmpty) {
        subDetails.add(subDetail);
      }
    }
    if (subDetails.isNotEmpty) {
      contentEntry['sub_details'] = subDetails;
    }

    // Related
    List<dynamic> relatedList = <dynamic>[];
    String relatedString = AppJson.stringValue(sourceEntry['related']);
    if (relatedString != null) {
      List<String> related = relatedString.split(RegExp('[;,\n ]'));
      for (String relatedEntry in related) {
        relatedEntry = relatedEntry.trim();
        if (relatedEntry.isNotEmpty) {
          relatedList.add(relatedEntry);
        }
      }
    }
    if (relatedList.isNotEmpty) {
      contentEntry['related'] = relatedList;
    }
    
    return contentEntry;
  }

  static List<String> _splitByCommas(String source) {
    List<String> result = <String>[];
    int pos, index = 0;
    while (0 <= (pos = source.indexOf(RegExp(r",[^ ]|,$"), index))) {
      result.add(source.substring(index, pos));
      index = pos + 1;
    }
    result.add(source.substring(index));
    return result;
  }*/

}

class GuideSection {
  final String name;
  final DateTime date;
  
  GuideSection({this.name, this.date});

  factory GuideSection.fromGuideEntry(Map<String, dynamic> guideEntry) {
    return (guideEntry != null) ? GuideSection(
        name: AppJson.stringValue(Guide().entryValue(guideEntry, 'section')),
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
        return date.compareTo(section.date);
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
        return name.compareTo(section.name);
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
  
  final String id;
  final String title;
  GuideFavorite({this.id, this.title});

  bool operator == (o) => o is GuideFavorite && o.id == id;

  int get hashCode => (id?.hashCode ?? 0);

  @override
  String get favoriteId => id;

  @override
  String get favoriteTitle => title;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "studentGuideIds";
}

GuideContentSource guideContentSourceFromString(String value) {
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

String guideContentSourceToString(GuideContentSource value) {
  switch (value) {
    case GuideContentSource.Net:   return 'Net';
    case GuideContentSource.Debug: return 'Debug';
  }
  return null;
}