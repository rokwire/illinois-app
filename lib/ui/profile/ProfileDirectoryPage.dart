
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileDirectoryAccountsPage.dart';
import 'package:illinois/ui/profile/ProfileDirectoryMyInfoPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileDirectoryPage extends StatefulWidget {
  static const String notifySignIn = "edu.illinois.rokwire.profile.sign_in";

  static const String tabParamKey = 'edu.illinois.rokwire.profile.directory.tab';

  final ScrollController? scrollController;
  final Map<String, dynamic>? params;

  ProfileDirectoryPage({super.key, this.scrollController, this.params});

  @override
  _ProfileDirectoryPageState createState() => _ProfileDirectoryPageState();

  ProfileDirectoryTab? get tabParam {
    dynamic tab = (params != null) ? params![tabParamKey] : null;
    return (tab is ProfileDirectoryTab) ? tab : null;
  }
}

enum ProfileDirectoryTab { myInfo, accounts }
enum MyProfileInfo { myConnectionsInfo, myDirectoryInfo }
enum DirectoryAccounts { myConnections, appDirectory }

class _ProfileDirectoryPageState extends State<ProfileDirectoryPage> implements NotificationsListener {

  late ProfileDirectoryTab _selectedTab;

  //Map<_Tab, Enum> _selectedSubTabs = <_Tab, Enum>{};

