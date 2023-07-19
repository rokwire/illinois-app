
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/events2/Event2SetupRegistrationPanel.dart';
import 'package:illinois/ui/events2/Event2SetupSponsorshipAndContactsPanel.dart';
import 'package:illinois/ui/events2/Event2SetupSurveyPanel.dart';
import 'package:illinois/ui/events2/Event2TimeRangePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreMapSelectLocationPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

import 'Event2SetupAttendancePanel.dart';

class Event2CreatePanel extends StatefulWidget {

  final Event2? event;

  Event2CreatePanel({Key? key, this.event}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2CreatePanelState();

  bool get isUpdate => StringUtils.isNotEmpty(event?.id);
  bool get isCreate => StringUtils.isEmpty(event?.id);

  // Shared Helpers

  static const EdgeInsetsGeometry sectionPadding = const EdgeInsets.only(bottom: 24);
  static const EdgeInsetsGeometry innerSectionPadding = const EdgeInsets.only(bottom: 12);

  static const EdgeInsetsGeometry sectionHeadingPadding = const EdgeInsets.only(bottom: 8);
  static const EdgeInsetsGeometry innerSectionHeadingPadding = const EdgeInsets.only(bottom: 4);

  static const EdgeInsetsGeometry sectionHeadingContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  static const EdgeInsetsGeometry sectionBodyContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsetsGeometry dropdownButtonContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static const EdgeInsetsGeometry textEditContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  static const EdgeInsetsGeometry innerTextEditContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static TextStyle? get headingTextStype => Styles().textStyles?.getTextStyle("panel.create_event.title.small");
  static TextStyle? get subTitleTextStype => Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");
  static TextStyle? get textEditStyle => Styles().textStyles?.getTextStyle('widget.input_field.dark.text.regular.thin');

  static BoxDecoration get sectionDecoration => BoxDecoration(
    border: Border.all(color: Styles().colors!.mediumGray2!, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8))
  );

  static BoxDecoration get sectionSplitterDecoration => BoxDecoration(
    border: Border(top: BorderSide(color: Styles().colors!.mediumGray2!, width: 1))
  );

