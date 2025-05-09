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
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/debug/DebugHomePanel.dart';
import 'package:illinois/ui/profile/ProfileInfoWrapperPage.dart';
import 'package:illinois/ui/profile/ProfileLoginPage.dart';
import 'package:illinois/ui/profile/ProfileRolesPage.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum ProfileContent { login, profile, share, who_are_you, }

class ProfileHomePanel extends StatefulWidget {
  static const String notifySelectContent = "edu.illinois.rokwire.profile.command.select";
  static const String routeName = 'settings_profile_content_panel';

  final ProfileContent? content;
  final Map<String, dynamic>? contentParams;

  ProfileHomePanel._({this.content, this.contentParams});

  @override
  _ProfileHomePanelState createState() => _ProfileHomePanelState();

  static void present(BuildContext context, { ProfileContent? content, Map<String, dynamic>? contentParams }) {
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
          return ProfileHomePanel._(content: content, contentParams: contentParams,);
        }
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

class _ProfileHomePanelState extends State<ProfileHomePanel> with NotificationsListener {

  ProfileContent? _selectedContent;
  static ProfileContent? _lastSelectedContent;
  bool _contentValuesVisible = false;

  final GlobalKey _pageKey = GlobalKey();
  final GlobalKey _pageHeadingKey = GlobalKey();
  final GlobalKey<ProfileInfoWrapperPageState> _profileInfoKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  final Map<ProfileContent?, Map<String, dynamic>?> _contentParams = <ProfileContent?, Map<String, dynamic>?>{};

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      ProfileHomePanel.notifySelectContent,
    ]);

    if (widget.content != null) {
      _selectedContent = _lastSelectedContent = widget.content;
      _contentParams[widget.content] = widget.contentParams;
    }
    else if (_lastSelectedContent != null) {
      _selectedContent = _lastSelectedContent;
    }
    else  {
      _selectedContent = _lastSelectedContent = ProfileContent.values.first;
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
    if (name == ProfileHomePanel.notifySelectContent) {
      _handleSelectNotification(param);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    //return _buildScaffold(context);
    return _buildSheet();
  }

  /*Widget _buildScaffold(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.settings.profile.header.profile.label', 'Profile')),
      body: _buildPage(context),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar()
    );
  }*/

  Widget _buildSheet() {
    // MediaQuery(data: MediaQueryData.fromWindow(WidgetsBinding.instance.window), child: SafeArea(bottom: false, child: ))
    return PopScopeFix(onClose: _closeSheet, child:
      Padding(padding: MediaQuery.of(context).viewInsets, child:
        Column(children: [
          _buildHeaderBar(),
          Container(color: Styles().colors.surfaceAccent, height: 1,),
          Expanded(child:
            _buildPage(),
          )
        ],),
      ),
    );
  }

  Widget _buildHeaderBar() {
    return Container(color: Styles().colors.white, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(left: 16), child:
            Text(Localization().getStringEx('panel.settings.profile.header.profile.label', 'Profile'), style: Styles().textStyles.getTextStyle("widget.label.medium.fat"),)
          )
        ),
        Visibility(visible: (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)), child:
          Semantics(label: "debug", child:
            InkWell(onTap : _onTapDebug, child:
              Container(padding: EdgeInsets.only(left: 16, right: 8, top: 16, bottom: 16), child:
                Styles().images.getImage('bug', excludeFromSemantics: true),
              ),
            ),
          )
        ),
        Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
          InkWell(onTap : _onTapClose, child:
            Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
              Styles().images.getImage('close-circle', excludeFromSemantics: true),
            ),
          ),
        ),

      ],),
    );
  }

  Widget _buildPage() {
    return Column(key: _pageKey, children: <Widget>[
      Expanded(child:
        Container(color: Styles().colors.background, child:
          SingleChildScrollView(controller: _scrollController, physics: _contentValuesVisible ? NeverScrollableScrollPhysics() : null, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(key: _pageHeadingKey, padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
                Semantics(hint: Localization().getStringEx("dropdown.hint", "DropDown"), focused: true, container: true, child:
                  RibbonButton(
                    textStyle: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"),
                    backgroundColor: Styles().colors.white,
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
      if (_selectedContent != contentItem) {
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
        backgroundColor: Styles().colors.white,
        border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
        rightIconKey: null,
        label: _getContentItemName(contentItem),
        onTap: () => _onTapContentItem(contentItem));
  }

  void _onTapContentItem(ProfileContent contentItem) async {
    Analytics().logSelect(target: contentItem.toString(), source: widget.runtimeType.toString());
    bool? modifiedResult = (_selectedContent == ProfileContent.profile) ? await saveModifiedProfile() : null;
    if (mounted) {
      setState(() {
        if (modifiedResult != false) {
          _contentParams.remove(_selectedContent);
          _selectedContent = _lastSelectedContent = contentItem;
        }
        _contentValuesVisible = !_contentValuesVisible;
      });
    }
  }

  void _onTapDebug() {
    Analytics().logSelect(target: 'Debug', source: widget.runtimeType.toString());
    if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => DebugHomePanel()));
    }
  }

  void _onTapClose() async {
    Analytics().logSelect(target: 'Close', source: widget.runtimeType.toString());
    _closeSheet();
  }

  void _closeSheet() async {
    bool? modifiedResult = await saveModifiedProfile();
    if (modifiedResult != false) {
      Navigator.of(context).pop();
    }
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

  Future<bool?> saveModifiedProfile() async => _profileInfoKey.currentState?.saveModified();

  void _handleSelectNotification(param) {
    ProfileContent? content;
    Map<String, dynamic>? contentParam;
    if (param is ProfileContent) {
      content = param;
    }
    else if (param is List) {
      if ((0 < param.length) && (param[0] is ProfileContent)) {
        content = param[0];
      }
      if ((1 < param.length) && (param[1] is Map<String, dynamic>)) {
        contentParam = param[1];
      }
    }

    if ((content != null) && mounted) {
      setState(() {
        _contentParams.remove(_selectedContent);
        _selectedContent = _lastSelectedContent = content;
        _contentParams[content] = contentParam;
      });
    }
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
      case ProfileContent.profile: return ProfileInfoWrapperPage(ProfileInfoWrapperContent.info, contentParams: _contentParams[ProfileContent.profile], key: _profileInfoKey);
      case ProfileContent.share: return ProfileInfoWrapperPage(ProfileInfoWrapperContent.share, contentParams: _contentParams[ProfileContent.share]);
      case ProfileContent.who_are_you: return ProfileRolesPage();
      case ProfileContent.login: return ProfileLoginPage();
      default: return Container();
    }
  }

  String? _getContentItemName(ProfileContent? contentItem) {
    switch (contentItem) {
      case ProfileContent.profile: return Localization().getStringEx('panel.settings.profile.content.profile.label', 'My Profile');
      case ProfileContent.share: return Localization().getStringEx('panel.settings.profile.content.share.label', 'My Digital Business Card');
      case ProfileContent.who_are_you: return Localization().getStringEx('panel.settings.profile.content.who_are_you.label', 'Who Are You');
      case ProfileContent.login: return Localization().getStringEx('panel.settings.profile.content.login.label', 'Sign In/Sign Out');
      default: return null;
    }
  }
}
