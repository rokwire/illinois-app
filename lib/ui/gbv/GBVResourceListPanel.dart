import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/GBVDetailContentWidget.dart';
import 'package:illinois/ui/gbv/QuickExitWidget.dart';
import 'package:illinois/ui/gbv/ResourceDetailPanel.dart';
import 'package:illinois/ui/gbv/ResourceDirectoryPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/utils/AppUtils.dart';

class GBVResourceListPanel extends StatelessWidget {
  final GBVResourceListScreen resourceListScreen;
  final List<GBVResource> resources;
  final List<String> categories;

  GBVResourceListPanel({ super.key, required this.resourceListScreen, required this.resources, required this.categories });

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: HeaderBar(),
          body: _bodyWidget(context, this.resourceListScreen, this.resources),
          backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar()
      );

  Widget _bodyWidget (BuildContext context, GBVResourceListScreen resourceListScreen, List<GBVResource> resources) {
    return
      SingleChildScrollView(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          QuickExitWidget(),
          Padding(padding: EdgeInsets.only(top: 16, left: 16), child: (
              Text(resourceListScreen.title ?? '', style: Styles().textStyles.getTextStyle("widget.button.title.large.fat")))
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16), child:
          Container(height: 1, color: Styles().colors.surfaceAccent)
          ),
          Padding(padding: EdgeInsets.only(right: 16, left: 16, bottom: 32), child: (
              Text(resourceListScreen.description ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))
          )),
          ...resourceListScreen.content.map((section) => _buildResourceSection(context, section, resources))
        ])
      );
  }

  Widget _buildResourceSection(BuildContext context, GBVResourceList resourceList, List<GBVResource> allResources) {
    List<GBVResource> filteredResources = List.from(allResources.where((resource) => resourceList.resourceIds.any((id) => id == resource.id)));
    List<Widget> resources = filteredResources.map((resource) => _resourceWidget(context, resource)).toList();

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

  Widget _resourceWidget (BuildContext context, GBVResource resource) {
    Widget descriptionWidget = (resource.directoryContent.isNotEmpty)
      ? Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 8), child:
        Column(children:
          List.from(resource.directoryContent.map((detail) => GBVDetailContentWidget(resourceDetail: detail)))
        )
      )
      : Container();
    return
      Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
        GestureDetector(onTap: () => _onTapResource(context, resource), child:
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
        )
      );
  }

  // void _onTapResource(BuildContext context, GBVResource resource) {
  //   Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourceDetailPanel(resource: resource)));
  // }

  void _onTapResource(BuildContext context, GBVResource resource) {
    switch (resource.type) {
      case GBVResourceType.external_link: {
        GBVResourceDetail? externalLinkDetail = resource.directoryContent.firstWhereOrNull((detail) => detail.type == GBVResourceDetailType.external_link);
        if (externalLinkDetail != null) {
          AppLaunchUrl.launch(context: context, url: externalLinkDetail.content);
        } else break;
      }
      case GBVResourceType.panel: Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourceDetailPanel(resource: resource))); break;
      case GBVResourceType.directory: Navigator.push(context, CupertinoPageRoute(builder: (context) => ResourceDirectoryPanel(resources: this.resources, categories: this.categories))); break;
    }
  }
}