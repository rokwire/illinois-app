import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/gbv/GBVDetailContentWidget.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GBVResourceDetailPanel extends StatefulWidget {
  final GBVResource resource;

  GBVResourceDetailPanel({ super.key, required this.resource});

  @override
  State<StatefulWidget> createState() => _GBVResourceDetailPanelState();

}

class _GBVResourceDetailPanelState extends State<GBVResourceDetailPanel> {

  List<String> _expandedSections = [];

  @override
  Widget build(BuildContext context) =>
      Scaffold(appBar: HeaderBar(),
          body: _scaffoldContentWidget(),
          backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar()
      );

  Widget _scaffoldContentWidget () {
    List<Widget> sections = (widget.resource.detailsList != null)
      ? List.from(widget.resource.detailsList!.map((x) => _buildResourceDetailSection(x)))
      : [];

    return
      SingleChildScrollView(child:
        Column(children: [
          GBVQuickExitWidget(),
            Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                  Text(widget.resource.title, style: Styles().textStyles.getTextStyle("widget.button.title.large.fat")),
                Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                Container(height: 1, color: Styles().colors.surfaceAccent)
                ),
                Padding(padding: EdgeInsets.only(bottom: 32), child:
                    HtmlWidget(widget.resource.description ?? '',
                        textStyle: Styles().textStyles.getTextStyle("widget.detail.regular"),
                        customStylesBuilder: (element) => (element.localName == "a") ? _htmlLinkStyle : null,
                        onTapUrl: _onTapHtmlLink,
                    )
                ),
                Container(decoration:
                  BoxDecoration(
                  color: Styles().colors.white,
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                ), child: Column(children: [...sections]))
              ])
            )
        ])
      );
  }

  Widget _buildResourceDetailSection(GBVDetailListSection section) {
    bool isExternalLink = (section.content.length == 1 && section.content[0].type == GBVResourceDetailType.external_link);
    return
      Column(children: [
        GestureDetector(onTap: (isExternalLink) ? () => AppLaunchUrl.launch(context: context, url: section.content[0].content) : () => _expandSection(section), child:
          Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1))), child:
            Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
              Row(children: [
                Expanded(child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    if (section.label != null)
                      Padding(padding: EdgeInsets.only(left: 16), child:
                        Text(section.label ?? '', style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat.secondary"))
                      ),
                    Padding(padding: EdgeInsets.only(left: 16), child:
                      Text(section.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
                    ),
                  ])
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                    Styles().images.getImage((isExternalLink)
                        ? 'external-link'
                        : (_expandedSections.contains(section.title)) ? 'chevron-up' : 'chevron-down',
                        width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                  )
              ])
            )
          )
        ),
        Visibility(visible: _expandedSections.contains(section.title), child:
          Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1))), child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4), child:
              Column(children: List.from(section.content.map((detail) =>
                GBVDetailContentWidget(resourceDetail: detail)
              )))
            )
          )
        )
      ]);
  }

  void _expandSection(GBVDetailListSection section) {
    setState(() {
      if (_expandedSections.contains(section.title)) this._expandedSections.remove(section.title);
      else {
        Analytics().logSelect(target: 'Expand detail section - ${section.title}');
        this._expandedSections.add(section.title);
      }
    });
  }

  Map<String, String> get _htmlLinkStyle => <String, String>{
    // 'color': _htmlLinkColor,
    'text-decoration-color': _htmlLinkColor,
  };

  String get _htmlLinkColor =>
      ColorUtils.toHex(Styles().colors.fillColorSecondary);

  bool _onTapHtmlLink(String url)  {
    Analytics().logSelect(target: 'Link: $url');
    if (DeepLink().isAppUrl(url)) {
      DeepLink().launchUrl(url);
    } else {
      AppLaunchUrl.launchExternal(url: url);
    }
    return true;
  }
}
