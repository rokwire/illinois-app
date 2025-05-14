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
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Storage.dart';
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

enum ProfileContentType { login, profile, share, who_are_you, }

class ProfileHomePanel extends StatefulWidget {
  static const String notifySelectContent = "edu.illinois.rokwire.profile.command.select";
  static const String routeName = 'settings_profile_content_panel';

  final ProfileContentType? contentType;
  final Map<String, dynamic>? contentParams;

  ProfileHomePanel._({this.contentType, this.contentParams});

  @override
  _ProfileHomePanelState createState() => _ProfileHomePanelState();

  static void present(BuildContext context, { ProfileContentType? contentType, Map<String, dynamic>? contentParams }) {
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
          return ProfileHomePanel._(contentType: contentType, contentParams: contentParams,);
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

  late List<ProfileContentType> _contentTypes;
  ProfileContentType? _selectedContentType;
  bool _contentValuesVisible = false;
  static ProfileContentType get _defaultContentType => Auth2().isLoggedIn ? ProfileContentType.profile : ProfileContentType.login;

  final GlobalKey _pageKey = GlobalKey();
  final GlobalKey _pageHeadingKey = GlobalKey();
  final GlobalKey<ProfileInfoWrapperPageState> _profileInfoKey = GlobalKey();

  final ScrollController _scrollController = ScrollController();

  final Map<ProfileContentType?, Map<String, dynamic>?> _contentParams = <ProfileContentType?, Map<String, dynamic>?>{};

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      ProfileHomePanel.notifySelectContent,
    ]);

    _contentTypes = _ProfileContentTypeList.fromContentTypes(ProfileContentType.values);

    if (widget.contentType != null) {
      Storage()._profileContentType = _selectedContentType = widget.contentType;
      _contentParams[widget.contentType] = widget.contentParams;
    }
    else {
      ProfileContentType? lastContentType = Storage()._profileContentType;
      _selectedContentType = (lastContentType != null) ? lastContentType : (Storage()._profileContentType = _defaultContentType);
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
                    label: _selectedContentType?.displayTitle ?? '',
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
          _dropdownDismissLayer,
          _dropdownList,
        ])
      )
    );
  }

  Widget get _dropdownDismissLayer {
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

  Widget get _dropdownList {
    List<Widget> contentList = <Widget>[];
    contentList.add(Container(color: Styles().colors.fillColorSecondary, height: 2));
    for (ProfileContentType contentType in _contentTypes) {
      contentList.add(RibbonButton(
          backgroundColor: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          textStyle: Styles().textStyles.getTextStyle((_selectedContentType == contentType) ? 'widget.button.title.medium.fat.secondary' : 'widget.button.title.medium.fat'),
          rightIconKey: (_selectedContentType == contentType) ? 'check-accent' : null,
          label: contentType.displayTitle,
          onTap: () => _onTapDropdownItem(contentType))
      );
    }
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      SingleChildScrollView(child:
        Column(children: contentList)
      )
    );
  }

  void _onTapDropdownItem(ProfileContentType contentItem) async {
    Analytics().logSelect(target: contentItem.displayTitleEn, source: widget.runtimeType.toString());
    if (_selectedContentType != contentItem) {
      bool? modifiedResult = (_selectedContentType == ProfileContentType.profile) ? await saveModifiedProfile() : null;
      if (mounted) {
        setState(() {
          if (modifiedResult != false) {
            _contentParams.remove(_selectedContentType);
            Storage()._profileContentType = _selectedContentType = contentItem;
          }
          _contentValuesVisible = false;
        });
      }
    }
    else {
      setState(() { _contentValuesVisible = false; });
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
    ProfileContentType? content;
    Map<String, dynamic>? contentParam;
    if (param is ProfileContentType) {
      content = param;
    }
    else if (param is List) {
      if ((0 < param.length) && (param[0] is ProfileContentType)) {
        content = param[0];
      }
      if ((1 < param.length) && (param[1] is Map<String, dynamic>)) {
        contentParam = param[1];
      }
    }

    if ((content != null) && mounted) {
      setState(() {
        _contentParams.remove(_selectedContentType);
        Storage()._profileContentType = _selectedContentType = content;
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
    switch (_selectedContentType) {
      case ProfileContentType.profile: return ProfileInfoWrapperPage(ProfileInfoWrapperContent.info, key: _profileInfoKey, contentParams: _contentParams[ProfileContentType.profile]);
      case ProfileContentType.share: return ProfileInfoWrapperPage(ProfileInfoWrapperContent.share, contentParams: _contentParams[ProfileContentType.share]);
      case ProfileContentType.who_are_you: return ProfileRolesPage();
      case ProfileContentType.login: return ProfileLoginPage();
      default: return Container();
    }
  }
}

// ProfileContentType

extension ProfileContentTypeImpl on ProfileContentType {
  String get displayTitle => displayTitleLng();
  String get displayTitleEn => displayTitleLng('en');

  String displayTitleLng([String? language]) {
    switch (this) {
      case ProfileContentType.profile: return Localization().getStringEx('panel.settings.profile.content.profile.label', 'My Profile', language: language);
      case ProfileContentType.share: return Localization().getStringEx('panel.settings.profile.content.share.label', 'My Digital Business Card', language: language);
      case ProfileContentType.who_are_you: return Localization().getStringEx('panel.settings.profile.content.who_are_you.label', 'Who Are You', language: language);
      case ProfileContentType.login: return Localization().getStringEx('panel.settings.profile.content.login.label', 'Sign In/Sign Out', language: language);
    }
  }

  String get jsonString {
    switch (this) {
      case ProfileContentType.profile: return 'profile';
      case ProfileContentType.share: return 'share';
      case ProfileContentType.who_are_you: return 'who_are_you';
      case ProfileContentType.login: return 'login';
    }
  }

  static ProfileContentType? fromJsonString(String? value) {
    switch(value) {
      case 'profile': return ProfileContentType.profile;
      case 'share': return ProfileContentType.share;
      case 'who_are_you': return ProfileContentType.who_are_you;
      case 'login': return ProfileContentType.login;
      default: return null;
    }
  }
}

extension _ProfileContentTypeList on List<ProfileContentType> {
  void sortAlphabetical() => sort((ProfileContentType t1, ProfileContentType t2) => t1.displayTitle.compareTo(t2.displayTitle));

  static List<ProfileContentType> fromContentTypes(Iterable<ProfileContentType> contentTypes) {
    List<ProfileContentType> contentTypesList = List<ProfileContentType>.from(contentTypes);
    contentTypesList.sortAlphabetical();
    return contentTypesList;
  }
}

extension _StorageProfileExt on Storage {
  ProfileContentType? get _profileContentType => ProfileContentTypeImpl.fromJsonString(profileContentType);
  set _profileContentType(ProfileContentType? value) => profileContentType = value?.jsonString;
}