  static InputDecoration textEditDecoration({EdgeInsetsGeometry? padding}) => InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1),
      borderRadius: BorderRadius.circular(8)
    ),
    contentPadding: padding,
  );

  static BoxDecoration get dropdownButtonDecoration => BoxDecoration(
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
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

  static Widget buildInnerSectionWidget({ required Widget heading, required Widget body,
    EdgeInsetsGeometry padding = innerSectionPadding,
    EdgeInsetsGeometry bodyPadding = EdgeInsets.zero
  }) => buildSectionWidget(heading: heading, body: body, padding: padding, bodyPadding: bodyPadding);

  static Widget buildSectionHeadingWidget(String title, { bool required = false, String? prefixImageKey, String? suffixImageKey, EdgeInsetsGeometry padding = sectionHeadingPadding }) {
    String semanticsLabel = title;
    if (required) {
      semanticsLabel += ", required";
    }

    List<Widget> contentList = <Widget>[];

    Widget? prefixImageWidget = (prefixImageKey != null) ? Styles().images?.getImage(prefixImageKey) : null;
    if (prefixImageWidget != null) {
      contentList.add(Padding(padding: EdgeInsets.only(right: 6), child:
        prefixImageWidget,
      ));
    }

    contentList.add(buildSectionTitleWidget(title));
    
    if (required) {
      contentList.add(Padding(padding: EdgeInsets.only(left: 2), child:
        Text('*', style: Styles().textStyles?.getTextStyle("widget.label.small.fat"),),
      ));
    }

    Widget? suffixImageWidget = (suffixImageKey != null) ? Styles().images?.getImage(suffixImageKey) : null;
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

  static Widget buildSectionTitleWidget(String title, {int? maxLines}) =>
    Text(title, style: headingTextStype, maxLines: maxLines);

  static Widget buildSectionSubTitleWidget(String subTitle) =>
    Text(subTitle, style: subTitleTextStype);

  static Widget buildSectionRequiredWidget() => 
    Text('*', style: Styles().textStyles?.getTextStyle("widget.label.small.fat"),);

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
  }) {
    List<Widget> wrapList = <Widget>[
      buildSectionTitleWidget(title),
    ];

    if (required) {
      wrapList.add(Padding(padding: EdgeInsets.only(left: 2), child:
        buildSectionRequiredWidget(), 
      ));
    }

    return InkWell(onTap: onToggleExpanded, child:
      Padding(padding: padding, child:
        Row(children: [
          Expanded(child:
            Wrap(children: wrapList),
          ),
          Padding(padding: EdgeInsets.only(left: 8), child:
            Styles().images?.getImage(expanded ? 'chevron-up' : 'chevron-down') ?? Container()
          ),
        ],),
      ),
    );
  }

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

  static Widget buildButtonSectionHeadingWidget({String? title, String? subTitle, bool required = false, void Function()? onTap, EdgeInsetsGeometry? padding }) {

    List<Widget> wrapList = <Widget>[];

    if (title != null) {
      wrapList.add(buildSectionTitleWidget(title));
    }

    if (required) {
      wrapList.add(Padding(padding: EdgeInsets.only(left: 2), child:
        buildSectionRequiredWidget(), 
      ));
    }

    Widget leftWidget = (subTitle != null) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(children: wrapList),
      Padding(padding: EdgeInsets.only(top: 2), child:
        buildSectionSubTitleWidget(subTitle),
      )
    ],) : Wrap(children: wrapList);

    EdgeInsetsGeometry appliedPadding = padding ?? ((subTitle != null) ?
      const EdgeInsets.symmetric(horizontal: 16, vertical: 11) :
      sectionHeadingContentPadding
    );

    return InkWell(onTap: onTap, child:
      Padding(padding: appliedPadding, child:
        Row(children: [
          Expanded(child:
            leftWidget,
          ),
          Padding(padding: EdgeInsets.only(left: 8), child:
            Styles().images?.getImage('chevron-right') ?? Container()
          ),
        ],),
      ),
    );
  }

  // Text Edit

  static Widget buildTextEditWidget(TextEditingController controller, {
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool autocorrect = false,
    EdgeInsetsGeometry padding = textEditContentPadding,
    void Function()? onChanged,
  }) =>
    TextField(
      controller: controller,
      decoration: textEditDecoration(padding: padding),
      style: textEditStyle,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autocorrect: autocorrect,
      onChanged: (onChanged != null) ? ((_) => onChanged) : null,
    );

  static Widget buildInnerTextEditWidget(TextEditingController controller, {
    TextInputType? keyboardType,
    int? maxLines = 1,
    bool autocorrect = false,
    EdgeInsetsGeometry padding = innerTextEditContentPadding,
    void Function()? onChanged,
  }) =>
    buildTextEditWidget(controller, keyboardType: keyboardType, maxLines: maxLines, autocorrect: autocorrect, padding: padding, onChanged: onChanged);


  // Confirm URL

  static Widget buildConfirmUrlLink({
    void Function()? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.only(top: 8, bottom: 16, left: 12)
  }) {
    return Align(alignment: Alignment.centerRight, child:
      LinkButton(
        title: Localization().getStringEx('panel.event2.create.button.confirm_url.title', 'Confirm URL'),
        hint: Localization().getStringEx('panel.event2.create.button.confirm_url.hint', ''),
        onTap: onTap,
        padding: padding,
      )
    );
  }

  static void confirmLinkUrl(TextEditingController controller, { String? analyticsTarget }) {
    Analytics().logSelect(target: analyticsTarget ?? "Confirm URL");
    if (controller.text.isNotEmpty) {
      Uri? uri = Uri.tryParse(controller.text);
      if (uri != null) {
        Uri? fixedUri = UrlUtils.fixUri(uri);
        if (fixedUri != null) {
          controller.text = fixedUri.toString();
          uri = fixedUri;
        }
        launchUrl(uri, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      }
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
                decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Styles().colors!.white!, width: 1.5, ))),
                child: Text(title ?? '',
                  style: Styles().textStyles?.getTextStyle("widget.heading.regular.fat")
                ),
              ),
            ],)
          ),
        ),
        //Padding(padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 12), child:
        //  Text(title ?? '', style: Styles().textStyles?.getTextStyle('panel.athletics.home.button.underline'))
        //),
      ),
    );
  }

  static Widget buildHeaderBarActionProgress({ EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 20) }) =>
    Padding(padding: padding, child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors?.white, strokeWidth: 3,)
        )
    );

}

class _Event2CreatePanelState extends State<Event2CreatePanel>  {

  String? _imageUrl;

  late Location _timeZone;
  DateTime? _startDate;
  TimeOfDay? _startTime;
  DateTime? _endDate;
  TimeOfDay? _endTime;
  bool _allDay = false;

  Event2Type? _eventType;
  late _Event2Visibility _visibility;
  
  late bool _free;
  
  Map<String, dynamic>? _attributes;

  Event2RegistrationDetails? _registrationDetails;
  Event2AttendanceDetails? _attendanceDetails;

  String? _sponsor;
  String? _speaker;
  List<Event2Contact>? _contacts;
  Event2SurveyDetails? _surveyDetails;
  // Explore? _locationExplore;

  late List<String> _errorList;
  bool _creatingEvent = false;

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

  bool _dateTimeSectionExpanded = false;
  bool _typeAndLocationSectionExpanded = false;
  bool _costSectionExpanded = false;

