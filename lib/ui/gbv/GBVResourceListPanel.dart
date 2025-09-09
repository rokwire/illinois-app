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
import 'package:illinois/service/Analytics.dart';

class GBVResourceListPanel extends StatelessWidget {
  final GBVResourceListScreen resourceListScreen;
  final GBVData gbvData;

  GBVResourceListPanel({ super.key, required this.resourceListScreen, required this.gbvData });

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
          Padding(padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), child:
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
    List<GBVResource> filteredResources = List.from(allResources.where((resource) => resourceList.resourceIds.any((id) => id == resource.id)));
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
                  .map((detail) => GBVDetailContentWidget(resourceDetail: detail))
          )
        )
      )
      : Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
        Column(children:
          List.from(resource.directoryContent.map((detail) => GBVDetailContentWidget(resourceDetail: detail)))
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
                  Styles().images.getImage((resource.type == GBVResourceType.external_link) ? 'external-link' : 'chevron-right', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                )
              ])
            )
          )
        )
      );
  }

  void _onTapResource(BuildContext context, GBVResource resource) {
    Analytics().logSelect(target: 'Resource - ${resource.title}');
    switch (resource.type) {
      case GBVResourceType.external_link: {
        GBVResourceDetail? externalLinkDetail = resource.directoryContent.firstWhereOrNull((detail) => detail.type == GBVResourceDetailType.external_link);
        if (externalLinkDetail != null) {
          AppLaunchUrl.launch(context: context, url: externalLinkDetail.content);
        } else break;
      }
      case GBVResourceType.panel: Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: resource))); break;
      case GBVResourceType.directory: Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDirectoryPanel(gbvData: this.gbvData))); break;
    }
  }

  Widget? _buildUrlDetail(BuildContext context) {
    String? url = Config().gbvWeCareUrl;
    return (url != null) ?
    Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), child:
    RichText(text: TextSpan(children: [
      TextSpan(
          text: Localization().getStringEx('panel.sexual_misconduct.resource_list.view_confidential', 'View additional confidential resources on the '),
          style: Styles().textStyles.getTextStyle('panel.gbv.footer.regular.italic')
      ),
      TextSpan(
          text: Localization().getStringEx('panel.sexual_misconduct.resource_list.confidential_we_care', 'Illinois We Care website'),
          style: Styles().textStyles.getTextStyle('panel.gbv.footer.regular.italic.underline'),
          recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(context, url)
      ),
      WidgetSpan(child:
      Padding(padding: EdgeInsets.only(left: 4), child:
      Styles().images.getImage('external-link', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
      )
      )
    ]))
    )
        : null;
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