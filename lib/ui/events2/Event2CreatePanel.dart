
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/ext/Survey.dart';
import 'package:illinois/mainImpl.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/events2/Event2DetailPanel.dart';
import 'package:illinois/ui/events2/Event2SetupAttendancePanel.dart';
import 'package:illinois/ui/events2/Event2SetupGroupsPanel.dart';
import 'package:illinois/ui/events2/Event2SetupRegistrationPanel.dart';
import 'package:illinois/ui/events2/Event2SetupSponsorshipAndContactsPanel.dart';
import 'package:illinois/ui/events2/Event2SetupSurveyPanel.dart';
import 'package:illinois/ui/events2/Event2TimeRangePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreMapSelectLocationPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/PopScopeFix.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/auth2.dart';
import 'package:rokwire_plugin/service/content.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2CreatePanel extends StatefulWidget {

  final Event2? event;
  final Survey? survey;
  final List<Group>? targetGroups;

  Event2CreatePanel({Key? key, this.event, this.survey, this.targetGroups}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2CreatePanelState();

  bool get isUpdate => StringUtils.isNotEmpty(event?.id);
  bool get isCreate => StringUtils.isEmpty(event?.id);

  // Shared Helpers

  static const double sectionPaddingHeight = 24;
  static const EdgeInsetsGeometry sectionPadding = const EdgeInsets.only(bottom: sectionPaddingHeight);

  static const double innerSectionPaddingHeight = 12;
  static const EdgeInsetsGeometry innerSectionPadding = const EdgeInsets.only(bottom: innerSectionPaddingHeight);

  static const EdgeInsetsGeometry sectionHeadingPadding = const EdgeInsets.only(bottom: 8);
  static const EdgeInsetsGeometry innerSectionHeadingPadding = const EdgeInsets.only(bottom: 4);

  static const EdgeInsetsGeometry sectionHeadingContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  static const EdgeInsetsGeometry sectionBodyContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsetsGeometry dropdownButtonContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static const EdgeInsetsGeometry textEditContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  static const EdgeInsetsGeometry innerTextEditContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static const double innerRecurrenceSectionPaddingWidth = 16;

  static TextStyle? get headingTextStype => Styles().textStyles.getTextStyle("widget.title.small.fat.spaced");
  static TextStyle? get headingDisabledTextStype => Styles().textStyles.getTextStyle("widget.title.small.fat.disabled.spaced");
  static TextStyle? get subTitleTextStype => Styles().textStyles.getTextStyle("widget.card.detail.small.regular");
  static TextStyle? get textEditStyle => Styles().textStyles.getTextStyle('widget.input_field.dark.text.regular.thin');

  static BoxDecoration get sectionDecoration => sectionDecorationEx(enabled: true);
  static BoxDecoration get sectionDisabledDecoration => sectionDecorationEx(enabled: false);

  static BoxDecoration sectionDecorationEx({bool enabled = true}) => BoxDecoration(
    border: Border.all(color: enabled ? Styles().colors.mediumGray2 : Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8))
  );

  static BoxDecoration get sectionSplitterDecoration => BoxDecoration(
    border: Border(top: BorderSide(color: Styles().colors.mediumGray2, width: 1))
  );

  static InputDecoration textEditDecoration({EdgeInsetsGeometry? padding}) => InputDecoration(
    fillColor: Styles().colors.surface,
    filled: true,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
      borderRadius: BorderRadius.circular(8)
    ),
    contentPadding: padding,
  );

  static BoxDecoration get dropdownButtonDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4))
  );

  // Sections / Regular Section
  
  static Widget buildSectionWidget({
    Widget? heading, Widget? body, Widget? trailing,
    EdgeInsetsGeometry padding = sectionPadding,
    EdgeInsetsGeometry bodyPadding = EdgeInsets.zero
  }) {
    List<Widget> contentList = <Widget>[];
    if (heading != null) {
      contentList.add(heading);
    }
    if (body != null) {
      contentList.add(Padding(padding: bodyPadding, child: body));
    }
    if (trailing != null) {
      contentList.add(trailing);
    }

    return Padding(padding: padding, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,)
    );
  }

  static Widget buildInnerSectionWidget({ Widget? heading, Widget? body, Widget? trailing,
    EdgeInsetsGeometry padding = innerSectionPadding,
    EdgeInsetsGeometry bodyPadding = EdgeInsets.zero
  }) => buildSectionWidget(heading: heading, body: body, trailing: trailing, padding: padding, bodyPadding: bodyPadding);

  static Widget buildSectionHeadingWidget(String title, { bool required = false, TextStyle? titleTextStyle, String? prefixImageKey, String? suffixImageKey, EdgeInsetsGeometry padding = sectionHeadingPadding }) {
    String semanticsLabel = title;
    if (required) {
      semanticsLabel += ", required";
    }

    List<Widget> contentList = <Widget>[];

    Widget? prefixImageWidget = (prefixImageKey != null) ? Styles().images.getImage(prefixImageKey) : null;
    if (prefixImageWidget != null) {
      contentList.add(Padding(padding: EdgeInsets.only(right: 6), child:
        prefixImageWidget,
      ));
    }

    contentList.add(buildSectionTitleWidget(title, textStyle: titleTextStyle));
    
    if (required) {
      contentList.add(Padding(padding: EdgeInsets.only(left: 2), child:
        Text('*', style: Styles().textStyles.getTextStyle("widget.label.small.fat"),),
      ));
    }

    Widget? suffixImageWidget = (suffixImageKey != null) ? Styles().images.getImage(suffixImageKey) : null;
    if (suffixImageWidget != null) {
      contentList.add(Padding(padding: EdgeInsets.only(left: 6), child:
        suffixImageWidget,
      ));
    }

    return Padding(padding: padding, child:
      Semantics(label: semanticsLabel, header: true, excludeSemantics: true, child:
        Row(children: contentList),
      ),
    );
  }

  static Widget buildInnerSectionHeadingWidget(String title, { bool required = false, String? prefixImageKey, String? suffixImageKey, EdgeInsetsGeometry padding = innerSectionHeadingPadding }) =>
    buildSectionHeadingWidget(title, required: required, prefixImageKey: prefixImageKey, suffixImageKey: suffixImageKey, padding : padding);

  static TextScaler get textScaler {
    BuildContext? context = App.instance?.currentContext;
    return (context != null) ? MediaQuery.of(context).textScaler : TextScaler.noScaling;
  }

  static Widget buildSectionTitleWidget(String title, { bool required = false, TextStyle? textStyle, TextStyle? requiredTextStyle,  }) =>
    Semantics ( label: title, child:
      RichText(textScaler: textScaler, text:
        TextSpan(text: title, style: textStyle ?? headingTextStype, semanticsLabel: "", children: required ? <InlineSpan>[
          TextSpan(text: ' *', style: requiredTextStyle ?? Styles().textStyles.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
        ] : null),
    ));


  static Widget buildSectionSubTitleWidget(String subTitle) =>
    Text(subTitle, style: subTitleTextStype);

  static Widget buildSectionRequiredWidget() => 
    Text('*', style: Styles().textStyles.getTextStyle("widget.label.small.fat"), semanticsLabel: ", required",);

  // Sections / Dropdown Section

  static Widget buildDropdownSectionWidget({
    required Widget heading, required Widget body, Widget? trailing,
    bool expanded = false,
    EdgeInsetsGeometry padding = sectionPadding,
    EdgeInsetsGeometry bodyPadding = sectionBodyContentPadding,
  }) {

    return Padding(padding: padding, child:
      Column(children: <Widget>[
        Container(decoration: sectionDecoration, child:
          Column(children: <Widget>[
            heading,
            Visibility(visible: expanded, child:
              Container(decoration: sectionSplitterDecoration, child:
                Padding(padding: bodyPadding, child:
                  body,
                ),
              ),
            ),
          ],),
        ),
        trailing ?? Container()
      ]),
    );
  }

  static Widget buildDropdownSectionHeadingWidget(String title, {
    bool required = false,
    bool expanded = false,
    void Function()? onToggleExpanded,
    EdgeInsetsGeometry padding = sectionHeadingContentPadding
  }) => Semantics(button: true, label: title,
      child: InkWell(onTap: onToggleExpanded, child:
        Padding(padding: padding, child:
          Row(children: [
            Expanded(child:
              buildSectionTitleWidget(title, required: required),
            ),
            Padding(padding: EdgeInsets.only(left: 8), child:
              Styles().images.getImage(expanded ? 'chevron-up' : 'chevron-down') ?? Container()
            ),
          ],),
        ),
      )
    );

  // Sections / Button Section

  static Widget buildButtonSectionWidget({ required Widget heading, Widget? body,
    EdgeInsetsGeometry padding = sectionPadding,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
  }) {
    List<Widget> contentList = <Widget>[
      heading
    ];
    if (body != null) {
      contentList.add(Container(decoration: sectionSplitterDecoration, child:
        Padding(padding: bodyPadding, child:
          body,
        ),
      ),);
    }
    return Padding(padding: padding, child:
      Container(decoration: sectionDecoration, child:
        Column(children: contentList,),
      ),
    );
  }

  static Widget buildButtonSectionHeadingWidget({required String title, String? subTitle, bool required = false, void Function()? onTap, EdgeInsetsGeometry? padding }) {

    Widget leftWidget = (subTitle != null) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      buildSectionTitleWidget(title, required: required),
      Padding(padding: EdgeInsets.only(top: 2), child:
        buildSectionSubTitleWidget(subTitle),
      )
    ],) : buildSectionTitleWidget(title, required: required);

    EdgeInsetsGeometry appliedPadding = padding ?? ((subTitle != null) ?
      const EdgeInsets.symmetric(horizontal: 16, vertical: 11) :
      sectionHeadingContentPadding
    );

    return Semantics( button: true,
      child:InkWell(onTap: onTap, child:
        Padding(padding: appliedPadding, child:
          Row(children: [
            Expanded(child:
              leftWidget,
            ),
            Padding(padding: EdgeInsets.only(left: 8), child:
              Styles().images.getImage('chevron-right') ?? Container()
            ),
          ],),
        ),
      )
    );
  }

  // Text Edit

  static Widget buildTextEditWidget(TextEditingController controller, {
    FocusNode? focusNode,
    TextInputType? keyboardType,
    int? maxLines = 1,
    int? minLines,
    bool autocorrect = false,
    EdgeInsetsGeometry padding = textEditContentPadding,
    void Function()? onChanged,
    String? semanticsLabel,
    String? semanticsHint,
  }) =>
    Semantics(
      label: semanticsLabel,
      hint: semanticsHint,
      textField: true,
      excludeSemantics: true,
      value: controller.text,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        decoration: textEditDecoration(padding: padding),
        style: textEditStyle,
        maxLines: maxLines,
        minLines: minLines,
        keyboardType: keyboardType,
        autocorrect: autocorrect,
        onChanged: (onChanged != null) ? ((_) => onChanged) : null,
    ));

  static Widget buildInnerTextEditWidget(TextEditingController controller, {
    FocusNode? focusNode,
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool autocorrect = false,
    EdgeInsetsGeometry padding = innerTextEditContentPadding,
    void Function()? onChanged,
    String? semanticsLabel,
    String? semanticsHint,
  }) =>
    buildTextEditWidget(controller, focusNode: focusNode, keyboardType: keyboardType, maxLines: maxLines, autocorrect: autocorrect, padding: padding, onChanged: onChanged, semanticsLabel: semanticsLabel, semanticsHint: semanticsHint);


  // Confirm URL

  static Widget buildConfirmUrlLink({
    void Function()? onTap,
    bool progress = false,
    EdgeInsetsGeometry padding = const EdgeInsets.only(top: 8, bottom: 16, left: 12)
  }) {
    return Align(alignment: Alignment.centerRight, child:
      Row(mainAxisSize: MainAxisSize.min, children: [
        progress ? Padding(padding: padding, child:
          SizedBox(width: 16, height: 16, child:
            CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
          ),
        ) : Container(),
        LinkButton(
          title: Localization().getStringEx('panel.event2.create.button.confirm_url.title', 'Confirm URL'),
          hint: Localization().getStringEx('panel.event2.create.button.confirm_url.hint', ''),
          onTap: onTap,
          padding: padding,
        )
      ],)
    );
  }

  static void confirmLinkUrl(BuildContext context, TextEditingController controller, { FocusNode? focusNode, void Function(bool progress)? updateProgress, String? analyticsTarget }) {
    Analytics().logSelect(target: analyticsTarget ?? "Confirm URL");
    hideKeyboard(context);
    if (controller.text.isNotEmpty) {
      Uri? uri = UriExt.parse(controller.text);
      if (uri != null) {
        if (updateProgress != null) {
          updateProgress(true);
        }
        uri.fixAsync().then((Uri? fixedUri) {
          if (updateProgress != null) {
            updateProgress(false);
          }
          if (fixedUri != null) {
            controller.text = fixedUri.toString();
            uri = fixedUri;
          }
          if (uri != null) {
            launchUrl(uri!, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault).then((bool result) {
              if (result == false) {
                Event2Popup.showMessage(context, message: Localization().getStringEx('panel.event2.create.confirm_url.failed.message', 'Failed to confirm URL.')).then((_) {
                  focusNode?.requestFocus();
                });
              }
            });
          }
         });
      }
      else {
        Event2Popup.showMessage(context, message: Localization().getStringEx('panel.event2.create.confirm_url.invalid.message', 'Please enter a valid URL.')).then((_) {
          focusNode?.requestFocus();
        });
      }
    }
    else {
      Event2Popup.showMessage(context, message: Localization().getStringEx('panel.event2.create.confirm_url.empty.message', 'Please enter URL string.')).then((_) {
        focusNode?.requestFocus();
      });
    }
  }

  // Text Controller

  static String? textFieldValue(TextEditingController textController) =>
    textController.text.isNotEmpty ? textController.text : null;

  static int? textFieldIntValue(TextEditingController textController) =>
    textController.text.isNotEmpty ? int.tryParse(textController.text) : null;

  // Keyboard

  static void hideKeyboard(BuildContext context) {
    FocusScope.of(context).unfocus();
  }

  // HeaderBar actions

  static Widget buildHeaderBarActionButton({ String? title, void Function()? onTap, EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12)}) {
    return Semantics(label: title, button: true, excludeSemantics: true, child: 
      InkWell(onTap: onTap, child:
        Align(alignment: Alignment.center, child:
          Padding(padding: padding, child:
            Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors.white, width: 1.5, ))),
                child: Text(title ?? '',
                  style: Styles().textStyles.getTextStyle("widget.heading.regular.fat")
                ),
              ),
            ],)
          ),
        ),
        //Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12), child:
        //  Text(title ?? '', style: Styles().textStyles.getTextStyle('panel.athletics.home.button.underline'))
        //),
      ),
    );
  }

  static Widget buildHeaderBarActionProgress({ EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20) }) =>
    Padding(padding: padding, child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors.white, strokeWidth: 3,)
        )
    );

}

class _Event2CreatePanelState extends State<Event2CreatePanel> {

  String? _imageUrl;

  late Location _timeZone;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _allDay = false;

  _RecurrenceRepeatType? _recurrenceRepeatType;
  List<DayOfWeek>? _recurrenceWeekDays;
  int? _weeklyRepeatPeriod;
  static const int _maxRecurrenceWeeksValue = 10;
  int? _monthlyRepeatPeriod;
  static const int _maxRecurrenceMonthsValue = 10;
  _RecurrenceRepeatMonthlyType? _recurrenceRepeatMonthlyType;
  int? _recurrenceRepeatDay;
  static const int _maxRecurrenceRepeatDayValue = 31;
  _RecurrenceOrdinalNumber? _recurrenceOrdinalNumber;
  _RecurrenceMonthWeekDay? _recurrenceMonthWeekDay;
  DateTime? _recurrenceEndDate;

  Event2Type? _eventType;
  late _Event2Visibility _visibility;

  late bool _free;
  late bool _published;

  Map<String, dynamic>? _attributes;

  Event2RegistrationDetails? _registrationDetails;
  Event2AttendanceDetails? _attendanceDetails;
  Event2SurveyDetails? _surveyDetails;
  Survey? _survey;
  List<Survey> _surveysCache = <Survey>[];

  List<Group>? _eventGroups;
  Set<String>? _initialGroupIds;
  bool _loadingEventGroups = false;

  // List<Event2PersonIdentifier>? _initialAdmins;
  bool _loadingAdmins = false;

  String? _sponsor;
  String? _speaker;
  List<Event2Contact>? _contacts;
  // Explore? _locationExplore;

