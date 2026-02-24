// GBVResourceDirectoryContentPanel


import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class GBVResourceDirectoryContentWidget extends StatefulWidget {
  final String? contentCategory;
  final String? contentAssetKey;
  final String? contentFailedMessage;
  GBVResourceDirectoryContentWidget({ this.contentCategory, this.contentAssetKey, this.contentFailedMessage });

  @override
  State<StatefulWidget> createState() => _GBVResourceDirectoryContentWidgetState();
}

class _GBVResourceDirectoryContentWidgetState extends State<GBVResourceDirectoryContentWidget> {
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
      return _messageContent(widget.contentFailedMessage ?? '');
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
    if (widget.contentCategory != null) {
      dynamic result = await Content().loadContentItem(widget.contentCategory ?? '');
      return GBVData.fromJson(JsonUtils.mapValue(result));
    }
    else if (widget.contentAssetKey != null) {
      String? assetString = await AppBundle.loadString(widget.contentAssetKey ?? '');
      return GBVData.fromJson(JsonUtils.decodeMap(assetString));
    }
    else {
      return null;
    }
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

class GBVResourceDirectoryContentPanel extends StatelessWidget with AnalyticsInfo {
  final String? contentCategory;
  final String? contentAssetKey;
  final String? headerBarTitle;
  final String? contentFailedMessage;
  final Widget Function(BuildContext)? contentWidgetBuilder;
  final AnalyticsFeature? analyticsFeature;

  GBVResourceDirectoryContentPanel({this.contentCategory, this.contentAssetKey, this.headerBarTitle, this.contentFailedMessage, this.contentWidgetBuilder, this.analyticsFeature});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: headerBarTitle),
      body: Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
        contentWidgetBuilder?.call(context) ??
        GBVResourceDirectoryContentWidget(
          contentCategory: contentCategory,
          contentAssetKey: contentAssetKey,
          contentFailedMessage: contentFailedMessage,
        )
      ),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar()
    );
  }

}
