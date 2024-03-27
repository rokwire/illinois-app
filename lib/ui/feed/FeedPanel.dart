import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';

class FeedPanel extends StatefulWidget {
  FeedPanel();

  @override
  _FeedPanelState createState() => _FeedPanelState();
}

class _FeedPanelState extends State<FeedPanel> with AutomaticKeepAliveClientMixin<FeedPanel> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, []);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;


  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.feeds.label.title', 'Browse')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              Column(children: _buildContentList(),)
            )
          ),
        ]),
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildContentList() {
    return <Widget>[];
  }

  Future<void> _onPullToRefresh() async {
    if (mounted) {
      setState(() {});
    }
  }

}
