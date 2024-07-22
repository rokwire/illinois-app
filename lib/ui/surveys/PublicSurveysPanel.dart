

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class PublicSurveysPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PublicSurveysPanelState();
}

class _PublicSurveysPanelState extends State<PublicSurveysPanel>  {

  ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: RootHeaderBar(title: Localization().getStringEx("panel.public_surveys.home.header.title", "Public Surveys"), leading: RootHeaderBarLeading.Back,),
    body: _panelContent,
    backgroundColor: Styles().colors.background,
    bottomNavigationBar: uiuc.TabBar(),
  );

  Widget get _panelContent => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Expanded(child:
      RefreshIndicator(onRefresh: _onRefresh, child:
        SingleChildScrollView(controller: _scrollController, physics: AlwaysScrollableScrollPhysics(), child:
          _surveysContent,
        )
      )
    )
  ],);

  Widget get _surveysContent => Container();

  Future<void> _onRefresh() async {
    Analytics().logSelect(target: 'Refresh');
  }
}