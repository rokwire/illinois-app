import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/GBVDetailContentWidget.dart';
import 'package:illinois/ui/gbv/QuickExitWidget.dart';
import 'package:illinois/ui/gbv/ResourceDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';

class ResourceDirectoryPanel extends StatefulWidget {
  final List<String> categories;
  final List<GBVResource> resources;

  ResourceDirectoryPanel({ super.key, required this.categories, required this.resources });

  @override
  State<StatefulWidget> createState() => _ResourceDirectoryPanelState();

}

class _ResourceDirectoryPanelState extends State<ResourceDirectoryPanel> {

  String _expandedSection = '';

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
      Scaffold(appBar: HeaderBar(title: 'Resource Directory'),
          body: _bodyWidget(),
          backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar()
      );

  Widget _bodyWidget () {
    return
      SingleChildScrollView(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          QuickExitWidget(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            Column(children: [
            ...widget.categories.map((category) => _buildCategory(category, widget.resources))
            ])
          )
        ])
      );
  }

  Widget _buildCategory(String category, List<GBVResource> allResources) {
    List<GBVResource> resources = List.from(allResources.where((resource) => category == resource.category));
    return
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Container(decoration:
          BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ), child:
          Column(children: [
            GestureDetector(onTap: () => _expandSection(category), child:
            Container(decoration: BoxDecoration(), child:
            Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
            Row(mainAxisAlignment: MainAxisAlignment.start, children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                Styles().images.getImage((_expandedSection == category) ? 'chevron-up' : 'chevron-down', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
              ),
              Text(category, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
            ])
            )
            )
            ),
            Visibility(visible: _expandedSection == category, child:
              Padding(padding: EdgeInsets.only(bottom: 8), child:
                Column(children:
                 List.from(resources.map((resource) => _resourceWidget(resource)))
                )
              )
            )
          ])
        )
      );
  }

  Widget _resourceWidget (GBVResource resource) {
    Widget descriptionWidget = (resource.directoryContent.isNotEmpty)
      ? Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
        Column(children:
          List.from(resource.directoryContent.map((detail) => GBVDetailContentWidget(resourceDetail: detail)))
        )
      )
      : Container();
    return
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        Container(decoration:
          BoxDecoration(
            color: Styles().colors.white,
            border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
          ), child:
          Padding(padding: EdgeInsets.only(top: 20), child:
            Row(children: [
              Expanded(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Padding(padding: EdgeInsets.only(left: 16), child:
                    Text(resource.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
                  ),
                  descriptionWidget
                ])
              ),
              GestureDetector(onTap: () => _onTapResource(resource), child:
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: (resource.type == GBVResourceType.panel)
                  ? Styles().images.getImage('chevron-right', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                  : (resource.directoryContent.any((detail) => detail.type == GBVResourceDetailType.external_link))
                    ? Styles().images.getImage('external-link', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                    : Container()
                  // Styles().images.getImage((resource.type == GBVResourceType.panel) ? 'chevron-right' : (resource.directoryContent.any((detail) => detail.type == GBVResourceDetailType.external_link) ? 'external-link' : ''), width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                )
              )
            ])
          )
        )
      );
  }

  void _expandSection(String category) {
    setState(() {
      this._expandedSection = (_expandedSection == category) ? '' : category;
    });
  }

  void _onTapResource(GBVResource resource) {
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourceDetailPanel(resource: resource)));
  }

}