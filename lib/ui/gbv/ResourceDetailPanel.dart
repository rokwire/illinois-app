import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/gbv/QuickExitWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ResourceDetailPanel extends StatefulWidget {
  final GBVResource resource;

  ResourceDetailPanel({ super.key, required this.resource});

  @override
  State<StatefulWidget> createState() => _ResourceDetailPanelState();

}

class _ResourceDetailPanelState extends State<ResourceDetailPanel> {

  String expandedSection = '';

  @override
  void initState() {
    // _loadResourceScreenData(widget.id).then((_GBVResourceListScreenData? resourceData) {
    //   setStateIfMounted(() {
    //     _loading = false;
    //     _resourceData = resourceData;
    //   });
    // });
    //
    // super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

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
          QuickExitWidget(),
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
        GestureDetector(onTap: () => _expandSection(section), child:
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
                        : (expandedSection == section.title) ? 'chevron-up' : 'chevron-down',
                        width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                  )
              ])
            )
          )
        ),
        Visibility(visible: expandedSection == section.title, child:
          Container(decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1))), child:
            Padding(padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4), child:
              Column(children: List.from(section.content.map((detail) =>
                  Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
                    Row(children: _buildDetailContent(detail))
                  ))
              ))
            )
          )
        )
      ]);
  }

  void _expandSection(GBVDetailListSection section) {
    setState(() {
      this.expandedSection = (expandedSection == section.title) ? '' : section.title;
    });
  }

  List<Widget> _buildDetailContent(GBVResourceDetail detail) {
    switch (detail.type) {
      case GBVResourceDetailType.address:
        return [
          Styles().images.getImage('location', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.email:
        return [
          Styles().images.getImage('envelope', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.external_link:
        return [
          Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.phone:
        return [
          Styles().images.getImage('phone', excludeFromSemantics: true) ?? Container(),
          Padding(padding: EdgeInsets.symmetric(horizontal: 4)),
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
      case GBVResourceDetailType.text:
        return [
          Expanded(child:
            GestureDetector(child: Text(detail.content ?? ''))
          )
        ];
    }
  }

}
