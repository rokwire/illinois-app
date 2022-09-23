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
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/settings/SettingsWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsLocationPanel extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SettingsLocationPanelState();
}

class _SettingsLocationPanelState extends State<SettingsLocationPanel> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: Localization().getStringEx("panel.settings.location.label.title", "Location"),
      ),
      body: SingleChildScrollView(child: _buildContent()),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildContent() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: <Widget>[
          Container(
            height: 24,
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              Localization().getStringEx("panel.settings.location.label.desctiption", "Find events and places on campus near you."),
              style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies!.bold),
            ),
          ),
          Container(
            height: 24,
          ),
          InfoButton(
            title: Localization().getStringEx("panel.settings.location.button.access_location.title", "Access device’s location"),
            description: _locationStatus,
            additionalInfo: Localization().getStringEx(
                "panel.settings.button.access_location.label.info", "To get the most out of our features, enable location in your device’s settings."),
            iconRes: "images/m.png",
            onTap: _onTapLocation(),
          ),
          Container(height: 24,),
          _InfoToggleButton(
            title: Localization().getStringEx("panel.settings.location.button.location_history.title", "Save location history"),
            additionalInfo: Localization().getStringEx("panel.settings.button.location_history.label.info","Only available when location access is enabled"),
            iconRes: "images/blue.png",
            iconResDisabled: "images/blue-off.png",
            toggled: _locationHistoryEnabled,
            enabled: _locationEnabled,
            onTap: _onTapLocationHistory,
          ),
        ],
      ),
    );
  }

  _onTapLocation() {
    //TBD
  }

  _onTapLocationHistory(){
    //TBD
    AppToast.show("TBD");
  }

  bool get _locationEnabled {
    return false; // tbd
  }

  bool get _locationHistoryEnabled {
    return false; // tbd
  }

  String? get _locationStatus {
    return _locationEnabled
        ? Localization().getStringEx("panel.settings.location.label.status.enabled", "Enabled")
        : Localization().getStringEx("panel.settings.location.label.status.disabled", "Disabled");
  }
}

class _InfoToggleButton extends StatefulWidget {
  final String? title;
  final String? iconRes;
  final String iconResDisabled;
  final String? additionalInfo;
  final bool enabled;
  final bool toggled;
  final double height;

  final void Function()? onTap;

  // ignore: unused_element
  const _InfoToggleButton({Key? key, this.title, this.iconRes, this.additionalInfo, this.onTap, this.enabled = true , this.toggled = false, this.height = 110, this.iconResDisabled="",}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _InfoToggleButtonState();
}

class _InfoToggleButtonState extends State<_InfoToggleButton> {
  @override
  Widget build(BuildContext context) {
    return
      SizedBox(
          height: widget.height,
          child: Semantics(
            container: true,
            child: InkWell(
            onTap: widget.enabled ? widget.onTap : (){},
              child: _buildButtonContent(),))
      );
  }

  Widget _buildButtonContent(){
    return Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
              color: Styles().colors!.surface,
              borderRadius: BorderRadius.all(Radius.circular(4)),
              boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 11,vertical: 4),
                    child: Image.asset(
                      widget.enabled? widget.iconRes!: widget.iconResDisabled,
                      excludeFromSemantics: true,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(height: 4,),
                        Container(
                            padding: EdgeInsets.only(right: 14),
                            child: Text(
                              widget.title!,
                              style: TextStyle(fontFamily: Styles().fontFamilies!.bold, fontSize: 16, color: widget.enabled?Styles().colors!.fillColorPrimary : Styles().colors!.fillColorPrimaryTransparent015),
                            )),
                        _buildAdditionalInfo(),
                      ],
                    ),
                  ),
                  Container(
                    width: 10,
                  ),
                  Container(
                    child: Image.asset(
                      widget.enabled?
                      (widget.toggled ? ('images/switch-on.png') : ('images/switch-off.png')) :
                      ("images/off.png"),
                      excludeFromSemantics: true,
                    ),
                  ),
                  Container(
                    width: 16,
                  )
                ],
              ),
            ],
          ),
        );
  }

  Widget _buildAdditionalInfo() {
    return widget.additionalInfo?.isEmpty ?? true
        ? Container()
        : Column(
            children: <Widget>[
              Container(
                height: 12,
              ),
              Container(
                height: 1,
                color: widget.enabled? Styles().colors!.surfaceAccent: Styles().colors!.surfaceAccentTransparent15,
              ),
              Container(height: 12),
              Text(
                widget.additionalInfo!,
                style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 12, color: widget.enabled? Styles().colors!.textSurface:  Styles().colors!.textSurfaceTransparent15),
              ),
            ],
          );
  }
}
