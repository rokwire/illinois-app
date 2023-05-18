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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/WPGUFMRadio.dart';
import 'package:illinois/ui/settings/SettingsHomeContentPanel.dart';
import 'package:illinois/ui/settings/SettingsNotificationsContentPanel.dart';
import 'package:illinois/ui/settings/SettingsProfileContentPanel.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

class HeaderBar extends rokwire.HeaderBar {

  static const String defaultLeadingIconKey = 'chevron-left-white';

  HeaderBar({Key? key,
    SemanticsSortKey? sortKey,

    Widget? leadingWidget,
    String? leadingLabel,
    String? leadingHint,
    String? leadingIconKey = defaultLeadingIconKey,
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
    bool? centerTitle = false,

    List<Widget>? actions,
  }) : super(key: key,
    sortKey: sortKey,
    
    leadingWidget: leadingWidget,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingIconKey: leadingIconKey,
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

  static const String defaultLeadingIconKey = 'chevron-left-white';

  SliverToutHeaderBar({
    bool pinned = true,
    bool floating = false,
    double? expandedHeight = 200,
    Color? backgroundColor,

    Widget? flexWidget,
    String? flexImageUrl,
    String? flexImageKey,
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
    String? leadingIconKey = defaultLeadingIconKey,
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
  }) : super(
    pinned: pinned,
    floating: floating,
    expandedHeight: expandedHeight,
    backgroundColor: backgroundColor ?? Styles().colors?.fillColorPrimaryVariant,

    flexWidget: flexWidget,
    flexImageKey: flexImageKey,
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
    leadingIconKey: leadingIconKey,
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
  );

  @override
  void leadingHandler(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }
}

// SliverSheetHeaderBar

class SliverHeaderBar extends rokwire.SliverHeaderBar  {
  static const String defaultLeadingIconKey = 'close-circle-white';

  SliverHeaderBar({Key? key,
    bool pinned = true,
    bool floating = false,
    double? elevation = 0,
    Color? backgroundColor,

    Widget? leadingWidget,
    String? leadingLabel,
    String? leadingHint,
    String? leadingIconKey = defaultLeadingIconKey,
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

    List<Widget>? actions,
  }) : super(key: key,
    
    pinned: pinned,
    floating: floating,
    elevation: elevation,
    backgroundColor: backgroundColor ?? Styles().colors?.fillColorPrimaryVariant,

    leadingWidget: leadingWidget,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingIconKey: leadingIconKey,
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
        centerTitle: false,
        actions: actions,
      );
}*/

enum RootHeaderBarLeading { Home, Back }

class RootHeaderBar extends StatefulWidget implements PreferredSizeWidget {

  final String? title;
  final RootHeaderBarLeading leading;
  final void Function()? onSettings;

  RootHeaderBar({Key? key, this.title, this.leading = RootHeaderBarLeading.Home, this.onSettings}) : super(key: key);

