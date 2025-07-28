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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/model/Appointment.dart';
import 'package:illinois/ext/Appointment.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/appointments/AppointmentDetailPanel.dart';
import 'package:illinois/ui/home/HomeFavoritesWidget.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/panels/modal_image_panel.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AppointmentCard extends StatefulWidget with AnalyticsInfo {
  final Appointment appointment;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter
  final CardDisplayMode displayMode;
  final void Function()? onTap;

  AppointmentCard({super.key,
    required this.appointment, this.analyticsFeature, this.onTap,
    this.displayMode = CardDisplayMode.browse,
  });

  @override
  _AppointmentCardState createState() => _AppointmentCardState();
}

class _AppointmentCardState extends State<AppointmentCard> with NotificationsListener {
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
    switch (widget.displayMode) {
      case CardDisplayMode.home: return _homeDisplayWidget;
      case CardDisplayMode.browse: return _browseDisplayWidget;
    }
  }

  Widget get _homeDisplayWidget =>
    InkWell(onTap: widget.onTap ?? _onTapAppointmentCard, child:
      Semantics(label: widget.appointment.title, child:
        Container(decoration: HomeFavoritesWidget.defaultCardDecoration, margin: EdgeInsets.only(bottom: HomeMessageCard.defaultShadowBlurRadius, ), child:
          Column(children: <Widget>[
            HomeFavoritesWidget.defaultHeaderWidget(_headerColor),
            _contentWidget
          ]),
        ),
      ),
    );

  Widget get _browseDisplayWidget =>
    InkWell(onTap: widget.onTap ?? _onTapAppointmentCard, child:
      Semantics(label: widget.appointment.title, child:
        Column(children: <Widget>[
          Container(height: HomeFavoritesWidget.defaultHeaderHeight, color: _headerColor,),
          Container(decoration: _browseDecoration, child:
            _contentWidget
          ),
        ]),
      ),
    );

  static BoxDecoration get _browseDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border(left: _browseBorderSide, right: _browseBorderSide, bottom: _browseBorderSide),
    borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)),
  );

  static BorderSide get _browseBorderSide =>
    BorderSide(color: Styles().colors.surfaceAccent, width: 1);

  Color get _headerColor => (widget.appointment.isUpcoming ? Styles().colors.fillColorSecondary : Styles().colors.fillColorPrimary);

  Widget get _contentWidget {
    const double imageSize = 64;
    const double iconSize = 18;
    String? imageKey = widget.appointment.imageKey;
    String semanticsImageLabel = 'appointment image';
    String semanticsImageHint = 'Double tap to expand image';

    String typeImageKey = (widget.appointment.type == AppointmentType.online) ? 'laptop' : 'location';
    String? displayTime = widget.appointment.displayShortScheduleTime;
    String? displayType = widget.appointment.displayType;
    String? displayHost = widget.appointment.host?.displayName;

    bool isFavorite = Auth2().isFavorite(widget.appointment);
    bool canFavorite = Auth2().canFavorite && widget.appointment.isUpcoming;
    String favImageKey = isFavorite ? 'star-filled' : 'star-outline-gray';
    String semanticsFavLabel = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
      Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites');
    String semanticsFavHint = isFavorite ?
      Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
      Localization().getStringEx('widget.card.button.favorite.on.hint', '');

    return Padding(padding: EdgeInsets.only(left: 16, bottom: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(top: 16, bottom: 16, right: canFavorite ? 0 : 16), child:
              Text(widget.appointment.category ?? '', style:
                Styles().textStyles.getTextStyle("widget.item.small.semi_fat")
              ),
            ),
          ),
          Visibility(visible: canFavorite, child:
            Semantics(label: semanticsFavLabel, hint: semanticsFavHint, button: true, child:
              GestureDetector(behavior: HitTestBehavior.opaque, onTap: _onTapExploreCardStar, child:
                Padding(padding: EdgeInsets.all(16), child:
                  Styles().images.getImage(favImageKey, excludeFromSemantics: true)
                )
              )
            )
          )
        ]),

        Padding(padding: EdgeInsets.only(right: 16), child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                Text(widget.appointment.title ?? '', style:
                  Styles().textStyles.getTextStyle("widget.title.large.extra_fat")
                ),

                Visibility(visible: StringUtils.isNotEmpty(displayTime), child:
                  Padding(padding: EdgeInsets.only(top: 4), child:
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: EdgeInsets.only(right: 6), child:
                        SizedBox(width: iconSize, height: iconSize, child:
                          Styles().images.getImage('calendar', excludeFromSemantics: true)
                        )
                      ),
                      Expanded(child:
                        Text(displayTime ?? '', style:
                          Styles().textStyles.getTextStyle("widget.item.regular")
                        )
                      )
                    ])
                  ),
                ),

                Visibility(visible: StringUtils.isNotEmpty(displayHost), child:
                  Padding(padding: EdgeInsets.only(top: 4), child:
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: EdgeInsets.only(right: 6), child:
                        SizedBox(width: iconSize, height: iconSize, child:
                          Styles().images.getImage('person', excludeFromSemantics: true)
                        )
                      ),
                      Expanded(child:
                        Text(displayHost ?? '', overflow: TextOverflow.ellipsis, style:
                          Styles().textStyles.getTextStyle("widget.item.regular")
                        )
                      ),
                    ])
                  ),
                ),

                Visibility(visible: StringUtils.isNotEmpty(displayType), child:
                  Padding(padding: EdgeInsets.only(top: 4), child:
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Padding(padding: EdgeInsets.only(right: 6), child:
                        SizedBox(width: iconSize, height: iconSize, child:
                          Styles().images.getImage(typeImageKey, excludeFromSemantics: true)
                        )
                      ),
                      Expanded(child:
                        Text(displayType ?? '', overflow: TextOverflow.ellipsis, style:
                          Styles().textStyles.getTextStyle("widget.item.regular")
                        )
                      ),
                    ])
                  ),
                ),

              ]),
            ),

            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Opacity(opacity: StringUtils.isNotEmpty(imageKey) ? 1 : 0, child:
                Padding(padding: EdgeInsets.only(left: 16), child:
                  Semantics(label: semanticsImageLabel, button: true, hint: semanticsImageHint, child:
                    InkWell(onTap: () => StringUtils.isNotEmpty(imageKey) ? _onTapCardImage(imageKey) : null, child:
                      SizedBox(width: imageSize, height: imageSize, child:
                        Styles().images.getImage(imageKey, excludeFromSemantics: true, fit: BoxFit.fill, networkHeaders: Config().networkAuthHeaders)
                      )
                    )
                  )
                )
              ),

              Visibility(visible: (widget.appointment.cancelled == true), child:
                Padding(padding: EdgeInsets.only(top: 6), child:
                  Text(Localization().getStringEx('widget.appointment.card.cancelled.label', 'Cancelled'), textAlign: TextAlign.right, style:
                    Styles().textStyles.getTextStyle("panel.appointment_detail.title.large")
                  )
                ),
              )

            ],)
          ]),
        ),
      ])
    );
  }

  void _onTapAppointmentCard() {
    Analytics().logSelect(target: 'Appointment Detail');
    Navigator.push(context, CupertinoPageRoute(builder: (context) => AppointmentDetailPanel(
      appointment: widget.appointment,
      analyticsFeature: widget.analyticsFeature,
    )));
  }

  void _onTapCardImage(String? imageKey) {
    Analytics().logSelect(target: 'Appointment Image');
    Navigator.push(context, PageRouteBuilder(opaque: false, pageBuilder: (context, _, __) =>
      ModalPhotoImagePanel(imageKey: imageKey, onCloseAnalytics: () => Analytics().logSelect(target: 'Close Image')))
    );
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