  late Map<_ErrorCategory, List<String>> _errorMap;
  bool _creatingEvent = false;

  final TextEditingController _adminNetIdsController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();

  final TextEditingController _locationBuildingController = TextEditingController();
  final TextEditingController _locationAddressController = TextEditingController();
  final TextEditingController _locationLatitudeController = TextEditingController();
  final TextEditingController _locationLongitudeController = TextEditingController();

  final TextEditingController _onlineUrlController = TextEditingController();
  final TextEditingController _onlineMeetingIdController = TextEditingController();
  final TextEditingController _onlinePasscodeController = TextEditingController();

  final TextEditingController _costController = TextEditingController();

  final FocusNode _websiteFocus = FocusNode();
  final FocusNode _onlineUrlFocus = FocusNode();

  bool _confirmingWebsiteUrl = false;
  bool _confirmingOnlineUrl = false;

  bool _dateTimeSectionExpanded = false;
  bool _recurrenceSectionExpanded = false;
  bool _typeAndLocationSectionExpanded = false;
  bool _costSectionExpanded = false;

  @override
  void initState() {
    _titleController.text = widget.event?.name ?? '';
    _descriptionController.text = widget.event?.description ?? '';
    _imageUrl = widget.event?.imageUrl;
    _websiteController.text = widget.event?.eventUrl ?? '';

    _timeZone = timeZoneDatabase.locations[widget.event?.timezone] ?? DateTimeLocal.timezoneLocal;
    DateTime? startTimeUtc = widget.event?.startTimeUtc;
    if (startTimeUtc != null) {
      TZDateTime startTime = TZDateTime.from(startTimeUtc, _timeZone);
      _startDate = TZDateTimeUtils.dateOnly(startTime);
      _startTime = TimeOfDay.fromDateTime(startTime);
    }
    DateTime? endTimeUtc = widget.event?.endTimeUtc;
    if (endTimeUtc != null) {
      TZDateTime endTime = TZDateTime.from(endTimeUtc, _timeZone);
      _endDate = TZDateTimeUtils.dateOnly(endTime);
      _endTime = TimeOfDay.fromDateTime(endTime);
    }
    //_allDay = (widget.event?.allDay == true);

    _weeklyRepeatPeriod = (widget.isCreate) ? 1 : null; // default 1 week
    _monthlyRepeatPeriod = (widget.isCreate) ? 1 : null; // default 1 month

    _eventType = widget.event?.eventType;
    _locationLatitudeController.text = _printLatLng(widget.event?.exploreLocation?.latitude);
    _locationLongitudeController.text = _printLatLng(widget.event?.exploreLocation?.longitude);
    _locationBuildingController.text = widget.event?.exploreLocation?.building ?? widget.event?.exploreLocation?.name ?? '';
    _locationAddressController.text = widget.event?.exploreLocation?.address ?? widget.event?.exploreLocation?.description ?? '';

    _onlineUrlController.text = widget.event?.onlineDetails?.url ?? '';
    _onlineMeetingIdController.text = widget.event?.onlineDetails?.meetingId ?? '';
    _onlinePasscodeController.text = widget.event?.onlineDetails?.meetingPasscode ?? '';

    _attributes = widget.event?.attributes;
    _visibility = _defaultVisibility;

    //NA: canceled
    //NA: userRole

    _free = widget.event?.free ?? true;
    _published = widget.event?.published ?? true;
    _costController.text = widget.event?.cost ?? '';

    _registrationDetails = widget.event?.registrationDetails;
    _attendanceDetails = widget.event?.attendanceDetails;
    _surveyDetails = widget.event?.surveyDetails;
    _survey = widget.survey;

    _sponsor = widget.event?.sponsor;
    _speaker = widget.event?.speaker;
    _contacts = widget.event?.contacts;

    _dateTimeSectionExpanded = widget.isUpdate || (widget.event?.startTimeUtc != null);
    _typeAndLocationSectionExpanded = widget.isUpdate || (widget.event?.eventType != null);
    _costSectionExpanded = widget.isUpdate || (widget.event?.free != null) || (widget.event?.cost != null);

    _errorMap = _buildErrorMap();

    _titleController.addListener(_updateErrorMap);
    _onlineUrlController.addListener(_updateErrorMap);
    _locationLatitudeController.addListener(_updateErrorMap);
    _locationLongitudeController.addListener(_updateErrorMap);
    _costController.addListener(_updateErrorMap);
    _websiteController.addListener(_updateErrorMap);

    _initEventGroups();
    _initEventAdmins();

    super.initState();
  }

