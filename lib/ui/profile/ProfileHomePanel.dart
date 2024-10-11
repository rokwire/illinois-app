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
import 'package:neom/service/FlexUI.dart';
import 'package:neom/ui/profile/ProfileDetailsPage.dart';
import 'package:neom/ui/profile/ProfileLoginPage.dart';
import 'package:neom/ui/profile/ProfileRolesPage.dart';
import 'package:neom/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum ProfileContent { login, profile, who_are_you, }

class ProfileHomePanel extends StatefulWidget {
  static final String routeName = 'settings_profile_content_panel';

  final ProfileContent? content;

  ProfileHomePanel._({this.content});

  @override
  _ProfileHomePanelState createState() => _ProfileHomePanelState();

  static void present(BuildContext context, {ProfileContent? content}) {
    if (ModalRoute.of(context)?.settings.name != routeName) {
      MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
      double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true,
        useRootNavigator: true,
        routeSettings: RouteSettings(name: routeName),
        clipBehavior: Clip.antiAlias,
        backgroundColor: Styles().colors.background,
        constraints: BoxConstraints(maxHeight: height, minHeight: height),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (context) {
          return ProfileHomePanel._(content: content);
        },
        useSafeArea: true,
      );

      /*Navigator.push(context, PageRouteBuilder(
        settings: RouteSettings(name: routeName),
        pageBuilder: (context, animation1, animation2) => SettingsProfileContentPanel._(content: content),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero
      ));*/
    }
  }
}

class _ProfileHomePanelState extends State<ProfileHomePanel> implements NotificationsListener {
  ProfileContent? _selectedContent;
  static ProfileContent? _lastSelectedContent;
  bool _contentValuesVisible = false;