  @override
  void initState() {
    _titleController.addListener(_updateErrorList);
    _onlineUrlController.addListener(_updateErrorList);
    _locationLatitudeController.addListener(_updateErrorList);
    _locationLongitudeController.addListener(_updateErrorList);
    
    _titleController.text = widget.event?.name ?? '';
    _descriptionController.text = widget.event?.description ?? '';
    _imageUrl = widget.event?.imageUrl;
    _websiteController.text = widget.event?.eventUrl ?? '';

    _timeZone = timeZoneDatabase.locations[widget.event?.timezone] ?? DateTimeUni.timezoneUniOrLocal;
    if (widget.event?.startTimeUtc != null) {
      TZDateTime startTimeUni = TZDateTime.from(widget.event!.startTimeUtc!, _timeZone);
      _startDate = TZDateTimeUtils.dateOnly(startTimeUni);
      _startTime = TimeOfDay.fromDateTime(startTimeUni);
    }
    if (widget.event?.endTimeUtc != null) {
      TZDateTime endTimeUni = TZDateTime.from(widget.event!.endTimeUtc!, _timeZone);
      _endDate = TZDateTimeUtils.dateOnly(endTimeUni);
      _endTime = TimeOfDay.fromDateTime(endTimeUni);
    }
    //_allDay = (widget.event?.allDay == true);

    _eventType = widget.event?.eventType;
    _locationLatitudeController.text = _printLatLng(widget.event?.exploreLocation?.latitude);
    _locationLongitudeController.text = _printLatLng(widget.event?.exploreLocation?.longitude);
    _locationBuildingController.text = widget.event?.exploreLocation?.building ?? widget.event?.exploreLocation?.name ?? '';
    _locationAddressController.text = widget.event?.exploreLocation?.address ?? widget.event?.exploreLocation?.description ?? '';

    _onlineUrlController.text = widget.event?.onlineDetails?.url ?? '';
    _onlineMeetingIdController.text = widget.event?.onlineDetails?.meetingId ?? '';
    _onlinePasscodeController.text = widget.event?.onlineDetails?.meetingPasscode ?? '';

    // TBD grouping
    _attributes = widget.event?.attributes;
    _visibility = _event2VisibilityFromPrivate(widget.event?.private) ?? _Event2Visibility.public;

    //NA: canceled
    //NA: userRole

    _free = widget.event?.free ?? true;
    _costController.text = widget.event?.cost ?? '';

    _registrationDetails = widget.event?.registrationDetails;
    _attendanceDetails = widget.event?.attendanceDetails;
    _surveyDetails = widget.event?.surveyDetails;

    _sponsor = widget.event?.sponsor ?? '';
    _speaker = widget.event?.speaker ?? '';
    _contacts = widget.event?.contacts;

    _dateTimeSectionExpanded = widget.isUpdate;
    _typeAndLocationSectionExpanded = widget.isUpdate;
    _costSectionExpanded = widget.isUpdate;

    _errorList = _buildErrorList();

    super.initState();
  }

