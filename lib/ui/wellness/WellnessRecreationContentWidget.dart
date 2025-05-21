import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Video.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/apphelp/AppHelpVideoTutorialPanel.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/ui/wellness/WellnessResourcesContentWidget.dart';
import 'package:illinois/ui/widgets/VideoPlayButton.dart';
import 'package:illinois/ui/widgets/WebNetworkImage.dart';
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

class _WellnessRecreationContent extends State<WellnessRecreationContentWidget> with NotificationsListener {
  Video? _video;
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
    if (name == Wellness.notifyRecreationContentChanged) {
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
      _buildVideoContent,
      Container(height: 16,),
      _buildRegularButtonsContainer(),
      Container(height: 8,),
      _buildLargeButtonsContainer()
    ]));
  }

  Widget get _buildVideoContent {
    if (_video == null) {
      return Container();
    }
    String? imageUrl = _video!.thumbUrl;
    bool hasImage = StringUtils.isNotEmpty(imageUrl);
    final Widget emptyImagePlaceholder = Container(height: 102);
    return Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4))),
        child: Stack(children: [
          Semantics(button: true,
              label: "${_video!.title ?? ""} video",
              child: GestureDetector(
                  onTap: _onTapVideo,
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Stack(alignment: Alignment.center, children: [
                        hasImage
                            ? ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: WebNetworkImage(imageUrl: imageUrl ?? '',
                                loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
                                  return (loadingProgress == null) ? child : emptyImagePlaceholder;
                                }))
                            : emptyImagePlaceholder,
                        VideoPlayButton()
                      ])))),
          Container(color: Styles().colors.accentColor3, height: 4)
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
            bool externalLink = JsonUtils.boolValue(command['external_link']) ?? UrlUtils.isWebScheme(JsonUtils.stringValue(command['url']));
            bool chevron = JsonUtils.boolValue(command['chevron']) ?? true;
            bool canFavorite = JsonUtils.boolValue(command['can_favorite']) ?? true;
            widgetList.add(WellnessRegularResourceButton(
              label: _getString(id),
              favorite: favorite,
              canFavorite: canFavorite ,
              hasChevron: chevron,
              hasExternalLink: externalLink,
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

  Widget _buildLargeButtonsContainer() {
    List<Widget> widgetList = <Widget>[];
    if (_commands != null) {
      for (dynamic entry in _commands!) {
        Map<String, dynamic>? command = JsonUtils.mapValue(entry);
        if (command != null) {
          String? type = JsonUtils.stringValue(command['type']);
          if (type == 'large') {
            String? id = JsonUtils.stringValue(command['id']);
            Favorite favorite = WellnessFavorite(id, category: widget.wellnessCategory);
            if (widgetList.isNotEmpty) {
              widgetList.add(Container(height: 8));
            }
            widgetList.add(WellnessLargeResourceButton(
              label: _getString(id),
              favorite: favorite,
              canFavorite: JsonUtils.boolValue(command['can_favorite']) ?? true,
              hasChevron: JsonUtils.boolValue(command['chevron']) ?? false,
              hasExternalLink: JsonUtils.boolValue(command['external_link']) ?? UrlUtils.isWebScheme(JsonUtils.stringValue(command['url'])),
              onTap: () => _onCommand(command),
            ));
          }
        }
      }
    }

    widgetList.add(Container(height: 16,));

    return Column(children: widgetList);
  }

  void _onTapVideo() {
    if (_video != null) {
      Analytics().logSelect(target: 'Mental Health Video', source: widget.runtimeType.toString(), attributes: JsonUtils.mapValue(_video!.analyticsAttributes));
      Navigator.push(context, CupertinoPageRoute(builder: (context) =>
          AppHelpVideoTutorialPanel(videoTutorial: _video!, analyticsFeature: AnalyticsFeature.WellnessMentalHealth,)
      ));
    }
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
      } else {
        Uri? uri = Uri.tryParse(url!);
        if (uri != null) {
          launchUrl(uri,
              mode: DeepLink().isAppUrl(url) ?
                LaunchMode.platformDefault :
                LaunchMode.externalApplication);
        }
      }
    }
  }

  void _initContent() async {
    // Map<String, dynamic>? content = Wellness().resources;
    // Map<String, dynamic>? assetsWellnessContent = JsonUtils.mapValue(JsonUtils.mapValue(await _loadWellnessContentFromAsset));
    Map<String, dynamic>? content = Wellness().recreation;

    _video = (content != null) ? Video.fromJson(JsonUtils.mapValue(content['video'])) : null;
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

  //static const String _assetsName   = "wellness.json";
  //String get _appAssetsKey => 'assets/$_assetsName';

  //TBD load from wellness service - content. TBD consider moving to Content BB.
  //Future<Map<String, dynamic>?> get _loadWellnessContentFromAsset async => await loadFromAssets(appAssetsKey);
}