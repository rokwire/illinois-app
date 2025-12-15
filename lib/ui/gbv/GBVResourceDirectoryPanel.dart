import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/GBVDetailContentWidget.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Analytics.dart';

class GBVResourceDirectoryPanel extends StatefulWidget {
  final GBVData gbvData;

  GBVResourceDirectoryPanel({ super.key, required this.gbvData});

  @override
  State<StatefulWidget> createState() => _GBVResourceDirectoryPanelState();

}

class _GBVResourceDirectoryPanelState extends State<GBVResourceDirectoryPanel> {

  List<String> _expandedSections = [];

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
          GBVQuickExitWidget(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            Column(children: [
              ...widget.gbvData.directoryCategories.map((category) => _buildCategory(category, widget.gbvData.resources)),
            ])
          ),
          _buildWeCareUrlWidget() ?? Container()
        ])
      );
  }

  Widget _buildCategory(String category, List<GBVResource> allResources) {
    List<GBVResource> resources = List.from(allResources.where((resource) => resource.categories.contains(category)));
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
                Styles().images.getImage((_expandedSections.contains(category)) ? 'chevron-up' : 'chevron-down', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
              ),
              Text(category, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
            ])
            )
            )
            ),
            Visibility(visible: _expandedSections.contains(category), child:
              Padding(padding: EdgeInsets.only(bottom: 8), child:
                Column(children:
                 List.from(resources.map((resource) => _resourceWidget(resource)))
                )
              )
            ),
          ])
        )
      );
  }

  Widget _resourceWidget (GBVResource resource) {
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
        GestureDetector(onTap: () => _onTapResource(resource), child:
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
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
                  (resource.type != GBVResourceType.external_link)
                    ? Styles().images.getImage('chevron-right', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                    : (resource.directoryContent.any((detail) => detail.type == GBVResourceDetailType.external_link)) ? Semantics(
                    label: Localization().getStringEx('panel.sexual_misconduct.resource_directory.external_link_icon', 'Opens in external browser'), image: true,
                    child: Styles().images.getImage('external-link', width: 16, height: 16, fit: BoxFit.contain) ?? Container(),
                    ): Container()
                )
              ])
            )
          )
        )
      );
  }

  void _expandSection(String section) {
    setState(() {
      if (_expandedSections.contains(section)) this._expandedSections.remove(section);
      else this._expandedSections.add(section);
    });
  }

  void _onTapResource(GBVResource resource) {
    Analytics().logSelect(target: 'Resource - ${resource.title}');
    switch (resource.type) {
      case GBVResourceType.external_link: {
        GBVResourceDetail? externalLinkDetail = resource.directoryContent.firstWhereOrNull((detail) => detail.type == GBVResourceDetailType.external_link);
        if (externalLinkDetail != null) {
          AppLaunchUrl.launch(context: context, url: externalLinkDetail.content);
        } else break;
      }
      case GBVResourceType.panel: Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceDetailPanel(resource: resource))); break;
      case GBVResourceType.directory: break;
      case GBVResourceType.resource_list: {
        GBVResourceListScreen? targetScreen = (resource.resourceScreenId == "supporting_a_friend") ?
        widget.gbvData.resourceListScreens?.supportingAFriend : null;
        if (targetScreen != null){
          Navigator.push(context, CupertinoPageRoute(builder: (context) => GBVResourceListPanel(gbvData: widget.gbvData, resourceListScreen: targetScreen)));
        } else break;
      }
      }
    }

  Widget? _buildWeCareUrlWidget() {
    String? url = Config().gbvWeCareResourcesUrl;
    return (url != null) ?
      Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), child:
            RichText(text: TextSpan(children: [
              TextSpan(
                text: Localization().getStringEx('panel.sexual_misconduct.resource_directory.view_additional', 'View additional resources on the '),
                style: Styles().textStyles.getTextStyle('panel.gbv.footer.regular.italic')
                ),
              TextSpan(
              text: Localization().getStringEx('panel.sexual_misconduct.resource_directory.we_care', 'Illinois We Care website'),
              style: Styles().textStyles.getTextStyle('panel.gbv.footer.regular.italic.underline'),
              recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(url)
              ),
              WidgetSpan(child: Semantics(
                label: Localization().getStringEx('panel.sexual_misconduct.resource_directory.external_link_icon', 'Opens directory in browser'),
                image: true, child: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images.getImage('external-link', width: 16, height: 16, fit: BoxFit.contain) ?? Container()),
              )
              )
            ]))
      )
      : null;
  }

  void _launchUrl(String? url) async {
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