  @override
  void dispose() {
    _adminNetIdsController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();

    _locationBuildingController.dispose();
    _locationAddressController.dispose();
    _locationLatitudeController.dispose();
    _locationLongitudeController.dispose();

    _onlineUrlController.dispose();
    _onlineMeetingIdController.dispose();
    _onlinePasscodeController.dispose();

    _costController.dispose();

    _websiteFocus.dispose();
    _onlineUrlFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    PopScopeFix(onBack: _onHeaderBack, child: _buildScaffoldContent(),);

  Widget _buildScaffoldContent() => Scaffold(
    appBar: HeaderBar(title: widget.isCreate ?
      Localization().getStringEx("panel.event2.create.header.title", "Create an Event") :
      Localization().getStringEx("panel.event2.update.header.title", "Update Event"),
      onLeading: _onHeaderBack,),
    body: _buildPanelContent(),
    backgroundColor: Styles().colors.white,
  );

  Widget _buildPanelContent() =>
    SingleChildScrollView(child:
      Column(children: [
        _buildImageWidget(),
        _buildImageDescriptionSection(),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildAdminSettingsSection(),
            _buildTitleSection(),
            _buildDateAndTimeDropdownSection(),
            _buildRecurrenceDropdownSection(),
            _buildTypeAndLocationDropdownSection(),
            _buildCostDropdownSection(),
            _buildDescriptionSection(),
            _buildWebsiteSection(),
            _buildAttributesButtonSection(),
            _buildRegistrationButtonSection(),
            _buildAttendanceButtonSection(),
            _buildSurveyButtonSection(),
            _buildSponsorshipAndContactsButtonSection(),
            _buildGroupsButtonSection(),
            _buildPublishedSection(),
            _buildVisibilitySection(),
            _buildCreateEventSection(),
          ]),
        )
      ],)
    );

  // Image

  Widget _buildImageWidget() {
    String buttonTitle = (_imageUrl != null) ?
      Localization().getStringEx("panel.create_event.modify_image", "Modify event image") :
      Localization().getStringEx("panel.create_event.add_image", "Add event image");
    String buttonHint = (_imageUrl != null) ?
      Localization().getStringEx("panel.create_event.modify_image.hint","") :
      Localization().getStringEx("panel.create_event.add_image.hint","");

    return Container(height: 200, color: Styles().colors.background, child:
      Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          Positioned.fill(child: (_imageUrl != null) ?
            Image.network(_imageUrl!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders) : Container()
          ),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child: Container(height: 53)),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.white), child: Container(height: 30)),
          Positioned.fill(child:
            Center(child:
              Semantics(label: buttonTitle, hint: buttonHint, button: true, excludeSemantics: true, child:
                RoundedButton(
                  label: buttonTitle,
                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                  onTap: _onTapAddImage,
                  backgroundColor: Styles().colors.white,
                  borderColor: Styles().colors.fillColorSecondary,
                  contentWeight: 0.67,
                )
              ),
            ),
          )
        ],
      ),
    );
  }

  void _onTapAddImage() {
    Analytics().logSelect(target: "Add Image");
    Event2CreatePanel.hideKeyboard(context);
    GroupAddImageWidget.show(context: context, url: _imageUrl).then((ImagesResult? updateResult) {
      if (updateResult?.succeeded == true && (_imageUrl != updateResult?.imageUrl)) {
        setStateIfMounted(() {
          _imageUrl = updateResult?.imageUrl;
        });
      }
    });

  }

  Widget _buildImageDescriptionSection() {
    return Padding(
        padding: EdgeInsets.only(left: 16, right: 16, top: 20),
        child: Row(children: [
          Expanded(
              child: Text(
                  Localization().getStringEx('panel.event2.create.section.image.description',
                      "The event image displays a 16:9 or 1000px x 615px jpg, png, or gif (not animated). Larger images are automatically positioned within the frame and can be tapped to view in their entirety within the Illinois app."),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 8,
                  style: Styles().textStyles.getTextStyle('widget.message.small')))
        ]));
  }

  //
  // AdminSection

  Widget _buildAdminSettingsSection() => Stack(alignment: Alignment.center ,children: [
    Event2CreatePanel.buildSectionWidget(
      heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('', "Event Admins NetIDs (comma separated)"), required: true),
      body: Event2CreatePanel.buildTextEditWidget(_adminNetIdsController, keyboardType: TextInputType.text, maxLines: null, autocorrect: true, semanticsLabel: Localization().getStringEx('panel.event2.create.section.title.field.title', 'TITLE FIELD'),),
    ),
    Align(alignment: Alignment.centerLeft, child:
        Visibility(visible: _loadingAdmins, child:
          Padding(padding: const EdgeInsets.only(left: 16), child:
            SizedBox(width: 14, height: 14, child:
              CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
            ),
          )
        )
    )
  ]);

  // Title and Description
  Widget _buildTitleSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.title.title', 'EVENT TITLE'), required: true),
    body: Event2CreatePanel.buildTextEditWidget(_titleController, keyboardType: TextInputType.text, maxLines: null, autocorrect: true, semanticsLabel: Localization().getStringEx('panel.event2.create.section.title.field.title', 'TITLE FIELD'),),
  );

  Widget _buildDescriptionSection() {
    String title = Localization().getStringEx('panel.event2.create.section.description.title', 'EVENT DESCRIPTION');
    String description = Localization().getStringEx(	"panel.event2.create.section.description.description", " (Hyperlinks added to this field will not be active. Please add all urls to the appropriate fields such as the event type online url, event website link, or event registration external link.)",);
    String semanticsLabel = title + description;

    return Event2CreatePanel.buildSectionWidget(
      heading: Padding(padding: Event2CreatePanel.sectionHeadingPadding, child:
        Semantics(label: semanticsLabel, header: true, excludeSemantics: true, child:
          Row(children: [
            Expanded(child:
              RichText(textScaler: MediaQuery.of(context).textScaler, text:
                TextSpan(text: title, style: Event2CreatePanel.headingTextStype,  children: <InlineSpan>[
                  TextSpan(text: description, style: Styles().textStyles.getTextStyle('widget.item.small.thin'),),
                ])
              )
            ),
          ]),
        )
      ),
      body: Event2CreatePanel.buildTextEditWidget(_descriptionController, keyboardType: TextInputType.text, maxLines: null, minLines: 3, autocorrect: true, semanticsLabel: Localization().getStringEx('panel.event2.create.section.description.field.title', 'DESCRIPTION FIELD')),
    );
  }

  Widget _buildWebsiteSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.website.title', 'ADD EVENT WEBSITE LINK'), suffixImageKey: 'external-link'),
    body: Event2CreatePanel.buildTextEditWidget(_websiteController, focusNode: _websiteFocus, keyboardType: TextInputType.url, semanticsLabel: Localization().getStringEx('panel.event2.create.section.website.field.title', 'WEBSITE LINK FIELD')),
    trailing: Event2CreatePanel.buildConfirmUrlLink(onTap: _onConfirmWebsiteLink, progress: _confirmingWebsiteUrl),
    padding: const EdgeInsets.only(bottom: 8), // Link button tapable area
  );

  void _onConfirmWebsiteLink() => Event2CreatePanel.confirmLinkUrl(context, _websiteController, focusNode: _websiteFocus, analyticsTarget: 'Confirm Website URL', updateProgress: (bool value) {
    setStateIfMounted(() { _confirmingWebsiteUrl = value; });
  });

  // Date & Time

  /*Widget _buildDateAndTimeSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.date_and_time.title', 'DATE AND TIME'),
      required: true
    ),
    body: _buildDateAndTimeSectionBody(),
    bodyPadding: EdgeInsets.only(top: 8)
  );*/

  Widget _buildDateAndTimeDropdownSection() => Event2CreatePanel.buildDropdownSectionWidget(
    heading: Event2CreatePanel.buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.date_and_time.title', 'DATE AND TIME'),
      required: true,
      expanded: _dateTimeSectionExpanded,
      onToggleExpanded: _onToggleDateAndTimeSection,
    ),
    body: _buildDateAndTimeSectionBody(),
    bodyPadding: _hasEndDateOrTime ? const EdgeInsets.only(left: 16, right: 16, top: 16) : Event2CreatePanel.sectionBodyContentPadding,
    expanded: _dateTimeSectionExpanded,
  );

  Widget _buildDateAndTimeSectionBody() => Column(children: [
    _buildTimeZoneDropdown(),
    
    Padding(padding: EdgeInsets.only(bottom: 12)),
    
    _buildDateTimeWidget(
      date: _startDate,
      time: _startTime,
      onDate: _onStartDate,
      onTime: _onStartTime,
      hasTime: (_allDay != true),
      semanticsDateLabel: Localization().getStringEx("panel.create_event.date_time.start_date.title", "START DATE"),
      semanticsTimeLabel: Localization().getStringEx("panel.create_event.date_time.start_time.title",'START TIME'),
      dateLabel: Localization().getStringEx("panel.create_event.date_time.start_date.title", "START DATE"),
      dateRequired: true,
      timeLabel: Localization().getStringEx("panel.create_event.date_time.start_time.title","START TIME"),
      timeRequired: true,
    ),
    
    Padding(padding: EdgeInsets.only(bottom: 12)),
    
    _buildDateTimeWidget(
      date: _endDate,
      time: _endTime,
      onDate: _onEndDate,
      onTime: _onEndTime,
      hasTime: (_allDay != true),
      semanticsDateLabel: Localization().getStringEx("panel.create_event.date_time.end_date.title", "END DATE"),
      semanticsTimeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title",'END TIME'),
      dateLabel: Localization().getStringEx("panel.create_event.date_time.end_date.title", "END DATE"),
      dateRequired: (_endDate == null) && (_endTime != null),
      timeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title","END TIME"),
      timeRequired: (_endDate != null) && (_endTime == null),
    ),

    Visibility(visible: _hasEndDateOrTime, child:
      Align(alignment: Alignment.bottomRight, child:
        LinkButton(
          title: Localization().getStringEx('panel.event2.create.button.clear_end_datetime.title', 'Clear End Date and Time'),
          hint: Localization().getStringEx('panel.event2.create.button.clear_end_datetime.hint', ''),
          onTap: _onClearEndDateTime,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    ),
    
    //Padding(padding: EdgeInsets.only(bottom: 12)),

    //_buildAllDayToggle(),

  ]);

  bool get _hasEndDateOrTime =>
    ((_endDate != null) || (_endTime != null));


  Widget _buildTimeZoneDropdown(){
    return Semantics(container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 4, child:
          Event2CreatePanel.buildSectionTitleWidget(Localization().getStringEx("panel.create_event.date_time.time_zone.title", "TIME ZONE"), required: true),
        ),
        Container(width: 16,),
        Expanded(flex: 6, child:
          Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
            Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
              DropdownButtonHideUnderline(child:
                DropdownButton<Location>(
                  dropdownColor: Styles().colors.white,
                  icon: Styles().images.getImage('chevron-down'),
                  isExpanded: true,
                  style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                  hint: Text(_timeZone.name,),
                  items: _buildTimeZoneDropDownItems(),
                  onChanged: _onTimeZoneChanged
                ),
              ),
            ),
          ),
        ),
      ])
    );
  }

  List<DropdownMenuItem<Location>>? _buildTimeZoneDropDownItems() {
    List<DropdownMenuItem<Location>> menuItems = <DropdownMenuItem<Location>>[];
    timeZoneDatabase.locations.forEach((String name, Location location) {
      if (name.startsWith('US/')) {
        menuItems.add(DropdownMenuItem<Location>(
          value: location,
          child: Semantics(label: name, excludeSemantics: true, container:true, child: Text(name,)),
        ));
        }
    });
    
    return menuItems;
  }

  void _onTimeZoneChanged(Location? value) {
    Analytics().logSelect(target: "Time Zone selected: $value");
    Event2CreatePanel.hideKeyboard(context);
    if ((value != null) && mounted) {
      setState(() {
        _timeZone = value;
      });
    }
  }

  Widget _buildDateTimeWidget({
    DateTime? date,
    TimeOfDay? time,
    void Function()? onDate,
    void Function()? onTime,
    bool hasTime = true,
    String? dateLabel,
    bool dateRequired = false,
    String? timeLabel,
    bool timeRequired = false,
    String? semanticsDateLabel,
    String? semanticsTimeLabel,
  }) {
    List<Widget> contentList = <Widget>[
      Expanded(flex: hasTime ? 65 : 100, child:
        Semantics(label: semanticsDateLabel, button: true, excludeSemantics: true, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: EdgeInsets.only(bottom: 4), child:
              Row(children: <Widget>[
                Event2CreatePanel.buildSectionTitleWidget(dateLabel ?? '', required: dateRequired),
              ],),
            ),
            _buildDropdownButton(label: (date != null) ? DateFormat("EEE, MMM dd, yyyy").format(date) : "-", onTap: onDate,)
          ],)
        ),
      ),
    ];
    
    if (hasTime) {
      contentList.add(Expanded(flex: 35, child:
        Padding(padding: EdgeInsets.only(left: 4), child:
          Semantics(label: semanticsTimeLabel, button: true, excludeSemantics: true, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(bottom: 4), child:
                Row(children: <Widget>[
                  Event2CreatePanel.buildSectionTitleWidget(timeLabel ?? '', required: timeRequired),
                ],),
              ),
              _buildDropdownButton(label: (time != null) ? DateFormat("h:mma").format(_dateWithTimeOfDay(time)) : "-", onTap: onTime,),
            ],)
          ),
        ),
      ),);
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: contentList,);
  }

  Widget _buildDropdownButton({String? label, GestureTapCallback? onTap}) {
    return InkWell(onTap: onTap, child:
      Container(decoration: Event2CreatePanel.dropdownButtonDecoration, padding: Event2CreatePanel.dropdownButtonContentPadding, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text(label ??  '-', style: Styles().textStyles.getTextStyle("widget.title.regular"),),
          Styles().images.getImage('chevron-down') ?? Container()
        ],),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildAllDayToggle() => Semantics(toggled: _allDay, excludeSemantics: true, 
    label:Localization().getStringEx("panel.create_event.date_time.all_day","All day"),
    hint: Localization().getStringEx("panel.create_event.date_time.all_day.hint",""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.create_event.date_time.all_day","All day"),
      padding: _togglePadding,
      toggled: _allDay,
      onTap: _onTapAllDay,
      border: _toggleBorder,
      borderRadius: _toggleBorderRadius,
    ));

  EdgeInsetsGeometry get _togglePadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  BoxBorder get _toggleBorder => Border.all(color: Styles().colors.surfaceAccent, width: 1);
  BorderRadius get _toggleBorderRadius => BorderRadius.all(Radius.circular(4));

  void _onToggleDateAndTimeSection() {
    Analytics().logSelect(target: "Toggle Date & Time");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _dateTimeSectionExpanded = !_dateTimeSectionExpanded;
    });
  }

  void _onStartDate() {
    Analytics().logSelect(target: "Start Date");
    Event2CreatePanel.hideKeyboard(context);
    DateTime now = DateUtils.dateOnly(DateTime.now());
    DateTime minDate = now;
    DateTime maxDate = ((_endDate != null) && now.isBefore(_endDate!)) ? _endDate! : now.add(Duration(days: 366));
    DateTime selectedDate = (_startDate != null) ? DateTimeUtils.min(DateTimeUtils.max(_startDate!, minDate), maxDate) : minDate;
    showDatePicker(context: context,
      initialDate: selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
      builder: (context, child) => _datePickerTransitionBuilder(context, child!),
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _startDate = DateUtils.dateOnly(result);
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  void _onStartTime() {
    Analytics().logSelect(target: "Start Time");
    Event2CreatePanel.hideKeyboard(context);
    showTimePicker(
      context: context,
      initialTime: _startTime ?? TimeOfDay(hour: 0, minute: 0),
      builder: (context, child) => _timePickerTransitionBuilder(context, child!),
    ).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _startTime = result;
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  void _onEndDate() {
    Analytics().logSelect(target: "End Date");
    Event2CreatePanel.hideKeyboard(context);
    DateTime now = DateUtils.dateOnly(DateTime.now());
    DateTime minDate = (_startDate != null) ? DateTimeUtils.max(_startDate!, now) : now;
    DateTime maxDate = minDate.add(Duration(days: 366));
    DateTime selectedDate = (_endDate != null) ? DateTimeUtils.min(DateTimeUtils.max(_endDate!, minDate), maxDate) : minDate;
    showDatePicker(context: context,
      initialDate: selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
      builder: (context, child) => _datePickerTransitionBuilder(context, child!),
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _endDate = DateUtils.dateOnly(result);
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  void _onEndTime() {
    Analytics().logSelect(target: "End Time");
    Event2CreatePanel.hideKeyboard(context);
    showTimePicker(
        context: context,
        initialTime: _endTime ?? TimeOfDay(hour: 0, minute: 0),
        builder: (context, child) => _timePickerTransitionBuilder(context, child!),
    ).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _endTime = result;
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  void _onClearEndDateTime() {
    Analytics().logSelect(target: "Clear End Date and Time");
    Event2CreatePanel.hideKeyboard(context);
    setState(() {
      _endDate = null;
      _endTime = null;
      _errorMap = _buildErrorMap();
    });
  }

  DateTime _dateWithTimeOfDay(TimeOfDay time) =>
    _dateTimeWithDateAndTimeOfDay(DateTime.now(), time);

  TZDateTime _dateTimeWithDateAndTimeOfDay(DateTime date, TimeOfDay? time, { bool inclusive = false}) =>
    TZDateTime(_timeZone, date.year, date.month, date.day, time?.hour ?? (inclusive ? 23 : 0), time?.minute ?? (inclusive ? 59 : 0));

  void _onTapAllDay() {
    Analytics().logSelect(target: "Toggle All Day");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _allDay = !_allDay;
    });
  }

  // Recurrence Section - show it only when creating an event

  // 1 Common Recurrence sections

  Widget _buildRecurrenceDropdownSection() => Visibility(visible: widget.isCreate, child: Event2CreatePanel.buildDropdownSectionWidget(
    heading: Event2CreatePanel.buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.recurrence.title', 'RECURRENCE'),
        required: false,
        expanded: _recurrenceSectionExpanded,
        onToggleExpanded: _onToggleRecurrenceSection
    ),
    body: _buildRecurrenceSectionBody(),
    expanded: _recurrenceSectionExpanded,
  ));

  Widget _buildRecurrenceSectionBody() {
    List<Widget> contentList = <Widget>[
      _buildRepeatTypeDropDown(),
    ];

    if (_recurrenceRepeatType == _RecurrenceRepeatType.weekly) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildRepeatOnWeeklySectionWidget(),
        _buildRecurrenceEveryWeekSectionWidget(),
        _buildRecurrenceEndOnSectionWidget()
      ]);
    } else if (_recurrenceRepeatType == _RecurrenceRepeatType.monthly) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildRepeatOnMonthlySectionWidget(),
        _buildRecurrenceEveryMonthSectionWidget(),
        _buildRecurrenceEndOnSectionWidget()
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget _buildRepeatTypeDropDown() {
    String? title = Localization().getStringEx('panel.event2.create.label.repeat_type.title', 'REPEAT');
    return Semantics(
        label: title,
        container: true,
        child: Row(children: <Widget>[
          Expanded(
              flex: 1,
              child: RichText(
                  textScaler: MediaQuery.of(context).textScaler,
                  text: TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: ""))),
          Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
          Expanded(
              flex: 4,
              child: Container(
                  decoration: Event2CreatePanel.dropdownButtonDecoration,
                  child: Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<_RecurrenceRepeatType>(
                              dropdownColor: Styles().colors.white,
                              icon: Styles().images.getImage('chevron-down'),
                              isExpanded: true,
                              style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                              hint: Text(_repeatTypeToDisplayString(_recurrenceRepeatType) ?? '-----',),
                              items: _buildRepeatTypeDropDownItems(),
                              onChanged: _onRepeatTypeChanged)))))
        ]));
  }

  List<DropdownMenuItem<_RecurrenceRepeatType>>? _buildRepeatTypeDropDownItems() {
    List<DropdownMenuItem<_RecurrenceRepeatType>> menuItems = <DropdownMenuItem<_RecurrenceRepeatType>>[];

    for (_RecurrenceRepeatType repeatType in _RecurrenceRepeatType.values) {
      menuItems.add(DropdownMenuItem<_RecurrenceRepeatType>(value: repeatType, child: Text(_repeatTypeToDisplayString(repeatType) ?? '')));
    }

    return menuItems;
  }

  Widget _buildRecurrenceEndOnSectionWidget() {
    String? title = Localization().getStringEx('panel.event2.create.label.recurrence.end_on.label', 'END ON');
    return Semantics(
        label: title,
        container: true,
        child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: Row(children: <Widget>[
              Expanded(
                  flex: 1,
                  child: RichText(
                      textScaler: MediaQuery.of(context).textScaler,
                      text: TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: ""))),
              Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
              Expanded(
                  flex: 4,
                  child: InkWell(
                      splashColor: Colors.transparent,
                      onTap: _onTapRecurrenceEndDate,
                      child: Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
                        Padding(padding: EdgeInsets.only(right: 10), child: Icon(Icons.calendar_today)),
                        Text(
                            _hasRecurrenceEndDate
                                ? DateFormat("EEE, MMM dd, yyyy").format(_recurrenceEndDate!)
                                : Localization().getStringEx('panel.event2.create.label.recurrence.end_date.label', 'End Date'),
                            style: _hasRecurrenceEndDate
                                ? Styles().textStyles.getTextStyle('widget.button.title.small.fat')
                                : Event2CreatePanel.headingDisabledTextStype)
                      ])))
            ])));
  }

  void _onToggleRecurrenceSection() {
    Analytics().logSelect(target: "Toggle Recurrence");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _recurrenceSectionExpanded = !_recurrenceSectionExpanded;
    });
  }

  void _onRepeatTypeChanged(_RecurrenceRepeatType? value) {
    Analytics().logSelect(target: "Recurrence Repeat type selected: $value");
    Event2CreatePanel.hideKeyboard(context);
    if (value != null) {
      setStateIfMounted(() {
        _recurrenceRepeatType = value;
        _errorMap = _buildErrorMap();
      });
    }
  }

  void _onTapRecurrenceEndDate() {
    Analytics().logSelect(target: 'Recurrence: End Date');
    Event2CreatePanel.hideKeyboard(context);
    DateTime now = DateUtils.dateOnly(DateTime.now());
    DateTime minDate = now;
    DateTime maxDate = now.add(Duration(days: 366));
    DateTime selectedDate =
    (_recurrenceEndDate != null) ? DateTimeUtils.min(DateTimeUtils.max(_recurrenceEndDate!, minDate), maxDate) : minDate;
    showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
      builder: (context, child) => _datePickerTransitionBuilder(context, child!),
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _recurrenceEndDate = DateUtils.dateOnly(result);
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  // 2 Weekly Section

  Widget _buildRepeatOnWeeklySectionWidget() {
    String? title = Localization().getStringEx('panel.event2.create.label.recurrence.on.label', 'ON');
    return Semantics(
        label: title,
        container: true,
        child: Row(children: <Widget>[
          Expanded(
              flex: 1,
              child: RichText(
                  textScaler: MediaQuery.of(context).textScaler,
                  text: TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: ""))),
          Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
          Expanded(
              flex: 4,
              child: _buildRecurrenceWeekDays())
        ]));
  }

  Widget _buildRecurrenceWeekDays() {
    List<Widget> daysWidgets = <Widget>[];
    for (DayOfWeek day in DayOfWeek.values) {
      bool selected = CollectionUtils.isNotEmpty(_recurrenceWeekDays) && _recurrenceWeekDays!.contains(day);
      String imageKey = selected ? 'check-circle-filled' : 'circle-outline-gray';
      daysWidgets.add(InkWell(
          splashColor: Colors.transparent,
          onTap: () => _onToggleWeekDay(day),
          child: Padding(
              padding: EdgeInsets.only(right: 10),
              child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Styles().images.getImage(imageKey) ?? Container(),
                Padding(padding: EdgeInsets.only(left: 6), child: Text(day.name))
              ]))));
    }
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 6, children: daysWidgets);
  }

  Widget _buildRecurrenceEveryWeekSectionWidget() {
    String? title = Localization().getStringEx('panel.event2.create.label.recurrence.every.label', 'EVERY');
    return Semantics(
        label: title,
        container: true,
        child: Padding(padding: EdgeInsets.only(top: 16), child: Row(children: <Widget>[
          Expanded(
              flex: 1,
              child: RichText(
                  textScaler: MediaQuery.of(context).textScaler,
                  text: TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: ""))),
          Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
          Expanded(
              flex: 4,
              child: Container(
                  decoration: Event2CreatePanel.dropdownButtonDecoration,
                  child: Padding(
                      padding: EdgeInsets.only(left: 12, right: 8),
                      child: DropdownButtonHideUnderline(
                          child: DropdownButton<int?>(
                              dropdownColor: Styles().colors.white,
                              icon: Styles().images.getImage('chevron-down'),
                              isExpanded: true,
                              style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                              hint: Text(_getEveryWeekRecurrencePeriod(_weeklyRepeatPeriod)),
                              items: _buildWeeklyRecurrenceDropDownItems(),
                              value: _weeklyRepeatPeriod,
                              onChanged: _onWeeklyPeriodChanged)))))
        ])));
  }

  List<DropdownMenuItem<int?>>? _buildWeeklyRecurrenceDropDownItems() {
    List<DropdownMenuItem<int?>> menuItems = <DropdownMenuItem<int?>>[];
    for (int i = 1; i<= _maxRecurrenceWeeksValue; i++) {
      menuItems.add(DropdownMenuItem<int?>(value: i, child: Text(_getEveryWeekRecurrencePeriod(i))));
    }

    return menuItems;
  }

  String _getEveryWeekRecurrencePeriod(int? period) {
    if (period == null) {
      return '-----';
    }

    String weeksLabel = (period > 1)
        ? Localization().getStringEx('panel.event2.create.label.recurrence.period.weeks.label', 'weeks')
        : Localization().getStringEx('panel.event2.create.label.recurrence.period.week.label', 'week');
    return '$period $weeksLabel';
  }

  void _onToggleWeekDay(DayOfWeek day) {
    setStateIfMounted(() {
      if (_recurrenceWeekDays == null) {
        _recurrenceWeekDays = <DayOfWeek>[];
        _recurrenceWeekDays!.add(day);
      } else if (_recurrenceWeekDays!.contains(day)) {
        _recurrenceWeekDays!.remove(day);
      } else {
        _recurrenceWeekDays!.add(day);
      }
      _errorMap = _buildErrorMap();
    });
  }

  void _onWeeklyPeriodChanged(int? value) {
    Analytics().logSelect(target: "Recurrence Every week: $value");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _weeklyRepeatPeriod = value;
      _errorMap = _buildErrorMap();
    });
  }

  // 3 Monthly Section

  Widget _buildRepeatOnMonthlySectionWidget() {
    String? title = Localization().getStringEx('panel.event2.create.label.recurrence.on.label', 'ON');
    return Semantics(
        label: title,
        container: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.start, crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(
                flex: 1,
                child: RichText(
                    textScaler: MediaQuery.of(context).textScaler,
                    text: TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: ""))),
            Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
            InkWell(
                onTap: () => _onRecurrenceRepeatMonthlyTypeChanged(_RecurrenceRepeatMonthlyType.daily),
                splashColor: Colors.transparent,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Event2CreatePanel.innerRecurrenceSectionPaddingWidth, vertical: 10),
                    child: Styles().images.getImage((_recurrenceRepeatMonthlyType == _RecurrenceRepeatMonthlyType.daily)
                        ? 'check-circle-filled'
                        : 'circle-outline-gray'))),
            Expanded(
                flex: 2,
                child: Container(
                    decoration: Event2CreatePanel.dropdownButtonDecoration,
                    child: Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton<int?>(
                                dropdownColor: Styles().colors.white,
                                icon: Styles().images.getImage('chevron-down'),
                                isExpanded: true,
                                style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                                hint: Text(_getRecurrenceMonthlyDayLabel(_recurrenceRepeatDay)),
                                items: _buildRecurrenceMonthDayDropDownItems(),
                                value: _recurrenceRepeatDay,
                                onChanged: _onMonthDayChanged))))),
            Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
            Expanded(flex: 2, child: Container())
          ]),
          Padding(padding: EdgeInsets.only(top: 10), child: Row(children: [
            Expanded(flex: 1, child: Container()),
            Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
            InkWell(
                onTap: () => _onRecurrenceRepeatMonthlyTypeChanged(_RecurrenceRepeatMonthlyType.weekly),
                splashColor: Colors.transparent,
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: Event2CreatePanel.innerRecurrenceSectionPaddingWidth, vertical: 10),
                    child: Styles().images.getImage((_recurrenceRepeatMonthlyType == _RecurrenceRepeatMonthlyType.weekly)
                        ? 'check-circle-filled'
                        : 'circle-outline-gray'))),
            Expanded(
                flex: 2,
                child: Container(
                    decoration: Event2CreatePanel.dropdownButtonDecoration,
                    child: Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton<_RecurrenceOrdinalNumber>(
                                dropdownColor: Styles().colors.white,
                                icon: Styles().images.getImage('chevron-down'),
                                isExpanded: true,
                                style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                                hint: Text(_recurrenceOrdinalNumberToDisplayString(_recurrenceOrdinalNumber)),
                                items: _buildRecurrenceOrdinalNumberDropDownItems(),
                                value: _recurrenceOrdinalNumber,
                                onChanged: _onMonthlyOrdinalNumberChanged))))),
            Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
            Expanded(
                flex: 2,
                child: Container(
                    decoration: Event2CreatePanel.dropdownButtonDecoration,
                    child: Padding(
                        padding: EdgeInsets.only(left: 12, right: 8),
                        child: DropdownButtonHideUnderline(
                            child: DropdownButton<_RecurrenceMonthWeekDay>(
                                dropdownColor: Styles().colors.white,
                                icon: Styles().images.getImage('chevron-down'),
                                isExpanded: true,
                                style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                                hint: Text(_recurrenceMonthWeekDayToDisplayString(_recurrenceMonthWeekDay)),
                                items: _buildRecurrenceMonthWeekDayDropDownItems(),
                                value: _recurrenceMonthWeekDay,
                                onChanged: _onMonthWeekDayChanged)))))
          ]))
        ]));
  }

  List<DropdownMenuItem<int?>>? _buildRecurrenceMonthDayDropDownItems() {
    List<DropdownMenuItem<int?>> menuItems = <DropdownMenuItem<int?>>[];
    for (int i = 1; i <= _maxRecurrenceRepeatDayValue; i++) {
      menuItems.add(DropdownMenuItem<int?>(value: i, child: Text(_getRecurrenceMonthlyDayLabel(i))));
    }

    return menuItems;
  }

  List<DropdownMenuItem<_RecurrenceOrdinalNumber>>? _buildRecurrenceOrdinalNumberDropDownItems() {
    List<DropdownMenuItem<_RecurrenceOrdinalNumber>> menuItems = <DropdownMenuItem<_RecurrenceOrdinalNumber>>[];
    for (_RecurrenceOrdinalNumber number in _RecurrenceOrdinalNumber.values) {
      menuItems.add(DropdownMenuItem<_RecurrenceOrdinalNumber>(
          value: number, child: Text(_recurrenceOrdinalNumberToDisplayString(number))));
    }

    return menuItems;
  }

  List<DropdownMenuItem<_RecurrenceMonthWeekDay>>? _buildRecurrenceMonthWeekDayDropDownItems() {
    List<DropdownMenuItem<_RecurrenceMonthWeekDay>> menuItems = <DropdownMenuItem<_RecurrenceMonthWeekDay>>[];
    for (_RecurrenceMonthWeekDay weekDay in _RecurrenceMonthWeekDay.values) {
      menuItems.add(DropdownMenuItem<_RecurrenceMonthWeekDay>(
          value: weekDay, child: Text(_recurrenceMonthWeekDayToDisplayString(weekDay))));
    }

    return menuItems;
  }

  Widget _buildRecurrenceEveryMonthSectionWidget() {
    String? title = Localization().getStringEx('panel.event2.create.label.recurrence.every.label', 'EVERY');
    return Semantics(
        label: title,
        container: true,
        child: Padding(
            padding: EdgeInsets.only(top: 16),
            child: Row(children: <Widget>[
              Expanded(
                  flex: 1,
                  child: RichText(
                      textScaler: MediaQuery.of(context).textScaler,
                      text: TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: ""))),
              Container(width: Event2CreatePanel.innerRecurrenceSectionPaddingWidth),
              Expanded(
                  flex: 4,
                  child: Container(
                      decoration: Event2CreatePanel.dropdownButtonDecoration,
                      child: Padding(
                          padding: EdgeInsets.only(left: 12, right: 8),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                  dropdownColor: Styles().colors.white,
                                  icon: Styles().images.getImage('chevron-down'),
                                  isExpanded: true,
                                  style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                                  hint: Text(_getEveryMonthRecurrencePeriod(_monthlyRepeatPeriod)),
                                  items: _buildMonthlyRecurrenceDropDownItems(),
                                  value: _monthlyRepeatPeriod,
                                  onChanged: _onMonthlyPeriodChanged)))))
            ])));
  }

  List<DropdownMenuItem<int?>>? _buildMonthlyRecurrenceDropDownItems() {
    List<DropdownMenuItem<int?>> menuItems = <DropdownMenuItem<int?>>[];
    for (int i = 1; i <= _maxRecurrenceMonthsValue; i++) {
      menuItems.add(DropdownMenuItem<int?>(value: i, child: Text(_getEveryMonthRecurrencePeriod(i))));
    }

    return menuItems;
  }

  String _getEveryMonthRecurrencePeriod(int? period) {
    if (period == null) {
      return '-----';
    }

    String monthsLabel = (period > 1)
        ? Localization().getStringEx('panel.event2.create.label.recurrence.period.months.label', 'months')
        : Localization().getStringEx('panel.event2.create.label.recurrence.period.month.label', 'month');
    return '$period $monthsLabel';
  }

  void _onRecurrenceRepeatMonthlyTypeChanged(_RecurrenceRepeatMonthlyType? value) {
    Analytics().logSelect(target: 'Recurrence Monthly type: $value');
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _recurrenceRepeatMonthlyType = value;
      _errorMap = _buildErrorMap();
    });
  }

  void _onMonthlyPeriodChanged(int? value) {
    Analytics().logSelect(target: 'Recurrence Every month: $value');
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _monthlyRepeatPeriod = value;
      _errorMap = _buildErrorMap();
    });
  }

  void _onMonthDayChanged(int? day) {
    Analytics().logSelect(target: "Recurrence Every month day: $day");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _recurrenceRepeatDay = day;
      _errorMap = _buildErrorMap();
    });
  }

  void _onMonthlyOrdinalNumberChanged(_RecurrenceOrdinalNumber? value) {
    Analytics().logSelect(target: 'Recurrence Ordinal number: $value');
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _recurrenceOrdinalNumber = value;
      _errorMap = _buildErrorMap();
    });
  }

  void _onMonthWeekDayChanged(_RecurrenceMonthWeekDay? value) {
    Analytics().logSelect(target: 'Recurrence Month week day: $value');
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _recurrenceMonthWeekDay = value;
      _errorMap = _buildErrorMap();
    });
  }

  // Event Type, Location and Online Details

  Widget _buildTypeAndLocationDropdownSection() => Event2CreatePanel.buildDropdownSectionWidget(
    heading: Event2CreatePanel.buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.type_and_location.title', 'EVENT TYPE AND LOCATION'),
      required: true,
      expanded: _typeAndLocationSectionExpanded,
      onToggleExpanded: _onToggleTypeAndLocationSection,
    ),
    body: _buildTypeAndLocationSectionBody(),
    expanded: _typeAndLocationSectionExpanded,
  );

  Widget _buildTypeAndLocationSectionBody() {
    List<Widget> contentList = <Widget>[
      _buildEventTypeDropdown(),
    ];

    if (_eventType == Event2Type.hybrid) {
      contentList.add(Padding(padding: EdgeInsets.only(top: Event2CreatePanel.sectionPaddingHeight), child: _innerSectionSplitter));
    }

    if ((_eventType == Event2Type.online) || (_eventType == Event2Type.hybrid)) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildOnlineUrlInnerSection(),
        _buildOnlineMeetingIdInnerSection(),
        _buildOnlinePasscodeInnerSection(),
      ]);
    }

    if (_eventType == Event2Type.hybrid) {
      contentList.add(Padding(padding: EdgeInsets.symmetric(vertical: Event2CreatePanel.innerSectionPaddingHeight), child: _innerSectionSplitter));
    }

    if ((_eventType == Event2Type.inPerson) || (_eventType == Event2Type.hybrid)) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildSelectLocationButton(),
        _buildLocationBuildingInnerSection(),
        _buildLocationAddressInnerSection(),
        _buildLocationLatitudeInnerSection(),
        _buildLocationLongitudeInnerSection(),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget _buildEventTypeDropdown(){
    String? title = Localization().getStringEx("panel.event2.create.label.event_type.title", "EVENT TYPE");
    return Semantics(label: "$title, required", container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 4, child:
          RichText(textScaler: MediaQuery.of(context).textScaler, text:
            TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: "", children: <InlineSpan>[
              TextSpan(text: ' *', style: Styles().textStyles.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
            ])
          )
        ),
        Container(width: 16,),
        Expanded(flex: 6, child:
          Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
            Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
              DropdownButtonHideUnderline(child:
                DropdownButton<Event2Type>(
                  dropdownColor: Styles().colors.white,
                  icon: Styles().images.getImage('chevron-down'),
                  isExpanded: true,
                  style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                  hint: Text(event2TypeToDisplayString(_eventType) ?? '-',),
                  items: _buildEventTypeDropDownItems(),
                  onChanged: _onEventTypeChanged
                ),
              ),
            ),
          ),
        ),
      ])
    );
  }

  List<DropdownMenuItem<Event2Type>>? _buildEventTypeDropDownItems() {
    List<DropdownMenuItem<Event2Type>> menuItems = <DropdownMenuItem<Event2Type>>[];

    for (Event2Type eventType in Event2Type.values) {
      menuItems.add(DropdownMenuItem<Event2Type>(
        value: eventType,
        child: Text(event2TypeToDisplayString(eventType) ?? '',),
      ));
    }

    return menuItems;
  }

  void _onToggleTypeAndLocationSection() {
    Analytics().logSelect(target: "Toggle Event Type and Location");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _typeAndLocationSectionExpanded = !_typeAndLocationSectionExpanded;
    });
  }

  void _onEventTypeChanged(Event2Type? value) {
    Analytics().logSelect(target: "Time Zone selected: $value");
    Event2CreatePanel.hideKeyboard(context);
    if ((value != null) && mounted) {
      setState(() {
        _eventType = value;
        _errorMap = _buildErrorMap();
      });
    }
  }

  Widget _buildLocationBuildingInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.building.title', 'LOCATION BUILDING')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationBuildingController, keyboardType: TextInputType.text, autocorrect: true, semanticsLabel: Localization().getStringEx('panel.event2.create.location.building.field', 'LOCATION BUILDING FIELD')),
  );

  Widget _buildLocationAddressInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.address.title', 'LOCATION ADDRESS')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationAddressController, keyboardType: TextInputType.text, autocorrect: true, semanticsLabel: Localization().getStringEx('panel.event2.create.location.address.field', 'LOCATION ADDRESS FIELD')),
  );

  Widget _buildLocationLatitudeInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.latitude.title', 'LOCATION LATITUDE'), required: true),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationLatitudeController, keyboardType: TextInputType.number, semanticsLabel: Localization().getStringEx('panel.event2.create.location.latitude.field', 'LOCATION LATITUDE FIELD')),
  );

  Widget _buildLocationLongitudeInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.longitude.title', 'LOCATION LONGITUDE'), required: true),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationLongitudeController, keyboardType: TextInputType.number, semanticsLabel: Localization().getStringEx('panel.event2.create.location.longitude.field', 'LOCATION LONGITUDE FIELD')),
  );

  Widget _buildSelectLocationButton() {
    String buttonTitle = Localization().getStringEx("panel.event2.create.location.button.select.title", "Select Location on a Map");
    String buttonHint = Localization().getStringEx("panel.event2.create.location.button.select.hint", "");

    return Padding(padding: Event2CreatePanel.innerSectionPadding, child:
      Semantics(label: buttonTitle, hint: buttonHint, button: true, excludeSemantics: true, child:
        RoundedButton(
          label: buttonTitle,
          textStyle: Styles().textStyles.getTextStyle("widget.button.title.regular"),
          onTap: _onTapSelectLocation,
          backgroundColor: Styles().colors.white,
          borderColor: Styles().colors.fillColorSecondary,
        )
      ),
    );
  }

  Widget _buildOnlineUrlInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.online_details.url.title', 'ONLINE URL'), required: true),
    body: Event2CreatePanel.buildInnerTextEditWidget(_onlineUrlController, focusNode: _onlineUrlFocus, keyboardType: TextInputType.url, semanticsLabel: Localization().getStringEx('panel.event2.create.online_details.url.field', 'ONLINE URL FIELD')),
    trailing: Event2CreatePanel.buildConfirmUrlLink(onTap: _onConfirmOnlineUrlLink, progress: _confirmingOnlineUrl),
    padding: EdgeInsets.zero,
  );

  void _onConfirmOnlineUrlLink() => Event2CreatePanel.confirmLinkUrl(context, _onlineUrlController, focusNode: _onlineUrlFocus, analyticsTarget: 'Confirm Online URL', updateProgress: (bool value) {
    setStateIfMounted(() { _confirmingOnlineUrl = value; });
  });

  Widget _buildOnlineMeetingIdInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.online_details.meeting_id.title', 'MEETING ID')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_onlineMeetingIdController, keyboardType: TextInputType.text, semanticsLabel: Localization().getStringEx('panel.event2.create.online_details.meeting_id.field', 'MEETING ID FIELD')),
  );

  Widget _buildOnlinePasscodeInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.online_details.passcode.title', 'PASSCODE')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_onlinePasscodeController, keyboardType: TextInputType.text, semanticsLabel: Localization().getStringEx('panel.event2.create.online_details.passcode.field', 'PASSCODE FIELD')),
  );

  void _onTapSelectLocation() {
    Analytics().logSelect(target: "Select Location");
    Event2CreatePanel.hideKeyboard(context);
    ExploreLocation? location = _constructLocation();

    ExploreMapSelectLocationPanel.push(context,
      selectedExplore: (location != null) ? ExplorePOI(location: location) : null,
    ).then((Explore? explore) {
      if ((explore != null) && mounted) {
        _locationBuildingController.text = (explore.exploreTitle ?? explore.exploreLocation?.building ?? explore.exploreLocation?.name ?? '').replaceAll('\n', ' ');
        _locationAddressController.text = explore.exploreLocation?.fullAddress ?? explore.exploreLocation?.buildDisplayAddress() ?? explore.exploreLocation?.description ?? '';
        _locationLatitudeController.text = _printLatLng(explore.exploreLocation?.latitude);
        _locationLongitudeController.text = _printLatLng(explore.exploreLocation?.longitude);
        setState(() {
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  Widget get _innerSectionSplitter => Container(color: Styles().colors.surfaceAccent, height: 1);

  // Cost

  Widget _buildCostDropdownSection() => Event2CreatePanel.buildDropdownSectionWidget(
    heading: Event2CreatePanel.buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.cost.title', 'COST'),
      required: !_free,
      expanded: _costSectionExpanded,
      onToggleExpanded: _onToggleCostSection,
    ),
    body: _buildCostSectionBody(),
    expanded: _costSectionExpanded,
  );

  Widget _buildCostSectionBody() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
    _buildFreeToggle(),
    Padding(padding: Event2CreatePanel.innerSectionPadding),
    _buildCostInnerSection(),
  ]);
    
  Widget _buildFreeToggle() => Semantics(toggled: _free, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.create.free.toggle.title", "List event as free"),
    hint: Localization().getStringEx("panel.event2.create.free.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.create.free.toggle.title", "List event as free"),
      padding: _togglePadding,
      toggled: _free,
      onTap: _onTapFree,
      border: _toggleBorder,
      borderRadius: _toggleBorderRadius,
    ));

  Widget _buildCostInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: _buildCostInnerSectionHeadingWidget(),
    body: Event2CreatePanel.buildInnerTextEditWidget(_costController, keyboardType: TextInputType.text),
  );

  Widget _buildCostInnerSectionHeadingWidget() {
    String title = Localization().getStringEx('panel.event2.create.label.cost.title', 'COST DESCRIPTION');
    String description = Localization().getStringEx('panel.event2.create.label.cost.description', ' (eg: \$10, Donation suggested)');
    String semanticsLabel = title + description;

    return Padding(padding: Event2CreatePanel.innerSectionHeadingPadding, child:
      Semantics(label: semanticsLabel, header: true, excludeSemantics: true, child:
        Row(children: [
          Expanded(child:
            RichText(textScaler: MediaQuery.of(context).textScaler, text:
              TextSpan(text: title, style: Event2CreatePanel.headingTextStype, children: <InlineSpan>[
                TextSpan(text: description, style: Styles().textStyles.getTextStyle('widget.item.small.thin'),),
                TextSpan(text: _free ? '' : ' *', style: Styles().textStyles.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
              ])
            )
          ),
        ]),
      ),
    );
  }

  void _onToggleCostSection() {
    Analytics().logSelect(target: "Toggle Cost Sectoion");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _costSectionExpanded = !_costSectionExpanded;
    });
  }

  void _onTapFree() {
    Analytics().logSelect(target: "Toggle Free");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _free = !_free;
      _errorMap = _buildErrorMap();
    });
  }


  // Attributes

  Widget _buildAttributesButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.attributes.title', 'EVENT ATTRIBUTES'),
      subTitle: (_attributes?.isEmpty ?? true) ? Localization().getStringEx('panel.event2.create.button.attributes.description', 'Choose attributes related to your event.') : null,
      required: Events2().contentAttributes?.hasRequired(contentAttributeRequirementsFunctionalScopeCreate) ?? false,
      onTap: _onEventAttributes,
    ),
    body: _buildAttributesSectionBody(),
  );

  Widget? _buildAttributesSectionBody() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.small.regular");

    ContentAttributes? contentAttributes = Events2().contentAttributes;
    List<ContentAttribute>? attributes = contentAttributes?.attributes;
    if ((_attributes != null) && _attributes!.isNotEmpty && (contentAttributes != null) && (attributes != null)) {
      for (ContentAttribute attribute in attributes) {
        List<String>? displayAttributeValues = attribute.displaySelectedLabelsFromSelection(_attributes, complete: true);
        if ((displayAttributeValues != null) && displayAttributeValues.isNotEmpty) {
          for (String attributeValue in displayAttributeValues) {
            if (descriptionList.isNotEmpty) {
              descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
            }
            descriptionList.add(TextSpan(text: attributeValue, style: regularStyle,),);
          }
        }
      }

      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
      }

      return Row(children: [
        Expanded(child:
          RichText(textScaler: MediaQuery.of(context).textScaler, text: TextSpan(style: regularStyle, children: descriptionList))
        ),
      ],);
    }
    else {
      return null;
    }
  }

  void _onEventAttributes() {
    Analytics().logSelect(target: "Attributes");

    Event2CreatePanel.hideKeyboard(context);
    Navigator.push(context, CupertinoPageRoute(builder: (context) => ContentAttributesPanel(
      title:  Localization().getStringEx('panel.event2.attributes.attributes.header.title', 'Event Attributes'),
      description: Localization().getStringEx('panel.event2.attributes.attributes.header.description', 'Choose one or more attributes that help describe this event.'),
      scope: Events2.contentAttributesScope,
      contentAttributes: Events2().contentAttributes,
      selection: _attributes,
      sortType: ContentAttributesSortType.native,
    ))).then((selection) {
      if ((selection != null) && mounted) {
        setState(() {
          _attributes = selection;
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  // Registration

  Widget  _buildRegistrationButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.registration.title', 'EVENT REGISTRATION'),
      subTitle: _displayRegistrationDescription,
      onTap: _onEventRegistration,
    ),
  );

  String get _displayRegistrationDescription {
    switch (_registrationDetails?.type) {
      case Event2RegistrationType.internal: return Localization().getStringEx('panel.event2.create.button.registration.confirmation.internal', 'Registration via the app is set up.');
      case Event2RegistrationType.external: return Localization().getStringEx('panel.event2.create.button.registration.confirmation.external', 'Registration via external link is set up.');
      default: return Localization().getStringEx('panel.event2.create.button.registration.description', 'Use in-app options or an external link.');
    }
  }

  void _onEventRegistration() {
    Analytics().logSelect(target: "Event Registration");
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<dynamic>(context, CupertinoPageRoute(builder: (context) => Event2SetupRegistrationPanel(
      event: widget.event,
      registrationDetails: _registrationDetails,
    ))).then((dynamic result) {
      setStateIfMounted(() {
        if (result is Event2RegistrationDetails) {
          _registrationDetails = result;
        }
        else if (result is Event2) {
          _registrationDetails = result.registrationDetails;
        }
      });
    });
  }

  // Attendance

  Widget  _buildAttendanceButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.attendance.title', 'EVENT ATTENDANCE'),
      subTitle: (_attendanceDetails?.isNotEmpty == true) ?
      Localization().getStringEx('panel.event2.create.button.attendance.confirmation', 'Event attendance details set up.') :
      Localization().getStringEx('panel.event2.create.button.attendance.description', 'Check in attendees via the app.'),
      onTap: _onEventAttendance,
    ),
  );

  void _onEventAttendance() {
    Analytics().logSelect(target: "Event Attendance");
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<Event2AttendanceDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupAttendancePanel(attendanceDetails: _attendanceDetails, event: widget.event,))).then((Event2AttendanceDetails? result) {
      if ((result != null) && mounted) {
        setState(() {
          _attendanceDetails = result;
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  // Follow-Up Survey

  Widget _buildSurveyButtonSection() {
    String? subTitle;
    if (StringUtils.isEmpty(_survey?.id)) {
      subTitle = Localization().getStringEx('panel.event2.create.button.survey.description', 'Receive feedback about your event');
    }
    else {
      String? surveyName = _survey?.title;
      subTitle = ((surveyName != null) && surveyName.isNotEmpty) ?
        surveyName /* Localization().getStringEx('panel.event2.create.button.survey.confirmation2', 'Follow-up survey: {{survey_name}}.').replaceAll('{{survey_name}}' ,surveyName) */ :
        Localization().getStringEx('panel.event2.create.button.survey.confirmation', 'Follow-up survey set up.');
    }
    return Event2CreatePanel.buildButtonSectionWidget(
      heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
        title: Localization().getStringEx('panel.event2.create.button.survey.title', 'EVENT FOLLOW-UP SURVEY'),
        subTitle: subTitle,
        onTap: _onEventSurvey,
      ),
    );
  }

  void _onEventSurvey() {
    Analytics().logSelect(target: "Event Follow-Up Survey");
    Event2CreatePanel.hideKeyboard(context);
    Event2SetupSurveyPanel.push(context,
      surveyParam: Event2SetupSurveyParam(
        details: _surveyDetails,
        survey: _survey,
      ),
      eventName: _titleController.text,
      surveysCache: _surveysCache,
    ).then((Event2SetupSurveyParam? result) {
      if ((result != null) && mounted) {
        setState(() {
          _survey = result.survey;
          _surveyDetails = result.details;
          _errorMap = _buildErrorMap();
        });
      }
    });
  }

  // Sponsorship and Contacts

  Widget _buildSponsorshipAndContactsButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.title', 'EVENT HOST DETAILS'),
      subTitle: !_hasSponsorshipAndContacts ? Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.description', 'Display event host and contact information.') : null,
      onTap: _onSponsorshipAndContacts,
    ),
    body: _buildSponsorshipAndContactsSectionBody()
  );

  Widget? _buildSponsorshipAndContactsSectionBody() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.small.regular");

//	"panel.event2.create.button.sponsorship_and_contacts.label.sponsor": "Sponsor: ",
//	"panel.event2.create.button.sponsorship_and_contacts.label.speaker": "Speaker: ",
//	"panel.event2.create.button.sponsorship_and_contacts.label.contacts": "Contacts: ",

    if (StringUtils.isNotEmpty(_sponsor)) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: "; " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.label.sponsor', 'Event Host: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: _sponsor, style: regularStyle,),);
    }

    if (StringUtils.isNotEmpty(_speaker)) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: "; " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.label.speaker', 'Speaker: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: _speaker, style: regularStyle,),);
    }

    if (CollectionUtils.isNotEmpty(_contacts)) {
      List<InlineSpan> contactsList = <InlineSpan>[];
      for (Event2Contact contact in _contacts!) {
        if (contactsList.isNotEmpty) {
          contactsList.add(TextSpan(text: ", " , style: regularStyle,));
        }
        contactsList.add(TextSpan(text: contact.fullName, style: regularStyle,),);
      }

      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: "; " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.label.contacts', 'Contacts: ') , style: boldStyle,));
      descriptionList.addAll(contactsList);
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.add(TextSpan(text: '.', style: regularStyle,),);

      return Row(children: [
        Expanded(child:
          RichText(textScaler: MediaQuery.of(context).textScaler, text: TextSpan(style: regularStyle, children: descriptionList))
        ),
      ],);
    }
    else {
      return null;
    }
  }

  bool get _hasSponsorshipAndContacts =>
    StringUtils.isNotEmpty(_sponsor) ||
    StringUtils.isNotEmpty(_speaker) ||
    CollectionUtils.isNotEmpty(_contacts);

  void _onSponsorshipAndContacts() {
    Analytics().logSelect(target: "Event Host Details");
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<Event2SponsorshipAndContactsDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupSponsorshipAndContactsPanel(details: Event2SponsorshipAndContactsDetails(
      sponsor: _sponsor,
      contacts: _contacts,
    )))).then((Event2SponsorshipAndContactsDetails? result) {
      if ((result != null) && mounted) {
        setState(() {
          _sponsor = (result.sponsor?.isNotEmpty ?? false) ? result.sponsor : null;
          _contacts = (result.contacts?.isNotEmpty ?? false) ? result.contacts : null;
        });
      }
    });
  }

  // Groups

  Widget _buildGroupsButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.groups.title', '{{app_title}} APP GROUPS').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois').toUpperCase()),
      subTitle: Localization().getStringEx('panel.event2.create.button.groups.description', 'Publish your event in group(s) that you administer.'),
      onTap: _onSelectGroups,
    ),
    body: _buildGroupsSectionBody()
  );

  Widget? _buildGroupsSectionBody() {
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("widget.card.detail.small.regular");
    if (_loadingEventGroups) {
      return Row(children: [
        Padding(padding: const EdgeInsets.only(right: 6), child:
          SizedBox(width: 14, height: 14, child:
            CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
          ),
        ),
        Expanded(child:
          Text(Localization().getStringEx('panel.event2.create.groups.load.progress.msg', 'Loading event groups...'), style: regularStyle,),
        ),
      ],);
    }
    else if (_eventGroups != null) {
      List<InlineSpan> descriptionList = <InlineSpan>[];

      for (Group group in _eventGroups!) {
        if (descriptionList.isNotEmpty) {
          descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
        }
        descriptionList.add(TextSpan(text: group.title ?? '', style: regularStyle,),);
      }

      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: '.', style: regularStyle,),);
      }

      return descriptionList.isNotEmpty ? Row(children: [
        Expanded(child:
          RichText(textScaler: MediaQuery.of(context).textScaler, text: TextSpan(style: regularStyle, children: descriptionList))
        ),
      ],) : null;
    }
    else {
      return (widget.isUpdate && CollectionUtils.isNotEmpty(widget.event?.groupIds)) ? Row(children: [
        Expanded(child:
          Text(Localization().getStringEx('panel.event2.create.groups.load.failed.msg', 'Failed to load event groups'), style: Styles().textStyles.getTextStyle("panel.settings.error.text.small"),),
        ),
      ],) : null;
    }
  }

  void _onSelectGroups() {
    Analytics().logSelect(target: "Event Groups");
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<List<Group>>(context, CupertinoPageRoute(builder: (context) => Event2SetupGroups(selection: _eventGroups ?? <Group>[]))).then((List<Group>? selection) {
      if (selection != null) {
        setStateIfMounted(() {
          _eventGroups = selection;
          if (CollectionUtils.isNotEmpty(_eventGroups) && (_visibility == _Event2Visibility.registered_user)) {
            _visibility = _Event2Visibility.group_member;
          } else if (CollectionUtils.isEmpty(_eventGroups) && (_visibility == _Event2Visibility.group_member)) {
            _visibility = _Event2Visibility.registered_user;
          }
        });
      }
    });
  }

  void _initEventGroups() {
    String? eventId = widget.event?.id;
    if (eventId != null) {
      _loadingEventGroups = true;
      Groups().loadGroupsByIds(groupIds: widget.event!.groupIds).then((List<Group>? groups) {
          setStateIfMounted(() {
            _loadingEventGroups = false;
            _eventGroups = groups;
            _initialGroupIds = Group.listToSetIds(_eventGroups) ?? <String>{};
          });
      });
    }
    else {
      _eventGroups = widget.targetGroups;
    }
  }

  void _initEventAdmins() async {
    if(widget.event != null) {
      setStateIfMounted(() => _loadingAdmins = true);
      widget.event?.asyncAdminIdentifiers.then((admins) =>
            _adminNetIdsController.text = Event2PersonIdentifierExt.extractNetIdsString(admins) ?? _adminNetIdsController.text
      ).whenComplete(() =>
          setStateIfMounted(() => _loadingAdmins = false)
      );
    }
  }

  // Visibility

  Widget _buildVisibilitySection() {
    String title = Localization().getStringEx('panel.event2.create.label.visibility.title', 'EVENT VISIBILITY');
    return Padding(padding: EdgeInsets.zero, child: // Event2CreatePanel.sectionPadding - the last section does not add padding at the bottom
      Semantics(container: true, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child:
            Wrap(children: [
              Event2CreatePanel.buildSectionTitleWidget(title),
              Event2CreatePanel.buildSectionRequiredWidget(), 
            ]),
          ),
          Expanded(child:
            Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
              Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
                DropdownButtonHideUnderline(child:
                  DropdownButton<_Event2Visibility>(
                    dropdownColor: Styles().colors.white,
                    icon: Styles().images.getImage('chevron-down'),
                    isExpanded: true,
                    style: Styles().textStyles.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                    hint: Text(_event2VisibilityToDisplayString(_visibility)),
                    items: _buildVisibilityDropDownItems(),
                    onChanged: _onVisibilityChanged
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  List<DropdownMenuItem<_Event2Visibility>>? _buildVisibilityDropDownItems() {
    List<DropdownMenuItem<_Event2Visibility>> menuItems = <DropdownMenuItem<_Event2Visibility>>[];
    for (_Event2Visibility value in _Event2Visibility.values) {
      bool canShowValue = true;
      if ((value == _Event2Visibility.registered_user) && _isGroupEvent) {
        canShowValue = false;
      } else if ((value == _Event2Visibility.group_member) && !_isGroupEvent) {
        canShowValue = false;
      } else if ((value == _Event2Visibility.public) && !Auth2().isCalendarAdmin) {
        canShowValue = false;
      }
      if (canShowValue) {
        menuItems.add(DropdownMenuItem<_Event2Visibility>(value: value, child: Text(_event2VisibilityToDisplayString(value))));
      }
    }
    return menuItems;
  }

  void _onVisibilityChanged(_Event2Visibility? value) {
    Analytics().logSelect(target: "Visibility: $value");
    Event2CreatePanel.hideKeyboard(context);
    if (value != null) {
      setStateIfMounted(() {
        _visibility = value;
      });
    }
  }

  _Event2Visibility get _defaultVisibility {
    return _event2VisibilityFromAuthorizationContext(widget.event?.authorizationContext) ??
        (Auth2().isCalendarAdmin ? _Event2Visibility.public :
        (CollectionUtils.isNotEmpty(widget.targetGroups) ? _Event2Visibility.group_member : _Event2Visibility.registered_user));
  }

  // Published

  Widget _buildPublishedSection() =>  Padding(padding: Event2CreatePanel.sectionPadding, child: _buildPublishedToggle());

  Widget _buildPublishedToggle() => Semantics(toggled: _published, excludeSemantics: true,
    label: Localization().getStringEx("panel.event2.create.published.toggle.title", "Publish this event"),
    hint: Localization().getStringEx("panel.event2.create.published.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.create.published.toggle.title", "Publish this event"),
      padding: _togglePadding,
      toggled: _published,
      onTap: _onTapPublished,
      border: _toggleBorder,
      borderRadius: _toggleBorderRadius,
    ));


  void _onTapPublished() {
    Analytics().logSelect(target: "Toggle publish this event");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _published = !_published;
    });
  }

  // Create Event

  Widget _buildCreateEventSection() => Padding(padding: Event2CreatePanel.sectionPadding, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      _errorMap.isNotEmpty ? _buildCreateErrorStatus() : Padding(padding: Event2CreatePanel.sectionPadding),
      _buildCreateEventButton(),
    ], )
  );

  Widget _buildCreateEventButton() {
    
    String buttonTitle = widget.isCreate ?
      Localization().getStringEx("panel.event2.create.button.create.title", "Create Event") :
      Localization().getStringEx("panel.event2.update.button.update.title", "Update Event");
    
    String buttonHint = widget.isCreate ?
      Localization().getStringEx("panel.event2.create.button.create.hint", "") :
      Localization().getStringEx("panel.event2.update.button.update.hint", "");
    
    bool buttonEnabled = _canCreateEvent();

    return Semantics(label: buttonTitle, hint: buttonHint, button: true, enabled: buttonEnabled, excludeSemantics: true, child:
      RoundedButton(
        label: buttonTitle,
        textStyle: buttonEnabled ? Styles().textStyles.getTextStyle('widget.button.title.large.fat') : Styles().textStyles.getTextStyle('widget.button.disabled.title.large.fat'),
        onTap: buttonEnabled ? _onTapCreateEvent : null,
        backgroundColor: Styles().colors.white,
        borderColor: buttonEnabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent,
        progress: _creatingEvent,
      )
    );
  }

  bool get _isEndBeforeStartDateTime {
    DateTime? startDateTimeUtc = _startDateTimeUtc;
    DateTime? endDateTimeUtc = _endDateTimeUtc;
    return ((startDateTimeUtc != null) && (endDateTimeUtc != null)) ? endDateTimeUtc.isBefore(startDateTimeUtc) : false;
  }

  bool get _isStartBeforeEndDateTime {
    DateTime? startDateTimeUtc = _startDateTimeUtc;
    DateTime? endDateTimeUtc = _endDateTimeUtc;
    return ((startDateTimeUtc != null) && (endDateTimeUtc != null)) ? startDateTimeUtc.isBefore(endDateTimeUtc) : false;
  }

  Map<_ErrorCategory, List<String>> _buildErrorMap() {
    List<String> missingList = <String>[];
    List<String> invalidList = <String>[];

    if (_titleController.text.isEmpty) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.name', 'event name'));
    }

    if ((_startDate == null) && (_startTime == null)) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.start_datetime', 'start date and time'));
    }
    else if (_startDate == null) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.start_date', 'start date'));
    }
    else if (_startTime == null) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.start_time', 'start time'));
    }
    
    if ((_endDate != null) || (_endTime != null)) {
      if (_endDate == null) {
        missingList.add(Localization().getStringEx('panel.event2.create.status.missing.end_date', 'end date'));
      }
      else if (_endTime == null) {
        missingList.add(Localization().getStringEx('panel.event2.create.status.missing.end_time', 'end time'));
      }
      else if (_isEndBeforeStartDateTime) {
        invalidList.add(Localization().getStringEx('panel.event2.create.status.invalid.date.pair', 'end before start'));
      }
    }

    if ((_recurrenceRepeatType != null) && (_recurrenceRepeatType != _RecurrenceRepeatType.does_not_repeat)) {
      if (_recurrenceRepeatType == _RecurrenceRepeatType.weekly) {
        if (CollectionUtils.isEmpty(_recurrenceWeekDays)) {
          missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.week.weekday', 'recurrence weekday'));
        } else if (_weeklyRepeatPeriod == null) {
          missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.week.every', 'recurrence week period'));
        }
      } else if (_recurrenceRepeatType == _RecurrenceRepeatType.monthly) {
        if (_recurrenceRepeatMonthlyType == null) {
          missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.monthly.on', 'recurrence on'));
        } else if ((_recurrenceRepeatMonthlyType == _RecurrenceRepeatMonthlyType.daily) && (_recurrenceRepeatDay == null)) {
          missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.monthly.on.day', 'recurrence on which day'));
        } else if (_recurrenceRepeatMonthlyType == _RecurrenceRepeatMonthlyType.weekly) {
          if (_recurrenceOrdinalNumber == null) {
            missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.monthly.week.ordinal', 'recurrence ordinal weekday'));
          } else if (_recurrenceMonthWeekDay == null) {
            missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.monthly.week.day', 'recurrence week day'));
          }
        } else if (_monthlyRepeatPeriod == null) {
          missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.monthly.every', 'recurrence every which month'));
        }
      }
      if (!_hasRecurrenceEndDate) {
        missingList.add(Localization().getStringEx('panel.event2.create.status.missing.recurrence.end_date', 'recurrence end date'));
      } else if (_recurrenceEndDate!.isBefore(_startDate!)) {
        invalidList.add(Localization().getStringEx('panel.event2.create.status.invalid.recurrence.end_date', 'recurrence end date before start date'));
      }
    }

    if (_eventType == null) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.event_type', 'event type'));
    }
    else {
      if (_inPersonEventType && !_hasLocation) {
        missingList.add(Localization().getStringEx('panel.event2.create.status.missing.location', 'location coordinates'));
      }
      if (_onlineEventType) {
        if (!_hasOnlineDetails) {
          missingList.add(Localization().getStringEx('panel.event2.create.status.missing.online_url', 'online URL'));
        }
        else if (!_hasValidOnlineDetails) {
          invalidList.add(Localization().getStringEx('panel.event2.create.status.invalid.online_url', 'online URL'));
        }
      }
    }
    

    if ((_free == false) && _costController.text.isEmpty) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.cost_description', 'cost description'));
    }

    if (_hasWebsiteURL && !_hasValidWebsiteURL) {
      invalidList.add(Localization().getStringEx('panel.event2.create.status.invalid.website_url', 'website URL'));
    }

    if (Events2().contentAttributes?.isSelectionValid(_attributes) != true) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.attributes', 'event attributes'));
    }

    if ((_registrationDetails?.type == Event2RegistrationType.external) && (_registrationDetails?.externalLink?.isEmpty ?? true)) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.registration_link', 'registration link'));
    }
    
    if (_hasSurvey && !_hasAttendanceDetails) {
      missingList.add(Localization().getStringEx('panel.event2.create.status.missing.survey_attendance_details', 'attendance (required for survey)'));
    }

    Map<_ErrorCategory, List<String>> errorMap = <_ErrorCategory, List<String>>{};
    if (missingList.isNotEmpty) {
      errorMap[_ErrorCategory.missing] = missingList;
    }
    if (invalidList.isNotEmpty) {
      errorMap[_ErrorCategory.invalid] = invalidList;
    }
    return errorMap;
  }

  Widget _buildCreateErrorStatus() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles.getTextStyle("panel.settings.error.text");
    TextStyle? regularStyle = Styles().textStyles.getTextStyle("panel.settings.error.text.small");

    List<String>? missingStringList = _errorMap[_ErrorCategory.missing];
    if ((missingStringList != null) && missingStringList.isNotEmpty) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: "; " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.create.status.missing.heading', 'Missing: ') , style: boldStyle,));
      int missingStart = descriptionList.length;
      for (String missingString in missingStringList) {
        if (missingStart < descriptionList.length) {
          descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
        }
        descriptionList.add(TextSpan(text: missingString, style: regularStyle,),);
      }
    }

    List<String>? invalidStringList = _errorMap[_ErrorCategory.invalid];
    if ((invalidStringList != null) && invalidStringList.isNotEmpty) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: "; " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.create.status.invalid.heading', 'Invalid: ') , style: boldStyle,));
      int invalidStart = descriptionList.length;
      for (String invalidString in invalidStringList) {
        if (invalidStart < descriptionList.length) {
          descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
        }
        descriptionList.add(TextSpan(text: invalidString, style: regularStyle,),);
      }
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.add(TextSpan(text: "." , style: regularStyle,));
    }

    return Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
      Row(children: [ Expanded(child:
        RichText(textScaler: MediaQuery.of(context).textScaler, text: TextSpan(style: regularStyle, children: descriptionList))
      ),],),
    );
  }

  void _onTapCreateEvent() async {
    Analytics().logSelect(target: widget.isCreate ? "Create Event" : "Update Event");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _creatingEvent = true;
    });

    List<_RecurringDatesPair>? recurringDates = _buildRecurringDatesPairs();
    DateTime? eventStartDate, eventEndDate;
    if (CollectionUtils.isNotEmpty(recurringDates)) {
      eventStartDate = recurringDates!.first.startDateTimeUtc;
      eventEndDate = recurringDates.last.endDateTimeUtc;
    }

    dynamic result;
    // Explicitly set the start date to be the first and end date to be the last - #4599
    Event2 event = _createEventFromData(recurringStartDateUtc: eventStartDate, recurringEndDateUtc: eventEndDate);
    List<Event2PersonIdentifier>? adminIdentifiers;
    if(StringUtils.isNotEmpty(_adminNetIdsController.text)) {
      List<String>? adminNetIds = ListUtils.notEmpty(ListUtils.stripEmptyStrings(_adminNetIdsController.text.split(ListUtils.commonDelimiterRegExp)));
      adminIdentifiers =  Event2PersonIdentifierExt.constructAdminIdentifiersFromIds(adminNetIds);
      adminIdentifiers?.removeWhere((identifier) =>  identifier.externalId == Auth2().netId); //exclude self otherwise the BB duplicates it
    }

    String? eventId = event.id;
    if (eventId == null) {
      if (_callCreateGroupEvent) {
        result = await Events2().createGroupEvent(event, adminIdentifiers: adminIdentifiers);
      } else {
        result = await Events2().createEvent(event, adminIdentifiers: adminIdentifiers);
      }
    } else {
      bool eventModified = (event != widget.event);
      if (eventModified) {
        result = await Events2().updateEvent(event, adminIdentifiers: adminIdentifiers, initialGroupIds: _initialGroupIds);
      }
      else {
        result = event;
      }
    }

    if (mounted) {
      if (result is Event2) {
        Survey? survey = widget.survey;
        if (widget.isCreate) {
          if (_shouldCreateRecurringEvents && CollectionUtils.isNotEmpty(recurringDates)) {
            await _createRecurringEventsFrom(mainEvent: result, recurringDates: recurringDates!);
          }
          if (_survey != null) {
            bool? success = await Surveys().createEvent2Survey(_survey!, result);
            if (mounted) {
              if (success == true && result.id != null) {
                survey = await Surveys().loadEvent2Survey(result.id!);
                if (mounted) {
                  setState(() {
                    _creatingEvent = false;
                  });
                  await _promptFavorite(result, surveySucceeded: true);
                  if (mounted) {
                    Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => Event2DetailPanel(
                      event: result,
                      survey: survey,
                    )));
                  }
                }
              }
              else {
                setState(() {
                  _creatingEvent = false;
                });
                await _promptFavorite(result, surveySucceeded: false);
                if (mounted) {
                  Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => Event2DetailPanel(
                    event: result,
                    survey: null,
                  )));
                }
              }
            }
          }
          else {
            await _promptFavorite(result);
            if (mounted) {
              Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => Event2DetailPanel(
                event: result,
              )));
            }
          }
        }
        else {
          // we have a survey and it is not available to attendees yet
          bool surveyUpdateResult = true;
          if ((_survey != null) || (survey != null) && (result.isSurveyAvailable == false)) {
            if (_survey?.title != survey?.title) {
              // a different template than the initially selected template was selected
              if (survey == null) {
                // the null template was initially selected (no survey exists), so create a new survey
                surveyUpdateResult = await Surveys().createEvent2Survey(_survey!, result) ?? false;
              } else if (_survey == null) {
                // the null template is now selected, so delete the existing survey
                surveyUpdateResult = await Surveys().deleteSurvey(survey.id) ?? false;
              } else {
                // a survey already exists and the template has been changed, so update the existing survey
                surveyUpdateResult = await Surveys().updateSurvey(_survey!) ?? false;
              }
              if (result.id != null) {
                // always load the survey if we have the event ID to make sure we have the current version (other admins may be editing)
                survey = await Surveys().loadEvent2Survey(result.id!);
              }
            }
          }
          if (mounted) {
            setState(() {
              _creatingEvent = false;
            });
            if (surveyUpdateResult) {
              Navigator.of(context).pop(Event2SetupSurveyParam(
                event: result,
                survey: survey,
              ));
            } else {
              Event2Popup.showErrorResult(context,Localization().getStringEx('panel.event2.create.survey.update.failed.msg', 'Failed to set event survey, but the number of hours setting has been saved. Remember that other event admins may have modified the survey.')).then((_) {
                Navigator.of(context).pop(Event2SetupSurveyParam(
                  event: result,
                  survey: survey,
                ));
              });
            }
          }
        }
      }
      else  {
        setState(() {
          _creatingEvent = false;
        });
        Event2Popup.showErrorResult(context, result);
      }
    }
  }

  bool get _callCreateGroupEvent => (!Auth2().isCalendarAdmin && _isGroupEvent);

  Future<bool> _promptFavorite(Event2 event, {bool? surveySucceeded} ) async {
    final String eventNameMacro = '{{event_name}}';
    final String starColorMacro = '{{star_color}}';

    String messageHtml = ((surveySucceeded != false) ?
      Localization().getStringEx("panel.event2.create.message.succeeded.star.promt", "Successfully created \"$eventNameMacro\" event. Would vou like to add this event to <span style='color:$starColorMacro;'><b>\u2605</b></span> My Events?") :
      Localization().getStringEx("panel.event2.create.message.succeeded.survey.failed.star.promt", "Successfully created \"$eventNameMacro\" event but failed to create the survey. Would vou like to add this event to <span style='color:$starColorMacro;'><b>\u2605</b></span> My Events?"))
        .replaceAll(eventNameMacro, event.name ?? '')
        .replaceAll(starColorMacro, ColorUtils.toHex(Styles().colors.fillColorSecondary));

    bool? result = await Event2Popup.showPrompt(context,
      title: Localization().getStringEx("panel.event2.create.message.succeeded.title", "Event Created"),
      messageHtml: messageHtml,
      positiveButtonTitle: Localization().getStringEx("dialog.yes.title", "Yes"),
      negativeButtonTitle: Localization().getStringEx("dialog.no.title", "No"),
    );
    if (result == true) {
      Auth2().prefs?.setFavorite(event, true);
      return true;
    }
    return false;
  }

  bool get _onlineEventType => (_eventType == Event2Type.online) ||  (_eventType == Event2Type.hybrid);
  bool get _inPersonEventType => (_eventType == Event2Type.inPerson) ||  (_eventType == Event2Type.hybrid);

  ExploreLocation? _constructLocation() {
    double? latitude = _parseLatLng(_locationLatitudeController);
    double? longitude = _parseLatLng(_locationLongitudeController);
    return ((latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0)) ? ExploreLocation(
      name: _locationBuildingController.text.isNotEmpty ? _locationBuildingController.text : null,
      building: _locationBuildingController.text.isNotEmpty ? _locationBuildingController.text : null,
      description: _locationAddressController.text.isNotEmpty ? _locationAddressController.text : null,
      fullAddress: _locationAddressController.text.isNotEmpty ? _locationAddressController.text : null,
      latitude: latitude,
      longitude: longitude,
    ) : null;
  }

  bool get _hasLocation {
    double? latitude = _parseLatLng(_locationLatitudeController);
    double? longitude = _parseLatLng(_locationLongitudeController);
    return ((latitude != null) && (latitude != 0) && (longitude != null) && (longitude != 0));
  }

  static double? _parseLatLng(TextEditingController textController) =>
    textController.text.isNotEmpty ? double.tryParse(textController.text) : null;

  static String _printLatLng(double? value) => value?.toStringAsFixed(6) ?? '';

  Event2OnlineDetails? get _onlineDetails => 
    _onlineUrlController.text.isNotEmpty ? Event2OnlineDetails(
      url: _onlineUrlController.text,
      meetingId: _onlineMeetingIdController.text,
      meetingPasscode: _onlinePasscodeController.text,
    ) : null;

  bool get _shouldCreateRecurringEvents =>
      ((_recurrenceRepeatType != null) && (_recurrenceRepeatType != _RecurrenceRepeatType.does_not_repeat));
  bool get _hasRecurrenceEndDate => (_recurrenceEndDate != null);
  bool get _hasOnlineDetails => _onlineUrlController.text.isNotEmpty;
  bool get _hasValidOnlineDetails => UrlUtils.isValidUrl(_onlineUrlController.text);
  bool get _hasAttendanceDetails => _attendanceDetails?.isNotEmpty ?? false;
  bool get _hasRegistrationDetails => _registrationDetails?.isNotEmpty ?? false;
  bool get _hasWebsiteURL => _websiteController.text.isNotEmpty;
  bool get _hasValidWebsiteURL => UrlUtils.isValidUrl(_websiteController.text);

  DateTime? get _startDateTimeUtc =>
    (_startDate != null) ? DateTime.fromMillisecondsSinceEpoch(Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, _startDate!, _startTime).millisecondsSinceEpoch)  : null;

  DateTime? get _endDateTimeUtc =>
    (_endDate != null) ? DateTime.fromMillisecondsSinceEpoch(Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, _endDate!, _endTime).millisecondsSinceEpoch) : null;

  DateTime? get _recurrenceEndDateTimeUtc =>
      _hasRecurrenceEndDate ? DateTime.fromMillisecondsSinceEpoch(Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, _recurrenceEndDate!, TimeOfDay(hour: 23, minute: 59)).millisecondsSinceEpoch) : null;

  bool get _private => (_visibility != _Event2Visibility.public);

  bool get _isGroupEvent => CollectionUtils.isNotEmpty(_eventGroups);

  bool get _hasSurvey => (_survey != null) || (_surveyDetails?.isNotEmpty ?? false);

  bool _canCreateEvent() => (
    _titleController.text.isNotEmpty &&
    (_startDate != null) && (_startTime != null) &&
    (((_endDate == null) && (_endTime == null)) || ((_endDate != null) && (_endTime != null) && _isStartBeforeEndDateTime)) &&
    (_eventType != null) &&
    (!_inPersonEventType || _hasLocation) &&
    (!_onlineEventType || _hasValidOnlineDetails) &&
    (!_hasWebsiteURL || _hasValidWebsiteURL) &&
    (_free || _costController.text.isNotEmpty) &&
    (Events2().contentAttributes?.isSelectionValid(_attributes) ?? false) &&
    ((_registrationDetails?.type != Event2RegistrationType.external) || (_registrationDetails?.externalLink?.isNotEmpty ?? false)) &&
    ((_registrationDetails?.type != Event2RegistrationType.internal) || ((_registrationDetails?.eventCapacity ?? 0) > 0)) &&
    (!_hasSurvey || _hasAttendanceDetails) &&
    (_recurringConditionsFulfilled) &&
    (_loadingAdmins == false)
  );

  bool get _recurringConditionsFulfilled {
    if (widget.isCreate) {
      if ((_recurrenceRepeatType != null) && (_recurrenceRepeatType != _RecurrenceRepeatType.does_not_repeat)) {
        if (!_hasRecurrenceEndDate) {
          return false;
        }
        if (_recurrenceRepeatType == _RecurrenceRepeatType.weekly) {
          if (CollectionUtils.isEmpty(_recurrenceWeekDays) || (_weeklyRepeatPeriod == null)) {
            return false;
          }
        } else if (_recurrenceRepeatType == _RecurrenceRepeatType.monthly) {
          if (_recurrenceRepeatMonthlyType == null) {
            return false;
          } else if ((_recurrenceRepeatMonthlyType == _RecurrenceRepeatMonthlyType.daily) && (_recurrenceRepeatDay == null)) {
            return false;
          } else if (_monthlyRepeatPeriod == null) {
            return false;
          } else if (_recurrenceRepeatMonthlyType == _RecurrenceRepeatMonthlyType.weekly) {
            if ((_recurrenceOrdinalNumber == null) || (_recurrenceMonthWeekDay == null)) {
              return false;
            }
          }
        }
      }
    }
    return true;
  }

  void _updateErrorMap() {
    Map<_ErrorCategory, List<String>> errorMap = _buildErrorMap();
    if (!DeepCollectionEquality().equals(errorMap, _errorMap)) {
      setStateIfMounted(() {
        _errorMap = errorMap;
      });
    }
  }

  void _onHeaderBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    _canGoBack().then((bool result) {
      if (result && mounted) {
        Navigator.of(context).pop();
      }
    });
  }

  Future<bool> _canGoBack() async {
    bool modified = false;
    if (widget.isCreate) {
      modified = _titleController.text.isNotEmpty ||
        _descriptionController.text.isNotEmpty ||
        _websiteController.text.isNotEmpty ||
        (_imageUrl != null) ||
        
        (_startDate != null) || (_startTime != null) ||
        (_endDate != null) || (_endTime != null) ||
        
        (_eventType != null) ||
        _locationLatitudeController.text.isNotEmpty ||
        _locationLongitudeController.text.isNotEmpty ||

        _hasOnlineDetails ||
        (_attributes?.isNotEmpty ?? false) ||
        (_private == true) ||
        (_free == false) ||
        _costController.text.isNotEmpty ||

        _hasRegistrationDetails ||
        _hasAttendanceDetails ||
        _hasSurvey ||

        !DeepCollectionEquality().equals(_eventGroups ?? <Group>[], widget.targetGroups ?? <Group>[]) ||
        
        (_sponsor != null) ||
        (_speaker != null) ||
        (_contacts?.isNotEmpty ?? false);
    }
    else {
      modified = ((widget.event?.name ?? '') != _titleController.text) ||
        ((widget.event?.description ?? '')  != _descriptionController.text) ||
        ((widget.event?.eventUrl ?? '') != _websiteController.text) ||
        (widget.event?.imageUrl != widget.event?.imageUrl) ||
        
        (widget.event?.startTimeUtc != _startDateTimeUtc) ||
        (widget.event?.endTimeUtc != _endDateTimeUtc) ||
        
        (widget.event?.eventType != _eventType) ||
        (_printLatLng(widget.event?.exploreLocation?.latitude) != _locationLatitudeController.text) ||
        (_printLatLng(widget.event?.exploreLocation?.longitude) != _locationLongitudeController.text) ||
        ((widget.event?.exploreLocation?.building ?? widget.event?.exploreLocation?.name ?? '') != _locationBuildingController.text) ||
        ((widget.event?.exploreLocation?.address ?? widget.event?.exploreLocation?.description ?? '') != _locationAddressController.text) ||

        ((widget.event?.onlineDetails?.url ?? '') != _onlineUrlController.text) ||
        ((widget.event?.onlineDetails?.meetingId ?? '') != _onlineMeetingIdController.text) ||
        ((widget.event?.onlineDetails?.meetingPasscode ?? '') != _onlinePasscodeController.text) ||

        !DeepCollectionEquality().equals(widget.event?.attributes, _attributes) ||
        (_defaultVisibility != _visibility) ||
        ((widget.event?.free ?? true) != _free) ||
        ((widget.event?.cost ?? '') != _costController.text) ||

        !Event2RegistrationDetails.equals(widget.event?.registrationDetails, _registrationDetails) ||
        //(widget.event?.registrationDetails != _registrationDetails) ||
        (widget.event?.attendanceDetails != _attendanceDetails) ||
        (widget.event?.surveyDetails != _surveyDetails) ||
        (widget.survey != _survey) ||

        !DeepCollectionEquality().equals(Group.listToSetIds(_eventGroups) ?? <String>{}, _initialGroupIds ?? <String>{}) ||

        (widget.event?.sponsor != _sponsor) ||
        (widget.event?.speaker != _speaker) ||
        !DeepCollectionEquality().equals(widget.event?.contacts, _contacts);
    }

    if (modified) {
      bool? result = await Event2Popup.showPrompt(context,
        title: Localization().getStringEx('panel.event2.create.exit.prompt.title', 'Exit'),
        message: Localization().getStringEx('panel.event2.create.exit.prompt.message', 'Exit and lose your changes?'),
      );
      return (result == true);
    }
    else {
      return true;
    }
  }

  Event2 _createEventFromData({DateTime? recurringStartDateUtc, DateTime? recurringEndDateUtc}) {
    List<String>? groupIds = _eventGroups?.map((group) => group.id!).toList();
    Event2AuthorizationContext? authorizationContext;
    Event2Context? event2Context;
    switch (_visibility) {
      case _Event2Visibility.public:
        authorizationContext = Event2AuthorizationContext.none();
        if (CollectionUtils.isNotEmpty(groupIds)) {
          event2Context = Event2Context.fromIdentifiers(identifiers: groupIds);
        }
        break;
      case _Event2Visibility.registered_user:
        authorizationContext = Event2AuthorizationContext.registeredUser();
        break;
      case _Event2Visibility.group_member:
        authorizationContext = Event2AuthorizationContext.groupMember(groupIds: groupIds);
        event2Context = Event2Context.fromIdentifiers(identifiers: groupIds);
        break;
    }

    Event2Grouping? grouping;
    if (widget.isCreate) {
      if (_shouldCreateRecurringEvents) {
        grouping = Event2Grouping.recurrence(null, individual: true); // set the main event to show as individual
      }
    } else {
      grouping = widget.event?.grouping;
    }

    DateTime? eventStartDateUtc = (widget.isCreate && _shouldCreateRecurringEvents && (recurringStartDateUtc != null)) ? recurringStartDateUtc : _startDateTimeUtc;
    DateTime? eventEndDateUtc = (widget.isCreate && _shouldCreateRecurringEvents && (recurringEndDateUtc != null)) ? recurringEndDateUtc : _endDateTimeUtc;

    return Event2(
      id: widget.event?.id,

      name: Event2CreatePanel.textFieldValue(_titleController),
      description: Event2CreatePanel.textFieldValue(_descriptionController),
      instructions: null,
      imageUrl: _imageUrl,
      eventUrl: Event2CreatePanel.textFieldValue(_websiteController),

      timezone: _timeZone.name,
      startTimeUtc: eventStartDateUtc,
      endTimeUtc: eventEndDateUtc,
      allDay: _allDay,

      eventType: _eventType,
      location: _constructLocation(),
      onlineDetails: _onlineDetails,

      grouping: grouping,
      attributes: _attributes,
      authorizationContext: authorizationContext,
      context: event2Context,
      published: _published,

      canceled: widget.event?.canceled, // NA
      userRole: widget.event?.userRole, // NA

      free: _free,
      cost: Event2CreatePanel.textFieldValue(_costController),

      registrationDetails: (_registrationDetails?.type != Event2RegistrationType.none) ? _registrationDetails : null,
      attendanceDetails: (_attendanceDetails?.isNotEmpty ?? false) ? _attendanceDetails : null,
      surveyDetails: (StringUtils.isNotEmpty(_survey?.id)) ? _surveyDetails : null,

      sponsor: _sponsor,
      speaker: _speaker,
      contacts: _contacts,
    );
  }

  List<_RecurringDatesPair>? _buildRecurringDatesPairs() {
    if (!widget.isCreate || !_shouldCreateRecurringEvents) {
      return null;
    }
    List<_RecurringDatesPair>? recurringDates;
    switch (_recurrenceRepeatType) {
      case _RecurrenceRepeatType.weekly:
        recurringDates = _buildWeeklyRecurringDates();
        break;
      case _RecurrenceRepeatType.monthly:
        recurringDates = _buildMonthlyRecurringDates();
        break;
      default:
        break;
    }
    return recurringDates;
  }

  List<_RecurringDatesPair>? _buildWeeklyRecurringDates() {
    List<int>? recurrenceWeekDaysIndexes = _recurrenceWeekDays?.map((day) => day.index).toList();
    recurrenceWeekDaysIndexes?.sort();
    DateTime recurringEndDateTimeUtc = _recurrenceEndDateTimeUtc!;
    List<_RecurringDatesPair> pairs = <_RecurringDatesPair>[];
    DateTime nextStartDateUtc = _startDateTimeUtc!;
    DateTime nextEndDateUtc = _endDateTimeUtc!;
    while (nextStartDateUtc.isBefore(recurringEndDateTimeUtc)) {
      if (recurrenceWeekDaysIndexes?.contains(nextStartDateUtc.weekday - 1) ?? false) {
        pairs.add(_RecurringDatesPair(startDateTimeUtc: nextStartDateUtc, endDateTimeUtc: nextEndDateUtc));
      }
      int daysToAdd = (nextStartDateUtc.weekday == 7) ? (1 + (_weeklyRepeatPeriod! - 1) * 7) : 1;
      nextStartDateUtc = nextStartDateUtc.add(Duration(days: daysToAdd));
      nextEndDateUtc = nextEndDateUtc.add(Duration(days: daysToAdd));
    }
    return pairs;
  }

  List<_RecurringDatesPair>? _buildMonthlyRecurringDates() {
    List<_RecurringDatesPair>? pairs;
    switch (_recurrenceRepeatMonthlyType) {
      case _RecurrenceRepeatMonthlyType.daily:
        pairs = _buildMonthlyRecurringDatesByOrdinalDay();
        break;
      case _RecurrenceRepeatMonthlyType.weekly:
        pairs = _buildMonthlyRecurringDatesByWeekDay();
        break;
      default:
        break;
    }
    return pairs;
  }

  List<_RecurringDatesPair>? _buildMonthlyRecurringDatesByOrdinalDay() {
    DateTime recurringEndDateTimeUtc = _recurrenceEndDateTimeUtc!;
    List<_RecurringDatesPair> pairs = <_RecurringDatesPair>[];
    DateTime nextStartDateUtc = _startDateTimeUtc!;
    DateTime nextEndDateUtc = _endDateTimeUtc!;
    while (nextStartDateUtc.isBefore(recurringEndDateTimeUtc)) {
      if ((_recurrenceRepeatDay == 0) || (_recurrenceRepeatDay == nextStartDateUtc.day)) {
        pairs.add(_RecurringDatesPair(startDateTimeUtc: nextStartDateUtc, endDateTimeUtc: nextEndDateUtc));
      }

      late int daysDiff;
      if (_recurrenceRepeatDay == 0) {
        daysDiff = 1;
      } else {
        if (nextStartDateUtc.day < _recurrenceRepeatDay!) {
          daysDiff = (_recurrenceRepeatDay! - nextStartDateUtc.day);
        } else {
          DateTime nextDate = DateTime.utc(
              nextStartDateUtc.year,
              (nextStartDateUtc.month + _monthlyRepeatPeriod!),
              _recurrenceRepeatDay!,
              nextStartDateUtc.hour,
              nextStartDateUtc.minute,
              nextStartDateUtc.second,
              nextStartDateUtc.millisecond,
              nextStartDateUtc.microsecond);
          daysDiff = nextDate.difference(nextStartDateUtc).inDays;
        }
      }

      Duration duration = Duration(days: daysDiff);
      nextStartDateUtc = nextStartDateUtc.add(duration);
      nextEndDateUtc = nextEndDateUtc.add(duration);
    }
    return pairs;
  }

  List<_RecurringDatesPair>? _buildMonthlyRecurringDatesByWeekDay() {
    DateTime recurringEndDateTimeUtc = _recurrenceEndDateTimeUtc!;
    List<_RecurringDatesPair> pairs = <_RecurringDatesPair>[];
    DateTime nextStartDateUtc = _startDateTimeUtc!;
    DateTime nextEndDateUtc = _endDateTimeUtc!;
    int? nThDayOfMonth = _nThDayOfMonth;
    DateTime? desiredDateTime = _getInitialRecurringDesiredDay(nextStartDateUtc: nextStartDateUtc, nThDayOfMonth: nThDayOfMonth);
    if (desiredDateTime != null) {
      while (nextStartDateUtc.isBefore(recurringEndDateTimeUtc)) {
        if (nextStartDateUtc.day == desiredDateTime!.day) {
          pairs.add(_RecurringDatesPair(startDateTimeUtc: nextStartDateUtc, endDateTimeUtc: nextEndDateUtc));
        } else if (nextStartDateUtc.day < desiredDateTime.day) {
          int daysDiff = desiredDateTime.difference(nextStartDateUtc).inDays;
          nextStartDateUtc = nextStartDateUtc.add(Duration(days: daysDiff));
          nextEndDateUtc = nextEndDateUtc.add(Duration(days: daysDiff));
          pairs.add(_RecurringDatesPair(startDateTimeUtc: nextStartDateUtc, endDateTimeUtc: nextEndDateUtc));
        }
        desiredDateTime = _getNextRecurringDesiredDay(nextStartDateUtc: nextStartDateUtc, nThDayOfMonth: nThDayOfMonth);
        int daysDiffToNext = desiredDateTime!.difference(nextStartDateUtc).inDays;
        Duration duration = Duration(days: daysDiffToNext);
        nextStartDateUtc = nextStartDateUtc.add(duration);
        nextEndDateUtc = nextEndDateUtc.add(duration);
      }
    }
    return pairs;
  }

  DateTime? _getInitialRecurringDesiredDay({required DateTime nextStartDateUtc, int? nThDayOfMonth}) {
    DateTime? dateTime;
    // Day
    if (_recurrenceMonthWeekDay == _RecurrenceMonthWeekDay.day) {
      int month = (nThDayOfMonth != null) ? nextStartDateUtc.month : (nextStartDateUtc.month + 1);
      int day = (nThDayOfMonth != null) ? nThDayOfMonth : 0;
      dateTime = DateTime.utc(nextStartDateUtc.year, month, day, nextStartDateUtc.hour, nextStartDateUtc.minute, nextStartDateUtc.second,
          nextStartDateUtc.millisecond, nextStartDateUtc.microsecond);
    }
    // Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
    else if (_isSelectedNamedWeekDay) {
      dateTime = (nThDayOfMonth != null)
          ? _getNthNamedWeekDay(dateTimeUtc: nextStartDateUtc, n: nThDayOfMonth, nextMonth: false, targetWeekDayNumber: _monthWeekDayNumber)
          : _getLastNamedWeekDay(dateTimeUtc: nextStartDateUtc, nextMonth: false, targetWeekDayNumber: _monthWeekDayNumber);
    }
    // Weekday, Weekend day
    else {
      dateTime = (nThDayOfMonth != null)
          ? _getNthWeekDay(dateTimeUtc: nextStartDateUtc, n: nThDayOfMonth, nextMonth: false)
          : _getLastWeekDay(dateTimeUtc: nextStartDateUtc, nextMonth: false);
    }
    return dateTime;
  }

  DateTime? _getNextRecurringDesiredDay({required DateTime nextStartDateUtc, int? nThDayOfMonth}) {
    DateTime? dateTime;
    // Day
    if (_recurrenceMonthWeekDay == _RecurrenceMonthWeekDay.day) {
      int month = ((nThDayOfMonth != null) ? nextStartDateUtc.month : (nextStartDateUtc.month + 1)) + _monthlyRepeatPeriod!;
      int day = (nThDayOfMonth != null) ? nThDayOfMonth : 0;
      dateTime = DateTime.utc(nextStartDateUtc.year, month, day, nextStartDateUtc.hour, nextStartDateUtc.minute, nextStartDateUtc.second,
          nextStartDateUtc.millisecond, nextStartDateUtc.microsecond);
    }
    // Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
    else if (_isSelectedNamedWeekDay) {
      dateTime = (nThDayOfMonth != null)
          ? _getNthNamedWeekDay(
              dateTimeUtc: nextStartDateUtc,
              n: nThDayOfMonth,
              nextMonth: true,
              targetWeekDayNumber: _monthWeekDayNumber,
              monthsAhead: _monthlyRepeatPeriod)
          : _getLastNamedWeekDay(
              dateTimeUtc: nextStartDateUtc, nextMonth: true, targetWeekDayNumber: _monthWeekDayNumber, monthsAhead: _monthlyRepeatPeriod);
    }
    // Weekday, Weekend day
    else {
      dateTime = (nThDayOfMonth != null)
          ? _getNthWeekDay(dateTimeUtc: nextStartDateUtc, n: nThDayOfMonth, nextMonth: true, monthsAhead: _monthlyRepeatPeriod)
          : _getLastWeekDay(dateTimeUtc: nextStartDateUtc, nextMonth: true, monthsAhead: _monthlyRepeatPeriod);
    }
    return dateTime;
  }

  bool get _isSelectedNamedWeekDay {
    return (_recurrenceMonthWeekDay != null) &&
        ![_RecurrenceMonthWeekDay.day, _RecurrenceMonthWeekDay.weekday, _RecurrenceMonthWeekDay.weekend_day]
            .contains(_recurrenceMonthWeekDay);
  }

  DateTime? _getNthNamedWeekDay(
      {required DateTime dateTimeUtc, required int n, bool nextMonth = false, int? targetWeekDayNumber, int? monthsAhead}) {
    if ((targetWeekDayNumber == null) || (targetWeekDayNumber < 1) || (targetWeekDayNumber > 7)) {
      return null;
    }
    int month = nextMonth ? (dateTimeUtc.month + (monthsAhead ?? 1)) : dateTimeUtc.month;
    DateTime firstDayOfMonth = DateTime.utc(dateTimeUtc.year, month, 1, dateTimeUtc.hour, dateTimeUtc.minute, dateTimeUtc.second,
        dateTimeUtc.millisecond, dateTimeUtc.microsecond);
    int firstDayOfWeek = firstDayOfMonth.weekday;
    int daysUntilTarget = (targetWeekDayNumber - firstDayOfWeek + 7) % 7;
    DateTime targetDay = firstDayOfMonth.add(Duration(days: daysUntilTarget));

    if ((n > 1) && (n <= 4)) {
      targetDay = targetDay.add(Duration(days: (n - 1) * 7));
    }
    if (targetDay.month != month) {
      return null;
    }

    return targetDay;
  }

  DateTime? _getLastNamedWeekDay({required DateTime dateTimeUtc, bool nextMonth = false, int? targetWeekDayNumber, int? monthsAhead}) {
    if ((targetWeekDayNumber == null) || (targetWeekDayNumber < 1) || (targetWeekDayNumber > 7)) {
      return null;
    }
    int month = (nextMonth ? (dateTimeUtc.month + (monthsAhead ?? 1)) : dateTimeUtc.month) + 1;
    DateTime lastDayOfMonth = DateTime.utc(dateTimeUtc.year, month, 0, dateTimeUtc.hour, dateTimeUtc.minute, dateTimeUtc.second,
        dateTimeUtc.millisecond, dateTimeUtc.microsecond);
    int lastDayOfWeek = lastDayOfMonth.weekday;
    int daysUntilTargetDay = (lastDayOfWeek - targetWeekDayNumber + 7) % 7;
    DateTime targetDay = lastDayOfMonth.subtract(Duration(days: daysUntilTargetDay));
    return targetDay;
  }

  List<DateTime>? _getWeekDaysInMonth({required DateTime dateTimeUtc, bool nextMonth = false, int? monthsAhead}) {
    if ((_recurrenceMonthWeekDay == null) ||
        ((_recurrenceMonthWeekDay != _RecurrenceMonthWeekDay.weekday) &&
            (_recurrenceMonthWeekDay != _RecurrenceMonthWeekDay.weekend_day))) {
      // Allow only weekday and weekend_day values
      return null;
    }
    List<DateTime> monthDays = <DateTime>[];

    int month = nextMonth ? (dateTimeUtc.month + (monthsAhead ?? 1)) : dateTimeUtc.month;

    DateTime firstDayOfMonth = DateTime.utc(dateTimeUtc.year, month, 1, dateTimeUtc.hour, dateTimeUtc.minute, dateTimeUtc.second,
        dateTimeUtc.millisecond, dateTimeUtc.microsecond);
    DateTime lastDayOfMonth = DateTime.utc(dateTimeUtc.year, month + 1, 0, dateTimeUtc.hour, dateTimeUtc.minute, dateTimeUtc.second,
        dateTimeUtc.millisecond, dateTimeUtc.microsecond);

    for (DateTime date = firstDayOfMonth; date.isBefore(lastDayOfMonth.add(Duration(days: 1))); date = date.add(Duration(days: 1))) {
      // Weekday
      if (_recurrenceMonthWeekDay == _RecurrenceMonthWeekDay.weekday) {
        if (date.weekday != DateTime.saturday && date.weekday != DateTime.sunday) {
          monthDays.add(date);
        }
      }
      // Weekend_day
      else if (_recurrenceMonthWeekDay == _RecurrenceMonthWeekDay.weekend_day) {
        if ((date.weekday == DateTime.saturday) || (date.weekday == DateTime.sunday)) {
          monthDays.add(date);
        }
      }
    }

    return monthDays;
  }

  DateTime? _getNthWeekDay({required DateTime dateTimeUtc, required int n, bool nextMonth = false, int? monthsAhead}) {
    List<DateTime>? weekdays = _getWeekDaysInMonth(dateTimeUtc: dateTimeUtc, nextMonth: nextMonth, monthsAhead: monthsAhead);
    if (CollectionUtils.isNotEmpty(weekdays) && (n <= weekdays!.length)) {
      return weekdays[n - 1];
    } else {
      return null;
    }
  }

  DateTime? _getLastWeekDay({required DateTime dateTimeUtc, bool nextMonth = false, int? monthsAhead}) {
    List<DateTime>? weekdays = _getWeekDaysInMonth(dateTimeUtc: dateTimeUtc, nextMonth: nextMonth, monthsAhead: monthsAhead);
    return CollectionUtils.isNotEmpty(weekdays) ? weekdays!.last : null;
  }

  int? get _monthWeekDayNumber {
    switch (_recurrenceMonthWeekDay) {
      case _RecurrenceMonthWeekDay.monday:
        return 1;
      case _RecurrenceMonthWeekDay.tuesday:
        return 2;
      case _RecurrenceMonthWeekDay.wednesday:
        return 3;
      case _RecurrenceMonthWeekDay.thursday:
        return 4;
      case _RecurrenceMonthWeekDay.friday:
        return 5;
      case _RecurrenceMonthWeekDay.saturday:
        return 6;
      case _RecurrenceMonthWeekDay.sunday:
        return 7;
      default:
        return null;
    }
  }

  int? get _nThDayOfMonth {
    switch (_recurrenceOrdinalNumber) {
      case _RecurrenceOrdinalNumber.first:
        return 1;
      case _RecurrenceOrdinalNumber.second:
        return 2;
      case _RecurrenceOrdinalNumber.third:
        return 3;
      case _RecurrenceOrdinalNumber.fourth:
        return 4;
      default:
        return null;
    }
  }

  List<Event2>? _buildRecurringEventsFrom({required Event2 mainEvent, required List<_RecurringDatesPair> dates}) {
    if (CollectionUtils.isEmpty(dates)) {
      return null;
    }
    List<Event2> events = <Event2>[];
    for (_RecurringDatesPair pair in dates) {
      events.add(mainEvent.toRecurringEvent(startDateTimeUtc: pair.startDateTimeUtc, endDateTimeUtc: pair.endDateTimeUtc));
    }
    return events;
  }

  Future<void> _createRecurringEventsFrom({required Event2 mainEvent, required List<_RecurringDatesPair> recurringDates}) async {
    // Create each event separately until we have a backend API for that
    List<Event2>? recurringEvents = _buildRecurringEventsFrom(mainEvent: mainEvent, dates: recurringDates);
    if (CollectionUtils.isNotEmpty(recurringEvents)) {
      for (Event2 recurringEvent in recurringEvents!) {
        dynamic recurringResult;
        if (_callCreateGroupEvent) {
          recurringResult = await Events2().createGroupEvent(recurringEvent);
        } else {
          recurringResult = await Events2().createEvent(recurringEvent);
        }
        if (recurringResult is Event2) {
          debugPrint('Successfully created recurring event: ${recurringResult.id}');
        } else {
          String errMsg = StringUtils.isNotEmptyString(recurringResult)
              ? recurringResult
              : Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred');
          Event2Popup.showErrorResult(
              context,
              Localization().getStringEx('panel.event2.create.recurring_event.failed.msg', 'Failed to create recurring event. Reason: ') +
                  errMsg);
        }
      }
    }
  }

  String _getRecurrenceMonthlyDayLabel(int? day) {
    if (day == null) {
      return '-----';
    }
    return '$day${_getOrdinalDaySuffix(day)} ${Localization().getStringEx('panel.event2.create.label.recurrence.period.day.label', 'day')}';
  }

  String _getOrdinalDaySuffix(int day) {
    if (day < 1 || day > _maxRecurrenceRepeatDayValue) {
      return '';
    }
    switch (day) {
      case 1:
      case 21:
      case 31:
        return 'st';
      case 2:
      case 22:
        return 'nd';
      case 3:
      case 23:
        return 'rd';
      default:
        return 'th';
    }
  }

  Widget _datePickerTransitionBuilder(BuildContext context, Widget child) {
    return Theme(
        data: Theme.of(context).copyWith(datePickerTheme: DatePickerThemeData(backgroundColor: Styles().colors.white)), child: child);
  }

  Widget _timePickerTransitionBuilder(BuildContext context, Widget child) {
    return Theme(
        data: Theme.of(context).copyWith(
            timePickerTheme: TimePickerThemeData(
                backgroundColor: Styles().colors.white,
                dialBackgroundColor: Styles().colors.background,
                hourMinuteColor: Styles().colors.background)),
        child: child);
  }
}

