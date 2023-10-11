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

import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/Guide.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/guide/GuideDetailPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

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
        return AlertDialog(content: contentWidget, actions: actions,contentPadding: contentPadding,);
      },
    );
    return alertDismissed;
  }

  static Future<bool?> showOfflineMessage(BuildContext context, String? message) async {
    return showDialog(context: context, builder: (context) {
      return AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(Localization().getStringEx("common.message.offline", "You appear to be offline"), style: Styles().textStyles?.getTextStyle("widget.dialog.message.dark.medium")),
          Container(height:16),
          Text(message!, textAlign: TextAlign.center,),
        ],),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx("dialog.ok.title", "OK")),
              onPressed: (){
                Analytics().logAlert(text: message, selection: "OK");
                  Navigator.pop(context, true);
              }
          ) //return dismissed 'true'
        ],
      );
    },);
  }

  static Future<void> showMessage(BuildContext context, String? message) async {
    return showDialog(context: context, builder: (context) {
      return AlertDialog(
        content: Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
          Text(message!, textAlign: TextAlign.center,),
        ],),
        actions: <Widget>[
          TextButton(
              child: Text(Localization().getStringEx("dialog.ok.title", "OK")),
              onPressed: (){
                Analytics().logAlert(text: message, selection: "OK");
                  Navigator.pop(context);
              }
          ) //return dismissed 'true'
        ],
      );
    },);
  }

  static Future<void> showPopup(BuildContext context, String? message) async {
    return showDialog(context: context, builder: (context) {
      return AlertDialog(contentPadding: EdgeInsets.zero, content:
        Container(decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(10.0)), child:
          Stack(alignment: Alignment.center, children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32), child:
              Column(mainAxisSize: MainAxisSize.min, children: [
                Styles().images?.getImage('university-logo', excludeFromSemantics: true) ?? Container(),
                Padding(padding: EdgeInsets.only(top: 18), child:
                  Text(message ?? '', textAlign: TextAlign.left, style: Styles().textStyles?.getTextStyle("widget.detail.small"))
                ),
              ])
            ),
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                InkWell(onTap: () {
                  Analytics().logAlert(text: message, selection: 'Close');
                  Navigator.of(context).pop();
                  }, child:
                  Padding(padding: EdgeInsets.all(16), child:
                    Styles().images?.getImage('close', excludeFromSemantics: true)
                  )
                )
              )
            ),
          ])
      )
      );
    },);
  }

  static Future<bool> showConfirmationDialog(
      {required BuildContext buildContext,
      required String message,
      String? positiveButtonLabel,
      VoidCallback? positiveCallback,
      VoidCallback? negativeCallback,
      String? negativeButtonLabel}) async {
    bool alertDismissed = await showDialog(
        context: buildContext,
        builder: (context) {
          return AlertDialog(content: Text(message), actions: <Widget>[
            TextButton(
                child: Text(
                    StringUtils.ensureNotEmpty(positiveButtonLabel, defaultValue: Localization().getStringEx('dialog.yes.title', 'Yes'))),
                onPressed: () {
                  Analytics().logAlert(text: message, selection: 'Yes');
                  Navigator.pop(context, true);
                  if (positiveCallback != null) {
                    positiveCallback();
                  }
                }),
            TextButton(
                child: Text(
                    StringUtils.ensureNotEmpty(negativeButtonLabel, defaultValue: Localization().getStringEx('dialog.no.title', 'No'))),
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

    static void announceMessage(BuildContext? context, String message){
        if(context != null){
          context.findRenderObject()!.sendSemanticsEvent(AnnounceSemanticsEvent(message,TextDirection.ltr));
        }
    }

    static void requestSemanticsUpdates(BuildContext? context){
      if(context != null){
        context.findRenderObject()?.markNeedsSemanticsUpdate();
        // context.findRenderObject()?.sendSemanticsEvent(semanticsEvent);
      }
    }


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
    //                         color : Styles().colors!.fillColorPrimary,
    //                         fontFamily: Styles().fontFamilies!.bold,
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
    //                         color : Styles().colors!.fillColorPrimary,
    //                         fontFamily: Styles().fontFamilies!.bold,
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
          return launchUrl(privacyPolicyUri, mode: LaunchMode.externalApplication);
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

class AppPopScope {
  static Future<bool> back(Function? fn) {
    fn?.call();
    return Future.value(false);
  }
}

extension StateExt on State {
  @protected
  void setStateIfMounted(VoidCallback fn) {
    if (mounted) {
      // ignore: invalid_use_of_protected_member
      setState(fn);
    }
  }

  @protected
  void setStateDelayedIfMounted(VoidCallback fn, { Duration duration = Duration.zero }) {
    Future.delayed(duration, () {
      if (mounted) {
        // ignore: invalid_use_of_protected_member
        setState(fn);
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