  @override
  void dispose() {
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: widget.isCreate ?
        Localization().getStringEx("panel.event2.create.header.title", "Create an Event") :
        Localization().getStringEx("panel.event2.update.header.title", "Update Event"),
      ),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
      Column(children: [
        _buildImageWidget(),
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildTitleSection(),
            _buildDateAndTimeDropdownSection(),
            _buildTypeAndLocationDropdownSection(),
            _buildCostDropdownSection(),
            _buildDescriptionSection(),
            _buildWebsiteSection(),
            _buildAttributesButtonSection(),
            _buildRegistrationButtonSection(),
            _buildAttendanceButtonSection(),
            _buildSurveyButtonSection(),
            _buildSponsorshipAndContactsButtonSection(),
            _buildVisibilitySection(),
            _buildCreateEventSection(),
          ]),
        )

      ],)

    );
  }

  // Image

  Widget _buildImageWidget() {
    String buttonTitle = (_imageUrl != null) ?
      Localization().getStringEx("panel.create_event.modify_image", "Modify event image") :
      Localization().getStringEx("panel.create_event.add_image", "Add event image");
    String buttonHint = (_imageUrl != null) ?
      Localization().getStringEx("panel.create_event.modify_image.hint","") :
      Localization().getStringEx("panel.create_event.add_image.hint","");

    return Container(height: 200, color: Styles().colors!.background, child:
      Stack(alignment: Alignment.bottomCenter, children: <Widget>[
          Positioned.fill(child: (_imageUrl != null) ?
            Image.network(_imageUrl!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders) : Container()
          ),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child: Container(height: 53)),
          CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.white), child: Container(height: 30)),
          Positioned.fill(child:
            Center(child:
              Semantics(label: buttonTitle, hint: buttonHint, button: true, excludeSemantics: true, child:
                RoundedButton(
                  label: buttonTitle,
                  textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                  onTap: _onTapAddImage,
                  backgroundColor: Styles().colors!.white,
                  borderColor: Styles().colors!.fillColorSecondary,
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
    GroupAddImageWidget.show(context: context, updateUrl: _imageUrl).then((String? updateUrl) {
      if (mounted && (updateUrl != null) && (0 < updateUrl.length) && (_imageUrl != updateUrl)) {
        setState(() {
          _imageUrl = updateUrl;
        });
      }
    });

  }

  // Title and Description

  Widget _buildTitleSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.title.title', 'EVENT TITLE'), required: true),
    body: Event2CreatePanel.buildTextEditWidget(_titleController, keyboardType: TextInputType.text, maxLines: null, autocorrect: true),
  );

  Widget _buildDescriptionSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.description.title', 'EVENT DESCRIPTION')),
    body: Event2CreatePanel.buildTextEditWidget(_descriptionController, keyboardType: TextInputType.text, maxLines: null, autocorrect: true),
  );

  Widget _buildWebsiteSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.website.title', 'ADD EVENT WEBSITE LINK'), suffixImageKey: 'external-link'),
    body: Event2CreatePanel.buildTextEditWidget(_websiteController, keyboardType: TextInputType.url),
    trailing: Event2CreatePanel.buildConfirmUrlLink(onTap: (_onConfirmWebsiteLink)),
    padding: const EdgeInsets.only(bottom: 8), // Link button tapable area
  );

  void _onConfirmWebsiteLink() => Event2CreatePanel.confirmLinkUrl(_websiteController, analyticsTarget: 'Confirm Website URL');

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
      timeLabel: Localization().getStringEx("panel.create_event.date_time.start_time.title","START TIME"),
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
      timeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title","END TIME"),
    ),
    
    //Padding(padding: EdgeInsets.only(bottom: 12)),

    //_buildAllDayToggle(),

  ]);

  
  Widget _buildTimeZoneDropdown(){
    return Semantics(container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 3, child:
          Event2CreatePanel.buildSectionTitleWidget(Localization().getStringEx("panel.create_event.date_time.time_zone.title", "TIME ZONE")),
        ),
        Container(width: 16,),
        Expanded(flex: 7, child:
          Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
            Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
              DropdownButtonHideUnderline(child:
                DropdownButton<Location>(
                  icon: Styles().images?.getImage('chevron-down'),
                  isExpanded: true,
                  style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
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
          child: Text(name,),
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
    String? timeLabel,
    String? semanticsDateLabel,
    String? semanticsTimeLabel,
  }) {
    List<Widget> contentList = <Widget>[
      Expanded(flex: hasTime ? 2 : 1, child:
        Semantics(label: semanticsDateLabel, button: true, excludeSemantics: true, child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
            Padding(padding: EdgeInsets.only(bottom: 4), child:
              Row(children: <Widget>[
                Event2CreatePanel.buildSectionTitleWidget(dateLabel ?? ''),
              ],),
            ),
            _buildDropdownButton(label: (date != null) ? DateFormat("EEE, MMM dd, yyyy").format(date) : "-", onTap: onDate,)
          ],)
        ),
      ),
    ];
    
    if (hasTime) {
      contentList.add(Expanded(flex: 1, child:
        Padding(padding: EdgeInsets.only(left: 4), child:
          Semantics(label:semanticsTimeLabel, button: true, excludeSemantics: true, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(bottom: 4), child:
                Row(children: <Widget>[
                  Text(timeLabel ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Event2CreatePanel.headingTextStype),
                ],),
              ),
              _buildDropdownButton(label: (time != null) ? DateFormat("h:mma").format(_dateWithTimeOfDay(time)) : "-", onTap: onTime,)
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
          Text(label ??  '-', style: Styles().textStyles?.getTextStyle("widget.title.regular"),),
          Styles().images?.getImage('chevron-down') ?? Container()
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
  BoxBorder get _toggleBorder => Border.all(color: Styles().colors!.surfaceAccent!, width: 1);
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
    showDatePicker(context: context,
      initialDate: _startDate ?? minDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _startDate = DateUtils.dateOnly(result);
          _errorList = _buildErrorList();
        });
      }
    });
  }

  void _onStartTime() {
    Analytics().logSelect(target: "Start Time");
    Event2CreatePanel.hideKeyboard(context);
    showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay(hour: 0, minute: 0)).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _startTime = result;
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
    showDatePicker(context: context,
      initialDate: _endDate ?? minDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
    ).then((DateTime? result) {
      if ((result != null) && mounted) {
        setState(() {
          _endDate = DateUtils.dateOnly(result);
        });
      }
    });
  }

  void _onEndTime() {
    Analytics().logSelect(target: "End Time");
    Event2CreatePanel.hideKeyboard(context);
    showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay(hour: 0, minute: 0)).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _endTime = result;
        });
      }
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

    if ((_eventType == Event2Type.inPerson) || (_eventType == Event2Type.hybrid)) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildLocationBuildingInnerSection(),
        _buildLocationAddressInnerSection(),
        _buildLocationLatitudeInnerSection(),
        _buildLocationLongitudeInnerSection(),
        _buildSelectLocationButton()
      ]);
    }

    if ((_eventType == Event2Type.online) || (_eventType == Event2Type.hybrid)) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildOnlineUrlInnerSection(),
        _buildOnlineMeetingIdInnerSection(),
        _buildOnlinePasscodeInnerSection(),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget _buildEventTypeDropdown(){
    return Semantics(container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 3, child:
          RichText(text:
            TextSpan(text: Localization().getStringEx("panel.event2.create.label.event_type.title", "EVENT TYPE"), style: Event2CreatePanel.headingTextStype, children: <InlineSpan>[
              TextSpan(text: ' *', style: Styles().textStyles?.getTextStyle('widget.label.small.fat'),),
            ])
          )
        ),
        Container(width: 16,),
        Expanded(flex: 7, child:
          Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
            Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
              DropdownButtonHideUnderline(child:
                DropdownButton<Event2Type>(
                  icon: Styles().images?.getImage('chevron-down'),
                  isExpanded: true,
                  style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
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
        _errorList = _buildErrorList();
      });
    }
  }

  Widget _buildLocationBuildingInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.building.title', 'LOCATION BUILDING')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationBuildingController, keyboardType: TextInputType.text, autocorrect: true),
  );

  Widget _buildLocationAddressInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.address.title', 'LOCATION ADDRESS')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationAddressController, keyboardType: TextInputType.text, autocorrect: true),
  );

  Widget _buildLocationLatitudeInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.latitude.title', 'LOCATION LATITUDE'), required: true),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationLatitudeController, keyboardType: TextInputType.number),
  );

  Widget _buildLocationLongitudeInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.location.longitude.title', 'LOCATION LONGITUDE'), required: true),
    body: Event2CreatePanel.buildInnerTextEditWidget(_locationLongitudeController, keyboardType: TextInputType.number),
  );

  Widget _buildSelectLocationButton() {
    String buttonTitle = Localization().getStringEx("panel.event2.create.location.button.select.title", "Select Location on a Map");
    String buttonHint = Localization().getStringEx("panel.event2.create.location.button.select.hint", "");

    return Padding(padding: Event2CreatePanel.innerSectionPadding, child:
      Semantics(label: buttonTitle, hint: buttonHint, button: true, excludeSemantics: true, child:
        RoundedButton(
          label: buttonTitle,
          textStyle: Styles().textStyles?.getTextStyle("widget.button.title.regular"),
          onTap: _onTapSelectLocation,
          backgroundColor: Styles().colors!.white,
          borderColor: Styles().colors!.fillColorSecondary,
          contentWeight: 0.80,
        )
      ),
    );
  }

  Widget _buildOnlineUrlInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.online_details.url.title', 'ONLINE URL'), required: true),
    body: Event2CreatePanel.buildInnerTextEditWidget(_onlineUrlController, keyboardType: TextInputType.url),
  );

  Widget _buildOnlineMeetingIdInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.online_details.meeting_id.title', 'MEETING ID')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_onlineMeetingIdController, keyboardType: TextInputType.text),
  );

  Widget _buildOnlinePasscodeInnerSection() => Event2CreatePanel.buildInnerSectionWidget(
    heading: Event2CreatePanel.buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.online_details.passcode.title', 'PASSCODE')),
    body: Event2CreatePanel.buildInnerTextEditWidget(_onlinePasscodeController, keyboardType: TextInputType.text),
  );

  void _onTapSelectLocation() {
    Analytics().logSelect(target: "Select Location");
    Event2CreatePanel.hideKeyboard(context);
    ExploreLocation? location = _constructLocation();

    Navigator.push<Explore>(context, CupertinoPageRoute(builder: (context) => ExploreMapSelectLocationPanel(
      selectedExplore: (location != null) ? ExplorePOI(location: location) : null,
    ))).then((Explore? explore) {
      if ((explore != null) && mounted) {
        _locationBuildingController.text = (explore.exploreTitle ?? explore.exploreLocation?.building ?? explore.exploreLocation?.name ?? '').replaceAll('\n', ' ');
        _locationAddressController.text = explore.exploreLocation?.fullAddress ?? explore.exploreLocation?.buildDisplayAddress() ?? explore.exploreLocation?.description ?? '';
        _locationLatitudeController.text = _printLatLng(explore.exploreLocation?.latitude);
        _locationLongitudeController.text = _printLatLng(explore.exploreLocation?.longitude);
        setState(() {
          _errorList = _buildErrorList();
        });
      }
    });
  }

  // Cost

  Widget _buildCostDropdownSection() => Event2CreatePanel.buildDropdownSectionWidget(
    heading: Event2CreatePanel.buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.section.cost.title', 'COST'),
      required: true,
      expanded: _costSectionExpanded,
      onToggleExpanded: _onToggleCostSection,
    ),
    body: _buildCostSectionBody(),
    expanded: _costSectionExpanded,
  );

  Widget _buildCostSectionBody() {
    List<Widget> contentList = <Widget>[
      _buildFreeToggle(),
    ];

    if (_free == false) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildCostInnerSection(),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget _buildFreeToggle() => Semantics(toggled: _free, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.create.free.toggle.title", "Is this event free?"),
    hint: Localization().getStringEx("panel.event2.create.free.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.create.free.toggle.title", "Is this event free?"),
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
            RichText(text:
              TextSpan(text: title, style: Event2CreatePanel.headingTextStype, children: <InlineSpan>[
                TextSpan(text: description, style: Styles().textStyles?.getTextStyle('widget.item.small.thin'),),
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
    });
  }


  // Attributes

  Widget _buildAttributesButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.attributes.title', 'EVENT ATTRIBUTES'),
      subTitle: (_attributes?.isEmpty ?? true) ? Localization().getStringEx('panel.event2.create.button.attributes.description', 'Choose attributes related to your event.') : null,
      required: Events2().contentAttributes?.hasRequired(contentAttributeRequirementsScopeCreate) ?? false,
      onTap: _onEventAttributes,
    ),
    body: _buildAttributesSectionBody(),
  );

  Widget? _buildAttributesSectionBody() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");

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
          RichText(text: TextSpan(style: regularStyle, children: descriptionList))
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
      contentAttributes: Events2().contentAttributes,
      selection: _attributes,
      sortType: ContentAttributesSortType.native,
    ))).then((selection) {
      if ((selection != null) && mounted) {
        setState(() {
          _attributes = selection;
          _errorList = _buildErrorList();
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
    Navigator.push<Event2RegistrationDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupRegistrationPanel(
      registrationDetails: _registrationDetails,
    ))).then((Event2RegistrationDetails? result) {
      setStateIfMounted(() {
        _registrationDetails = result;
      });
    });
  }

  // Attendance

  Widget  _buildAttendanceButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.attendance.title', 'EVENT ATTENDANCE'),
      subTitle: (_attendanceDetails?.isNotEmpty == true) ?
        Localization().getStringEx('panel.event2.create.button.attendance.confirmation', 'Event attendance details set up.') :
        Localization().getStringEx('panel.event2.create.button.attendance.description', 'Receive feedback about your event.'),
      onTap: _onEventAttendance,
    ),
  );

  void _onEventAttendance() {
    Analytics().logSelect(target: "Event Attendance");
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<Event2AttendanceDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupAttendancePanel(attendanceDetails: _attendanceDetails
    ))).then((Event2AttendanceDetails? result) {
      setStateIfMounted(() {
        _attendanceDetails = result;
      });
    });
  }

  // Follow-Up Survey

  Widget  _buildSurveyButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.survey.title', 'EVENT FOLLOW-UP SURVEY'),
      subTitle: Localization().getStringEx('panel.event2.create.button.survey.description', 'Receive feedback about your event'),
      onTap: _onEventSurvey,
    ),
  );

  void _onEventSurvey() {
    Analytics().logSelect(target: "Event Follow-Up Survey");
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<Event2SurveyDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupSurveyPanel(details: _surveyDetails
    ))).then((Event2SurveyDetails? result) {
      setStateIfMounted(() {
        _surveyDetails = result;
      });
    });
  }

  // Sponsorship and Contacts

  Widget _buildSponsorshipAndContactsButtonSection() => Event2CreatePanel.buildButtonSectionWidget(
    heading: Event2CreatePanel.buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.title', 'SPONSORSHIP AND CONTACTS'),
      subTitle: !_hasSponsorshipAndContacts ? Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.description', 'Set sponsor, speaker and contacts to your event.') : null,
      onTap: _onSponsorshipAndContacts,
    ),
    body: _buildSponsorshipAndContactsSectionBody()
  );

  Widget? _buildSponsorshipAndContactsSectionBody() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");

