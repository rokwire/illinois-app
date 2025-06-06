/*
 * Copyright 2023 Board of Trustees of the University of Illinois.
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
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Survey.dart';
import 'package:illinois/model/Analytics.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/surveys/SurveyPanel.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/popups/popup_message.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2SetupSurveyPanel extends StatefulWidget with AnalyticsInfo {
  static final String routeName = 'Event2SetupSurveyPanel';

  final Event2SetupSurveyParam surveyParam;
  final List<Survey>? surveysCache;
  final String? eventName;
  final AnalyticsFeature? analyticsFeature; //This overrides AnalyticsInfo.analyticsFeature getter

  Event2SetupSurveyPanel({Key? key, required this.surveyParam, this.eventName, this.surveysCache, this.analyticsFeature}) : super(key: key);

  static Future<Event2SetupSurveyParam?> push(BuildContext context, {Key? key, required Event2SetupSurveyParam surveyParam, List<Survey>? surveysCache, String? eventName, AnalyticsFeature? analyticsFeature}) =>
    Navigator.push<Event2SetupSurveyParam>(context, CupertinoPageRoute(
      settings: RouteSettings(name: routeName),
      builder: (context) => Event2SetupSurveyPanel(
        surveyParam: surveyParam,
        eventName: eventName,
        surveysCache: surveysCache,
        analyticsFeature: analyticsFeature,
      ),
    ));

  static void popUntil(BuildContext context) => Navigator.of(context).popUntil((route) => route.settings.name == routeName);

  Event2SurveyDetails? get details => (surveyParam.event?.id != null) ? surveyParam.event?.surveyDetails : surveyParam.details;

  @override
  State<StatefulWidget> createState() => _Event2SetupSurveyPanelState();
}

class _Event2SetupSurveyPanelState extends State<Event2SetupSurveyPanel>  {

  List<Survey>? _surveys;

  Survey? _survey;
  Survey? _displaySurvey;
  Survey? _initialSurvey;

  final TextEditingController _hoursController = TextEditingController();
  late String _initialHours;

  bool _modified = false;
  bool _loadingSurveys = false;
  bool _updatingSurvey = false;

  @override
  void initState() {

    _hoursController.text = _initialHours = widget.details?.hoursAfterEvent?.toString() ?? '';
    if (_isEditing) {
      _hoursController.addListener(_checkModified);
    }

    if ((widget.surveysCache != null) && (widget.surveysCache?.isNotEmpty == true)) {
      _surveys = widget.surveysCache;
      _initialSurvey = Survey.findInList(_surveys, title: widget.surveyParam.survey?.title);
      _selectSurvey(_initialSurvey);
    }
    else {
      _loadingSurveys = true;
      Surveys().loadEvent2SurveyTemplates().then((List<Survey>? surveys) {
        if ((widget.surveysCache != null) && (widget.surveysCache?.isEmpty == true) && (surveys != null)) {
          widget.surveysCache?.addAll(surveys);
        }
        setStateIfMounted(() {
          _surveys = surveys;
          _initialSurvey = Survey.findInList(_surveys, title: widget.surveyParam.survey?.title);
          _selectSurvey(_initialSurvey);
          _loadingSurveys = false;
        });
      });
    }

    _checkModified();

    super.initState();
  }

  @override
  void dispose() {
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    PopScopeFix(onBack: _onHeaderBarBack, child: _buildScaffoldContent());

  Widget _buildScaffoldContent() => Scaffold(
    appBar: _headerBar,
    body: _buildPanelContent(),
    backgroundColor: Styles().colors.background
  );

  Widget _buildPanelContent() {
    if (_loadingSurveys) {
      return _buildLoadingContent();
    }
    else if (_surveys == null) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.setup.survey.surveys.failed.msg', 'Failed to load available surveys.'));
    }
    else if ((_surveys?.length ?? 0) == 0) {
      return _buildMessageContent(Localization().getStringEx('panel.event2.setup.survey.surveys.empty.msg', 'There are no surveys available.'));
    }
    else {
      return _buildSurveyContent();
    }
  }

  Widget _buildSurveyContent() {
    return SingleChildScrollView(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.event2.setup.survey.explanation.title', 'Choose a survey template to be sent to attendees of this event after it completes.'),
              style: Styles().textStyles.getTextStyle('widget.description.regular')),
          SizedBox(height: 16.0),
          _buildSurveysSection(),
          _buildHoursSection(),
          _buildSurveyPreviewSection(),
          _buildDownloadResultsDescription()
        ])
      )
    );
  }

  Widget _buildLoadingContent() {
    return Column(children: [
      Expanded(flex: 1, child: Container(),),
      SizedBox(width: 32, height: 32, child:
        CircularProgressIndicator(color: Styles().colors.fillColorSecondary, strokeWidth: 3,),
      ),
      Expanded(flex: 2, child: Container(),),
    ],);
  }

  Widget _buildMessageContent(String? message) {
    return Column(children: [
      Expanded(flex: 1, child: Container(),),
      Padding(padding: EdgeInsets.symmetric(horizontal: 32), child:
        Text(message ?? '', textAlign: TextAlign.center, style: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 18)),
      ),
      Expanded(flex: 2, child: Container(),),
    ],);
  }

  // Surveys

  Widget _buildSurveysSection() {
    String title = Localization().getStringEx('panel.event2.setup.survey.survey.title', 'SURVEY');
    return Padding(padding: Event2CreatePanel.sectionPadding, child:
      Semantics(container: true, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(flex: 1, child:
            Padding(padding: EdgeInsets.only(right: 8), child:
              Wrap(children: [
                Event2CreatePanel.buildSectionTitleWidget(title),
              ]),
            ),
          ),
          Expanded(flex: 3, child: _surveysDropdownWidget),
        ]),
      ),

      /*Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child: Wrap(children: [Event2CreatePanel.buildSectionTitleWidget(title)])),
          Expanded(child: _surveysDropdownWidget)
        ]),
      ])*/
    );
  }

  Widget get _surveysDropdownWidget =>
    Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
    Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
      DropdownButtonHideUnderline(child:
        DropdownButton<Survey?>(
          icon: Styles().images.getImage('chevron-down'),
          isExpanded: true,
          value: _survey,
          style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
          hint: Text((_survey != null) ? (_survey?.displayTitle ?? '') : nullSurveyTitle),
          items: _buildSurveyDropDownItems(),
          onChanged: _onSurveyChanged
        ),
      ),
    ),
  );


  List<DropdownMenuItem<Survey?>>? _buildSurveyDropDownItems() {
    List<DropdownMenuItem<Survey?>> items = <DropdownMenuItem<Survey?>>[];
    items.add(DropdownMenuItem<Survey?>(value: null, child:
      Text(nullSurveyTitle),
    ));
    if (_surveys != null) {
      for (Survey survey in _surveys!) {
        items.add(DropdownMenuItem<Survey?>(value: survey, child:
          Text(survey.displayTitle ?? '')
        ));
      }
    }
    return items;
  }

  void _onSurveyChanged(Survey? survey) {
    Analytics().logSelect(target: "Survey: ${(survey != null) ? survey.title : 'null'}");
    if ((_survey != survey) && mounted) {
      setState(() {
        _selectSurvey(survey);
      });
      _checkModified();
      //TBD: Preview selected survey
    }
  }

  void _selectSurvey(Survey? survey) {
    _survey = survey;
    _displaySurvey = survey != null ? Survey.fromOther(survey) : null;
    _displaySurvey?.replaceKey('event_name', widget.eventName ?? widget.surveyParam.event?.name);
  }

  String get nullSurveyTitle => Localization().getStringEx('panel.event2.setup.survey.no_survey.title', '---');

  // Hours

  Widget _buildHoursSection() => Visibility(visible: (_displaySurvey != null), child:
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Event2CreatePanel.buildSectionTitleWidget(Localization().getStringEx('panel.event2.setup.survey.hours.title', 'SEND TIME'), required: true),
        Padding(padding: EdgeInsets.only(top: 2), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(flex: 5, child:
            Event2CreatePanel.buildSectionSubTitleWidget(Localization().getStringEx("panel.event2.setup.survey.hours.description", "How many hours after the event's end time should the survey notification be sent to attendees (or hours after the start time, if no end time is set)? Enter 0 for immediate delivery or a whole positive number to delay sending.")),
          ),
          Expanded(flex: 1, child:
            Padding(padding: EdgeInsets.only(left: 6), child:
              Event2CreatePanel.buildTextEditWidget(_hoursController, keyboardType: TextInputType.number, maxLines: 1)
            )
          )
        ])
        )
      ],)
    )
  );

  // Survey Preview

  Widget _buildSurveyPreviewSection() => Visibility(visible: _survey != null,
    child: Event2CreatePanel.buildButtonSectionWidget(
      heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
        title: Localization().getStringEx('panel.event2.setup.survey.preview.title', 'Survey Preview'),
        subTitle: Localization().getStringEx('panel.event2.setup.survey.preview.subtitle', 'Try out the survey by filling out a sample.'),
        onTap: _onSurveyPreview,
      ),
    ),
  );

  Widget _buildPreviewContinueWidget() {
    return PopupMessage(
      title: "Sample Follow-Up Survey",
      messageWidget: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 24, bottom: 8),
        child: Text(
          Localization().getStringEx('panel.event2.setup.survey.preview.continue.message',
            'Thank you for testing your event follow-up survey. At this point, the survey would be submitted, and the results would be available to view under the event admin settings.'),
          style: Styles().textStyles.getTextStyle('widget.detail.regular.fat'),
        )
      ),
      buttonTitle: Localization().getStringEx("dialog.ok.title", "OK"),
      onTapButton: (context) {
        Event2SetupSurveyPanel.popUntil(context);
      },
    );
  }

  Widget _buildDownloadResultsDescription() {
    TextStyle? mainStyle = Styles().textStyles.getTextStyle('widget.card.detail.small.regular.italic');
    final Color defaultStyleColor = Colors.red;
    final String? eventAttendanceUrl = Config().eventAttendanceUrl;
    final String? displayAttendanceUrl = (eventAttendanceUrl != null) ? (UrlUtils.stripUrlScheme(eventAttendanceUrl) ?? eventAttendanceUrl) : null;
    final String eventAttendanceUrlMacro = '{{event_attendance_url}}';
    String contentHtml = Localization().getStringEx('panel.event2.detail.survey.download.results.description',
      "Download survey results at {{event_attendance_url}}.");
    contentHtml = contentHtml.replaceAll(eventAttendanceUrlMacro, displayAttendanceUrl ?? '');
    return Visibility(visible: PlatformUtils.isMobile && (_survey != null) && StringUtils.isNotEmpty(displayAttendanceUrl), child:
      Padding(padding: EdgeInsets.zero, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Styles().images.getImage('info') ?? Container(),
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 6), child:
              HtmlWidget(contentHtml, onTapUrl: _onTapHtmlLink, textStyle: mainStyle,
                customStylesBuilder: (element) => (element.localName == "a") ? { "color": ColorUtils.toHex(mainStyle?.color ?? defaultStyleColor), "text-decoration-color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null,
              )
            ),
          ),
        ])
      ),
    );
  }

  bool _onTapHtmlLink(String? url) {
    Analytics().logSelect(target: '($url)');
    UrlUtils.launchExternal(url, mode: LaunchMode.externalApplication);
    return true;
  }

  String get surveyTitleMacro => '{{survey_title}}';

  PreferredSizeWidget? _buildPreviewHeaderBar() => HeaderBar(
    title: Localization().getStringEx('panel.event2.setup.survey.preview.headerbar.title', '$surveyTitleMacro Preview').replaceAll(surveyTitleMacro, _displaySurvey?.title ?? Localization().getStringEx("panel.event2.setup.survey.survey.title", "SURVEY")),
  );

  // HeaderBar

  bool get _isEditing => StringUtils.isNotEmpty(widget.surveyParam.event?.id);

  PreferredSizeWidget get _headerBar => HeaderBar(
    title: Localization().getStringEx('panel.event2.setup.survey.header.title', 'Event Follow-Up Survey'),
    onLeading: _onHeaderBarBack,
    actions: _headerBarActions,
  );

  List<Widget>? get _headerBarActions {
    if (_updatingSurvey) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if (_isEditing && _modified) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onHeaderBarApply,
      )];
    }
    else {
      return null;
    }
  }

  void _checkModified() {
    if (_isEditing && mounted) {
      
      bool modified = (_survey?.title != _initialSurvey?.title) ||
        (_hoursController.text != _initialHours);

      if (_modified != modified) {
        setState(() {
          _modified = modified;
        });
      }
    }
  }

  Event2SetupSurveyParam _buildSurveyParam() {
    Survey? survey = _survey != null ? Survey.fromOther(_survey!, id: widget.surveyParam.survey?.id) : null;

    // set calendarEventId in survey if it is missing
    if (survey != null && StringUtils.isEmpty(survey.calendarEventId)) {
      survey.calendarEventId = widget.surveyParam.survey?.calendarEventId ?? widget.surveyParam.event?.id;
    }

    return Event2SetupSurveyParam(
      survey: survey,
      details: Event2SurveyDetails(
        hoursAfterEvent: _survey != null ? Event2CreatePanel.textFieldIntValue(_hoursController) : null,
      ),
    );
  }

  bool _checkSurveyResult(Event2SetupSurveyParam surveyParam) {
    if ((surveyParam.survey?.id != null) && ((surveyParam.details?.hoursAfterEvent == null) || ((surveyParam.details?.hoursAfterEvent ?? 0) < 0))) {
      AppAlert.showDialogResult(context, Localization().getStringEx('panel.event2.setup.survey.hours.invalid.msg', 'Please, fill valid non-negative number for hours.'));
      return false;
    }
    return true;
  }

  Future<void> _updateEventSurveyDetails(Event2SetupSurveyParam? surveyParam) async {
    String? eventId = widget.surveyParam.event?.id;
    if ((eventId != null) && eventId.isNotEmpty && (_updatingSurvey != true)) {

      Event2? event = widget.surveyParam.event;
      if (event?.isSurveyAvailable == false) {
        setState(() {
          _updatingSurvey = true;
        });

        // the survey is not available to attendees yet
        if (surveyParam?.details != widget.details) {
          dynamic result = await Events2().updateEventSurveyDetails(eventId, surveyParam?.details);
          if (mounted) {
            if (result is Event2) {
              event = result;
            }
            else {
              setState(() {
                _updatingSurvey = false;
              });
              Event2Popup.showErrorResult(context, result);
              return;
            }
          }
        }

        bool surveyUpdateResult = true;
        Survey? survey = widget.surveyParam.survey;
        if (surveyParam?.survey?.title != survey?.title) {
          // a different template than the initially selected template is now selected
          if (survey == null) {
            // the null template was initially selected (no survey exists), so create a new survey
            surveyUpdateResult = await Surveys().createEvent2Survey(surveyParam!.survey!, event!) ?? false;
          } else if (surveyParam?.survey == null) {
            // the null template is now selected, so delete the existing survey
            surveyUpdateResult = await Surveys().deleteSurvey(survey.id) ?? false;
          } else {
            // a survey already exists and the template has been changed, so update the existing survey
            surveyUpdateResult = await Surveys().updateSurvey(surveyParam!.survey!) ?? false;
          }

          // always load the survey to make sure we have the current version (other admins may be editing)
          survey = await Surveys().loadEvent2Survey(eventId);
        }

        if (mounted) {
          setState(() {
            _updatingSurvey = false;
          });

          if (surveyUpdateResult) {
            Navigator.of(context).pop(Event2SetupSurveyParam(
              event: event,
              survey: survey,
            ));
          }
          else {
            Event2Popup.showErrorResult(context, Localization().getStringEx('panel.event2.setup.survey.update.failed.msg', 'Failed to set event survey, but the number of hours setting has been saved. Remember that other event admins may have modified the survey.')).then((_) {
              Navigator.of(context).pop(Event2SetupSurveyParam(
                event: event,
                survey: survey,
              ));
            });
          }
        }
      } else {
        Event2Popup.showErrorResult(context, Localization().getStringEx('panel.event2.setup.survey.update.already_available.msg', 'This survey is already available to attendees, so it will not be updated.'));
      }
    } else {
      Event2Popup.showErrorResult(context, Localization().getStringEx('panel.event2.setup.survey.update.event_missing.msg', 'Failed to find associated event.'));
    }
  }

  void _onHeaderBarApply() {
    Analytics().logSelect(target: 'HeaderBar: Apply');
    Event2SetupSurveyParam surveyParam = _buildSurveyParam();
    if (_checkSurveyResult(surveyParam)) {
      _updateEventSurveyDetails(surveyParam);
    }
  }

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    if (_isEditing) {
      Navigator.of(context).pop(null);
    }
    else {
      Event2SetupSurveyParam surveyParam = _buildSurveyParam();
      if (_checkSurveyResult(surveyParam)) {
        Navigator.of(context).pop(surveyParam);
      }
    }
  }

  void _onSurveyPreview() {
    Navigator.of(context).push(CupertinoPageRoute(builder: (context) => SurveyPanel(
        survey: _displaySurvey,
        summarizeResultRules: true,
        summarizeResultRulesWidget: _buildPreviewContinueWidget(),
        headerBar: _buildPreviewHeaderBar(),
    )));
  }
}

class Event2SetupSurveyParam {
  final Event2? event;
  final Survey? survey;
  final Event2SurveyDetails? details;
  Event2SetupSurveyParam({this.event, this.survey, this.details});
}