  final GlobalKey _pageKey = GlobalKey();
  final GlobalKey _pageHeadingKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      FlexUI.notifyChanged,
    ]);

    if (_isContentItemEnabled(widget.content)) {
      _selectedContent = _lastSelectedContent = widget.content;
    }
    else if (_isContentItemEnabled(_lastSelectedContent)) {
      _selectedContent = _lastSelectedContent;
    }
    else  {
      _selectedContent = _initialSelectedContent;
    }
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, param) {
    if ((name == Auth2.notifyLoginChanged) ||
        (name == FlexUI.notifyChanged)) {
      _updateContentItemIfNeeded();
    }
  }
  
  @override
  Widget build(BuildContext context) {
    //return _buildScaffold(context);
    return _buildSheet(context);
  }

  /*Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.settings.profile.header.profile.label', 'Profile')),
      body: _buildPage(context),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar()
    );
  }*/

  Widget _buildSheet(BuildContext context) {
    // MediaQuery(data: MediaQueryData.fromWindow(WidgetsBinding.instance.window), child: SafeArea(bottom: false, child: ))
    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Column(children: [
        Container(color: Styles().colors.backgroundAccent, child:
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16), child:
                Text(Localization().getStringEx('panel.settings.profile.header.profile.label', 'PROFILE'), style: Styles().textStyles.getTextStyle("widget.title.light.large.fat"),)
              )
            ),
            // Visibility(visible: (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)), child:
            //   Semantics(label: "debug", child:
            //     InkWell(onTap : _onTapDebug, child:
            //       Container(padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16), child:
            //         Styles().images.getImage('bug', excludeFromSemantics: true),
            //       ),
            //     ),
            //   )
            // ),
            Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
              InkWell(onTap : _onTapClose, child:
                Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
                  Styles().images.getImage('close-circle-white', excludeFromSemantics: true),
                ),
              ),
            ),
          ],),
        ),
        Expanded(child:
          _buildPage(context),
        )
      ],),
    );
  }

  Widget _buildPage(BuildContext context) {
    return Column(key: _pageKey, children: <Widget>[
      Expanded(child:
        Container(color: Styles().colors.background, child:
          SingleChildScrollView(physics: _contentValuesVisible ? NeverScrollableScrollPhysics() : null, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(key: _pageHeadingKey, padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
                Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), focused: true, container: true, child:
                  RibbonButton(
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                    backgroundColor: Styles().colors.gradientColorPrimary,
                    borderRadius: BorderRadius.all(Radius.circular(5)),
                    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                    rightIconKey: (_contentValuesVisible ? 'chevron-up' : 'chevron-down'),
                    label: _getContentItemName(_selectedContent) ?? '',
                    onTap: _onTapContentSwitch
                  )
                )
              ),
              _buildContent(),
            ])
          )
        )
      )
    ]);
  }


  Widget _buildContent() {
    return Stack(children: [
      _contentWidget,
      Container(height: _contentHeight),
      _buildContentValuesContainer()
    ]);
  }

  Widget _buildContentValuesContainer() {
    return Visibility(visible: _contentValuesVisible, child:
      Positioned.fill(child:
        Stack(children: <Widget>[
          _buildContentDismissLayer(),
          _buildContentValuesWidget()
        ])
      )
    );
  }

  Widget _buildContentDismissLayer() {
    return Positioned.fill(child:
      BlockSemantics(child:
        Semantics(excludeSemantics: true, child:
          GestureDetector(onTap: _onTapDismissLayer, child:
            Container(color: Styles().colors.blackTransparent06)
          )
        )
      )
    );
  }

  Widget _buildContentValuesWidget() {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (ProfileContent contentItem in ProfileContent.values) {
      if (_isContentItemEnabled(contentItem) && (_selectedContent != contentItem)) {
        contentList.add(_buildContentItem(contentItem));
      }
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  Widget _buildContentItem(ProfileContent contentItem) {
    return RibbonButton(
        textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"),
        backgroundColor: Styles().colors.gradientColorPrimary,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        label: _getContentItemName(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentItem(ProfileContent contentItem) {
    Analytics().logSelect(target: contentItem.toString(), source: widget.runtimeType.toString());
    setState(() {
      _selectedContent = _lastSelectedContent = contentItem;
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  // void _onTapDebug() {
  //   Analytics().logSelect(target: 'Debug', source: widget.runtimeType.toString());
  //   if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
  //     Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
  //   }
  // }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    Navigator.of(context).pop();
  }

  void _onTapContentSwitch() {
    setState(() {
      _contentValuesVisible = !_contentValuesVisible;
    });
  }

  void _onTapDismissLayer() {
    setState(() {
      _contentValuesVisible = false;
    });
  }

  // Utilities

  double? get _contentHeight  {
    RenderObject? pageRenderBox = _pageKey.currentContext?.findRenderObject();
    double? pageHeight = ((pageRenderBox is RenderBox) && pageRenderBox.hasSize) ? pageRenderBox.size.height : null;

    RenderObject? pageHeaderRenderBox = _pageHeadingKey.currentContext?.findRenderObject();
    double? pageHeaderHeight = ((pageHeaderRenderBox is RenderBox) && pageHeaderRenderBox.hasSize) ? pageHeaderRenderBox.size.height : null;

    return ((pageHeight != null) && (pageHeaderHeight != null)) ? (pageHeight - pageHeaderHeight) : null;
  }

  Widget get _contentWidget {
    switch (_selectedContent) {
      case ProfileContent.profile: return ProfileDetailsPage(parentRouteName: ProfileHomePanel.routeName,);
      case ProfileContent.who_are_you: return ProfileRolesPage();
      case ProfileContent.login: return ProfileLoginPage();
      default: return Container();
    }
  }

  String? _getContentItemName(ProfileContent? contentItem) {
    switch (contentItem) {
      case ProfileContent.profile: return Localization().getStringEx('panel.settings.profile.content.profile.label', 'My Profile');
      case ProfileContent.who_are_you: return Localization().getStringEx('panel.settings.profile.content.who_are_you.label', 'Who Are You');
      case ProfileContent.login: return Localization().getStringEx('panel.settings.profile.content.login.label', 'Sign In/Sign Out');
      default: return null;
    }
  }

  bool _isContentItemEnabled(ProfileContent? contentItem) {
    switch (contentItem) {
      case ProfileContent.profile: return Auth2().isLoggedIn;
      case ProfileContent.who_are_you: return true;
      case ProfileContent.login: return FlexUI().hasFeature('authentication');
      default: return false;
    }
  }

  ProfileContent? get _initialSelectedContent {
    for (ProfileContent contentItem in ProfileContent.values) {
      if (_isContentItemEnabled(contentItem)) {
        return contentItem;
      }
    }
    return null;
  }

  void _updateContentItemIfNeeded() {
    if ((_selectedContent == null) || !_isContentItemEnabled(_selectedContent)) {
      ProfileContent? selectedContent = _isContentItemEnabled(_lastSelectedContent) ? _lastSelectedContent : _initialSelectedContent;
      if ((selectedContent != null) && (selectedContent != _selectedContent) && mounted) {
        setState(() {
          _selectedContent = selectedContent;
        });
      }
    }
  }
}
