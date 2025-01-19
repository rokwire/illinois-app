import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../service/Wellness.dart';

class WellnessRecreationContentWidget extends StatefulWidget{
  static const String wellnessCategoryKey = 'recreation';
  final String wellnessCategory = wellnessCategoryKey;

  @override
  State<StatefulWidget> createState() => _WellnessRecreationContent();

}

class _WellnessRecreationContent extends State<WellnessRecreationContentWidget> implements NotificationsListener {
  Map<String, dynamic>? _video;
  List<dynamic>? _commands;
  Map<String, dynamic>? _strings;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      Wellness.notifyRecreationContentChanged,
    ]);
    _initContent();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  void onNotification(String name, dynamic param) {
    if (name == Wellness.notifyResourcesContentChanged) {
      if (mounted) {
        setState(() {
          _initContent();
        });
      }
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted((){});
    }
  }

  @override
  Widget build(BuildContext context) {
    return _buildContent();
  }

  Widget _buildContent() {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Column(children: [
      _buildRegularButtonsContainer(),
    ]));
  }

  Widget _buildRegularButtonsContainer() {
    List<Widget> widgetList = <Widget>[];
    if (_commands != null) {
      for (dynamic entry in _commands!) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? type = JsonUtils.stringValue(command['type']);
          if (type == 'regular') {
            if (widgetList.isNotEmpty) {
              widgetList.add(Divider(color: Styles().colors.surfaceAccent, height: 1,));
            }
            String? id = JsonUtils.stringValue(command['id']);
            Favorite favorite = WellnessFavorite(id, category: widget.wellnessCategory);
            bool? externalLink = JsonUtils.boolValue(command['external_link']);
            bool? chevron = JsonUtils.boolValue(command['chevron']);
            widgetList.add(WellnessRegularResourceButton(
              label: _getString(id),
              favorite: favorite,
              hasChevron: chevron ?? true,
              hasExternalLink: externalLink ?? UrlUtils.isWebScheme(JsonUtils.stringValue(command['url'])),
              onTap: () => _onCommand(command),
            ));
          }
        }
      }
    }

    return Container(decoration: BoxDecoration(color: Styles().colors.white, border: Border.all(color: Styles().colors.surfaceAccent, width: 1), borderRadius: BorderRadius.circular(5)), child:
    Column(children: widgetList)
    );

  }

  void _onCommand(Map<String, dynamic> command) {
    Analytics().logSelect(
        target: _getString(JsonUtils.stringValue(command['id']), languageCode: Localization().defaultLocale?.languageCode),
        source: widget.runtimeType.toString()
    );

    String? url = JsonUtils.stringValue(command['url']);
    if (StringUtils.isNotEmpty(url)) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  void _initContent() async {
    // Map<String, dynamic>? content = Wellness().resources;
    Map<String, dynamic>? content = JsonUtils.mapValue(JsonUtils.mapValue(await _loadContentFromAsset)?[WellnessRecreationContentWidget.wellnessCategoryKey]);
    _video = (content != null) ? JsonUtils.mapValue(content['video']) : null;
    _commands = (content != null) ? JsonUtils.listValue(content['commands']) : null;
    _strings = (content != null) ? JsonUtils.mapValue(content['strings']) : null;
    WellnessResourcesContentWidget.ensureDefaultFavorites(_commands, category: widget.wellnessCategory);
    setStateIfMounted();
  }

  String? _getString(String? key, {String? languageCode}) {
    if ((_strings != null) && (key != null)) {
      Map<String, dynamic>? mapping =
          JsonUtils.mapValue(_strings![languageCode]) ??
              JsonUtils.mapValue(_strings![Localization().currentLocale?.languageCode]) ??
              JsonUtils.mapValue(_strings![Localization().defaultLocale?.languageCode]);
      if (mapping != null) {
        return JsonUtils.stringValue(mapping[key]);
      }
    }
    return null;
  }

  @protected
  Future<Map<String, dynamic>?> loadFromAssets(String assetsKey) async {
    try { return JsonUtils.decodeMap(await rootBundle.loadString(assetsKey)); }
    catch(e) { debugPrint(e.toString()); }
    return null;
  }

  static const String _assetsName   = "wellness.json";
  String get appAssetsKey => 'assets/extra/$_assetsName';

  //TBD load from wellness service - content
  Future<Map<String, dynamic>?> get _loadContentFromAsset async => await loadFromAssets(appAssetsKey);
}