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
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/model/Dining.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class DiningCard extends StatefulWidget {
  final Dining? dining;
  final void Function(BuildContext context)? onTap;

  DiningCard(this.dining, {super.key, this.onTap, });

  @override
  _DiningCardState createState() => _DiningCardState();
}

class _DiningCardState extends State<DiningCard> with NotificationsListener {
  static Decoration get _listContentDecoration => HomeMessageCard.defaultDecoration;
  /*BoxDecoration(
      color: Styles().colors.surface,
      borderRadius: _listContentBorderRadius,
      // border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
      boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );*/
  static BorderRadiusGeometry get _listContentBorderRadius => BorderRadius.all(Radius.circular(8));
  static const EdgeInsets _listContentMargin =  EdgeInsets.symmetric(vertical: 4, horizontal: 4);
  static const EdgeInsets _sectionPadding = EdgeInsets.only(top: 8, bottom: 8, left: 16, right: 16);
  static const EdgeInsets _detailPadding = EdgeInsets.only(bottom: 8, left: 16, right: 16);
  static const EdgeInsets _iconPadding = EdgeInsets.only(right: 6);

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
    return "$title, $workTime";
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(label: semanticLabel, button: true, child:
      GestureDetector(behavior: HitTestBehavior.opaque, onTap: ()=> widget.onTap?.call(context), child:
          Container(decoration: _listContentDecoration,
              padding: EdgeInsets.symmetric(horizontal: 0),
              margin: _listContentMargin,
              child: ClipRRect(borderRadius: _listContentBorderRadius, child:
                Container(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                    _buildImage,
                    _exploreTop(),
                    Semantics(excludeSemantics: true, child:
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                        Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                          Expanded(child:
                            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
                              _diningDetails(),
                            ],)
                          ),
                        ],),
                        _diningPaymentTypes(),
                      ]),
                    )
                  ],),),)
          ),
      ),
    );
  }

  Widget get _buildImage {
    String? imageUrl = widget.dining?.imageURL;
    return Visibility(visible: StringUtils.isNotEmpty(imageUrl), child:
      Container(decoration: _imageHeadingDecoration, child:
        AspectRatio(aspectRatio: 2.5, child:
          Image.network(imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
        ),
      )
    );
  }

  Decoration get _imageHeadingDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
  );

  Widget _exploreTop() {
    bool isFavorite = widget.dining?.isFavorite ?? false;
    bool starVisible = Auth2().canFavorite && (widget.dining is Favorite);
    String leftLabel = widget.dining!.title ?? "";
    TextStyle? leftLabelStyle = Styles().textStyles.getTextStyle('widget.title.medium.fat') ;

    return Padding(padding: _sectionPadding, child:
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Text(
                leftLabel,
                style: leftLabelStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
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
                    child:Container(child: Padding(padding: EdgeInsets.only(left: 16,bottom: 5, top: 5),
                      child: Styles().images.getImage(isFavorite
                          ? 'star-filled'
                          : 'star-outline-gray',
                        excludeFromSemantics: true,)
                      ))
                  )),)))
        ],
    ));
  }

  Widget _diningDetails() {
    List<Widget> details = [];

    Widget? workTime = _diningWorkTimeDetail();
    if (workTime != null) {
      details.add(workTime);
    }

    return (0 < details.length)
        ? Padding(
        padding: EdgeInsets.only(bottom: 8),
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
                  style: Styles().textStyles.getTextStyle('common.body')),
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
              Container(height: 6,),
              Padding(
                padding: _sectionPadding,
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

  void _onTapDiningCardStar() {
    Analytics().logSelect(target: "Favorite: ${widget.dining?.title}");
    widget.dining?.toggleFavorite();
  }

  // void _onTapCardImage(String? url) {
  //   Analytics().logSelect(target: "Explore Image");
  //   if (url != null) {
  //     Navigator.push(
  //         context,
  //         PageRouteBuilder(
  //             opaque: false,
  //             pageBuilder: (context, _, __) =>
  //                 ModalImagePanel(imageUrl: url, onCloseAnalytics: () => Analytics().logSelect(target: "Close Image"))));
  //   }
  // }

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
