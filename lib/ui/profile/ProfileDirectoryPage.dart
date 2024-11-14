
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/profile/ProfileDirectoryConnectionsPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileDirectoryPage extends StatefulWidget {
  static const String notifySignIn = "edu.illinois.rokwire.profile.sign_in";

  ProfileDirectoryPage({super.key});

  @override
  _ProfileDirectoryPageState createState() => _ProfileDirectoryPageState();
}

enum _Tab { myInfo, connections }
enum MyDirectoryInfo { myConnectionsInfo, myDirectoryInfo }
enum DirectoryConnections { myConnections, appDirectory }

class _ProfileDirectoryPageState extends State<ProfileDirectoryPage> implements NotificationsListener {

  String get _appTitle => _appTitleEx();
  String _appTitleEx({String? language}) => Localization().getStringEx('app.title', 'Illinois', language: language);
  static const String _appTitleMacro = "{{app_title}}";

  late _Tab _selectedTab;

  Map<_Tab, Enum> _selectedSubTabs = <_Tab, Enum>{};
  Map<Enum, Key> _subTabsKeys = <Enum, Key>{};

  // ignore: unused_element
  MyDirectoryInfo get _selectedInfoTab => (_selectedSubTabs[_Tab.myInfo] as MyDirectoryInfo?) ?? MyDirectoryInfo.values.first;
  DirectoryConnections get _selectedConnectionsTab => (_selectedSubTabs[_Tab.connections] as DirectoryConnections?) ?? DirectoryConnections.values.first;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);

    _selectedTab = _Tab.values.first;

    for (_Tab tab in _Tab.values) {
      _selectedSubTabs[tab] = tab.subTabs.first;
    }
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
      _tabPage(_selectedTab),
    ],);

  // My Info

  Widget get _myInfoTabPage =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: [
        _subTabsWidget(_Tab.myInfo)
      ],),
    );

  // Connections

  Widget get _connectionsTabPage =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: [
        _subTabsWidget(_Tab.connections),
        ProfileDirectoryConnectionsPage(contentType: _selectedConnectionsTab, key: _subTabsKeys[_selectedConnectionsTab] ??= GlobalKey(),),
      ],),
    );

  Widget _tabPage(_Tab tab) {
    switch(tab) {
      case _Tab.myInfo: return _myInfoTabPage;
      case _Tab.connections: return _connectionsTabPage;
    }
  }

  // Tabs widget

  Widget get _tabsWidget {
    List<Widget> tabs = <Widget>[];
    for (_Tab tab in _Tab.values) {
      tabs.add(Expanded(child: _tabWidget(tab, selected: tab == _selectedTab)));
    }
    return Column(children: [
      Row(children: tabs,),
      _tabsShadow,
    ],);
  }

  Widget _tabWidget(_Tab tab, { bool selected = false }) =>
    InkWell(onTap: () => _selectTab(tab),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3, vertical: 12),
        decoration: selected ? _selectedTabDecoration : null,
        child: Center(
          child: Text(tab.title, style: selected ? _selectedTabTextStyle : _regularTabTextStyle, textAlign: TextAlign.center)
        ),
      ),
    );

  void _selectTab(_Tab tab) {
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

  Widget _subTabsWidget(_Tab tab) {
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


  // Signed out
  Widget get _loggedOutContent {
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = Localization().getStringEx('panel.profile.directory.message.signed_out', 'To view "My Info & $_appTitleMacro Connections", $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.').replaceAll(_appTitleMacro, _appTitle);
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

extension _TabExt on _Tab {

  String get title => titleEx();

  String titleEx({String? language}) {
    switch(this) {
      case _Tab.myInfo: return Localization().getStringEx('panel.profile.directory.tab.my_info.title', 'My Info', language: language);
      case _Tab.connections: return AppTextUtils.appTitleString('panel.profile.directory.tab.connections.title', '${AppTextUtils.appTitleMacro} Connections', language: language);
    }
  }

  List<Enum> get subTabs {
    switch (this) {
      case _Tab.myInfo: return MyDirectoryInfo.values;
      case _Tab.connections: return DirectoryConnections.values;
    }
  }
}

extension MyDirectoryInfoExt on MyDirectoryInfo {
  String get title => titleEx();

  String titleEx({String? language}) {
    switch(this) {
      case MyDirectoryInfo.myConnectionsInfo: return Localization().getStringEx('panel.profile.directory.tab.my_info.connections.title', 'My Connections Info', language: language);
      case MyDirectoryInfo.myDirectoryInfo: return Localization().getStringEx('panel.profile.directory.tab.my_info.directory.title', 'My Directory Info', language: language);
    }
  }
}

extension DirectoryConnectionsExt on DirectoryConnections {
  String get title => titleEx();

  String titleEx({String? language}) {
    switch(this) {
      case DirectoryConnections.myConnections: return AppTextUtils.appTitleString('panel.profile.directory.tab.connections.connections.title', 'My ${AppTextUtils.appTitleMacro} Connections', language: language);
      case DirectoryConnections.appDirectory: return AppTextUtils.appTitleString('panel.profile.directory.tab.connections.directory.title', '${AppTextUtils.appTitleMacro} App Directory', language: language);
    }
  }
}