  //MyDirectoryInfo get _selectedMyInfoTab => (_selectedSubTabs[_Tab.myInfo] as MyDirectoryInfo?) ?? MyDirectoryInfo.values.first;
  //DirectoryConnections get _selectedConnectionsTab => (_selectedSubTabs[_Tab.connections] as DirectoryConnections?) ?? DirectoryConnections.values.first;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
      ProfileDirectoryAccountsPage.notifyEditInfo,
    ]);

    _selectedTab = widget.tabParam ?? ProfileDirectoryTab.values.first;

    //for (_Tab tab in _Tab.values) {
    //  _selectedSubTabs[tab] = tab.subTabs.first;
    //}
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2.notifyLoginChanged) {
      setStateIfMounted();
    }
    else if (name == ProfileDirectoryAccountsPage.notifyEditInfo) {
      setStateIfMounted((){
        _selectedTab = ProfileDirectoryTab.myInfo;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!Auth2().isLoggedIn) {
      return _loggedOutContent;
    }
    else {
      return _pageContent;
    }
  }

  Widget get _pageContent =>
    Column(children: [
      _tabsWidget,
      Visibility(visible: (_selectedTab == ProfileDirectoryTab.myInfo), maintainState: true, child:
        _tabPage(ProfileDirectoryTab.myInfo)
      ),
      Visibility(visible: (_selectedTab == ProfileDirectoryTab.accounts), maintainState: true, child:
        _tabPage(ProfileDirectoryTab.accounts)
      ),
    ],);

  Widget _tabPage(ProfileDirectoryTab tab) {
    switch(tab) {
      case ProfileDirectoryTab.myInfo: return _myInfoTabPage;
      case ProfileDirectoryTab.accounts: return _connectionsTabPage;
    }
  }

  // My Info

  Widget get _myInfoTabPage =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      Column(children: [
        //_subTabsWidget(_Tab.myInfo),
        //Visibility(visible: (_selectedMyInfoTab == MyDirectoryInfo.myConnectionsInfo), maintainState: true, child:
          //ProfileDirectoryMyInfoPage(contentType: MyDirectoryInfo.myConnectionsInfo,)
        //),
        //Visibility(visible: (_selectedMyInfoTab == MyDirectoryInfo.myDirectoryInfo), maintainState: true, child:
          ProfileDirectoryMyInfoPage(contentType: MyProfileInfo.myDirectoryInfo, params: widget.params,)
        //),

      ],),
    );

  // Connections

  Widget get _connectionsTabPage =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
      Column(children: [
        //_subTabsWidget(_Tab.connections),
        //Visibility(visible: (_selectedConnectionsTab == DirectoryConnections.myConnections), maintainState: true, child:
          //ProfileDirectoryConnectionsPage(contentType: DirectoryConnections.myConnections,)
        //),
        //Visibility(visible: (_selectedConnectionsTab == DirectoryConnections.appDirectory), maintainState: true, child:
          ProfileDirectoryAccountsPage(DirectoryAccounts.appDirectory, scrollController: widget.scrollController, onEditProfile: _onEditProfile,)
        //),
      ],),
    );

  void _onEditProfile(DirectoryAccounts contentType) =>
    NotificationService().notify(ProfileDirectoryAccountsPage.notifyEditInfo, contentType.profileInfo);

  // Tabs widget

  Widget get _tabsWidget {
    List<Widget> tabs = <Widget>[];
    for (ProfileDirectoryTab tab in ProfileDirectoryTab.values) {
      tabs.add(Expanded(child: _tabWidget(tab, selected: tab == _selectedTab)));
    }
    return Column(children: [
      Row(children: tabs,),
      _tabsShadow,
    ],);
  }

  Widget _tabWidget(ProfileDirectoryTab tab, { bool selected = false }) =>
    InkWell(onTap: () => _selectTab(tab),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 12),
        decoration: selected ? _selectedTabDecoration : null,
        child: Center(
          child: Text(tab.title, style: selected ? _selectedTabTextStyle : _regularTabTextStyle, textAlign: TextAlign.center)
        ),
      ),
    );

  void _selectTab(ProfileDirectoryTab tab) {
    Analytics().logSelect(target: tab.titleEx(language: 'en'));
    if (_selectedTab != tab) {
      setState(() {
        _selectedTab = tab;
      });
    }
  }

  Widget get _tabsShadow => Container(
    height: 5,
    decoration: BoxDecoration(gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Styles().colors.fillColorPrimaryTransparent03,
        Colors.transparent,
      ]
    )),
  );

  TextStyle? get _regularTabTextStyle =>
    Styles().textStyles.getTextStyle('widget.button.title.medium');

  TextStyle? get _selectedTabTextStyle =>
    Styles().textStyles.getTextStyle('widget.button.title.medium.fat');

  BoxDecoration get _selectedTabDecoration =>
    BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 2)));

  // SubTab

  /*Widget _subTabsWidget(_Tab tab) {
    List<Widget> widgets = <Widget>[];
    List<Enum> subTabs = tab.subTabs;
    for (Enum subTab in subTabs) {
      widgets.add(Expanded(child: _subTabWidget(tab, subTab,
        first: subTab == subTabs.first,
        last: subTab == subTabs.last,
        selected: subTab == _selectedSubTabs[tab]
      )));
    }
    return Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
      Row(children: widgets,)
    );
  }

  Widget _subTabWidget(_Tab tab, Enum subTab, { bool first = false, last =  false, bool selected = false }) =>
    InkWell(onTap: () => _selectSubTab(tab, subTab),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? _selectedSubTabColor : _regularSubTabColor,
          border: Border.all(color: Styles().colors.mediumGray2, width: 1),
          borderRadius: BorderRadius.horizontal(
            left: first ? Radius.circular(24) : Radius.zero,
            right: last ? Radius.circular(24) : Radius.zero,
          ),
        ),
        child: Center(
          child: Text(_subTabTitle(subTab), style: selected ? _selectedSubTabTextStyle : _regularSubTabTextStyle, textAlign: TextAlign.center,)
        ),
      ),
    );

  String _subTabTitle(Enum subTab, {String? language}) {
    if (subTab is MyDirectoryInfo) {
      return subTab.titleEx(language: language);
    }
    else if (subTab is DirectoryConnections) {
      return subTab.titleEx(language: language);
    }
    else {
      return '';
    }
  }

  void _selectSubTab(_Tab tab, Enum subTab) {
    Analytics().logSelect(target: _subTabTitle(subTab));
    if (subTab != _selectedSubTabs[tab]) {
      setState(() {
        _selectedSubTabs[tab] = subTab;
      });
    }
  }

  TextStyle? get _regularSubTabTextStyle =>
    _regularTabTextStyle;

  TextStyle? get _selectedSubTabTextStyle =>
    _selectedTabTextStyle;

  Color? get _regularSubTabColor =>
    null;

  Color? get _selectedSubTabColor =>
    Styles().colors.white;
   */

  // Signed out
  Widget get _loggedOutContent {
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = AppTextUtils.appTitleString('panel.profile.directory.message.signed_out', 'To view "My Info & ${AppTextUtils.appTitleMacro} App Directory", $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.');
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx('panel.profile.directory.message.signed_out.link.login', "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: TapGestureRecognizer()..onTap = _onTapSignIn, ));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  void _onTapSignIn() => NotificationService().notify(ProfileDirectoryPage.notifySignIn);
}

extension _TabExt on ProfileDirectoryTab {

  String get title => titleEx();

  String titleEx({String? language}) {
    switch(this) {
      case ProfileDirectoryTab.myInfo: return Localization().getStringEx('panel.profile.directory.tab.my_info.title', 'My Info', language: language);
      case ProfileDirectoryTab.accounts: return AppTextUtils.appTitleString('panel.profile.directory.tab.accounts.title', '${AppTextUtils.appTitleMacro} App Directory', language: language);
    }
  }

  /*List<Enum> get subTabs {
    switch (this) {
      case _Tab.myInfo: return MyDirectoryInfo.values;
      case _Tab.connections: return DirectoryConnections.values;
    }
  }*/
}

extension MyDirectoryInfoExt on MyProfileInfo {
  String get title => titleEx();

  String titleEx({String? language}) {
    switch(this) {
      case MyProfileInfo.myConnectionsInfo: return Localization().getStringEx('panel.profile.directory.tab.my_info.connections.title', 'My Connections Info', language: language);
      case MyProfileInfo.myDirectoryInfo: return Localization().getStringEx('panel.profile.directory.tab.my_info.directory.title', 'My Directory Info', language: language);
    }
  }
}

extension DirectoryConnectionsExt on DirectoryAccounts {
  String get title => titleEx();

  String titleEx({String? language}) {
    switch(this) {
      case DirectoryAccounts.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.tab.accounts.connections.title', 'My ${AppTextUtils.appTitleMacro} Connections', language: language);
      case DirectoryAccounts.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.tab.accounts.directory.title', '${AppTextUtils.appTitleMacro} App Directory', language: language);
    }
  }

  MyProfileInfo get profileInfo {
    switch(this) {
      case DirectoryAccounts.myConnections: return MyProfileInfo.myConnectionsInfo;
      case DirectoryAccounts.appDirectory: return MyProfileInfo.myDirectoryInfo;
    }
  }

}