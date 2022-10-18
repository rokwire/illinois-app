/*
 * Copyright 2022 Board of Trustees of the University of Illinois.
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
import 'package:illinois/model/wellness/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AppointmentCard extends StatefulWidget {
  final Appointment appointment;

  AppointmentCard({required this.appointment});

  @override
  _AppointmentCardState createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> implements NotificationsListener {
  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
    ]);
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double imageSize = 64;
    DateTime now = DateTime.now();
    bool isUpcoming = (widget.appointment.dateTimeUtc != null) && widget.appointment.dateTimeUtc!.isAfter(now.toUtc());
    String? imageUrl = widget.appointment.imageUrl;
    bool isFavorite = Auth2().isFavorite(widget.appointment);
    bool starVisible = Auth2().canFavorite && isUpcoming;

    return InkWell(
        onTap: _onTapAppointmentCard,
        child: ClipRRect(
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
            child: Stack(children: [
              Container(
                  decoration: BoxDecoration(
                      color: Styles().colors!.surface,
                      border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
                      borderRadius: BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          Expanded(
                              child: Text(StringUtils.ensureNotEmpty(widget.appointment.category),
                                  style: TextStyle(
                                      color: Styles().colors?.textBackground, fontFamily: Styles().fontFamilies?.semiBold, fontSize: 14))),
                          Visibility(
                              visible: starVisible,
                              child: Semantics(
                                  container: true,
                                  child: Container(
                                      child: Semantics(
                                          label: isFavorite
                                              ? Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites')
                                              : Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
                                          hint: isFavorite
                                              ? Localization().getStringEx('widget.card.button.favorite.off.hint', '')
                                              : Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
                                          button: true,
                                          child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTap: _onTapExploreCardStar,
                                              child: Container(
                                                  child: Padding(
                                                      padding: EdgeInsets.only(left: 24, bottom: 5),
                                                      child: Image.asset(
                                                          isFavorite
                                                              ? 'images/icon-star-orange.png'
                                                              : 'images/icon-star-gray-frame-thin.png',
                                                          excludeFromSemantics: true))))))))
                        ]),
                        Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Expanded(
                                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Row(children: [
                                  Expanded(
                                      child: Text(StringUtils.ensureNotEmpty(widget.appointment.title),
                                          style: TextStyle(
                                              color: Styles().colors?.fillColorPrimary,
                                              fontFamily: Styles().fontFamilies?.extraBold,
                                              fontSize: 20)))
                                ]),
                                Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Row(children: [
                                      Padding(padding: EdgeInsets.only(right: 6), child: Image.asset('images/icon-calendar.png')),
                                      Expanded(
                                          child: Text(StringUtils.ensureNotEmpty(widget.appointment.displayDate),
                                              style: TextStyle(
                                                  color: Styles().colors?.textBackground,
                                                  fontFamily: Styles().fontFamilies?.medium,
                                                  fontSize: 16)))
                                    ])),
                                Padding(
                                    padding: EdgeInsets.only(top: 12),
                                    child: Row(children: [
                                      Padding(
                                          padding: EdgeInsets.only(right: 6),
                                          child: Image.asset((widget.appointment.type == AppointmentType.online)
                                              ? 'images/icon-telehealth.png'
                                              : 'images/icon-location.png')),
                                      Expanded(
                                          child: Text(StringUtils.ensureNotEmpty(Appointment.typeToDisplayString(widget.appointment.type)),
                                              style: TextStyle(
                                                  color: Styles().colors?.textBackground,
                                                  fontFamily: Styles().fontFamilies?.medium,
                                                  fontSize: 16)))
                                    ]))
                              ])),
                              Visibility(
                                  visible: StringUtils.isNotEmpty(imageUrl),
                                  child: Padding(
                                      padding: EdgeInsets.only(left: 16, bottom: 4),
                                      child: SizedBox(
                                          width: imageSize,
                                          height: imageSize,
                                          child: InkWell(
                                              onTap: () => _onTapCardImage(imageUrl!),
                                              child: Image.network(imageUrl!,
                                                  excludeFromSemantics: true, fit: BoxFit.fill, headers: Config().networkAuthHeaders)))))
                            ]))
                      ]))),
              Container(color: (isUpcoming ? Styles().colors?.fillColorSecondary : Styles().colors?.fillColorPrimary), height: 4)
            ])));
  }

  void _onTapAppointmentCard() {
    //TBD: Appointment - implement
  }

  void _onTapCardImage(String imageUrl) {
    Analytics().logSelect(target: 'Appointment Image');
    Navigator.push(
        context,
        PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, _, __) =>
                ModalImagePanel(imageUrl: imageUrl, onCloseAnalytics: () => Analytics().logSelect(target: 'Close Image'))));
  }

  void _onTapExploreCardStar() {
    Analytics().logSelect(target: "Favorite: ${widget.appointment.exploreTitle}");
    Auth2().prefs?.toggleFavorite(widget.appointment);
  }

  @override
  void onNotification(String name, param) {
    if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted(() {});
    }
  }
}
