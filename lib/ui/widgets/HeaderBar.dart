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

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/WPGUFMRadio.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/settings/SettingsProfileContentPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart' as rokwire;

class HeaderBar extends rokwire.HeaderBar {

  static const String defaultLeadingAsset = 'images/chevron-left-white.png';

  HeaderBar({Key? key,
    SemanticsSortKey? sortKey,

    Widget? leadingWidget,
    String? leadingLabel,
    String? leadingHint,
    String? leadingAsset = defaultLeadingAsset,
    void Function()? onLeading,
    
    Widget? titleWidget,
    String? title,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double? fontSize = 16.0,
    double? letterSpacing = 1.0,
    int? maxLines,
    TextAlign? textAlign,
    bool? centerTitle = true,

    List<Widget>? actions,
  }) : super(key: key,
    sortKey: sortKey,
    
    leadingWidget: leadingWidget,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingAsset: leadingAsset,
    onLeading: onLeading,

    titleWidget: titleWidget,
    title: title,
    textStyle: textStyle,
    textColor: textColor ?? Styles().colors?.white,
    fontFamily: fontFamily ?? Styles().fontFamilies?.extraBold,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    maxLines: maxLines,
    textAlign: textAlign,
    centerTitle: centerTitle,

    actions: actions,
  );

  @override
  void leadingHandler(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }
}

class SliverToutHeaderBar extends rokwire.SliverToutHeaderBar {

  static const String defaultLeadingAsset = 'images/chevron-left-white.png';

  SliverToutHeaderBar({
    bool pinned = true,
    bool floating = false,
    double? expandedHeight = 200,
    Color? backgroundColor,

    Widget? flexWidget,
    String? flexImageUrl,
    Color?  flexBackColor,
    Color?  flexRightToLeftTriangleColor,
    double? flexRightToLeftTriangleHeight = 30,
    Color?  flexLeftToRightTriangleColor,
    double? flexLeftToRightTriangleHeight = 53,

    Widget? leadingWidget,
    String? leadingLabel,
    String? leadingHint,
    EdgeInsetsGeometry? leadingPadding = const EdgeInsets.all(8),
    Size? leadingOvalSize = const Size(32, 32),
    Color? leadingOvalColor,
    String? leadingAsset = defaultLeadingAsset,
    void Function()? onLeading,
  }) : super(
    pinned: pinned,
    floating: floating,
    expandedHeight: expandedHeight,
    backgroundColor: backgroundColor ?? Styles().colors?.fillColorPrimaryVariant,

    flexWidget: flexWidget,
    flexImageUrl: flexImageUrl,
    flexBackColor: flexBackColor ?? Styles().colors?.background,
    flexRightToLeftTriangleColor: flexRightToLeftTriangleColor ?? Styles().colors?.background,
    flexRightToLeftTriangleHeight: flexRightToLeftTriangleHeight,
    flexLeftToRightTriangleColor: flexLeftToRightTriangleColor ?? Styles().colors?.fillColorSecondaryTransparent05,
    flexLeftToRightTriangleHeight: flexLeftToRightTriangleHeight,

    leadingWidget: leadingWidget,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingPadding: leadingPadding,
    leadingOvalSize: leadingOvalSize,
    leadingOvalColor: leadingOvalColor ?? Styles().colors?.fillColorPrimary,
    leadingAsset: leadingAsset,
    onLeading: onLeading,
  );

  @override
  void leadingHandler(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }
}

// SliverSheetHeaderBar

class SliverHeaderBar extends rokwire.SliverHeaderBar  {
  static const String defaultLeadingAsset = 'images/close-white.png';

  SliverHeaderBar({Key? key,
    bool pinned = true,
    bool floating = false,
    double? elevation = 0,
    Color? backgroundColor,

    Widget? leadingWidget,
    String? leadingLabel,
    String? leadingHint,
    String? leadingAsset = defaultLeadingAsset,
    void Function()? onLeading,
    
    Widget? titleWidget,
    String? title,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double? fontSize = 16.0,
    double? letterSpacing = 1.0,
    int? maxLines,
    TextAlign? textAlign,
    bool? centerTitle = true,

    List<Widget>? actions,
  }) : super(key: key,
    
    pinned: pinned,
    floating: floating,
    elevation: elevation,
    backgroundColor: backgroundColor ?? Styles().colors?.fillColorPrimaryVariant,

    leadingWidget: leadingWidget,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingAsset: leadingAsset,
    onLeading: onLeading,

    titleWidget: titleWidget,
    title: title,
    textStyle: textStyle,
    textColor: textColor ?? Styles().colors?.white,
    fontFamily: fontFamily ?? Styles().fontFamilies?.extraBold,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    maxLines: maxLines,
    textAlign: textAlign,
    centerTitle: centerTitle,

    actions: actions,
  );

  @override
  void leadingHandler(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }
}