// _Event2Visibility

enum _Event2Visibility { public, group_member, registered_user }

String _event2VisibilityToDisplayString(_Event2Visibility value) {
  switch (value) {
    case _Event2Visibility.public:
      return Localization().getStringEx('model.event2.event_type.public', 'Public');
    case _Event2Visibility.group_member:
      return Localization().getStringEx('model.event2.event_type.group_members', 'Group Members Only');
    case _Event2Visibility.registered_user:
      return Localization().getStringEx('model.event2.event_type.private', 'Uploaded Guest List Only');
  }
}

_Event2Visibility? _event2VisibilityFromAuthorizationContext(Event2AuthorizationContext? authorizationContext) {
  if (authorizationContext == null) {
    return _Event2Visibility.public;
  } else {
    if (authorizationContext.isGroupMembersOnly) {
      return _Event2Visibility.group_member;
    } else if (authorizationContext.isGuestListOnly) {
      return _Event2Visibility.registered_user;
    } else {
      return _Event2Visibility.public;
    }
  }
}

// _ErrorCategory

enum _ErrorCategory { missing, invalid }

// _RecurrenceRepeatType

enum _RecurrenceRepeatType { does_not_repeat, weekly, monthly }

String? _repeatTypeToDisplayString(_RecurrenceRepeatType? value) {
  switch (value) {
    case _RecurrenceRepeatType.does_not_repeat: return Localization().getStringEx('panel.event2.create.recurrence.repeat_type.does_not_repeat.label', 'Does Not Repeat');
    case _RecurrenceRepeatType.weekly: return Localization().getStringEx('panel.event2.create.recurrence.repeat_type.weekly.label', 'Weekly');
    case _RecurrenceRepeatType.monthly: return Localization().getStringEx('panel.event2.create.recurrence.repeat_type.monthly.label', 'Monthly');
    default: return null;
  }
}

