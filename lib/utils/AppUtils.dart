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

import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:universal_io/io.dart';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/tracking_services.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:universal_html/html.dart' as html;
import 'package:url_launcher/url_launcher.dart' as launcher_plugin;

class AppAlert {
  
  static Future<bool?> showDialogResult(BuildContext context, String? message, { String? buttonTitle, Function? onConfirm}) async {
    return await showDialog(
      context: context,
      builder: (BuildContext context) {
        String displayButtonTitle = buttonTitle ?? Localization().getStringEx("dialog.ok.title", "OK");
        return AlertDialog(
          content: Text(message ?? ''),
          actions: <Widget>[
            TextButton(
                child: Text(displayButtonTitle),
                onPressed: () {
                  Analytics().logAlert(text: message, selection: displayButtonTitle);
                  Navigator.pop(context, true);
                  onConfirm?.call();
                }
            ) //return dismissed 'true'
          ],
        );
      },
    );
  }

  static Future<bool?> showCustomDialog(
    {required BuildContext context, Widget? contentWidget, List<Widget>? actions, EdgeInsets contentPadding = const EdgeInsets.all(18), }) async {
    bool? alertDismissed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(content: (contentWidget != null ? PointerInterceptor(child: contentWidget) : contentWidget), actions: actions, contentPadding: contentPadding,);
      },
    );
    return alertDismissed;
  }

  static Future<void> showLoggedOutFeatureNAMessage(BuildContext context, String featureName, { bool verbose = true }) async =>
    showTextMessage(context, AppTextUtils.loggedOutFeatureNA(featureName, verbose: verbose));

  static Future<void> showOfflineMessage(BuildContext context, String? message) async =>
    showTextMessage(context, Localization().getStringEx("common.message.offline", "You appear to be offline"));

  static Future<void> showTextMessage(BuildContext context, String? message) =>
    showWidgetMessage(context, Text(message!, textAlign: TextAlign.center,), analyticsMessage: message);

  static Future<void> showAuthenticationNAMessage(BuildContext context) async {
    final String linkSettingsMacro = "{{link.settings}}";
    return showLinkedTextMessage(context,
      message: Localization().getStringEx('common.message.login.not_available', 'To sign in, $linkSettingsMacro to 4 or 5 under Settings'),
      linkMacro: linkSettingsMacro,
      linkText: Localization().getStringEx('common.message.login.not_available.link.settings', 'set your privacy level'),
      linkAction: () { Navigator.pop(context); SettingsHomeContentPanel.present(context, content: SettingsContent.privacy); },
    );
  }

  static Future<void> showLinkedTextMessage(BuildContext context, { required String message, required String linkMacro, required String linkText, void Function()? linkAction }) async {
    List<InlineSpan> spanList = <InlineSpan>[];
    GestureRecognizer linkGestureRecognizer = TapGestureRecognizer()..onTap = linkAction;
    List<String> messages = message.split(linkMacro);
    if (0 < messages.length) {
      spanList.add(TextSpan(text: messages.first));
    }
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: linkText, recognizer: linkGestureRecognizer, style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),));
      spanList.add(TextSpan(text: messages[index]));
    }

    await showWidgetMessage(context,
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.regular"), children: spanList)
      ),
      buttonTextStyle: Styles().textStyles.getTextStyle("widget.message.regular"),
      analyticsMessage: message.replaceAll(linkMacro, linkText)
    );
    linkGestureRecognizer.dispose();
  }

  static Future<void> showWidgetMessage(BuildContext context, Widget messageWidget, { TextStyle? buttonTextStyle, String? analyticsMessage }) =>
    showDialog(context: context, builder: (context) {
      return AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          messageWidget,
        ],),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx("dialog.ok.title", "OK"), style: buttonTextStyle,),
              onPressed: () {
                Analytics().logAlert(text: analyticsMessage, selection: "OK");
                Navigator.pop(context);
              }
          ) //return dismissed 'true'
        ],
      );
    },);

  static Future<bool> showConfirmationDialog(BuildContext context, {
      required String message,
      String? positiveButtonLabel,
      VoidCallback? positiveCallback,
      String? negativeButtonLabel,
      VoidCallback? negativeCallback,
  }) async {
    bool alertDismissed = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(content: Text(message), actions: <Widget>[
            TextButton(
            child: Text(StringUtils.ensureNotEmpty(positiveButtonLabel, defaultValue: Localization().getStringEx('dialog.yes.title', 'Yes'))),
            onPressed: () {
              Analytics().logAlert(text: message, selection: 'Yes');
              Navigator.pop(context, true);
              if (positiveCallback != null) {
                positiveCallback();
              }
            }),
            TextButton(
              child: Text(StringUtils.ensureNotEmpty(negativeButtonLabel, defaultValue: Localization().getStringEx('dialog.no.title', 'No'))),
              onPressed: () {
                Analytics().logAlert(text: message, selection: 'No');
                Navigator.pop(context, false);
                if (negativeCallback != null) {
                  negativeCallback();
                }
              })
          ]);
        });
    return alertDismissed;
  }
}

