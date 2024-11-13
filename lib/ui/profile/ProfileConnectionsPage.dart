
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class ProfileConnectionsPage extends StatefulWidget {
  static const String notifySignIn = "edu.illinois.rokwire.profile.sign_in";

  ProfileConnectionsPage({super.key});

  @override
  _ProfileConnectionsPageState createState() => _ProfileConnectionsPageState();
}

enum _Tab { myInfo, connections }

class _ProfileConnectionsPageState extends State<ProfileConnectionsPage> implements NotificationsListener {

  static const String _appTitleMacro = "{{app_title}}";
  String get _appTitle => Localization().getStringEx('app.title', 'Illinois');

  late _Tab _selectedTab;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2.notifyLoginChanged,
    ]);
    _selectedTab = _Tab.values.first;
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
          child: Text(_tabTitle(tab), style: selected ? _selectedTabTextStyle : _regularTabTextStyle,)
        ),
      ),
    );

  void _selectTab(_Tab tab) {
    Analytics().logSelect(target: _tabTitle(tab, language: 'en'));
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

  Widget _tabPage(_Tab tab) {
    switch(tab) {
      case _Tab.myInfo: return _myInfoTabPage;
      case _Tab.connections: return _connectionsTabPage;
    }
  }

  String _tabTitle(_Tab tab, { String? language }) {
    switch(tab) {
      case _Tab.myInfo: return Localization().getStringEx('panel.profile.connections.tab.my_info.title', 'My Info', language: language);
      case _Tab.connections: return Localization().getStringEx('panel.profile.connections.tab.connections.title', '$_appTitleMacro Connections', language: language).replaceAll(_appTitleMacro, _appTitle);
    }
  }

  TextStyle? get _regularTabTextStyle =>
    Styles().textStyles.getTextStyle('widget.button.title.medium');

  TextStyle? get _selectedTabTextStyle =>
    Styles().textStyles.getTextStyle('widget.button.title.medium.fat');

  BoxDecoration get _selectedTabDecoration =>
    BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.fillColorSecondary, width: 2)));

  // My Info

  Widget get _myInfoTabPage => Container(color: Colors.amber,);

  // Connections

  Widget get _connectionsTabPage => Container(color: Colors.teal,);

  // Signed out
  Widget get _loggedOutContent {
    final String linkLoginMacro = "{{link.login}}";
    String messageTemplate = Localization().getStringEx('panel.profile.connections.message.signed_out', 'To view "My Info & $_appTitleMacro Connections", $linkLoginMacro with your NetID and set your privacy level to 4 or 5 under Settings.').replaceAll(_appTitleMacro, _appTitle);
    List<String> messages = messageTemplate.split(linkLoginMacro);
    List<InlineSpan> spanList = <InlineSpan>[];
    if (0 < messages.length)
      spanList.add(TextSpan(text: messages.first));
    for (int index = 1; index < messages.length; index++) {
      spanList.add(TextSpan(text: Localization().getStringEx('panel.profile.connections.message.signed_out.link.login', "sign in"), style : Styles().textStyles.getTextStyle("widget.link.button.title.regular"),
        recognizer: TapGestureRecognizer()..onTap = _onTapSignIn, ));
      spanList.add(TextSpan(text: messages[index]));
    }

    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.message.dark.regular"), children: spanList)
      )
    );
  }

  void _onTapSignIn() => NotificationService().notify(ProfileConnectionsPage.notifySignIn);

}