// _RecurrenceRepeatMonthlyType

enum _RecurrenceRepeatMonthlyType { daily, weekly }

// _RecurrenceOrdinalNumber

enum _RecurrenceOrdinalNumber { first, second, third, fourth, last }

String _recurrenceOrdinalNumberToDisplayString(_RecurrenceOrdinalNumber? value) {
  switch (value) {
    case _RecurrenceOrdinalNumber.first: return Localization().getStringEx('panel.event2.create.recurrence.ordinal_number.first.label', 'First');
    case _RecurrenceOrdinalNumber.second: return Localization().getStringEx('panel.event2.create.recurrence.ordinal_number.second.label', 'Second');
    case _RecurrenceOrdinalNumber.third: return Localization().getStringEx('panel.event2.create.recurrence.ordinal_number.third.label', 'Third');
    case _RecurrenceOrdinalNumber.fourth: return Localization().getStringEx('panel.event2.create.recurrence.ordinal_number.fourth.label', 'Fourth');
    case _RecurrenceOrdinalNumber.last: return Localization().getStringEx('panel.event2.create.recurrence.ordinal_number.last.label', 'Last');
    default: return '-----';
  }
}

// _RecurrenceMonthWeekDay

enum _RecurrenceMonthWeekDay { sunday, monday, tuesday, wednesday, thursday, friday, saturday, day, weekday, weekend_day }