class AppSemantics {
    static void announceCheckBoxStateChange(BuildContext? context, bool checked, String? name){
      String message = (StringUtils.isNotEmpty(name)?name!+", " :"")+
          (checked ?
            Localization().getStringEx("toggle_button.status.checked", "checked",) :
            Localization().getStringEx("toggle_button.status.unchecked", "unchecked")); // !toggled because we announce before it got changed
      announceMessage(context, message);
    }

    static Semantics buildCheckBoxSemantics({Widget? child, String? title, bool selected = false, double? sortOrder}){
      return Semantics(label: title, button: true ,excludeSemantics: true, sortKey: sortOrder!=null?OrdinalSortKey(sortOrder) : null,
      value: (selected?Localization().getStringEx("toggle_button.status.checked", "checked",) :
      Localization().getStringEx("toggle_button.status.unchecked", "unchecked")) +
      ", "+ Localization().getStringEx("toggle_button.status.checkbox", "checkbox"),
      child: child );
    }

    static void requestSemanticsUpdates(BuildContext? context){
      if(context != null){
        context.findRenderObject()?.markNeedsSemanticsUpdate();
        // context.findRenderObject()?.sendSemanticsEvent(semanticsEvent);
      }
    }

    static bool isAccessibilityEnabled(BuildContext context) =>
        MediaQuery.of(context).accessibleNavigation;

    static void announceMessage(BuildContext? context, String message) =>
        context?.findRenderObject()?.
          sendSemanticsEvent(
            AnnounceSemanticsEvent(message,TextDirection.ltr));

    static void triggerAccessibilityTap(GlobalKey? groupKey) =>
        groupKey?.currentContext?.findRenderObject()?.
          sendSemanticsEvent(
            TapSemanticEvent());

    static void triggerAccessibilityFocus(GlobalKey? groupKey) =>
      groupKey?.currentContext?.findRenderObject()?.
        sendSemanticsEvent(
          FocusSemanticEvent());

    static SemanticsNode? extractSemanticsNote(GlobalKey? groupKey) =>
        groupKey?.currentContext?.findRenderObject()?.debugSemantics;

    static String getIosHintLongPress(String? hint) => Platform.isIOS ? "Double tap and hold to  $hint" : "";

    static String getIosHintDrag(String? hint) => Platform.isIOS ? "Double tap hold move to  $hint" : "";
// final SemanticsNode? semanticsNode = renderObject.debugSemantics;
// final SemanticsOwner? owner = renderObject.owner!.semanticsOwner;
// Send a SemanticsActionEvent with the tap action
// AppToast.showMessage("owner =   ${owner}");
// owner?.performAction(
//   semanticsNode?.id ?? -1,
//   SemanticsAction.didGainAccessibilityFocus,
// );

