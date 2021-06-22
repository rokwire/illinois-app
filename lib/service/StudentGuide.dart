import 'dart:collection';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/model/UserData.dart';
import 'package:illinois/service/AppLivecycle.dart';
import 'package:illinois/service/Auth.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Network.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Service.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/User.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

enum StudentGuideContentSource { Net, Debug }

class StudentGuide with Service implements NotificationsListener {

  static const String notifyChanged  = "edu.illinois.rokwire.student.guide.changed";

  static const String _cacheFileName = "student.guide.json";

  List<dynamic> _contentList;
  LinkedHashMap<String, Map<String, dynamic>> _contentMap;
  StudentGuideContentSource _contentSource;

  File          _cacheFile;
  DateTime      _pausedDateTime;

  static final StudentGuide _service = StudentGuide._internal();
  StudentGuide._internal();

  factory StudentGuide() {
    return _service;
  }

  // Service

  @override
  void createService() {
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
    ]);
  }

  @override
  void destroyService() {
    NotificationService().unsubscribe(this);
  }

  @override
  Future<void> initService() async {
    _cacheFile = await _getCacheFile();
    _contentList = await _loadContentJsonFromCache();
    _contentSource = studentGuideContentSourceFromString(Storage().studentGuideContentSource);
    if (_contentList != null) {
      _contentMap = _buildContentMap(_contentList);
      _updateContentFromNet();
    }
    else {
      String contentString = await _loadContentStringFromNet();
      _contentList = AppJson.decodeList(contentString);
      if (_contentList != null) {
        _contentMap = _buildContentMap(_contentList);
        _contentSource = StudentGuideContentSource.Net;
        Storage().studentGuideContentSource = studentGuideContentSourceToString(_contentSource);
        _saveContentStringToCache(contentString);
      }
    }
  }

  @override
  Set<Service> get serviceDependsOn {
    return Set.from([Storage(), Config()]);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
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
      Response response = await Network().get("${Config().contentUrl}/student_guides", auth: NetworkAuth.App);
      return ((response != null) && (response.statusCode == 200)) ? response.body : null;
    }
    catch (e) { print(e.toString()); }
    return null;
  }

  Future<void> _updateContentFromNet() async {
    if ((_contentSource == null) || (_contentSource == StudentGuideContentSource.Net)) {
      String contentString = await _loadContentStringFromNet();
      List<dynamic> contentList = AppJson.decodeList(contentString);
      if ((contentList != null) && !DeepCollectionEquality().equals(_contentList, contentList)) {
        _contentList = contentList;
        _contentMap = _buildContentMap(_contentList);
        _contentSource = StudentGuideContentSource.Net;
        Storage().studentGuideContentSource = studentGuideContentSourceToString(_contentSource);
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

  StudentGuideContentSource get contentSource {
    return _contentSource;
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

  List<dynamic> get promotedList {
    if (_contentList != null) {
      List<dynamic> promotedList = <dynamic>[];
      for (dynamic entry in _contentList) {
        if (_isEntryPromoted(AppJson.mapValue(entry))) {
          promotedList.add(entry);
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
      return (userRole != null) ? (User().roles?.contains(userRole) ?? false) : null;
    }) : true; 
  }

  static bool _checkPromotionCard(Map<String, dynamic> promotion) {
    Map<String, dynamic> card = (promotion != null) ? AppJson.mapValue(promotion['card']) : null;
    if (card != null) {
      dynamic cardRole = card['role'];
      if ((cardRole != null) && !AppBoolExpr.eval(cardRole, (String role) { return Auth().authCard?.role?.toLowerCase() == role?.toLowerCase(); })) {
        return false;
      }

      dynamic cardStudentLevel = card['student_level'];
      if ((cardStudentLevel != null) && !AppBoolExpr.eval(cardStudentLevel, (String studentLevel) { return Auth().authCard?.studentLevel?.toLowerCase() == studentLevel?.toLowerCase(); })) {
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
    StudentGuideContentSource contentSource;
    if (value != null) {
      contentString = value;
      contentSource = StudentGuideContentSource.Debug;
    }
    else {
      contentString = await _loadContentStringFromNet();
      contentSource = StudentGuideContentSource.Net;
    }

    contentList = AppJson.decodeList(contentString);
    if (contentList != null) {
      _contentSource = contentSource;
      Storage().studentGuideContentSource = studentGuideContentSourceToString(_contentSource);
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

  /*static Future<void> _convertFile(String contentFileName, String sourceFileName) async {
    Directory appDocDir = await getApplicationDocumentsDirectory();

    String sourceFilePath = join(appDocDir.path, sourceFileName);
    File sourceFile = File(sourceFilePath);
    String sourceString = await sourceFile.exists() ? await sourceFile.readAsString() : null;
    List<dynamic> sourceList = AppJson.decodeList(sourceString);
    
    List<dynamic> contentList = _convertContent(sourceList);
    String contentString = AppJson.encode(contentList, prettify: true);
    if (contentString != null) {
      String contentFilePath = join(appDocDir.path, contentFileName);
      File contentFile = File(contentFilePath);
      await contentFile.writeAsString(contentString, flush: true);
    }
  }

  static List<dynamic> convertContent(List<dynamic> sourceList) {
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
          contentLinks.add({ "text": phoneLink, "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-phone.png", "url": "tel:+1-$phoneLink" });
        }
      }
    }
    String emailLinksString = AppJson.stringValue(sourceEntry['email_links']);
    if (emailLinksString != null) {
      List<String> emailLinks = emailLinksString.split(RegExp('[;,\n ]'));
      for (String emailLink in emailLinks) {
        if (emailLink.isNotEmpty) {
          contentLinks.add({ "text": emailLink, "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-mail.png", "url": "mailto:$emailLink" });
        }
      }
    }
    String webLinksString = AppJson.stringValue(sourceEntry['web_links']);
    if (webLinksString != null) {
      List<String> webLinks = webLinksString.split(RegExp('[;,\n ]'));
      for (String webLink in webLinks) {
        if (webLink.isNotEmpty) {
          contentLinks.add({ "text": webLink, "icon": "https://rokwire-ios-beta.s3.us-east-2.amazonaws.com/Images/icon-web.png", "url": webLink });
        }
      }
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
      String sectionNumbersString = AppJson.stringValue(sourceEntry['sub_details_section${index}_numbers'])?.replaceAll('\n', '');
      if (sectionNumbersString != null) {
        List<String> sectionNumers = sectionNumbersString.split(RegExp('[;\n]'));
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
      String sectionBulletsString = AppJson.stringValue(sourceEntry['sub_details_section${index}_bullets'])?.replaceAll('\n', '');
      if (sectionBulletsString != null) {
        List<String> sectionBullets = sectionBulletsString.split(RegExp('[;\n]'));
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
  }*/

}

class StudentGuideFavorite implements Favorite {
  
  final String id;
  StudentGuideFavorite({this.id});

  bool operator == (o) => o is StudentGuideFavorite && o.id == id;

  int get hashCode => (id?.hashCode ?? 0);

  @override
  String get favoriteId => id;

  @override
  String get favoriteKey => favoriteKeyName;

  static String favoriteKeyName = "studentGuideIds";
}

StudentGuideContentSource studentGuideContentSourceFromString(String value) {
  if (value == 'Net') {
    return StudentGuideContentSource.Net;
  }
  else if (value == 'Debug') {
    return StudentGuideContentSource.Debug;
  }
  else {
    return null;
  }
}

String studentGuideContentSourceToString(StudentGuideContentSource value) {
  switch (value) {
    case StudentGuideContentSource.Net:   return 'Net';
    case StudentGuideContentSource.Debug: return 'Debug';
  }
  return null;
}