String _recurrenceMonthWeekDayToDisplayString(_RecurrenceMonthWeekDay? value) {
  switch (value) {
    case _RecurrenceMonthWeekDay.sunday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.sunday.label', 'Sunday');
    case _RecurrenceMonthWeekDay.monday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.monday.label', 'Monday');
    case _RecurrenceMonthWeekDay.tuesday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.tuesday.label', 'Tuesday');
    case _RecurrenceMonthWeekDay.wednesday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.wednesday.label', 'Wednesday');
    case _RecurrenceMonthWeekDay.thursday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.thursday.label', 'Thursday');
    case _RecurrenceMonthWeekDay.friday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.friday.label', 'Friday');
    case _RecurrenceMonthWeekDay.saturday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.saturday.label', 'Saturday');
    case _RecurrenceMonthWeekDay.day: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.day.label', 'Day');
    case _RecurrenceMonthWeekDay.weekday: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.weekday.label', 'Weekday');
    case _RecurrenceMonthWeekDay.weekend_day: return Localization().getStringEx('panel.event2.create.recurrence.month.weekday.weekend_day.label', 'Weekend Day');
    default: return '-----';
  }
}

class _RecurringDatesPair {
  final DateTime startDateTimeUtc;
  final DateTime endDateTimeUtc;

  _RecurringDatesPair({required this.startDateTimeUtc, required this.endDateTimeUtc});
}