    //These navigation buttons are designed to improve the Accessibility support for horizontal scroll elements
    // static Widget createPageViewNavigationButtons({Function? onTapPrevious, Function? onTapNext}){
    //   return Row(
    //     mainAxisSize: MainAxisSize.max,
    //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
    //     children: [
    //       Visibility(
    //           visible: onTapPrevious != null,
    //           child: Semantics(
    //               // enabled: prevEnabled,
    //               label: "Previous Page",
    //               button: true,
    //               child: GestureDetector(
    //                   onTap: (){if(onTapPrevious!= null) onTapPrevious();},
    //                   child: Container(
    //                     padding: EdgeInsets.all(24),
    //                     child: Text(
    //                       "<",
    //                       semanticsLabel: "",
    //                       style: TextStyle(
    //                         color : Styles().colors.fillColorPrimary,
    //                         fontFamily: Styles().fontFamilies.bold,
    //                         fontSize: 26,
    //                       ),),)
    //               )
    //           )
    //       ),
    //       Visibility(
    //           visible: onTapNext != null,
    //           child: Semantics(
    //               label: "Next Page",
    //               button: true,
    //               child: GestureDetector(
    //                   onTap: (){if(onTapNext!= null) onTapNext();},
    //                   child: Container(
    //                     padding: EdgeInsets.all(24),
    //                     child: Text(
    //                       ">",
    //                       semanticsLabel: "",
    //                       style: TextStyle(
    //                         color : Styles().colors.fillColorPrimary,
    //                         fontFamily: Styles().fontFamilies.bold,
    //                         fontSize: 26,
    //                       ),),)
    //               )
    //           )
    //       )
    //     ],
    //   );
    // }
    //
    // static void _onTapNext(PageController? _pageController, {Function? onRefresh}){
    //   _pageController?.nextPage(duration: Duration(seconds: 1), curve: Curves.easeIn);
    //   if(onRefresh!=null){
    //     onRefresh();
    //   }
    // }
    //
    // static void _onTapPrevious(PageController? _pageController, {Function? onRefresh}){
    //   _pageController?.previousPage(duration: Duration(seconds: 1), curve: Curves.easeIn);
    //   if(onRefresh!=null){
    //     onRefresh();
    //   }
    // }
}

class AppDateTimeUtils {


  static String getDisplayDateTime(DateTime? dateTimeUtc, {bool? allDay = false, bool considerSettingsDisplayTime = true}) {
    String? timePrefix = getDisplayDay(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime, includeAtSuffix: true);
    String? timeSuffix = getDisplayTime(dateTimeUtc: dateTimeUtc, allDay: allDay, considerSettingsDisplayTime: considerSettingsDisplayTime);
    return '$timePrefix $timeSuffix';
  }

