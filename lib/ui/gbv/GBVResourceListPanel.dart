import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/GBVDetailContentWidget.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceDirectoryPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Config.dart';

class GBVResourceListPanel extends StatelessWidget {
  final GBVResourceListScreen resourceListScreen;
  final GBVData gbvData;
  final bool showDirectoryLink;

  GBVResourceListPanel({ super.key, required this.resourceListScreen, required this.gbvData, this.showDirectoryLink = false}); // Default to false to not impact current references

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: HeaderBar(),
          body: _bodyWidget(context, this.resourceListScreen, this.gbvData.resources),
          backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar()
      );

  Widget _bodyWidget (BuildContext context, GBVResourceListScreen resourceListScreen, List<GBVResource> resources) {
    return
      SingleChildScrollView(child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          GBVQuickExitWidget(),
          Padding(padding: EdgeInsets.only(top: 16, left: 16), child: (
              Text(resourceListScreen.title ?? '', style: Styles().textStyles.getTextStyle("widget.button.title.large.fat")))
          ),
          Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 16), child:
          Container(height: 1, color: Styles().colors.surfaceAccent)
          ),
          Padding(padding: EdgeInsets.only(right: 16, left: 16, bottom: 0), child: (
              Text(resourceListScreen.description ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))
          )),
          ...resourceListScreen.content.map((section) => _buildResourceSection(context, section, resources)),
          _buildUrlDetail(context) ?? Container()
        ])
      );
  }

  Widget _buildResourceSection(BuildContext context, GBVResourceList resourceList, List<GBVResource> allResources) {
    List<GBVResource> filteredResources = resourceList.resourceIds
        .map((id) => allResources.firstWhereOrNull((resource) => resource.id == id))
        .whereType<GBVResource>()
        .toList();
    List<Widget> resources = filteredResources.map((resource) => _resourceWidget(context, resource)).toList();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      (resourceList.title != '')
          ? Padding(padding: EdgeInsets.only(top: 30, left: 16, right: 16), child: (
          Text(resourceList.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"))
      ))
          : Container(),
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), child:
      Column(children: resources)
      )
    ]);

  }

  Widget _resourceWidget (BuildContext context, GBVResource resource) {
    Widget descriptionWidget = (resource.type == GBVResourceType.external_link)
      ? Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(children:
          List.from(
              resource.directoryContent.where((detail) => detail.type != GBVResourceDetailType.external_link)
                  .map((detail) => GBVDetailContentWidget(resourceDetail: detail, isTextSelectable: false))
          )
        )
      )
      : Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(children:
          List.from(resource.directoryContent.map((detail) => GBVDetailContentWidget(resourceDetail: detail, isTextSelectable: false)))
        )
      );
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
                  (resource.type != GBVResourceType.external_link)
                    ? Styles().images.getImage('chevron-right', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                    : (resource.directoryContent.any((detail) => detail.type == GBVResourceDetailType.external_link))
                    ? Styles().images.getImage('external-link', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                    : Container()
                )
              ])
            )
          )
        )
      );
  }

  void _navigateToDirectory(BuildContext context) {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => GBVResourceDirectoryPanel(gbvData: this.gbvData)
        )
    );
  }


  void _onTapResource(BuildContext context, GBVResource resource) {
    switch (resource.type) {
      case GBVResourceType.external_link: {
        GBVResourceDetail? externalLinkDetail = resource.directoryContent.firstWhereOrNull((detail) => detail.type == GBVResourceDetailType.external_link);
        if (externalLinkDetail != null) {
          AppLaunchUrl.launch(context: context, url: externalLinkDetail.content);
        } else break;
      }
      case GBVResourceType.panel: Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: resource))); break;
      case GBVResourceType.directory: Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDirectoryPanel(gbvData: this.gbvData))); break;
      case GBVResourceType.resource_list: {
            GBVResourceListScreen? targetScreen = (resource.resourceScreenId == "supporting_a_friend") ?
            gbvData.resourceListScreens?.supportingAFriend : null;
            if (targetScreen != null){
            Navigator.push(context,
            CupertinoPageRoute(builder: (context) =>
            GBVResourceListPanel(gbvData: gbvData,
            resourceListScreen: targetScreen)));
            } else break;
      }
    }
  }

  Widget? _buildUrlDetail(BuildContext context) {
    if (showDirectoryLink) {
      return Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), child:
        Align(alignment: Alignment.center, child:
          RichText(textAlign: TextAlign.center, text: TextSpan(children: [
            TextSpan(
                text: Localization().getStringEx('', 'For more options, view the '),
                style: Styles().textStyles.getTextStyle('widget.description.regular')
            ),
            TextSpan(
              text: Localization().getStringEx('', 'Resource Directory.'),
              style: Styles().textStyles.getTextStyle('widget.description.regular.underline'),
              recognizer: TapGestureRecognizer()..onTap = () => _navigateToDirectory(context)
            )
          ]))
        )
      );
    } else {
      // Original Illinois We Care URL logic
      String? url = Config().gbvWeCareResourcesUrl;
      return (resourceListScreen == gbvData.resourceListScreens?.confidentialResources && url != null) ?
      Padding(
          padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          child: RichText(
              text: TextSpan(
                  children: [
                    TextSpan(
                        text: Localization().getStringEx('', 'View additional confidential resources on the '),
                        style: Styles().textStyles.getTextStyle('panel.gbv.footer.regular.italic')
                    ),
                    TextSpan(
                        text: Localization().getStringEx('', 'Illinois We Care website'),
                        style: Styles().textStyles.getTextStyle('panel.gbv.footer.regular.italic.underline'),
                        recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(context, url)
                    ),
                    WidgetSpan(
                        child: Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Styles().images.getImage('external-link', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                        )
                    )
                  ]
              )
          )
      ) : null;
    }
  }


  void _launchUrl(BuildContext context, String? url) async {
    if (StringUtils.isNotEmpty(url)) {
      if (StringUtils.isNotEmpty(url)) {
        Uri? uri = Uri.tryParse(url!);
        if ((uri != null) && (await canLaunchUrl(uri))) {
          AppLaunchUrl.launch(context: context, url: url);
        }
      }
    }
  }
}