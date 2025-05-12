/*
 * Copyright 2024 Board of Trustees of the University of Illinois.
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

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/ui/wellness/WellnessHomePanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/model/wellness/SuccessTeam.dart';

class WellnessSuccessTeamContentWidget extends StatefulWidget {
  WellnessSuccessTeamContentWidget();

  @override
  State<WellnessSuccessTeamContentWidget> createState() => _WellnessSuccessTeamContentWidgetState();
}

class _WellnessSuccessTeamContentWidgetState extends State<WellnessSuccessTeamContentWidget> {

  bool _loading = false;

  List<SuccessTeamMember?> primaryCareProviders = [];
  List<SuccessTeamMember?> academicAdvisors = [];

  int pcpIndex = 0;
  int advisorIndex = 0;

  static const String _mcKinleyPhoneMacro = '{{mckinley_phone}}';
  String get _htmlLinkColor => ColorUtils.toHex(Styles().colors.fillColorSecondary);
  Map<String, String> get _htmlAnchorStyle => <String, String>{
    //'color': _htmlLinkColor,
    'text-decoration-color': _htmlLinkColor
  };

  @override
  void initState() {
    _getSuccessTeam();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading ? _buildLoadingContent() : _buildContentUi();
  }

  Widget _buildLoadingContent() {
    return Center(
        child: Column(children: <Widget>[
          Container(height: MediaQuery.of(context).size.height / 5),
          CircularProgressIndicator(),
          Container(height: MediaQuery.of(context).size.height / 5 * 3)
        ]));
  }

  Widget _buildContentUi() {
    List<Widget> widgetList = <Widget>[];

    SuccessTeamMember? pcp = primaryCareProviders.isNotEmpty ? primaryCareProviders.first : null;
    if (pcp != null) {
      widgetList.add(_buildSuccessTeamItem("MCKINLEY HEALTH CENTER", "Primary Care Provider", "${pcp.firstName} ${pcp.lastName}", pcp.externalLink ?? '', pcp.image, widgetList.isNotEmpty ? 16 : 0));
    }

    SuccessTeamMember? advisor = ((0 <= advisorIndex) && (advisorIndex < academicAdvisors.length)) ? academicAdvisors[advisorIndex] : null;
    if (advisor != null) {
      widgetList.add(_buildSuccessTeamItem("THE GRAINGER COLLEGE OF ENGINEERING", "Academic Advisor", "${advisor.firstName} ${advisor.lastName}", "https://my.engr.illinois.edu/advising", advisor.image, widgetList.isNotEmpty ? 16 : 0));
    }

    if (this.academicAdvisors.length > 1) {
      widgetList.add(Container(child:
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Padding(padding: EdgeInsets.only(left: 6), child:
                (advisorIndex != 0)
                ? GestureDetector(onTap: () => _changeActiveAdvisor(-1), child:
                    Styles().images.getImage('chevron-left-bold') ?? Container()
                  )
                : Container(foregroundDecoration: BoxDecoration(color: Colors.grey, backgroundBlendMode: BlendMode.saturation,), child:
                    Styles().images.getImage('chevron-left-bold') ?? Container()
                  )
            ),
            Spacer(),
            Text("${advisorIndex+1} of ${academicAdvisors.length}", style: Styles().textStyles.getTextStyle('widget.description.regular')),
            Spacer(),
            Padding(padding: EdgeInsets.only(right: 6), child:
              (advisorIndex+1 == academicAdvisors.length)
                ? Container(foregroundDecoration: BoxDecoration(color: Colors.grey, backgroundBlendMode: BlendMode.saturation,), child:
                    Styles().images.getImage('chevron-right-bold') ?? Container()
                  )
                : GestureDetector(onTap: () => _changeActiveAdvisor(1), child:
                    Styles().images.getImage('chevron-right-bold') ?? Container()
                  )
            )
          ])
      ));
    }

    if (widgetList.isEmpty) {
      widgetList.add(Padding(padding: EdgeInsets.zero, child:
        Container(
          decoration: BoxDecoration(
            color: Styles().colors.surface,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.circular(4)
          ),
          child: Container(padding: EdgeInsets.all(16), child:
          Row(children: [
            Flexible(child:
              HtmlWidget(_emptyContentHtml,
                onTapUrl: _onTapUrl,
                textStyle:  Styles().textStyles.getTextStyle("widget.description.small"),
                customStylesBuilder: (element) => (element.localName == "a") ? _htmlAnchorStyle : null,
              )
            ),
          ])
          )
        )
      ));
    }

    widgetList.add(Padding(padding: EdgeInsets.zero, child:
      Align(alignment: Alignment.centerLeft, child:
        InkWell(onTap: _onTapUpcomingAppointments, child:
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
            Text(Localization().getStringEx('panel.wellness.successteam.upcoming.appointments.link', 'View your upcoming McKinley appointments.'), style:
              Styles().textStyles.getTextStyle('widget.message.small.underline')
            )
          )
        )
      )
    ));

    widgetList.add(Padding(padding: EdgeInsets.zero, child:
      Row(children: [
        Flexible(child:
          HtmlWidget(_dialNurseHtml,
            onTapUrl: _onTapUrl,
            textStyle: Styles().textStyles.getTextStyle("widget.description.small"),
            customStylesBuilder: (element) => (element.localName == "a") ? _htmlAnchorStyle : null,
          )
        ),
      ])
    ));

    return Padding(padding: const EdgeInsets.all(16), child:
      Column(children: widgetList)
    );
  }

  Widget _buildSuccessTeamItem(String department, String type, String name, String externalLink, [String image = "", double padding = 0]) {
    return Padding(padding: EdgeInsets.only(top: padding), child: Container(
        decoration: BoxDecoration(
            color: Styles().colors.surface,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.circular(4)),
        child: Container(padding: EdgeInsets.all(16), child: Column(children: [
          Row(children: [
            Padding(padding: EdgeInsets.only(top: 4, bottom: 4), child:
            Text(department, style: Styles().textStyles.getTextStyle('widget.title.small.fat'))
            ),
          ]),
          Row(children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Padding(padding: EdgeInsets.only(top: 4), child:
            Row(children: [
              Text(type, style: Styles().textStyles.getTextStyle('widget.title.medium.extra_fat')),
              GestureDetector(onTap: () => _onTapInfo(type), child: Padding(padding: EdgeInsets.only(left: 4), child: Styles().images.getImage('info', excludeFromSemantics: true) ?? Container()))
            ])
            ),
              Row(children: [
                Padding(padding: EdgeInsets.only(right: 6), child: Styles().images.getImage('person', excludeFromSemantics: true) ?? Container()),
                Text(name, style: Styles().textStyles.getTextStyle('widget.description.regular')),
              ]),
              Row(children: [
                Padding(padding: EdgeInsets.only(right: 6), child: Styles().images.getImage('external-link', excludeFromSemantics: true) ?? Container()),
                GestureDetector(onTap: () => launchUrl(Uri.parse(externalLink)), child:
                  Text("Schedule an Appointment", style: Styles().textStyles.getTextStyle('widget.description.regular.underline'))
                )]),
            ]),
            Spacer(),
            Padding(padding: EdgeInsets.only(left: 8), child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: image != ""
                ? Image.memory(base64Decode(image), width: 80, height: 80)
                : Styles().images.getImage('default-profile-photo', width: 80, height: 80, excludeFromSemantics: true)))
          ]),
        ])
        )));
  }

  String get _emptyContentHtml => Localization().getStringEx("panel.wellness.successteam.empty.content.description",
    "<p>There are no primary care providers (PCP) to display. After enrollment, Illinois students are automatically assigned a PCP at McKinley. Call <a href='tel:$_mcKinleyPhoneMacro'>$_mcKinleyPhoneMacro</a> for more information.</p>")
    .replaceAll(_mcKinleyPhoneMacro, Config().saferMcKinleyPhone ?? '');

  String get _dialNurseHtml => Localization().getStringEx("panel.wellness.successteam.dial.nurse.description",
    "<p><a href='tel:$_mcKinleyPhoneMacro'>Call Dial-A-Nurse at $_mcKinleyPhoneMacro</a> 24/hrs/7 days to coordinate healthcare needs and answer questions about illnesses, injuries, or other health concerns.</p>")
    .replaceAll(_mcKinleyPhoneMacro, Config().saferMcKinleyPhone ?? '');

  FutureOr<bool> _onTapUrl(String url) async {
    Analytics().logSelect(target: 'Url: $url');
    if (url.isNotEmpty) {
      if (DeepLink().isAppUrl(url)) {
        DeepLink().launchUrl(url);
      }
      else {
        AppLaunchUrl.launch(context: context, url: url, tryInternal: false);
      }
    }
    return true;
  }

  void _onTapUpcomingAppointments() {
    Analytics().logSelect(target: 'Upcoming appointments');
    NotificationService().notify(WellnessHomePanel.notifySelectContent, WellnessContent.appointments);
  }

  void _changeActiveAdvisor(int direction) {
    setState(() {
      this.advisorIndex = this.advisorIndex + direction;
    });
  }

  void _getSuccessTeam() {
    _setLoading(true);
    bool pcpLoading = true;
    bool advisorsLoading = true;
    Wellness().getPrimaryCareProviders().then((item) {
      this.primaryCareProviders = item;
      pcpLoading = false;
      _setLoading(advisorsLoading);
    });
    Wellness().getAcademicAdvisors().then((advisors) {
      this.academicAdvisors = this.academicAdvisors + advisors;
      advisorsLoading = false;
      _setLoading(pcpLoading);
    });
  }

  void _onTapInfo(String type) {
    Widget textWidget = Text(
      type == "Primary Care Provider"
        ? Localization().getStringEx('panel.wellness.successteam.pcp.info.description', "A primary care provider (PCP) provides essential healthcare services, promotes your overall wellbeing, and can refer you to services such as internal medicine, family practice, psychiatry, and gynecology.")
        : Localization().getStringEx('panel.wellness.successteam.advisors.info.description', "An academic advisor is your go-to person for course registration, degree planning, and academic support services."),
      style: Styles().textStyles.getTextStyle('panel.skills_self_evaluation.auth_dialog.text'),
      textAlign: TextAlign.center,
    );
    showDialog(context: context, builder: (_) => InfoPopup(
      backColor: Styles().colors.surface,
      padding: EdgeInsets.only(left: 32, right: 32, top: 40, bottom: 32),
      alignment: Alignment.center,
      infoTextWidget: textWidget,
      closeIcon: Styles().images.getImage('close-circle', excludeFromSemantics: true),
    ),);
  }

  void _setLoading(bool loading) {
    _loading = loading;
    if (mounted) {
      setState(() {});
    }
  }

}