  static String? getDisplayDay({DateTime? dateTimeUtc, bool? allDay = false, bool considerSettingsDisplayTime = true, bool includeAtSuffix = false}) {
    String? displayDay = '';
    if(dateTimeUtc != null) {
      DateTime dateTimeToCompare = _getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      DateTime nowDevice = DateTime.now();
      DateTime nowUtc = nowDevice.toUtc();
      DateTime? nowUniLocal = AppDateTime().getUniLocalTimeFromUtcTime(nowUtc);
      DateTime nowToCompare = AppDateTime().useDeviceLocalTimeZone ? nowDevice : nowUniLocal!;
      int calendarDaysDiff = dateTimeToCompare.day - nowToCompare.day;
      int timeDaysDiff = dateTimeToCompare.difference(nowToCompare).inDays;
      if ((calendarDaysDiff != 0) && (calendarDaysDiff > timeDaysDiff)) {
        timeDaysDiff += 1;
      }
      if (timeDaysDiff == 0) {
        displayDay = Localization().getStringEx('model.explore.date_time.today', 'Today');
        if (!allDay! && includeAtSuffix) {
          displayDay = "$displayDay ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      }
      else if (timeDaysDiff == 1) {
        displayDay = Localization().getStringEx('model.explore.date_time.tomorrow', 'Tomorrow');
        if (!allDay! && includeAtSuffix) {
          displayDay = "$displayDay ${Localization().getStringEx('model.explore.date_time.at', 'at')}";
        }
      }
      else {
        displayDay = AppDateTime().formatDateTime(dateTimeToCompare, format: "MMM dd", ignoreTimeZone: true, showTzSuffix: false);
      }
    }
    return displayDay;
  }

  static String? getDisplayTime({DateTime? dateTimeUtc, bool? allDay = false, bool considerSettingsDisplayTime = true}) {
    String? timeToString = '';
    if (dateTimeUtc != null && !allDay!) {
      DateTime dateTimeToCompare = _getDateTimeToCompare(dateTimeUtc: dateTimeUtc, considerSettingsDisplayTime: considerSettingsDisplayTime)!;
      String format = (dateTimeToCompare.minute == 0) ? 'ha' : 'h:mma';
      timeToString = AppDateTime().formatDateTime(dateTimeToCompare, format: format, ignoreTimeZone: true, showTzSuffix: !AppDateTime().useDeviceLocalTimeZone)?.toLowerCase();
    }
    return timeToString;
  }

  static DateTime? _getDateTimeToCompare({DateTime? dateTimeUtc, bool considerSettingsDisplayTime = true}) {
    if (dateTimeUtc == null) {
      return null;
    }
    DateTime? dateTimeToCompare;
    //workaround for receiving incorrect date times from server for games: http://fightingillini.com/services/schedule_xml_2.aspx
    if (AppDateTime().useDeviceLocalTimeZone && considerSettingsDisplayTime) {
      dateTimeToCompare = AppDateTime().getDeviceTimeFromUtcTime(dateTimeUtc);
    } else {
      dateTimeToCompare = AppDateTime().getUniLocalTimeFromUtcTime(dateTimeUtc);
    }
    return dateTimeToCompare;
  }

  static String getDayPartGreeting({DayPart? dayPart}) {
    dayPart ??= DateTimeUtils.getDayPart();
    switch(dayPart) {
      case DayPart.morning: return Localization().getStringEx("logic.date_time.greeting.morning", "Good morning");
      case DayPart.afternoon: return Localization().getStringEx("logic.date_time.greeting.afternoon", "Good afternoon");
      case DayPart.evening: return Localization().getStringEx("logic.date_time.greeting.evening", "Good evening");
      case DayPart.night: return Localization().getStringEx("logic.date_time.greeting.night", "Good night");
    }
  }

  static String timeAgoSinceDate(DateTime date, {bool numericDates = true}) {
    final date2 = DateTime.now();
    final difference = date2.difference(date);

    if (difference.inDays >= 2) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays >= 1) {
      return (numericDates) ? '1 day ago' : 'Yesterday';
    } else if (difference.inHours >= 2) {
      return '${difference.inHours} hours ago';
    } else if (difference.inHours >= 1) {
      return (numericDates) ? '1 hour ago' : 'An hour ago';
    } else if (difference.inMinutes >= 2) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inMinutes >= 1) {
      return (numericDates) ? '1 minute ago' : 'A minute ago';
    } else if (difference.inSeconds >= 3) {
      return '${difference.inSeconds} seconds ago';
    } else {
      return 'Just now';
    }
  }
}

class AppPrivacyPolicy {

  static Future<bool> launch(BuildContext context) async {
    if ((Config().privacyPolicyUrl != null) && await UrlUtils.isHostAvailable(Config().privacyPolicyUrl)) {
      if (Platform.isIOS) {
        Uri? privacyPolicyUri = Uri.tryParse(Config().privacyPolicyUrl!);
        if (privacyPolicyUri != null) {
          return launcher_plugin.launchUrl(privacyPolicyUri, mode: launcher_plugin.LaunchMode.externalApplication);
        }
        else {
          return false;
        }
      }
      else {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: Config().privacyPolicyUrl, showTabBar: false, title: Localization().getStringEx("panel.onboarding2.panel.privacy_notice.heading.title", "Privacy notice"),)));
        return true;
      }
    }
    else {
      Map<String, dynamic>? privacyPolicyGuideEntry = Guide().entryById(Config().privacyPolicyGuideId) ?? JsonUtils.decodeMap(await AppBundle.loadString('assets/privacy.notice.json'));
      if (privacyPolicyGuideEntry != null) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailPanel(guideEntry: privacyPolicyGuideEntry, showTabBar: false,)));
        return true;
      }
      else {
        return false;
      }
    }
  }
}

extension StateExt on State {
  @protected
  void setStateIfMounted([VoidCallback? fn]) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn ?? (){});
    }
  }

  @protected
  void setStateDelayedIfMounted(VoidCallback? fn, { Duration duration = Duration.zero }) {
    Future.delayed(duration, () {
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        setState(fn ?? (){});
      }
    });
  }

  @protected
  void applyStateIfMounted(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
    else {
      fn();
    }
  }

  @protected
  void applyStateDelayedIfMounted(VoidCallback fn, { Duration duration = Duration.zero }) {
    Future.delayed(duration, () {
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        setState(fn);
      }
      else {
        fn();
      }
    });
  }
}

