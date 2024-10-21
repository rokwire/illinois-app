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
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/RadioPlayer.dart';
import 'package:neom/ui/messages/MessagesHomePanel.dart';
import 'package:neom/ui/settings/SettingsHomeContentPanel.dart';
import 'package:neom/ui/notifications/NotificationsHomePanel.dart';
import 'package:neom/ui/profile/ProfileHomePanel.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/header_bar.dart' as rokwire;
import 'package:rokwire_plugin/utils/utils.dart';

class HeaderBar extends rokwire.HeaderBar {

  static const String defaultLeadingIconKey = 'caret-left';

  HeaderBar({super.key,
    super.sortKey,

    Widget? leadingWidget,
    String? leadingLabel,
    String? leadingHint,
    String? leadingIconKey = defaultLeadingIconKey,
    double? leadingWidth,
    void Function()? onLeading,
    
    Widget? titleWidget,
    String? title,
    double? titleSpacing = 0,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double? fontSize = 16.0,
    double? letterSpacing = 1.0,
    int? maxLines,
    TextAlign? textAlign,
    bool? centerTitle = false,

    List<Widget>? actions,
  }) : super(
    
    leadingWidget: leadingWidget,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingIconKey: leadingIconKey,
    leadingWidth: leadingWidth,
    onLeading: onLeading,

    titleWidget: titleWidget,
    title: title,
    titleSpacing: titleSpacing,
    textStyle: textStyle,
    textColor: textColor ?? Styles().colors.surface,
    fontFamily: fontFamily ?? Styles().fontFamilies.extraBold,
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

  static const String defaultLeadingIconKey = 'caret-left';

  SliverToutHeaderBar({
    super.key,

    bool pinned = true,
    bool floating = false,
    double toolbarHeight = 9 * kToolbarHeight / 7,
    double? expandedHeight = kToolbarHeight * 4,
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
    double? leadingWidth,
    String? leadingLabel,
    String? leadingHint,
    EdgeInsetsGeometry leadingPadding = const EdgeInsets.all(8 + kToolbarHeight / 7),
    Size? leadingOvalSize = const Size(32, 32),
    Color? leadingOvalColor,
    String? leadingIconKey = defaultLeadingIconKey,
    void Function()? onLeading,

    Widget? titleWidget,
    String? title,
    double? titleSpacing = 0,
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
    toolbarHeight: toolbarHeight,
    expandedHeight: expandedHeight,
    backgroundColor: backgroundColor ?? Styles().colors.fillColorPrimaryVariant,

    flexWidget: flexWidget,
    flexImageKey: flexImageKey,
    flexImageUrl: flexImageUrl,
    flexBackColor: flexBackColor ?? Styles().colors.background,
    flexRightToLeftTriangleColor: flexRightToLeftTriangleColor ?? Styles().colors.background,
    flexRightToLeftTriangleHeight: flexRightToLeftTriangleHeight,
    flexLeftToRightTriangleColor: flexLeftToRightTriangleColor ?? Styles().colors.fillColorSecondary,
    flexLeftToRightTriangleHeight: flexLeftToRightTriangleHeight,

    leadingWidget: leadingWidget,
    leadingWidth: leadingWidth,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingPadding: leadingPadding,
    leadingOvalSize: leadingOvalSize,
    leadingOvalColor: leadingOvalColor ?? Styles().colors.fillColorPrimary,
    leadingIconKey: leadingIconKey,
    onLeading: onLeading,

    titleWidget: titleWidget,
    title: title,
    titleSpacing: titleSpacing,
    textStyle: textStyle,
    textColor: textColor ?? Styles().colors.surface,
    fontFamily: fontFamily ?? Styles().fontFamilies.extraBold,
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

  SliverHeaderBar({
    super.key,

    bool pinned = true,
    bool floating = false,
    double? elevation = 0,
    double toolbarHeight = kToolbarHeight,
    double? expandedHeight,
    Color? backgroundColor,

    Widget? leadingWidget,
    double? leadingWidth,
    String? leadingLabel,
    String? leadingHint,
    String? leadingIconKey = defaultLeadingIconKey,
    void Function()? onLeading,
    
    Widget? titleWidget,
    String? title,
    double? titleSpacing = 0,
    TextStyle? textStyle,
    Color? textColor,
    String? fontFamily,
    double? fontSize = 16.0,
    double? letterSpacing = 1.0,
    int? maxLines,
    TextAlign? textAlign,

    List<Widget>? actions,
    Widget? flexibleSpace,
    PreferredSizeWidget? bottom,
  }) : super(
    
    pinned: pinned,
    floating: floating,
    elevation: elevation,
    toolbarHeight: toolbarHeight,
    expandedHeight: expandedHeight,
    backgroundColor: backgroundColor ?? Styles().colors.fillColorPrimaryVariant,

    leadingWidget: leadingWidget,
    leadingWidth: leadingWidth,
    leadingLabel: leadingLabel ?? Localization().getStringEx('headerbar.back.title', 'Back'),
    leadingHint: leadingHint ?? Localization().getStringEx('headerbar.back.hint', ''),
    leadingIconKey: leadingIconKey,
    onLeading: onLeading,

    titleWidget: titleWidget,
    title: title,
    titleSpacing: titleSpacing,
    textStyle: textStyle,
    textColor: textColor ?? Styles().colors.surface,
    fontFamily: fontFamily ?? Styles().fontFamilies.extraBold,
    fontSize: fontSize,
    letterSpacing: letterSpacing,
    maxLines: maxLines,
    textAlign: textAlign,

    actions: actions,
    flexibleSpace: flexibleSpace,
    bottom: bottom,
  );

  @override
  void leadingHandler(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.pop(context);
  }
}

enum RootHeaderBarLeading { Home, Back }

class RootHeaderBar extends StatefulWidget implements PreferredSizeWidget {

  final String? title;
  final double? titleSpacing;
  final RootHeaderBarLeading leading;
  final void Function()? onSettings;

  RootHeaderBar({Key? key, this.title, this.titleSpacing = 0, this.leading = RootHeaderBarLeading.Home, this.onSettings}) : super(key: key);

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
      RadioPlayer.notifyPlayerStateChanged,
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
    if (name == RadioPlayer.notifyPlayerStateChanged) {
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
    backgroundColor: Styles().colors.fillColorPrimaryVariant,
    leading: _buildHeaderLeading(),
    titleSpacing: widget.titleSpacing,
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
      IconButton(icon: Styles().images.getImage('university-logo', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapHome(),),);
  }

  Widget _buildHeaderBackButton() {
    return Semantics(label: Localization().getStringEx('headerbar.back.title', 'Back'), hint: Localization().getStringEx('headerbar.back.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images.getImage('caret-left', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapBack()));
  }

  Widget _buildHeaderTitle() {
    return RadioPlayer().isPlaying ? Row(mainAxisSize: MainAxisSize.min, children: [
      _buildHeaderTitleText(),
      _buildHeaderRadioButton(),
    ],) : _buildHeaderTitleText();
  }

  Widget _buildHeaderTitleText() {
    return Semantics(label: widget.title, excludeSemantics: true, child:
      Text(widget.title ?? '', style: Styles().textStyles.getTextStyle("widget.heading.regular.fat.light"),),);
  }

  Widget _buildHeaderRadioButton() {
    return Semantics(label: Localization().getStringEx('headerbar.radio.title', 'WPGU 107.1 FM'), hint: Localization().getStringEx('headerbar.radio.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images.getImage('radio-white', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapRadio(),),);
  }

  List<Widget> _buildHeaderActions() {
    return <Widget>[
      _buildHeaderPersonalInfoButton(),
      _buildHeaderMessagesButton(),
      _buildHeaderNotificationsButton(),
      _buildHeaderSettingsButton()
    ];
  }

  Widget _buildHeaderSettingsButton() {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Semantics(label: Localization().getStringEx('headerbar.settings.title', 'Settings'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
      //    IconButton(icon: Styles().images.getImage('images/settings-white.png', excludeFromSemantics: true) ?? Container(), onPressed: () => onTapSettings())
        InkWell(onTap: _onTapSettings, child:
          Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8), child:
            Styles().images.getImage('settings-header', excludeFromSemantics: true),
          )
        )
      ),
    );
  }

  Widget _buildHeaderMessagesButton() {
    //TODO: add unread messages count using Social BB (see notifications button below)
    return Semantics(label: Localization().getStringEx('headerbar.messages.title', 'Messages'), hint: Localization().getStringEx('headerbar.messages.hint', ''), button: true, excludeSemantics: true, child:
      InkWell(onTap: _onTapMessages, child:
        Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8), child:
          Styles().images.getImage('messages-header', excludeFromSemantics: true),
        )
      )
    );
  }

  Widget _buildHeaderNotificationsButton() {
    int unreadMsgsCount = Inbox().unreadMessagesCount;
    return Semantics(label: Localization().getStringEx('headerbar.notifications.title', 'Notifications'), hint: Localization().getStringEx('headerbar.notifications.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Styles().images.getImage('images/notifications-white.png', excludeFromSemantics: true) ?? Container(), onPressed: () => _onTapNotifications())
      InkWell(onTap: _onTapNotifications, child:
        Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
          Stack(alignment: Alignment.topRight, children: [
            Center(child: Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Styles().images.getImage('notification-header', excludeFromSemantics: true))),
            Opacity(opacity: (unreadMsgsCount > 0) ? 1 : 0, child:
              Align(alignment: Alignment.topRight, child: Container(padding: EdgeInsets.all(4), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.red), child:
                Text(unreadMsgsCount.toString(), style: Styles().textStyles.getTextStyle("widget.title.light.tiny")))))
          ])
        )
      )
    );
  }

  Widget _buildHeaderPersonalInfoButton() {
    return Semantics(label: Localization().getStringEx('headerbar.personal_information.title', 'Personal Information'), hint: Localization().getStringEx('headerbar.personal_information.hint', ''), button: true, excludeSemantics: true, child:
//    IconButton(icon: Styles().images.getImage('images/person-white.png', excludeFromSemantics: true), onPressed: () => onTapPersonalInformations())
      InkWell(onTap: () => _onTapPersonalInformation(), child:
        CollectionUtils.isNotEmpty(Auth2().authPicture) ?
          Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8), child:
            Container(width: 20, height: 20, decoration:
              BoxDecoration(shape: BoxShape.circle, color: Colors.white, image:
                DecorationImage( fit: BoxFit.cover, image: Image.memory(Auth2().authPicture!).image)
              )
            )
          ) :
          Padding(padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8), child:
            Styles().images.getImage('person-circle-header', excludeFromSemantics: true),
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
    RadioPlayer().pause();
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

  void _onTapMessages() {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != MessagesHomePanel.routeName) {
      Analytics().logSelect(target: "Messages");
      MessagesHomePanel.present(context);
    }
  }

  void _onTapNotifications() {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != NotificationsHomePanel.routeName) {
      Analytics().logSelect(target: "Notifications");
      NotificationsHomePanel.present(context,
          content: (Inbox().unreadMessagesCount > 0) ? NotificationsContent.unread : NotificationsContent.all);
    }
  }

  void _onTapPersonalInformation() {
    String? currentRouteName = ModalRoute.of(context)?.settings.name;
    if (currentRouteName != ProfileHomePanel.routeName) {
      Analytics().logSelect(target: "Personal Information");
      ProfileHomePanel.present(context);
    }
  }
}

class HeaderBarActionTextButton extends StatelessWidget {
  final String? title;
  final bool enabled;
  final void Function()? onTap;
  HeaderBarActionTextButton({super.key, this.title, this.enabled = true, this.onTap, });

  @override
  Widget build(BuildContext context) =>
    Semantics(label: title, button: true, child:
      InkWell(onTap: onTap, child:
        Align(alignment: Alignment.center, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12), child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: enabled ? Styles().colors.surface : Styles().colors.surface.withAlpha(153), width: 1.5, ))),
                child: Text(title ?? '',
                  style: Styles().textStyles.getTextStyle(enabled ? "widget.heading.regular.fat" : "widget.heading.regular.fat.disabled"),
                  semanticsLabel: "",
                ),
              ),
            ],)
          ),
        ),
        //Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12), child:
        //  Text(title ?? '', style: Styles().textStyles.getTextStyle('panel.athletics.home.button.underline'))
        //),
      ),
    );
}