import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';

class GBVResourceListPanel extends StatefulWidget {
  final GBVResourceListScreen? resourceListScreen;

  GBVResourceListPanel({ super.key, this.resourceListScreen });

  @override
  State<StatefulWidget> createState() => _GBVResourceListPanelState();

}

class _GBVResourceListPanelState extends State<GBVResourceListPanel> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: HeaderBar(title: Localization().getStringEx('panel.safety.header.title', 'Safety')), body: _bodyWidget(widget.resourceListScreen), backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar());

  Widget? _bodyWidget (GBVResourceListScreen? resourceListScreen) {
    List<Widget> resourceSections = resourceListScreen?.content?.map((resourceList) {
      List<Widget> resources = resourceList.resourceIds.map((id) {
        GBVResource resource = _getResourceById(id);
        return _resourceWidget(
            resource.title, resource.directoryContent, resource.type);
        }
      ).toList();
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        (resourceList?.title != '')
        ? Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: (
          Text(resourceList.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"))
        ))
        : Container(),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
          Column(children: resources)
        )
      ]);
    }).toList() ?? [];
    return
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(top: 32, left: 16), child: (
            Text(resourceListScreen?.title ?? '', style: Styles().textStyles.getTextStyle("widget.button.title.large.fat")))
        ),
        Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16,), child:
          Container(height: 1, color: Styles().colors.surfaceAccent)
        ),
        Padding(padding: EdgeInsets.only(left: 16, bottom: 32), child: (
            Text(resourceListScreen?.description ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))
        )),
        ...resourceSections
      ]);
}
  Widget _resourceWidget (String title, List<GBVResourceDetail> content, GBVResourceType type) {
    Widget descriptionWidget = (content.isNotEmpty)
      ? Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
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
          Row(children: [
            Expanded(child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Padding(padding: EdgeInsets.only(left: 16, top: 12), child:
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
      );
  }

  GBVResource _getResourceById(String id) {
    // Fetch GBVResource json by id and deserialize here
    return GBVResource(id: id, type: GBVResourceType.panel, title: "Test Resource", directoryContent: []);
  }

}