class AppTextUtils {

  // App Title

  static const String appTitleMacro = "{{app_title}}";

  static String get appTitle => appTitleEx();
  static String appTitleEx({String? language}) =>
    Localization().getStringEx('app.title', 'Illinois', language: language);

  static String appTitleString(String key, String defaults, {String? language}) =>
    Localization().getStringEx(key, defaults, language: language).replaceAll(appTitleMacro, appTitleEx(language: language));

  // University Name

  static const String universityNameMacro = "{{university_name}}";
  static String get universityName => universityNameEx();
  static String universityNameEx({String? language}) =>
    Localization().getStringEx('app.univerity_name', 'University of Illinois', language: language);

  static String appUniversityNameString(String key, String defaults, {String? language}) =>
    Localization().getStringEx(key, defaults, language: language).replaceAll(universityNameMacro, universityNameEx(language: language));

  // University Long Name

  static const String universityLongNameMacro = "{{university_long_name}}";
  static String get universityLongName => universityLongNameEx();
  static String universityLongNameEx({String? language}) =>
    Localization().getStringEx('app.univerity_long_name', 'University of Illinois Urbana-Champaign', language: language);

  static String appUniversityLongNameString(String key, String defaults, {String? language}) =>
    Localization().getStringEx(key, defaults, language: language).replaceAll(universityLongNameMacro, universityLongNameEx(language: language));

  // App Title / University (Long) Name

  static String appBrandString(String key, String defaults, {String? language}) =>
    Localization().getStringEx(key, defaults, language: language)
      .replaceAll(appTitleMacro, appTitleEx(language: language))
      .replaceAll(universityNameMacro, universityNameEx(language: language))
      .replaceAll(universityLongNameMacro, universityLongNameEx(language: language));

  // Logged Out Feature NA

  static const String featureMacro = '{{feature}}';

  static loggedOutFeatureNA(String featureName, { bool verbose = false }) {
    String message = verbose ?
      Localization().getStringEx('auth.logged_out.feature.not_available.message.verbose', 'To access {{feature}}, you need to sign in with your NetID and set your privacy level to 4 or 5 under Profile.') :
      Localization().getStringEx('auth.logged_out.feature.not_available.message.short', 'To access {{feature}}, you need to sign in with your NetID.');
    return message.replaceAll(featureMacro, featureName);
  }
}

class AppLaunchUrl {
  static Future<void> launch({required BuildContext context, String? url, Uri? uri, bool tryInternal = true, String? title,
      String? analyticsName, Map<String, dynamic>? analyticsSource, AnalyticsFeature? analyticsFeature, bool showTabBar = true}) async {
    if (uri == null) {
      uri = UriExt.tryParse(url);
    }
    uri = uri?.fix() ?? uri;

    if (uri != null) {
      if (tryInternal && uri.isWebScheme && await TrackingServices.isAllowed()) {
        Navigator.push(context, CupertinoPageRoute( builder: (context) => WebPanel(
            uri: uri,
            title: title,
            analyticsName: analyticsName,
            analyticsSource: analyticsSource,
            analyticsFeature: analyticsFeature,
            showTabBar: showTabBar
        )));
      } else {
        launcher_plugin.launchUrl(uri, mode: Platform.isAndroid ? launcher_plugin.LaunchMode.externalApplication : launcher_plugin.LaunchMode.platformDefault);
      }
    }
  }
}

class AppWebUtils {
  static final double screenWidth = 1092;
}

class AppFile {
  ///
  /// returns fileName if succeeded and null - otherwise
  ///
  static String? downloadFile({required Uint8List fileBytes, required String fileName}) {
    if (!kIsWeb) {
      return null;
    }

    // prepare
    final blob = html.Blob([fileBytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = fileName;
    html.document.body?.children.add(anchor);

    // download
    anchor.click();

    // cleanup
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    return fileName;
  }

  static Future<void> exportCsv({required List<List<dynamic>> rows, required String fileName, String? fieldDelimiter}) async {
    String csvContent = const ListToCsvConverter().convert(rows, fieldDelimiter: fieldDelimiter);
    final fileBytesContent = utf8.encode(csvContent);
    await downloadFile(fileBytes: fileBytesContent, fileName: fileName);
  }
}