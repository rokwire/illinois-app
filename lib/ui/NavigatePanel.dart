
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/settings/SettingsHomePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class NavigatePanel extends StatefulWidget {

  NavigatePanel();

  @override
  _NavigatePanelState createState() => _NavigatePanelState();
}

class _NavigatePanelState extends State<NavigatePanel> with AutomaticKeepAliveClientMixin<NavigatePanel> implements NotificationsListener {
  
  @override
  void initState() {
    NotificationService().subscribe(this, [
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
  }

  // AutomaticKeepAliveClientMixin
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Styles().colors?.fillColorPrimaryVariant,
        leading: _buildHeaderHomeButton(),
        title: _buildHeaderTitle(),
        actions: [_buildHeaderActions()],
      ),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            _buildContent(),
          ),
        ]),
        
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  // Widgets

  Widget _buildContent() {
      return _buildTBD();
  }

  Widget _buildTBD() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16), child:
      Column(children: <Widget>[
        Expanded(child: Container(), flex: 1),
        Text("Whoops! Nothing to see here.", style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),),
        Container(height:8),
        Text("Panel content will be filled shortly in the future.", style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 16, color: Styles().colors?.textBackground),),
        Expanded(child: Container(), flex: 3),
    ],),);
  }

  Widget _buildHeaderHomeButton() {
    return Semantics(label: Localization().getStringEx('headerbar.home.title', 'Home'), hint: Localization().getStringEx('headerbar.home.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/block-i-orange.png', excludeFromSemantics: true), onPressed: _onTapHome,),);
  }

  Widget _buildHeaderTitle() {
    return Semantics(label: Localization().getStringEx('panel.navigate.header.title', 'Navigate'), excludeSemantics: true, child:
      Text(Localization().getStringEx('panel.navigate.header.title', 'Navigate'), style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.0),),);
  }

  Widget _buildHeaderSettingsButton() {
    return Semantics(label: Localization().getStringEx('headerbar.settings.title', 'Settings'), hint: Localization().getStringEx('headerbar.settings.hint', ''), button: true, excludeSemantics: true, child:
      IconButton(icon: Image.asset('images/settings-white.png', excludeFromSemantics: true), onPressed: _onTapSettings));
  }

  Widget _buildHeaderActions() {
    List<Widget> actions = <Widget>[ _buildHeaderSettingsButton() ];
    return Row(mainAxisSize: MainAxisSize.min, children: actions,);
  }


  Future<void>_onPullToRefresh() async {
  }

  void _onTapSettings() {
    Analytics().logSelect(target: "Settings");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsHomePanel()));
  }

  void _onTapHome() {
    Analytics().logSelect(target: "Home");
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}
