import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/GBV.dart';
import 'package:illinois/ui/gbv/GBVDetailContentWidget.dart';
import 'package:illinois/ui/gbv/GBVQuickExitWidget.dart';
import 'package:illinois/ui/gbv/GBVResourceDetailPanel.dart';
import 'package:illinois/ui/gbv/GBVResourceListPanel.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/model/GBV.dart';
import 'package:illinois/service/Config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/service/Analytics.dart';

class GBVResourceDirectoryPanel extends StatelessWidget {
  final GBVData gbvData;
  final String? favoriteKey;
  final String? favoriteCategory;

  GBVResourceDirectoryPanel({ super.key, required this.gbvData, this.favoriteKey, this.favoriteCategory});

  @override
  Widget build(BuildContext context) =>
    Scaffold(appBar: HeaderBar(title: 'Resource Directory'),
      body: _buildBody(context),
      backgroundColor: Styles().colors.background, bottomNavigationBar: uiuc.TabBar()
    );

  Widget _buildBody(BuildContext context) =>
    SingleChildScrollView(child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        GBVQuickExitWidget(),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
          GBVResourceDirectoryWidget(gbvData: gbvData, favoriteKey: favoriteKey, favoriteCategory: favoriteCategory,)
        ),
        _buildWeCareUrlWidget(context) ?? Container()
      ])
    );

  Widget? _buildWeCareUrlWidget(BuildContext context) {
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
              recognizer: TapGestureRecognizer()..onTap = () => _launchUrl(context, url)
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

class GBVResourceDirectoryWidget extends StatefulWidget {
  final GBVData gbvData;
  final String? favoriteKey;
  final String? favoriteCategory;

  GBVResourceDirectoryWidget({ super.key, required this.gbvData, this.favoriteKey, this.favoriteCategory });

  @override
  State<StatefulWidget> createState() => _GBVResourceDirectoryWidgetState();

}

class _GBVResourceDirectoryWidgetState extends State<GBVResourceDirectoryWidget> with NotificationsListener {

  List<String> _expandedSections = [];

  bool get _canFavorite => true && (widget.favoriteKey != null);

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged
    ]);
    if (widget.gbvData.directoryCategories.length == 1) {
      _expandedSections.add(widget.gbvData.directoryCategories.first);
    }
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    ...widget.gbvData.directoryCategories.map((category) => _buildCategory(category, widget.gbvData.resources)),
  ]);

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
              Padding(padding: EdgeInsets.symmetric(vertical: 20), child:
                Row(mainAxisAlignment: MainAxisAlignment.start, children: [
                  Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                    Styles().images.getImage((_expandedSections.contains(category)) ? 'chevron-up' : 'chevron-down', width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                  ),
                  Expanded(child:
                    Padding(padding: EdgeInsets.only(right: 16), child:
                      Text(category, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
                    )
                  )
                ])
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

  Widget _resourceWidget(GBVResource resource) {
    Iterable<GBVResourceDetail> descriptionDetails = (resource.type.isLink) ? resource.directoryNotLinkContent : resource.directoryContent;

    Widget contentWidget;
    if (descriptionDetails.isNotEmpty) {
      TextStyle? titleTextStyle = Styles().textStyles.getTextStyle("widget.button.title.medium.fat");
      double favTitleOffsetY = max(FavoriteStarIcon.defaultButtonSize - MediaQuery.of(context).textScaler.scale(titleTextStyle?.fontSize ?? 0) * 1.5, 0) / 2;
      contentWidget = Padding(padding: _canFavorite ? EdgeInsets.zero : EdgeInsets.only(bottom: 4), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (_canFavorite)
            FavoriteButton(style: FavoriteIconStyle.Button, favorite: GBVResourceFavorite(key: widget.favoriteKey ?? '', category: widget.favoriteCategory, id: resource.id),),
          Expanded(child:
            Row(children: [
              Expanded(child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                  Padding(padding: _canFavorite ? EdgeInsets.only(top: favTitleOffsetY) : EdgeInsets.only(left: 16, top: 16), child:
                    Text(resource.title, style: titleTextStyle)
                  ),
                  Padding(padding: _canFavorite ? EdgeInsets.zero : EdgeInsets.only(left: 16), child:
                    Column(children:
                      List.from(descriptionDetails.map((detail) => GBVDetailContentWidget(resourceDetail: detail, isTextSelectable: false)))
                    ),
                  ),
                ])
              ),
              Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
                Styles().images.getImage(resource.chevronIconKey, width: 16, height: 16, fit: BoxFit.contain) ?? Container()
              )
            ]),
          )
        ]),
      );
    } else {
      contentWidget = Row(children: [
        if (_canFavorite)
          FavoriteButton(style: FavoriteIconStyle.Button, favorite: GBVResourceFavorite(key: widget.favoriteKey ?? '', category: widget.favoriteCategory, id: resource.id),),
        Expanded(child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: _canFavorite ? EdgeInsets.zero : EdgeInsets.only(left: 16, top: 16, bottom: 16), child:
              Text(resource.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"))
            ),
          ])
        ),
        Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
          Styles().images.getImage(resource.chevronIconKey, width: 16, height: 16, fit: BoxFit.contain) ?? Container()
        )
      ]);
    }

    BoxDecoration contentDecoration = BoxDecoration(
      color: Styles().colors.white,
      border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
    );

    return GestureDetector(onTap: () => _onTapResource(resource), child:
      Container(decoration: contentDecoration, child: contentWidget)
    );
  }

  // ignore: unused_element
  Widget _resourceWidget2(GBVResource resource) {
    Widget titleTextWidget = Text(resource.title, style: Styles().textStyles.getTextStyle("widget.button.title.medium.fat"));
    Widget titleWidget = _canFavorite ?
      Row(children: [
        FavoriteButton(style: FavoriteIconStyle.Button, favorite: GBVResourceFavorite(key: widget.favoriteKey ?? '', category: widget.favoriteCategory, id: resource.id),),
        Expanded(child:
          Padding(padding: EdgeInsetsGeometry.symmetric(vertical: 4), child:
            titleTextWidget
          )
        )
      ],) :
      Padding(padding: EdgeInsets.only(left: 16), child:
        titleTextWidget
      );

    EdgeInsets descriptionPadding = EdgeInsets.only(left: _canFavorite ? FavoriteStarIcon.defaultButtonSize : 16 /*, right: 16 */);
    Iterable<GBVResourceDetail> resourceDetails = (resource.type.isLink) ? resource.directoryNotLinkContent : resource.directoryContent;
    Widget descriptionWidget = Padding(padding: descriptionPadding, child:
      Column(children:
        List.from(resourceDetails.map((detail) => GBVDetailContentWidget(resourceDetail: detail, isTextSelectable: false)))
      )
    );
    return
        GestureDetector(onTap: () => _onTapResource(resource), child:
          Container(decoration:
            BoxDecoration(
              color: Styles().colors.white,
              border: Border(top: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
            ), child:
            Padding(padding: EdgeInsets.only(top: _canFavorite ? 0 : 16, bottom: _canFavorite ? 0 : (resourceDetails.isNotEmpty ? 4 : 16)), child:
              Row(children: [
                Expanded(child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    titleWidget,
                    descriptionWidget
                  ])
                ),
                Padding(padding: EdgeInsets.symmetric(horizontal: 8), child:
                  Styles().images.getImage(resource.chevronIconKey, width: 16, height: 16, fit: BoxFit.contain) ?? Container()
                )
              ])
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
        GBVResourceDetail? linkDetail = resource.externalOrInternalLinkDetail;
        if (linkDetail != null) {
          AppLaunchUrl.launch(context: context, url: linkDetail.content);
        } else break;
      }
      case GBVResourceType.internal_link: {
        GBVResourceDetail? linkDetail = resource.internalOrExternalLinkDetail;
        if (linkDetail != null) {
          AppLaunchUrl.launch(context: context, url: linkDetail.content);
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
}