
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/safety/SafetySafeWalkRequestPage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class HomeSafeWalkRequestWidget extends StatelessWidget {
  final String? favoriteId;
  final StreamController<String>? updateController;

  HomeSafeWalkRequestWidget({super.key, this.favoriteId, this.updateController});

  static Widget handle({Key? key, String? favoriteId, HomeDragAndDropHost? dragAndDropHost, int? position}) =>
    HomeHandleWidget(key: key, favoriteId: favoriteId, dragAndDropHost: dragAndDropHost, position: position,
      title: title,
    );

  static String get title => Localization().getStringEx('widget.home.safety.safewalk_request.title', 'SafeWalks');

  @override
  Widget build(BuildContext context) {
    return HomeFavoriteWidget(favoriteId: favoriteId,
      title: title,
      child: _contentWidget(context),
    );
  }

  Widget _contentWidget(BuildContext context) =>
    Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
      SafetySafeWalkRequestCard(
        backgroundColor: Styles().colors.white,
        borderRadius: BorderRadius.all(Radius.circular(6)),
        headerWidget: _cardHeaderWidget(context),
      )
    );

  Widget _cardHeaderWidget(BuildContext context) =>
    Padding(padding: EdgeInsets.only(bottom: 16), child:
      HtmlWidget(_infoHtml,
        onTapUrl : (url) { _onTapLink(url, context: context, analyticsTarget: Config().safeWalkPhoneNumber); return true;},
        textStyle:  Styles().textStyles.getTextStyle("widget.message.small"),
        customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorPrimary)} : null
      ),
    );

  static const String _safeWalkPhoneNumberMacro = '{{safewalk_phone_number}}';
  static const String _safeWalkStartTimeMacro = '{{safewalk_start_time}}';
  static const String _safeWalkEndTimeMacro = '{{safewalk_end_time}}';

  String get _infoHtml =>
    Localization().getStringEx('widget.home.safety.safewalk_request.info', 'To request a student patrol officer to walk with you between $_safeWalkStartTimeMacro and $_safeWalkStartTimeMacro, call <a href=\'tel:$_safeWalkEndTimeMacro\'>$_safeWalkEndTimeMacro</a> or enter your information below.')
      .replaceAll(_safeWalkStartTimeMacro, Config().safeWalkStartTime ?? '9:00 p.m.')
      .replaceAll(_safeWalkEndTimeMacro, Config().safeWalkEndTime ?? '2:30 a.m.')
      .replaceAll(_safeWalkPhoneNumberMacro, Config().safeWalkPhoneNumber ?? '');

  void _onTapLink(String url, { required BuildContext context, String? analyticsTarget, bool launchInternal = false }) {
    Analytics().logSelect(target: analyticsTarget ?? url);
    if (url.isNotEmpty) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        bool tryInternal = launchInternal && UrlUtils.canLaunchInternal(url);
        AppLaunchUrl.launch(context: context, url: url, tryInternal: tryInternal);
      }
    }
  }


}

