// GBVResourceDirectoryContentPanel


import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Content.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:path/path.dart' as path;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';


class GBVResourceDirectoryContentWidget extends StatefulWidget {
  final String? favoriteKey;
  final String? contentCategory;
  final String? contentAssetKey;
  final String? contentFailedMessage;
  final Widget Function(BuildContext)? prefixWidgetBuilder;
  final Widget Function(BuildContext)? suffixWidgetBuilder;

  GBVResourceDirectoryContentWidget({
    this.contentCategory, this.contentAssetKey, this.favoriteKey,
    this.contentFailedMessage,
    this.prefixWidgetBuilder, this.suffixWidgetBuilder,
  });

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
        Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
          widget.prefixWidgetBuilder?.call(context) ?? Container(),
          GBVResourceDirectoryWidget(gbvData: _linksData ?? GBVData.empty(), favoriteKey: widget.favoriteKey, favoriteCategory: _favoriteCategory,),
          widget.suffixWidgetBuilder?.call(context) ?? Container(),
        ],)
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
        Column(children:[
          widget.prefixWidgetBuilder?.call(context) ?? Container(height: _screenHeight / 10,),
          Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 64), child:
            Text(message, textAlign: TextAlign.center, style: Styles().textStyles.getTextStyle('widget.title.regular.medium_fat')),
          ),
          widget.suffixWidgetBuilder?.call(context) ?? Container(height: 8 * _screenHeight / 10,),
        ]),
      ),
    );


  double get _screenHeight => MediaQuery.of(context).size.height;

  String? get _favoriteCategory {
    if (widget.contentCategory != null) {
      return widget.contentCategory;
    }
    else if (widget.contentAssetKey != null) {
      List<String> assetItems = path.split(path.withoutExtension(widget.contentAssetKey ?? ''));
      return assetItems.isNotEmpty ? assetItems.last : null;
    } else {
      return null;
    }
  }

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
  final String? favoriteKey;
  final String? contentCategory;
  final String? contentAssetKey;
  final String? headerBarTitle;
  final String? contentFailedMessage;
  final Widget Function(BuildContext)? contentWidgetBuilder;
  final AnalyticsFeature? analyticsFeature;

  GBVResourceDirectoryContentPanel({this.favoriteKey,
    this.contentCategory, this.contentAssetKey,
    this.headerBarTitle, this.contentFailedMessage,
    this.contentWidgetBuilder, this.analyticsFeature
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: headerBarTitle),
      body: Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
        contentWidgetBuilder?.call(context) ??
        GBVResourceDirectoryContentWidget(
          favoriteKey: favoriteKey,
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
