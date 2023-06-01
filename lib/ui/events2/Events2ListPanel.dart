
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Events2ListPanel extends StatefulWidget {
  static final String routeName = 'Events2ListPanel';

  @override
  State<StatefulWidget> createState() => _Events2ListPanelState();

  static void present(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Events2ListPanel.routeName), builder: (context) => Events2ListPanel()));
  }
}

class _Events2ListPanelState extends State<Events2ListPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.events2_list.header.title", "Events"), leading: RootHeaderBarLeading.Back,),
      body: _buildContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Container();
  }
}