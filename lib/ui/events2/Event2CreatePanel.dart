
import 'dart:io';

import 'package:collection/collection.dart';
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
import 'package:illinois/ui/events2/Event2SetupRegistrationPanel.dart';
import 'package:illinois/ui/events2/Event2SetupSponsorshipAndContactsPanel.dart';
import 'package:illinois/ui/events2/Event2SetupSurveyPanel.dart';
import 'package:illinois/ui/events2/Event2TimeRangePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/explore/ExploreMapSelectLocationPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/GestureDetector.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2CreatePanel extends StatefulWidget {

  final Event2? event;
  final Survey? survey;
  final Event2Selector? eventSelector;

  Event2CreatePanel({Key? key, this.event, this.survey, this.eventSelector}) : super(key: key);

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

  static TextStyle? get headingTextStype => Styles().textStyles?.getTextStyle("widget.title.small.fat.spaced");
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
    fillColor: Styles().colors?.surface,
    filled: true,
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1),
      borderRadius: BorderRadius.circular(8)
    ),
    contentPadding: padding,
  );

  static BoxDecoration get dropdownButtonDecoration => BoxDecoration(
    color: Styles().colors?.surface,
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

  static Widget buildInnerSectionWidget({ Widget? heading, Widget? body, Widget? trailing,
    EdgeInsetsGeometry padding = innerSectionPadding,
    EdgeInsetsGeometry bodyPadding = EdgeInsets.zero
  }) => buildSectionWidget(heading: heading, body: body, trailing: trailing, padding: padding, bodyPadding: bodyPadding);

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

  static double get textScaleFactor {
    BuildContext? context = App.instance?.currentContext;
    return (context != null) ? MediaQuery.of(context).textScaleFactor : 1.0;
  }

  static Widget buildSectionTitleWidget(String title, { bool required = false, TextStyle? textStyle, TextStyle? requiredTextStyle,  }) =>
    Semantics ( label: title,
    child: RichText(textScaleFactor: textScaleFactor, text:
      TextSpan(text: title, style: textStyle ?? headingTextStype, semanticsLabel: "", children: required ? <InlineSpan>[
        TextSpan(text: ' *', style: requiredTextStyle ?? Styles().textStyles?.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
      ] : null),
    ));


  static Widget buildSectionSubTitleWidget(String subTitle) =>
    Text(subTitle, style: subTitleTextStype);

  static Widget buildSectionRequiredWidget() => 
    Text('*', style: Styles().textStyles?.getTextStyle("widget.label.small.fat"), semanticsLabel: ", required",);

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
              Styles().images?.getImage(expanded ? 'chevron-up' : 'chevron-down') ?? Container()
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
              Styles().images?.getImage('chevron-right') ?? Container()
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
            CircularProgressIndicator(strokeWidth: 2, color: Styles().colors?.fillColorSecondary,)
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
      Uri? uri = UrlUtils.parseUri(controller.text);
      if (uri != null) {
        if (updateProgress != null) {
          updateProgress(true);
        }
         UrlUtils.fixUriAsync(uri).then((Uri? fixedUri) {
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

class _Event2CreatePanelState extends State<Event2CreatePanel> implements Event2SelectorDataProvider{

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
  late bool _published;

  Map<String, dynamic>? _attributes;

  Event2RegistrationDetails? _registrationDetails;
  Event2AttendanceDetails? _attendanceDetails;
  Event2SurveyDetails? _surveyDetails;
  Survey? _survey;

  String? _sponsor;
  String? _speaker;
  List<Event2Contact>? _contacts;
  // Explore? _locationExplore;

  late Map<_ErrorCategory, List<String>> _errorMap;
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

  final FocusNode _websiteFocus = FocusNode();
  final FocusNode _onlineUrlFocus = FocusNode();

  bool _confirmingWebsiteUrl = false;
  bool _confirmingOnlineUrl = false;

  bool _dateTimeSectionExpanded = false;
  bool _typeAndLocationSectionExpanded = false;
  bool _costSectionExpanded = false;

  List<Survey> _surveysCache = <Survey>[];

  @override
  void initState() {
    _titleController.text = widget.event?.name ?? '';
    _descriptionController.text = widget.event?.description ?? '';
    _imageUrl = widget.event?.imageUrl;
    _websiteController.text = widget.event?.eventUrl ?? '';

    _timeZone = timeZoneDatabase.locations[widget.event?.timezone] ?? DateTimeLocal.timezoneLocal;
    if (widget.event?.startTimeUtc != null) {
      TZDateTime startTime = TZDateTime.from(widget.event!.startTimeUtc!, _timeZone);
      _startDate = TZDateTimeUtils.dateOnly(startTime);
      _startTime = TimeOfDay.fromDateTime(startTime);
    }
    if (widget.event?.endTimeUtc != null) {
      TZDateTime endTime = TZDateTime.from(widget.event!.endTimeUtc!, _timeZone);
      _endDate = TZDateTimeUtils.dateOnly(endTime);
      _endTime = TimeOfDay.fromDateTime(endTime);
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
    _published = widget.event?.published ?? true;
    _costController.text = widget.event?.cost ?? '';

    _registrationDetails = widget.event?.registrationDetails;
    _attendanceDetails = widget.event?.attendanceDetails;
    _surveyDetails = widget.event?.surveyDetails;
    _survey = widget.survey;

    _sponsor = widget.event?.sponsor;
    _speaker = widget.event?.speaker;
    _contacts = widget.event?.contacts;

    _dateTimeSectionExpanded = widget.isUpdate;
    _typeAndLocationSectionExpanded = widget.isUpdate;
    _costSectionExpanded = widget.isUpdate;

    _errorMap = _buildErrorMap();

    _titleController.addListener(_updateErrorMap);
    _onlineUrlController.addListener(_updateErrorMap);
    _locationLatitudeController.addListener(_updateErrorMap);
    _locationLongitudeController.addListener(_updateErrorMap);
    _costController.addListener(_updateErrorMap);
    _websiteController.addListener(_updateErrorMap);
    _initSelector();

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

    _websiteFocus.dispose();
    _onlineUrlFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: _canGoBack, child: Platform.isIOS ?
      BackGestureDetector(onBack: _onHeaderBack, child:
        _buildScaffoldContent(),
      ) :
      _buildScaffoldContent(),
    );
  }

  Widget _buildScaffoldContent() => Scaffold(
    appBar: HeaderBar(title: widget.isCreate ?
      Localization().getStringEx("panel.event2.create.header.title", "Create an Event") :
      Localization().getStringEx("panel.event2.update.header.title", "Update Event"),
      onLeading: _onHeaderBack,),
    body: _buildPanelContent(),
    backgroundColor: Styles().colors!.white,
  );

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
            _buildPublishedSection(),
            _buildVisibilitySection(),
            _buildEventSelectorSection(),
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
              RichText(textScaleFactor: MediaQuery.of(context).textScaleFactor, text:
                TextSpan(text: title, style: Event2CreatePanel.headingTextStype,  children: <InlineSpan>[
                  TextSpan(text: description, style: Styles().textStyles?.getTextStyle('widget.item.small.thin'),),
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
      dateRequired: (_endDate != null) || (_endTime != null),
      timeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title","END TIME"),
      timeRequired: (_endDate != null) || (_endTime != null),
    ),
    
    //Padding(padding: EdgeInsets.only(bottom: 12)),

    //_buildAllDayToggle(),

  ]);

  
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
      Expanded(flex: hasTime ? 2 : 1, child:
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
      contentList.add(Expanded(flex: 1, child:
        Padding(padding: EdgeInsets.only(left: 4), child:
          Semantics(label: semanticsTimeLabel, button: true, excludeSemantics: true, child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Padding(padding: EdgeInsets.only(bottom: 4), child:
                Row(children: <Widget>[
                  Event2CreatePanel.buildSectionTitleWidget(timeLabel ?? '', required: timeRequired),
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
    DateTime selectedDate = (_startDate != null) ? DateTimeUtils.min(DateTimeUtils.max(_startDate!, minDate), maxDate) : minDate;
    showDatePicker(context: context,
      initialDate: selectedDate,
      firstDate: minDate,
      lastDate: maxDate,
      currentDate: now,
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
    showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay(hour: 0, minute: 0)).then((TimeOfDay? result) {
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
    showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay(hour: 0, minute: 0)).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _endTime = result;
          _errorMap = _buildErrorMap();
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

    if ((_eventType == Event2Type.online) || (_eventType == Event2Type.hybrid)) {
      contentList.addAll(<Widget>[
        Padding(padding: Event2CreatePanel.innerSectionPadding),
        _buildOnlineUrlInnerSection(),
        _buildOnlineMeetingIdInnerSection(),
        _buildOnlinePasscodeInnerSection(),
      ]);
    }

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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget _buildEventTypeDropdown(){
    String? title = Localization().getStringEx("panel.event2.create.label.event_type.title", "EVENT TYPE");
    return Semantics(label: "$title, required", container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 4, child:
          RichText(textScaleFactor: MediaQuery.of(context).textScaleFactor, text:
            TextSpan(text: title, style: Event2CreatePanel.headingTextStype, semanticsLabel: "", children: <InlineSpan>[
              TextSpan(text: ' *', style: Styles().textStyles?.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
            ])
          )
        ),
        Container(width: 16,),
        Expanded(flex: 6, child:
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

    Navigator.push<Explore>(context, CupertinoPageRoute(builder: (context) => ExploreMapSelectLocationPanel(
      selectedExplore: (location != null) ? ExplorePOI(location: location) : null,
    ))).then((Explore? explore) {
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
            RichText(textScaleFactor: MediaQuery.of(context).textScaleFactor, text:
              TextSpan(text: title, style: Event2CreatePanel.headingTextStype, children: <InlineSpan>[
                TextSpan(text: description, style: Styles().textStyles?.getTextStyle('widget.item.small.thin'),),
                TextSpan(text: _free ? '' : ' *', style: Styles().textStyles?.getTextStyle('widget.label.small.fat'), semanticsLabel: ""),
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
          RichText(textScaleFactor: MediaQuery.of(context).textScaleFactor, text: TextSpan(style: regularStyle, children: descriptionList))
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
    Navigator.push<Event2RegistrationDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupRegistrationPanel(
      registrationDetails: _registrationDetails,
    ))).then((Event2RegistrationDetails? result) {
      if ((result != null) && mounted) {
        setState(() {
          _registrationDetails = result;
        });
      }
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
    Navigator.push<Event2AttendanceDetails>(context, CupertinoPageRoute(builder: (context) => Event2SetupAttendancePanel(attendanceDetails: _attendanceDetails
    ))).then((Event2AttendanceDetails? result) {
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
    Navigator.push<Event2SetupSurveyParam>(context, CupertinoPageRoute(builder: (context) => Event2SetupSurveyPanel(
      surveyParam: Event2SetupSurveyParam(
        details: _surveyDetails,
        survey: _survey,
      ),
      eventName: _titleController.text,
      surveysCache: _surveysCache,
    ))).then((Event2SetupSurveyParam? result) {
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
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("widget.card.title.tiny.fat");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("widget.card.detail.small.regular");

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
          RichText(textScaleFactor: MediaQuery.of(context).textScaleFactor, text: TextSpan(style: regularStyle, children: descriptionList))
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

  // Published

  Widget _buildPublishedSection() =>  Padding(padding: Event2CreatePanel.sectionPadding, child: _buildPublishedToggle());

  Widget _buildPublishedToggle() => Semantics(toggled: _free, excludeSemantics: true, 
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

  //EventSelector section
  Widget _buildEventSelectorSection() {
    if(widget.eventSelector != null){
      return widget.eventSelector!.buildWidget(this) ?? Container();
    }
    return Container();
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
        textStyle: buttonEnabled ? Styles().textStyles?.getTextStyle('widget.button.title.large.fat') : Styles().textStyles?.getTextStyle('widget.button.disabled.title.large.fat'),
        onTap: buttonEnabled ? _onTapCreateEvent : null,
        backgroundColor: Styles().colors!.white,
        borderColor: buttonEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
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
    TextStyle? boldStyle = Styles().textStyles?.getTextStyle("panel.settings.error.text");
    TextStyle? regularStyle = Styles().textStyles?.getTextStyle("panel.settings.error.text.small");

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
        RichText(textScaleFactor: MediaQuery.of(context).textScaleFactor, text: TextSpan(style: regularStyle, children: descriptionList))
      ),],),
    );
  }

  void _onTapCreateEvent() async {
    Analytics().logSelect(target: widget.isCreate ? "Create Event" : "Update Event");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _creatingEvent = true;
    });
    await widget.eventSelector?.prepareSelection(this);
    Future<dynamic> Function(Event2 source) serviceAPI = widget.eventSelector?.event2SelectorServiceAPI() ?? (widget.isCreate ? Events2().createEvent : Events2().updateEvent);
    dynamic result = await serviceAPI(_createEventFromData());

    if (mounted) {
      if (result is Event2) {
        _selectorEvent = result;
        await widget.eventSelector?.performSelection(this);
        Survey? survey = widget.survey;
        if (widget.isCreate) {
          if (_survey != null) {
            bool? success = await Surveys().createEvent2Survey(_survey!, result);

            setStateIfMounted(() {
              _creatingEvent = false;
            });
            if (success == true && result.id != null) {
              survey = await Surveys().loadEvent2Survey(result.id!);
              Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => Event2DetailPanel(
                event: result,
                survey: survey,
                eventSelector: widget.eventSelector,
              )));
            }
            else {
              Event2Popup.showErrorResult(context, Localization().getStringEx('panel.event2.create.survey.create.failed.msg', 'Failed to create event survey.')).then((_) {
                Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => Event2DetailPanel(
                  event: result,
                  survey: null,
                  eventSelector: widget.eventSelector,
                )));
              });
            }
          }
          else {
            Navigator.of(context).pushReplacement(CupertinoPageRoute(builder: (context) => Event2DetailPanel(
              event: result, eventSelector: widget.eventSelector,
            )));
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
        widget.eventSelector?.finishSelection(this);
      }
      else  {
        setState(() {
          _creatingEvent = false;
        });
        Event2Popup.showErrorResult(context, result);
      }
    }
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
  bool get _hasValidOnlineDetails => UrlUtils.isValidUrl(_onlineUrlController.text);
  bool get _hasAttendanceDetails => _attendanceDetails?.isNotEmpty ?? false;
  bool get _hasRegistrationDetails => _registrationDetails?.requiresRegistration ?? false;
  bool get _hasWebsiteURL => _websiteController.text.isNotEmpty;
  bool get _hasValidWebsiteURL => UrlUtils.isValidUrl(_websiteController.text);

  DateTime? get _startDateTimeUtc =>
    (_startDate != null) ? Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, _startDate!, _startTime).toUtc() : null;

  DateTime? get _endDateTimeUtc =>
    (_endDate != null) ? Event2TimeRangePanel.dateTimeWithDateAndTimeOfDay(_timeZone, _endDate!, _endTime) : null;

  bool get _private => (_visibility == _Event2Visibility.private);

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
    (!_hasSurvey || _hasAttendanceDetails)
  );

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
      if (result) {
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
        ((_event2VisibilityFromPrivate(widget.event?.private) ?? _Event2Visibility.public) != _visibility) ||
        ((widget.event?.free ?? true) != _free) ||
        ((widget.event?.cost ?? '') != _costController.text) ||

        (widget.event?.registrationDetails != _registrationDetails) ||
        (widget.event?.attendanceDetails != _attendanceDetails) ||
        (widget.event?.surveyDetails != _surveyDetails) ||
        (widget.survey != _survey) ||

        ((widget.event?.sponsor ?? '') != _sponsor) ||
        ((widget.event?.speaker ?? '') != _speaker) ||
        !DeepCollectionEquality().equals(widget.event?.contacts, _contacts);
    }

    if (modified) {
      bool? result = await Event2Popup.showPrompt(context,
        Localization().getStringEx('panel.event2.create.exit.prompt.title', 'Exit'),
        Localization().getStringEx('panel.event2.create.exit.prompt.message', 'Exit and loose your changes?'),
      );
      return (result == true);
    }
    else {
      return true;
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
      published: _published,

      canceled: null, // NA
      userRole: null, // NA

      free: _free,
      cost: Event2CreatePanel.textFieldValue(_costController),

      registrationDetails: (_registrationDetails?.type != Event2RegistrationType.none) ? _registrationDetails : null,
      attendanceDetails: (_attendanceDetails?.isNotEmpty ?? false) ? _attendanceDetails : null,
      surveyDetails: (StringUtils.isNotEmpty(_survey?.id)) ? _surveyDetails : null,

      sponsor: _sponsor,
      speaker: _speaker,
      contacts: _contacts,
    );

  //EventSelector
  @override
  Event2SelectorData? selectorData;

  //Selector
  void _initSelector(){
    widget.eventSelector?.init(this);
  }

  void set _selectorEvent(Event2 event) => selectorData?.event = event;
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

// _ErrorCategory

enum _ErrorCategory { missing, invalid }
