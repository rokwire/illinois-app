import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GBVResourceListPanel extends StatefulWidget {
  final GBVResourceListScreen? resourceListScreen;

  GBVResourceListPanel({ super.key, this.resourceListScreen });

  @override
  State<StatefulWidget> createState() => _GBVResourceListPanelState();

}

class _GBVResourceListPanelState extends State<GBVResourceListPanel> {

  List<Widget> _resourceSections = [];
  bool _loading = true;

  @override
  void initState() {
    _buildResourceSectionList(widget.resourceListScreen).then((_) {
      setState(() {
        _loading = false;
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
          body: (_loading)
          ? _buildLoadingContent()
          : _bodyWidget(widget.resourceListScreen), backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar()
      );

  Widget? _bodyWidget (GBVResourceListScreen? resourceListScreen) {
    return
      SingleChildScrollView(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Padding(padding: EdgeInsets.only(top: 32, left: 16), child: (
              Text(resourceListScreen?.title ?? '', style: Styles().textStyles.getTextStyle("widget.button.title.large.fat")))
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16), child:
            Container(height: 1, color: Styles().colors.surfaceAccent)
          ),
          Padding(padding: EdgeInsets.only(right: 16, left: 16, bottom: 32), child: (
              Text(resourceListScreen?.description ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))
          )),
          ..._resourceSections
        ])
      );
  }
  Widget _resourceWidget (String title, List<GBVResourceDetail> content, GBVResourceType type) {
    Widget descriptionWidget = (content.isNotEmpty)
      ? Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
        Column(children:
          content.map((detail) => Text(detail.content ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))).toList()
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
                  Text(title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
                  ),
                  descriptionWidget
                ])
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
              Styles().images.getImage((type == GBVResourceType.external_link) ? 'external-link' : 'chevron-right', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
              )
            ])
          )
        )
      );
  }

  Future<GBVResource?> _getResourceById(String id) async {
    // temporary json load from assets
    String? json = await AppBundle.loadString('assets/extra/gbv/$id.json');
    return (json != null)
      ? GBVResource.fromJson(JsonUtils.decodeMap(json))
      : null;
  }

  Future<Widget> _buildResourceSection(GBVResourceList resourceList) async {
      Iterable<Future<Widget>> resourceFutures = resourceList.resourceIds.map((id) async {
        GBVResource? resource = await _getResourceById(id);
        return (resource != null)
            ? _resourceWidget(resource.title, resource.directoryContent, resource.type)
            : Container();
      });
      List<Widget> resources = await Future.wait(resourceFutures);
      print(resources.length);
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

  Future<void> _buildResourceSectionList (GBVResourceListScreen? resourceListScreen) async {
    if (resourceListScreen != null && resourceListScreen.content != null) {
      resourceListScreen.content!.forEach((resourceList) async {
        _resourceSections.add(await _buildResourceSection(resourceList));
      });
    } 
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          CircularProgressIndicator(),
          Container(height: MediaQuery.of(context).size.height / 5 * 3)
        ]));
  }

}