import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/GBVDetailContentWidget.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/utils/AppUtils.dart';

class GBVResourceDetailPanel extends StatefulWidget {
  final GBVResource resource;

  GBVResourceDetailPanel({ super.key, required this.resource});

  @override
  State<StatefulWidget> createState() => _GBVResourceDetailPanelState();

}

class _GBVResourceDetailPanelState extends State<GBVResourceDetailPanel> {

  String _expandedSection = '';

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
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                // Padding(padding: EdgeInsets.only(top: 16, left: 16), child: (
                    Text(widget.resource.title, style: Styles().textStyles.getTextStyle("widget.button.title.large.fat")),
                // ),
                Padding(padding: EdgeInsets.symmetric(vertical: 4, horizontal: 0), child:
                Container(height: 1, color: Styles().colors.surfaceAccent)
                ),
                Padding(padding: EdgeInsets.only(right: 0, left: 0, bottom: 32), child: (
                    Text(widget.resource.description ?? '', style: Styles().textStyles.getTextStyle("widget.detail.regular"))
                )),
                Padding(padding: EdgeInsets.symmetric(horizontal: 0), child:
                  Container(decoration:
                    BoxDecoration(
                    color: Styles().colors.white,
                    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ), child: Column(children: [
                  ...sections
                    ])
                  )
                )
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
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Padding(padding: EdgeInsets.only(left: 16), child:
                      Text(section.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
                    ),
                  ])
                  ),
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                    Styles().images.getImage((isExternalLink)
                        ? 'external-link'
                        : (_expandedSection == section.title) ? 'chevron-up' : 'chevron-down',
                        width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                  )
              ])
            )
          )
        ),
        Visibility(visible: _expandedSection == section.title, child:
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
      this._expandedSection = (_expandedSection == section.title) ? '' : section.title;
    });
  }

}
