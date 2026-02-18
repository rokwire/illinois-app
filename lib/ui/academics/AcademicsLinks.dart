
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class AcademicLinksWidget extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AcademicLinksWidgetState();
}

class _AcademicLinksWidgetState extends State<AcademicLinksWidget> {
  GBVData? _linksData;
  bool _loadingLinksData = false;

  @override
  void initState() {
    _loadingLinksData = true;
    _loadLinksData().then((GBVData? linksData) {
      setStateIfMounted(() {
        _linksData = linksData;
        _loadingLinksData = false;
      });
    });
    super.initState();
  }

  @override
  void deactivate() {
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingLinksData) {
      return _loadingContent;
    } else if (_linksData == null) {
      return _messageContent(Localization().getStringEx('', 'Failed to load academic links data'));
    } else {
      return _resourceContent;
    }
  }

  Widget get _resourceContent =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
        Padding(padding: EdgeInsets.only(bottom: 16), child:
          GBVResourceDirectoryWidget(gbvData: _linksData ?? GBVData.empty(),),
        )
      ),
    );

  Widget get _loadingContent =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64), child:
      Column(children:[
        Expanded(flex: 1, child: Container()),
        SizedBox.square(dimension: 32, child:
          CircularProgressIndicator(strokeWidth: 3, color: Styles().colors.fillColorSecondary,)
        ),
        Expanded(flex: 5, child: Container()),
      ]),
    );

  Widget _messageContent(String message) =>
    RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64), child:
          Column(children:[
            Container(height: _screenHeight / 10,),
            Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.title.regular.medium_fat')),
            Container(height: 8 * _screenHeight / 10,),
          ]),
        )
      ),
    );


  double get _screenHeight => MediaQuery.of(context).size.height;

  Future<GBVData?> _loadLinksData() async {
    final String contentCategory = 'academic_links';
    dynamic result = await Content().loadContentItem(contentCategory);
    return GBVData.fromJson(JsonUtils.mapValue(result));
  }

  Future<void> _onRefresh() async {
    if ((_loadingLinksData == false) && mounted) {
      setState(() {
        _loadingLinksData = true;
      });
      GBVData? linksData = await _loadLinksData();
      setStateIfMounted(() {
        _linksData = linksData;
        _loadingLinksData = false;
      });
    }
  }

}

class AcademicLinksPanel extends StatelessWidget with AnalyticsInfo {
  AcademicLinksPanel();

  @override
  AnalyticsFeature? get analyticsFeature => AnalyticsFeature.AcademicsLinks;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.browse.entry.academics.academic_links.title', 'Academic Links')),
      body: Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child: AcademicLinksWidget()),
      backgroundColor: Styles().colors.white,
      bottomNavigationBar: uiuc.TabBar()
    );
  }
}
