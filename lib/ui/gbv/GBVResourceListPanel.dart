import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GBVResourceListPanel extends StatefulWidget {
  final String id;

  GBVResourceListPanel({ super.key, required this.id });

  @override
  State<StatefulWidget> createState() => _GBVResourceListPanelState();

}

class _GBVResourceListPanelState extends State<GBVResourceListPanel> {

  _GBVResourceListScreenData? _resourceData;
  bool _loading = true;

  @override
  void initState() {
    _loadResourceScreenData(widget.id).then((_GBVResourceListScreenData? resourceData) {
      setStateIfMounted(() {
        _loading = false;
        _resourceData = resourceData;
      });
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: HeaderBar(),
        body: _scaffoldContentWidget(_resourceData),
        backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar()
      );

  Widget _scaffoldContentWidget (_GBVResourceListScreenData? resourceData) {
    if (_loading) {
      return _buildLoadingContent();
    }
    else if (resourceData == null) {
      return _buildErrorContent();
    }
    else {
      return _bodyWidget(resourceData);
    }
  }

  Widget _bodyWidget (_GBVResourceListScreenData resourceData) {
    GBVResourceListScreen resourceListScreen = resourceData.resourceListScreen;
    return
      SingleChildScrollView(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(padding: EdgeInsets.only(top: 32, left: 16), child: (
              Text(resourceListScreen.title ?? '', style: Styles().textStyles.getTextStyle("widget.button.title.large.fat")))
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16), child:
            Container(height: 1, color: Styles().colors.surfaceAccent)
          ),
          Padding(padding: EdgeInsets.only(right: 16, left: 16, bottom: 32), child: (
              Text(resourceListScreen.description ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))
          )),
          ...resourceListScreen.content.map((section) => _buildResourceSection(section, resourceItems: resourceData.resourceItems))
        ])
      );
  }

  Widget _buildResourceSection(GBVResourceList resourceList, { required Map<String, GBVResource> resourceItems }) {
      List<Widget> resources = resourceList.resourceIds.map((id) {
        GBVResource? resource = resourceItems[id];
        return (resource != null)
            ? _resourceWidget(resource)
            : Container();
      }).toList();

      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        (resourceList.title != '')
            ? Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: (
            Text(resourceList.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"))
        ))
            : Container(),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
          Column(children: resources)
        )
      ]);

  }

  Widget _resourceWidget (GBVResource resource) {
    Widget descriptionWidget = (resource.directoryContent.isNotEmpty)
      ? Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
        Column(children:
          resource.directoryContent.map((detail) => Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))).toList()
        )
      )
      : Container();
    return
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Container(decoration:
          BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ), child:
          Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
            Row(children: [
              Expanded(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Padding(padding: EdgeInsets.only(left: 16), child:
                  Text(resource.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
                  ),
                  descriptionWidget
                ])
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
                Styles().images.getImage((resource.type == GBVResourceType.external_link) ? 'external-link' : 'chevron-right', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
              )
            ])
          )
        )
      );
  }

  Widget _buildLoadingContent() {
    return Column(children: <Widget>[
        Expanded(flex: 1, child: Container()),
        SizedBox(width: 32, height: 32, child:
          CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
        ),
        Expanded(flex: 2, child: Container()),
    ]);
  }

  Widget _buildErrorContent() {
    return Column(children: <Widget>[
        Expanded(flex: 1, child: Container()),
        Padding(padding: EdgeInsets.symmetric(horizontal: 48), child:
          Text(Localization().getStringEx('', 'Failed to load resource data.'), style: Styles().textStyles.getTextStyle('widget.button.title.medium.fat'), textAlign: TextAlign.center,),
        ),
        Expanded(flex: 3, child: Container()),
    ]);
  }

  Future<_GBVResourceListScreenData?> _loadResourceScreenData(String screenId) async {
    // temporary json load from assets
    String? json = await AppBundle.loadString('assets/extra/gbv/${screenId}.json');
    GBVResourceListScreen? resourceListScreen = (json != null)
        ? GBVResourceListScreen.fromJson(JsonUtils.decodeMap(json))
        : null;

    if ((resourceListScreen != null) && mounted) {
      List<GBVResource?> resources = await Future.wait(List.from(resourceListScreen.resourceIds.map((String resourceId) => _loadResourceById(resourceId))));

      Map<String, GBVResource> resourceItems = <String, GBVResource>{};
      for (GBVResource? resource in resources) {
        if (resource != null) {
          resourceItems[resource.id] = resource;
        }
      }

      return _GBVResourceListScreenData(
          resourceListScreen: resourceListScreen,
          resourceItems: resourceItems,
      );
    }
    else {
      return null;
    }
  }

  Future<GBVResource?> _loadResourceById(String id) async {
    // temporary json load from assets
    String? json = await AppBundle.loadString('assets/extra/gbv/$id.json');
    return (json != null)
      ? GBVResource.fromJson(JsonUtils.decodeMap(json))
      : null;
  }
}

class _GBVResourceListScreenData {
  final GBVResourceListScreen resourceListScreen;
  final Map<String, GBVResource> resourceItems;

  _GBVResourceListScreenData({
    required this.resourceListScreen,
    required this.resourceItems,
  });
}