  @override
  State<RootHeaderBar> createState() => _RootHeaderBarState();

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _RootHeaderBarState extends State<RootHeaderBar> implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      WPGUFMRadio.notifyPlayerStateChanged,
      Inbox.notifyInboxUnreadMessagesCountChanged,
      Auth2.notifyPictureChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == WPGUFMRadio.notifyPlayerStateChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == Inbox.notifyInboxUnreadMessagesCountChanged) {
      if (mounted) {
        setState(() {});
      }
    }
    else if (name == Auth2.notifyPictureChanged) {
      if (mounted) {
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: Styles().colors?.fillColorPrimaryVariant,
    leading: _buildHeaderLeading(),
    title: _buildHeaderTitle(),
    actions: _buildHeaderActions(),
  );

  // Implamentation

  Widget _buildHeaderLeading() {
    switch(widget.leading)
    {
      case RootHeaderBarLeading.Home: return _buildHeaderHomeButton();
      case RootHeaderBarLeading.Back: return _buildHeaderBackButton();
    }
  }

  Widget _buildHeaderHomeButton() {
    return Semantics(label: Localization().getStringEx('headerbar.home.title', 'Home'), hint: Localization().getStringEx('headerbar.home.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images?.getImage('university-logo', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapHome(),),);
  }

  Widget _buildHeaderBackButton() {
    return Semantics(label: Localization().getStringEx('headerbar.back.title', 'Back'), hint: Localization().getStringEx('headerbar.back.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images?.getImage('chevron-left-white', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapBack()));
  }

  Widget _buildHeaderTitle() {
    return WPGUFMRadio().isPlaying ? Row(mainAxisSize: MainAxisSize.min, children: [
      _buildHeaderTitleText(),
      _buildHeaderRadioButton(),
    ],) : _buildHeaderTitleText();
  }

  Widget _buildHeaderTitleText() {
    return Semantics(label: widget.title, excludeSemantics: true, child:
      Text(widget.title ?? '', style: Styles().textStyles?.getTextStyle("widget.heading.regular.extra_fat"),),);
  }

  Widget _buildHeaderRadioButton() {
    return Semantics(label: Localization().getStringEx('headerbar.radio.title', 'WPGU 107.1 FM'), hint: Localization().getStringEx('headerbar.radio.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images?.getImage('radio-white', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapRadio(),),);
  }

  List<Widget> _buildHeaderActions() {
    return <Widget>[
      _buildHeaderPersonalInfoButton(),
      _buildHeaderNotificationsButton(),
      _buildHeaderSettingsButton()
    ];
  }

  Widget _buildHeaderSettingsButton() {
    return Semantics(label: Localization().getStringEx('headerbar.settings.title', 'Settings'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Styles().images?.getImage('images/settings-white.png', excludeFromSemantics: true) ?? Container(), onPressed: () => onTapSettings())
      InkWell(onTap: () => _onTapSettings(), child:
        Padding(padding: EdgeInsets.only(top: 16, bottom: 16, right: 16, left: 6), child:
          Styles().images?.getImage('settings-white', excludeFromSemantics: true),
        )
      )
    );
  }

  Widget _buildHeaderNotificationsButton() {
    int unreadMsgsCount = Inbox().unreadMessagesCount;
    return Semantics(label: Localization().getStringEx('headerbar.notifications.title', 'Notifications'), hint: Localization().getStringEx('headerbar.notifications.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Styles().images?.getImage('images/notifications-white.png', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapNotifications())
      InkWell(onTap: () => _onTapNotifications(), child:
        Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 2), child:
          Stack(alignment: Alignment.topRight, children: [
            Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Styles().images?.getImage('notification-white', excludeFromSemantics: true,))),
            Opacity(opacity: (unreadMsgsCount > 0) ? 1 : 0, child:
              Align(alignment: Alignment.topRight, child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red), child:
                Text(unreadMsgsCount.toString(), style: Styles().textStyles?.getTextStyle("widget.title.light.tiny")))))
          ])
        )
      )
    );
  }

  Widget _buildHeaderPersonalInfoButton() {
    return Semantics(label: Localization().getStringEx('headerbar.personal_information.title', 'Personal Information'), hint: Localization().getStringEx('headerbar.personal_information.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Styles().images?.getImage('images/person-white.png', excludeFromSemantics: true), onPressed: () => onTapPersonalInformations())
      InkWell(onTap: () => _onTapPersonalInformation(), child:
        CollectionUtils.isNotEmpty(Auth2().authPicture) ?
          Padding(padding: EdgeInsets.symmetric(vertical: 15, horizontal: 5), child:
            Container(width: 20, height: 20, decoration:
              BoxDecoration(shape: BoxShape.circle, color: Colors.white, image:
                DecorationImage( fit: BoxFit.cover, image: Image.memory(Auth2().authPicture!).image)
              )
            )
          ) :
          Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 6), child:
            Styles().images?.getImage('person-circle-white', excludeFromSemantics: true),
          ),
      )
    );
  }

  void _onTapHome() {
    Analytics().logSelect(target: "Home");
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onTapBack() {
    Analytics().logSelect(target: 'Back');
    Navigator.of(context).pop();
  }

  void _onTapRadio() {
    Analytics().logSelect(target: "WPGU FM Radio");
    WPGUFMRadio().pause();
  }

  void _onTapSettings() {
    Analytics().logSelect(target: "Settings");
    if (widget.onSettings != null) {
      widget.onSettings!();
    }
    else {
      SettingsHomeContentPanel.present(context);
    }
  }

  void _onTapNotifications() {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != SettingsNotificationsContentPanel.routeName) {
      Analytics().logSelect(target: "Notifications");
      SettingsNotificationsContentPanel.present(context,
          content: (Inbox().unreadMessagesCount > 0) ? SettingsNotificationsContent.unread : SettingsNotificationsContent.all);
    }
  }

  void _onTapPersonalInformation() {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != SettingsProfileContentPanel.routeName) {
      Analytics().logSelect(target: "Personal Information");
      SettingsProfileContentPanel.present(context);
    }
  }
}