/*class SliverHeaderBar extends SliverAppBar {
  final BuildContext context;
  final Widget? titleWidget;
  final bool backVisible;
  final Color? backgroundColor;
  final String backIconRes;
  final Function? onBackPressed;
  final List<Widget>? actions;

  SliverHeaderBar({required this.context, this.titleWidget, this.backVisible = true, this.onBackPressed, this.backgroundColor, this.backIconRes = 'images/chevron-left-white.png', this.actions}):
        super(
        pinned: true,
        floating: false,
        backgroundColor: backgroundColor ?? Styles().colors!.fillColorPrimaryVariant,
        elevation: 0,
        leading: Visibility(visible: backVisible, child: Semantics(
            label: Localization().getStringEx('headerbar.back.title', 'Back'),
            hint: Localization().getStringEx('headerbar.back.hint', ''),
            button: true,
            excludeSemantics: true,
            child: IconButton(
                icon: Image.asset(backIconRes, excludeFromSemantics: true),
                onPressed: (){
                    Analytics().logSelect(target: "Back");
                    if (onBackPressed != null) {
                      onBackPressed();
                    } else {
                      Navigator.pop(context);
                    }
                })),),
        title: titleWidget,
        centerTitle: true,
        actions: actions,
      );
}*/

class RootHeaderBar extends StatefulWidget implements PreferredSizeWidget {

  final String? title;

  RootHeaderBar({Key? key, this.title}) : super(key: key);

  @override
  State<RootHeaderBar> createState() => _RootHeaderBarState();

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  // Implamentation

  Widget buildHeaderHomeButton(BuildContext context) {
    return Semantics(label: Localization().getStringEx('headerbar.home.title', 'Home'), hint: Localization().getStringEx('headerbar.home.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/block-i-orange.png', excludeFromSemantics: true), onPressed: () => onTapHome(context),),);
  }

  Widget buildHeaderTitle(BuildContext context) {
    return WPGUFMRadio().isPlaying ? Row(mainAxisSize: MainAxisSize.min, children: [
      buildHeaderTitleText(context),
      buildHeaderRadioButton(context),
    ],) : buildHeaderTitleText(context);
  }

  Widget buildHeaderTitleText(BuildContext context) {
    return Semantics(label: title, excludeSemantics: true, child:
      Text(title ?? '', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),),);
  }

  Widget buildHeaderRadioButton(BuildContext context) {
    return Semantics(label: Localization().getStringEx('headerbar.radio.title', 'WPGU FM Radio'), hint: Localization().getStringEx('headerbar.radio.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/radio-white.png', excludeFromSemantics: true), onPressed: () => onTapRadio(context),),);
  }

  List<Widget> buildHeaderActions(BuildContext context) {
    return <Widget>[
      buildHeaderPersonalInfoButton(context),
      buildHeaderNotificationsButton(context),
      buildHeaderSettingsButton(context)
    ];
  }

  Widget buildHeaderSettingsButton(BuildContext context) {
    return Semantics(label: Localization().getStringEx('headerbar.settings.title', 'Settings'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Image.asset('images/settings-white.png', excludeFromSemantics: true), onPressed: () => onTapSettings(context))
      InkWell(onTap: () => onTapSettings(context), child:
        Padding(padding: EdgeInsets.only(top: 16, bottom: 16, right: 16, left: 6), child:
          Image.asset('images/settings-white.png', excludeFromSemantics: true,),
        )
      )
    );
  }

  Widget buildHeaderNotificationsButton(BuildContext context) {
    return Semantics(label: Localization().getStringEx('headerbar.notifications.title', 'Notifications'), hint: Localization().getStringEx('headerbar.notifications.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Image.asset('images/notifications-white.png', excludeFromSemantics: true), onPressed: () => onTapNotifications(context))
      InkWell(onTap: () => onTapNotifications(context), child:
        Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 6), child:
          Image.asset('images/notifications-white.png', excludeFromSemantics: true,),
        )
      )
    );
  }

  Widget buildHeaderPersonalInfoButton(BuildContext context) {
    return Semantics(label: Localization().getStringEx('headerbar.personal_information.title', 'Personal Information'), hint: Localization().getStringEx('headerbar.personal_information.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Image.asset('images/person-white.png', excludeFromSemantics: true), onPressed: () => onTapPersonalInformations(context))
      InkWell(onTap: () => onTapPersonalInformations(context), child:
        Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 6), child:
          Image.asset('images/person-white.png', excludeFromSemantics: true,),
        )
      )
    );
  }

  void onTapHome(BuildContext context) {
    Analytics().logSelect(target: "Home");
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void onTapRadio(BuildContext context) {
    Analytics().logSelect(target: "WPGU FM Radio");
    WPGUFMRadio().pause();
  }

  void onTapSettings(BuildContext context) {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != SettingsHomeContentPanel.routeName) {
      Analytics().logSelect(target: "Settings");
      SettingsHomeContentPanel.present(context);
    }
  }

  void onTapNotifications(BuildContext context) {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != SettingsNotificationsContentPanel.routeName) {
      Analytics().logSelect(target: "Notifications");
      SettingsNotificationsContentPanel.present(context, content: SettingsNotificationsContent.inbox);
    }
  }

  void onTapPersonalInformations(BuildContext context) {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != SettingsProfileContentPanel.routeName) {
      Analytics().logSelect(target: "Personal Information");
      SettingsProfileContentPanel.present(context);
    }
  }

}

class _RootHeaderBarState extends State<RootHeaderBar> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      WPGUFMRadio.notifyPlayerStateChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: Styles().colors?.fillColorPrimaryVariant,
    leading: widget.buildHeaderHomeButton(context),
    title: widget.buildHeaderTitle(context),
    actions: widget.buildHeaderActions(context),
  );

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == WPGUFMRadio.notifyPlayerStateChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }
}