//	"panel.event2.create.button.sponsorship_and_contacts.label.sponsor": "Sponsor: ",
//	"panel.event2.create.button.sponsorship_and_contacts.label.speaker": "Speaker: ",
//	"panel.event2.create.button.sponsorship_and_contacts.label.contacts": "Contacts: ",

    if (StringUtils.isNotEmpty(_sponsor)) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: "; " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: Localization().getStringEx('panel.event2.create.button.sponsorship_and_contacts.label.sponsor', 'Sponsor: ') , style: boldStyle,));
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
          RichText(text: TextSpan(style: regularStyle, children: descriptionList))
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
    Analytics().logSelect(target: "Sponsorship and Contacts");
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<Event2SponsorshipAndContactsDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupSponsorshipAndContactsPanel(details: Event2SponsorshipAndContactsDetails(
      sponsor: _sponsor,
      speaker: _speaker,
      contacts: _contacts,
    )))).then((Event2SponsorshipAndContactsDetails? result) {
      if ((result != null) && mounted) {
        setState(() {
          _sponsor = result.sponsor;
          _speaker = result.speaker;
          _contacts = result.contacts;
        });
      }
    });
  }

  // Visibility

  Widget _buildVisibilitySection() {
    String title = Localization().getStringEx('panel.event2.create.label.visibility.title', 'EVENT VISIBILITY');
    return Padding(padding: Event2CreatePanel.sectionPadding, child:
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
                    icon: Styles().images?.getImage('chevron-down'),
                    isExpanded: true,
                    style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                    hint: Text(_event2VisibilityToDisplayString(_visibility),),
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
      menuItems.add(DropdownMenuItem<_Event2Visibility>(
        value: value,
        child: Text(_event2VisibilityToDisplayString(value),),
      ));
    }
    return menuItems;
  }

  void _onVisibilityChanged(_Event2Visibility? value) {
    Analytics().logSelect(target: "Visibility: $value");
    Event2CreatePanel.hideKeyboard(context);
    if ((value != null) && mounted) {
      setState(() {
        _visibility = value;
      });
    }
  }

  // Create Event

  Widget _buildCreateEventSection() {
    List<Widget> contentList = <Widget>[
      _buildCreateEventButton(),
    ];
    if (_errorList.isNotEmpty) {
      contentList.add(_buildCreateErrorStatus());
    }
    return Padding(padding: Event2CreatePanel.sectionPadding, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList, )
    );
  }

  Widget _buildCreateEventButton() {
    
    String buttonTitle = widget.isCreate ?
      Localization().getStringEx("panel.event2.create.button.create.title", "Create Event") :
      Localization().getStringEx("panel.event2.update.button.update.title", "Update Event");
    
    String buttonHint = widget.isCreate ?
      Localization().getStringEx("panel.event2.create.button.create.hint", "") :
      Localization().getStringEx("panel.event2.update.button.update.hint", "");
    
    bool buttonEnabled = _canCreateEvent();

    return Semantics(label: buttonTitle, hint: buttonHint, button: true, excludeSemantics: true, child:
      RoundedButton(
        label: buttonTitle,
        textStyle: buttonEnabled ? Styles().textStyles?.getTextStyle('widget.button.title.large.fat') : Styles().textStyles?.getTextStyle('widget.button.disabled.title.large.fat'),
        onTap: buttonEnabled ? _onTapCreateEvent : null,
        backgroundColor: Styles().colors!.white,
        borderColor: buttonEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
        progress: _creatingEvent,
      )
    );
  }

  List<String> _buildErrorList() {
    List<String> errorList = <String>[];

    if (_titleController.text.isEmpty) {
      errorList.add(Localization().getStringEx('panel.event2.create.status.missing.name', 'event name'));
    }

    if (_startDate == null) {
      errorList.add(Localization().getStringEx('panel.event2.create.status.missing.date', 'date and time'));
    }

    if (_eventType == null) {
      errorList.add(Localization().getStringEx('panel.event2.create.status.missing.event_type', 'event type'));
    }
    else if (_inPersonEventType && !_hasLocation) {
      errorList.add(Localization().getStringEx('panel.event2.create.status.missing.location', 'location coordinates'));
    }
    else if (_onlineEventType && !_hasOnlineDetails) {
      errorList.add(Localization().getStringEx('panel.event2.create.status.missing.online_url', 'online URL'));
    }

    if (Events2().contentAttributes?.isSelectionValid(_attributes) != true) {
      errorList.add(Localization().getStringEx('panel.event2.create.status.missing.attributes', 'event attributes'));
    }

    if ((_registrationDetails?.type == Event2RegistrationType.external) && (_registrationDetails?.externalLink?.isEmpty ?? true)) {
      errorList.add(Localization().getStringEx('panel.event2.create.status.missing.registration_link', 'registration link'));
    }
    
    return errorList;
  }


  Widget _buildCreateErrorStatus() {
    List<InlineSpan> descriptionList = <InlineSpan>[];
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("panel.settings.error.text");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("panel.settings.error.text.small");

    for (String error in _errorList) {
      if (descriptionList.isNotEmpty) {
        descriptionList.add(TextSpan(text: ", " , style: regularStyle,));
      }
      descriptionList.add(TextSpan(text: error, style: regularStyle,),);
    }

    if (descriptionList.isNotEmpty) {
      descriptionList.insert(0, TextSpan(text: Localization().getStringEx('panel.event2.create.status.missing.heading', 'Missing: ') , style: boldStyle,));
      descriptionList.add(TextSpan(text: "." , style: regularStyle,));
    }

    return Padding(padding: EdgeInsets.only(top: 12), child:
      Row(children: [ Expanded(child:
        RichText(text: TextSpan(style: regularStyle, children: descriptionList))
      ),],),
    );
  }

  Future<void> _showPopup(String title, String? message) =>
    Event2Popup.showMessage(context, title, message);

  void _onTapCreateEvent() {
    Analytics().logSelect(target: widget.isCreate ? "Create Event" : "Update Event");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _creatingEvent = true;
    });
    Future<dynamic> Function(Event2 source) serviceAPI = widget.isCreate ? Events2().createEvent : Events2().updateEvent;
    serviceAPI(_createEventFromData()).then((dynamic result) {
      if (mounted) {
        setState(() {
          _creatingEvent = false;
        });

        String? title, message;
        if (result is Event2) {
          title = Localization().getStringEx('panel.event2.create.message.succeeded.title', 'Succeeded');
          message = Localization().getStringEx('panel.event2.create.message.succeeded.message', 'Successfully created {{event_name}} event').replaceAll('{{event_name}}', result.name ?? '');
        }
        else if (result is String) {
          title = Localization().getStringEx('panel.event2.create.message.failed.title', 'Failed');
          message = result;
        }

        if (title != null) {
          _showPopup(title, message).then((_) {
            if (result is Event2) {
              Navigator.of(context).pop();
            }
          });
        }
      }
    });
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

  bool get _hasOnlineDetails => _onlineUrlController.text.isNotEmpty;

  DateTime? get _startDateTimeUtc =>
    (_startDate != null) ? Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, _startDate!, _startTime).toUtc() : null;

  DateTime? get _endDateTimeUtc =>
    (_endDate != null) ? Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, _endDate!, _endTime) : null;

  bool get _private => (_visibility == _Event2Visibility.private);

  bool _canCreateEvent() => (
    _titleController.text.isNotEmpty &&
    (_startDate != null) &&
    (_eventType != null) &&
    (!_inPersonEventType || _hasLocation) &&
    (!_onlineEventType || _hasOnlineDetails) &&
    (Events2().contentAttributes?.isAttributesSelectionValid(_attributes) ?? false) &&
    ((_registrationDetails?.type != Event2RegistrationType.external) || (_registrationDetails?.externalLink?.isNotEmpty ?? false))
  );

  void _updateErrorList() {
    List<String> errorList = _buildErrorList();
    if (!DeepCollectionEquality().equals(errorList, _errorList)) {
      setStateIfMounted(() {
        _errorList = errorList;
      });
    }
  }

  Event2 _createEventFromData() =>
    Event2(
      id: widget.event?.id,

      name: Event2CreatePanel.textFieldValue(_titleController),
      description: Event2CreatePanel.textFieldValue(_descriptionController),
      instructions: null,
      imageUrl: _imageUrl,
      eventUrl: Event2CreatePanel.textFieldValue(_websiteController),

      timezone: _timeZone.name,
      startTimeUtc: _startDateTimeUtc,
      endTimeUtc: _endDateTimeUtc,
      allDay: _allDay,

      eventType: _eventType,
      location: _constructLocation(),
      onlineDetails: _onlineDetails,

      grouping: null, // TBD
      attributes: _attributes,
      private: _private,

      canceled: null, // NA
      userRole: null, // NA

      free: _free,
      cost: Event2CreatePanel.textFieldValue(_costController),

      registrationDetails: (_registrationDetails?.type != Event2RegistrationType.none) ? _registrationDetails : null,
      attendanceDetails: (_attendanceDetails?.isNotEmpty ?? false) ? _attendanceDetails : null,
      surveyDetails: (_surveyDetails?.hasSurvey == true) ? _surveyDetails : null,

      sponsor: _sponsor,
      speaker: _speaker,
      contacts: _contacts,
    );
}

// _Event2Visibility

enum _Event2Visibility { public, private }

String _event2VisibilityToDisplayString(_Event2Visibility value) {
  switch(value) {
    case _Event2Visibility.public: return Localization().getStringEx('model.event2.event_type.public', 'Public');
    case _Event2Visibility.private: return Localization().getStringEx('model.event2.event_type.private', 'Private');
  }
}

_Event2Visibility? _event2VisibilityFromPrivate(bool? private) {
  switch (private) {
    case true: return _Event2Visibility.private;
    case false: return _Event2Visibility.public;
    default: return null;
  }
}