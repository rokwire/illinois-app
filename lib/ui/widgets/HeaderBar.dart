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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/main.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/inbox/InboxHomePanel.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:illinois/ui/settings/SettingsPrivacyCenterPanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
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

class RootHeaderBar extends StatelessWidget implements PreferredSizeWidget {

  final String? title;

  RootHeaderBar({Key? key, this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) => AppBar(
    backgroundColor: Styles().colors?.fillColorPrimaryVariant,
    leading: _buildHeaderHomeButton(),
    title: _buildHeaderTitle(),
    actions: _buildHeaderActions(),
  );

  // PreferredSizeWidget
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget _buildHeaderHomeButton() {
    return Semantics(label: Localization().getStringEx('headerbar.home.title', 'Home'), hint: Localization().getStringEx('headerbar.home.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/block-i-orange.png', excludeFromSemantics: true), onPressed: _onTapHome,),);
  }

  Widget _buildHeaderTitle() {
    return Semantics(label: title, excludeSemantics: true, child:
      Text(title ?? '', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),),);
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
      IconButton(icon: Image.asset('images/settings-white.png', excludeFromSemantics: true), onPressed: _onTapSettings));
  }

  Widget _buildHeaderNotificationsButton() {
    return Semantics(label: Localization().getStringEx('headerbar.notifications.title', 'Notifications'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/notifications-white.png', excludeFromSemantics: true), onPressed: _onTapNotifications));
  }

  Widget _buildHeaderPersonalInfoButton() {
    return Semantics(label: Localization().getStringEx('headerbar.personal_information.title', 'Personal Information'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/personal-white.png', excludeFromSemantics: true), onPressed: _onTapPersonalInformations));
  }

  void _onTapHome() {
    Analytics().logSelect(target: "Home");
    if (App.instance?.currentContext != null) {
      Navigator.of(App.instance!.currentContext!).popUntil((route) => route.isFirst);
    }
  }
  void _onTapSettings() {
    Analytics().logSelect(target: "Settings");
    if (App.instance?.currentContext != null) {
      Navigator.push(App.instance!.currentContext!, CupertinoPageRoute(builder: (context) => SettingsHomePanel()));
    }
  }

  void _onTapNotifications() {
    Analytics().logSelect(target: "Notifications");
    if (App.instance?.currentContext != null) {
      Navigator.push(App.instance!.currentContext!, CupertinoPageRoute(builder: (context) => InboxHomePanel()));
    }
  }
  

  void _onTapPersonalInformations() {
    Analytics().logSelect(target: "Personal Information");
    if (App.instance?.currentContext != null) {
      Navigator.push(App.instance!.currentContext!, CupertinoPageRoute(builder: (context) => SettingsPrivacyCenterPanel()));
    }
  }

  

}