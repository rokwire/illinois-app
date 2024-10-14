/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class DiningCard extends StatefulWidget {
  final Dining? dining;
  final GestureTapCallback? onTap;

  DiningCard(this.dining, {super.key, this.onTap, });

  @override
  _DiningCardState createState() => _DiningCardState();
}

class _DiningCardState extends State<DiningCard> implements NotificationsListener {

  static const EdgeInsets _detailPadding = EdgeInsets.only(bottom: 8, left: 16, right: 16);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 8);
  static const double _smallImageSize = 64;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  String get semanticLabel {
    Explore? explore = widget.dining;
    String title = widget.dining?.title ?? "";
    String workTime = ((explore is Dining) ? explore.displayWorkTime : null) ?? "";
    String interests = "";
    interests = interests.isNotEmpty ? interests.replaceRange(0, 0, Localization().getStringEx('widget.card.label.interests', 'Because of your interest in:')) : "";
    String eventType = explore?.typeDisplayString??"";

    return "$title, $workTime, $interests, $eventType";
  }

  @override
  Widget build(BuildContext context) {
    String imageUrl = StringUtils.ensureNotEmpty(widget.dining?.imageURL);

    return Semantics(label: semanticLabel, button: true, child:
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: widget.onTap, child:
        Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            Stack(alignment: Alignment.topCenter, children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4)),
                boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                _exploreTop(),
                Semantics(excludeSemantics: true, child:
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                      Expanded(child:
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          _diningDetails(),
                        ],)
                      ),
                      Visibility(visible: StringUtils.isNotEmpty(imageUrl), child:
                        Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 12), child:
                          SizedBox(width: _smallImageSize, height: _smallImageSize, child:
                            InkWell(onTap: () => _onTapCardImage(imageUrl), 
                              child: Image.network(imageUrl, excludeFromSemantics: true, fit: BoxFit.fill, headers: Config().networkAuthHeaders)),
                          ),
                        )
                      ),
                    ],),
                    _diningPaymentTypes(),
                  ]),
                )
              ],),),
              _topBorder(),
            ]),
          ),
        ],),
      ),
    );
  }

  Widget _exploreTop() {

    bool isFavorite = widget.dining?.isFavorite ?? false;
    bool starVisible = Auth2().canFavorite && (widget.dining is Favorite);
    String leftLabel = widget.dining!.title ?? "";
    TextStyle? leftLabelStyle = Styles().textStyles.getTextStyle('widget.explore.card.title.regular.extra_fat') ;

    return Row(
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 16, right: 16, top: 19, bottom: 12),
              child: Text(
                leftLabel,
                style: leftLabelStyle,
                semanticsLabel: "",
              )
            ),
          ),
          Visibility(visible: starVisible, child:
            Semantics(container: true, child:
              Container( child:
                Semantics(
                  label: isFavorite ? Localization().getStringEx(
                      'widget.card.button.favorite.off.title',
                      'Remove From Favorites') : Localization().getStringEx(
                      'widget.card.button.favorite.on.title',
                      'Add To Favorites'),
                  hint: isFavorite ? Localization().getStringEx(
                      'widget.card.button.favorite.off.hint', '') : Localization()
                      .getStringEx('widget.card.button.favorite.on.hint', ''),
                  button: true,
                  child:  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _onTapDiningCardStar,
                    child:Container(child: Padding(padding: EdgeInsets.only(
                      right: 16, top: 12, left: 24, bottom: 5),
                      child: Styles().images.getImage(isFavorite
                          ? 'star-filled'
                          : 'star-outline-gray',
                        excludeFromSemantics: true,)
                      ))
                  )),)))
        ],
    );
  }

  Widget _diningDetails() {
    List<Widget> details = [];

    Widget? workTime = _diningWorkTimeDetail();
    if (workTime != null) {
      details.add(workTime);
    }

    return (0 < details.length)
        ? Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: details))
        : Container();
  }

  Widget? _diningWorkTimeDetail() {
    Dining? dining = (widget.dining is Dining) ? (widget.dining as Dining) : null;
    String? displayTime = dining?.displayWorkTime;
    if ((displayTime != null) && displayTime.isNotEmpty) {
      return Semantics(label: displayTime, child:Padding(
        padding: _detailPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Styles().images.getImage('time', excludeFromSemantics: true) ?? Container(),
            Padding(
              padding: _iconPadding,
            ),
            Expanded(
              child: Text(displayTime,
                  style: Styles().textStyles.getTextStyle('widget.explore.card.detail.regular')),
            ),
          ],
        ),
      ));
    }
    return null;
  }

  Widget _diningPaymentTypes() {
    List<Widget>? details;
    Dining? dining = (widget.dining is Dining) ? (widget.dining as Dining) : null;
    List<PaymentType>? paymentTypes = dining?.paymentTypes;
    if ((paymentTypes != null) && (0 < paymentTypes.length)) {
      details = [];
      for (PaymentType? paymentType in paymentTypes) {
        Widget? image = PaymentTypeHelper.paymentTypeIcon(paymentType);
        if (image != null) {
          details.add(Padding(padding: EdgeInsets.only(right: 6), child:image) );
        }
      }
    }
      return ((details != null) && (0 < details.length)) ? Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _divider(),
              Padding(
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 24),
        child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: details))
              
            ])
        
        : Container();
  }

  Widget _divider(){
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0),
      child: Container(
        height: 1,
        color: Styles().colors.fillColorPrimaryTransparent015,
      ),
    );
  }

  Widget _topBorder() {
    return Container(height: 7, color: widget.dining?.uiColor);
  }

  void _onTapDiningCardStar() {
    Analytics().logSelect(target: "Favorite: ${widget.dining?.title}");
    widget.dining?.toggleFavorite();
  }

  void _onTapCardImage(String? url) {
    Analytics().logSelect(target: "Explore Image");
    if (url != null) {
      Navigator.push(
          context,
          PageRouteBuilder(
              opaque: false,
              pageBuilder: (context, _, __) =>
                  ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
    }
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    }
    else if (name == FlexUI.notifyChanged) {
      setStateIfMounted(() {});
    }
  }
}
