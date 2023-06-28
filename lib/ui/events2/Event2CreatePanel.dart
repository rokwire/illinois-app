
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/attributes/ContentAttributesPanel.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2CreatePanel extends StatefulWidget {

  @override
  State<StatefulWidget> createState() => _Event2CreatePanelState();
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
  
  bool _free = true;

  Map<String, dynamic>? _attributes;

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
    _timeZone = DateTimeUni.timezoneUniOrLocal;
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
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.create.header.title", "Create an Event"),),
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
    GroupAddImageWidget.show(context: context, updateUrl: _imageUrl).then((String? updateUrl) {
      if (mounted && (updateUrl != null) && (0 < updateUrl.length) && (_imageUrl != updateUrl)) {
        setState(() {
          _imageUrl = updateUrl;
        });
      }
    });

  }

  // Title and Description

  Widget _buildTitleSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.title.title', 'EVENT TITLE'), required: true),
    body: _buildTextEditWidget(_titleController, keyboardType: TextInputType.text, maxLines: null),
  );

  Widget _buildDescriptionSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.description.title', 'EVENT DESCRIPTION')),
    body: _buildTextEditWidget(_descriptionController, keyboardType: TextInputType.text, maxLines: null),
  );

  Widget _buildWebsiteSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.website.title', 'ADD EVENT WEBSITE LINK'), suffixImageKey: 'external-link'),
    body: _buildTextEditWidget(_websiteController, keyboardType: TextInputType.url),
    trailing: _buildConfirmUrlLink(onTap: (_onConfirmWebsiteLink)),
    padding: const EdgeInsets.only(bottom: 8), // Link button tapable area
  );

  void _onConfirmWebsiteLink() => _confirmLinkUrl(_websiteController, analyticsTarget: 'Confirm Website URL');

  // Date & Time

  /*Widget _buildDateAndTimeSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.date_and_time.title', 'DATE AND TIME'),
      required: true
    ),
    body: _buildDateAndTimeSectionBody(),
    bodyPadding: EdgeInsets.only(top: 8)
  );*/

  Widget _buildDateAndTimeDropdownSection() => _buildDropdownSectionWidget(
    heading: _buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.date_and_time.title', 'DATE AND TIME'),
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
      hasTime: !_allDay,
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
      hasTime: !_allDay,
      semanticsDateLabel: Localization().getStringEx("panel.create_event.date_time.end_date.title", "END DATE"),
      semanticsTimeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title",'END TIME'),
      dateLabel: Localization().getStringEx("panel.create_event.date_time.end_date.title", "END DATE"),
      timeLabel: Localization().getStringEx("panel.create_event.date_time.end_time.title","END TIME"),
    ),
    
    Padding(padding: EdgeInsets.only(bottom: 12)),

    _buildAllDayToggle(),

  ]);

  
  Widget _buildTimeZoneDropdown(){
    return Semantics(container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 3, child:
          Text(Localization().getStringEx("panel.create_event.date_time.time_zone.title", "TIME ZONE"), style:
            Styles().textStyles?.getTextStyle("panel.create_event.title.small")
          ),
        ),
        Container(width: 16,),
        Expanded(flex: 7, child:
          Container(decoration: _dropdownButtonDecoration, child:
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
                Text(dateLabel ?? '', style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"), ),
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
                  Text(timeLabel ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")),
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
      Container(decoration: _dropdownButtonDecoration, padding: _dropdownButtonContentPadding, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
          Text(label ??  '-', style: Styles().textStyles?.getTextStyle("widget.title.regular"),),
          Styles().images?.getImage('chevron-down') ?? Container()
        ],),
      ),
    );
  }

  BoxDecoration get _dropdownButtonDecoration => BoxDecoration(
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(4))
  );

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
    setStateIfMounted(() {
      _dateTimeSectionExpanded = !_dateTimeSectionExpanded;
    });
  }

  void _onStartDate() {
    Analytics().logSelect(target: "Start Date");
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
        });
      }
    });
  }

  void _onStartTime() {
    Analytics().logSelect(target: "Start Time");
    showTimePicker(context: context, initialTime: _startTime ?? TimeOfDay.fromDateTime(DateTime.now())).then((TimeOfDay? result) {
      if ((result != null) && mounted) {
        setState(() {
          _startTime = result;
        });
      }
    });
  }

  void _onEndDate() {
    Analytics().logSelect(target: "End Date");
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
    showTimePicker(context: context, initialTime: _endTime ?? TimeOfDay.fromDateTime(TZDateTime.now(_timeZone))).then((TimeOfDay? result) {
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
    setStateIfMounted(() {
      _allDay = !_allDay;
    });
  }

  // Event Type, Location and Online Details

  Widget _buildTypeAndLocationDropdownSection() => _buildDropdownSectionWidget(
    heading: _buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.type_and_location.title', 'EVENT TYPE AND LOCATION'),
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
        Padding(padding: _innerSectionPadding),
        _buildLocationBuildingInnerSection(),
        _buildLocationAddressInnerSection(),
        _buildLocationLatitudeInnerSection(),
        _buildLocationLongitudeInnerSection(),
        _buildSelectLocationButton()
      ]);
    }

    if ((_eventType == Event2Type.online) || (_eventType == Event2Type.hybrid)) {
      contentList.addAll(<Widget>[
        Padding(padding: _innerSectionPadding),
        _buildOnlineUrlInnerSection(),
        _buildOnlineMeetingIdInnerSection(),
        _buildOnlinePasscodeInnerSection(),
      ]);
    }

    /* contentList.add(Padding(padding: EdgeInsets.only(bottom: 12), child:
      Text('More stuff to come here...', style:
        Styles().textStyles?.getTextStyle("panel.create_event.title.small")
      ),
    ),); */

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget _buildEventTypeDropdown(){
    return Semantics(container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 3, child:
          RichText(text:
            TextSpan(text: Localization().getStringEx("panel.event2.create.event.label.event_type.title", "EVENT TYPE"), style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"), children: <InlineSpan>[
              TextSpan(text: ' *', style: Styles().textStyles?.getTextStyle('widget.label.small.fat'),),
            ])
          )
        ),
        Container(width: 16,),
        Expanded(flex: 7, child:
          Container(decoration: _dropdownButtonDecoration, child:
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
    setStateIfMounted(() {
      _typeAndLocationSectionExpanded = !_typeAndLocationSectionExpanded;
    });
  }

  void _onEventTypeChanged(Event2Type? value) {
    Analytics().logSelect(target: "Time Zone selected: $value");
    if ((value != null) && mounted) {
      setState(() {
        _eventType = value;
      });
    }
  }

  Widget _buildLocationBuildingInnerSection() => _buildInnerSectionWidget(
    heading: _buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.location.building.title', 'LOCATION BUILDING')),
    body: _buildInnerTextEditWidget(_locationBuildingController, keyboardType: TextInputType.text),
  );

  Widget _buildLocationAddressInnerSection() => _buildInnerSectionWidget(
    heading: _buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.location.address.title', 'LOCATION ADDRESS')),
    body: _buildInnerTextEditWidget(_locationAddressController, keyboardType: TextInputType.text),
  );

  Widget _buildLocationLatitudeInnerSection() => _buildInnerSectionWidget(
    heading: _buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.location.latitude.title', 'LOCATION LATITUDE'), required: true),
    body: _buildInnerTextEditWidget(_locationLatitudeController, keyboardType: TextInputType.number),
  );

  Widget _buildLocationLongitudeInnerSection() => _buildInnerSectionWidget(
    heading: _buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.location.longitude.title', 'LOCATION LONGITUDE'), required: true),
    body: _buildInnerTextEditWidget(_locationLongitudeController, keyboardType: TextInputType.number),
  );

  Widget _buildSelectLocationButton() {
    String buttonTitle = Localization().getStringEx("panel.event2.create.event.location.button.select.title", "Select Location on a Map");
    String buttonHint = Localization().getStringEx("panel.event2.create.event.location.button.select.hint", "");

    return Padding(padding: _innerSectionPadding, child:
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

  Widget _buildOnlineUrlInnerSection() => _buildInnerSectionWidget(
    heading: _buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.online_details.url.title', 'ONLINE URL'), required: true),
    body: _buildInnerTextEditWidget(_onlineUrlController, keyboardType: TextInputType.url),
  );

  Widget _buildOnlineMeetingIdInnerSection() => _buildInnerSectionWidget(
    heading: _buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.online_details.meeting_id.title', 'MEETING ID')),
    body: _buildInnerTextEditWidget(_onlineMeetingIdController, keyboardType: TextInputType.text),
  );

  Widget _buildOnlinePasscodeInnerSection() => _buildInnerSectionWidget(
    heading: _buildInnerSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.online_details.passcode.title', 'PASSCODE')),
    body: _buildInnerTextEditWidget(_onlinePasscodeController, keyboardType: TextInputType.text),
  );

  void _onTapSelectLocation() {
    Analytics().logSelect(target: "Select Location");
    AppAlert.showDialogResult(context, 'TBD');
  }

  // Cost

  Widget _buildCostDropdownSection() => _buildDropdownSectionWidget(
    heading: _buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.cost.title', 'COST'),
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
        Padding(padding: _innerSectionPadding),
        _buildCostInnerSection(),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList);
  }

  Widget _buildFreeToggle() => Semantics(toggled: _free, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.create.event.free.toggle.title", "Is this event free?"),
    hint: Localization().getStringEx("panel.event2.create.event.free.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.create.event.free.toggle.title", "Is this event free?"),
      padding: _togglePadding,
      toggled: _free,
      onTap: _onTapFree,
      border: _toggleBorder,
      borderRadius: _toggleBorderRadius,
    ));

  Widget _buildCostInnerSection() => _buildInnerSectionWidget(
    heading: _buildCostInnerSectionHeadingWidget(),
    body: _buildInnerTextEditWidget(_costController, keyboardType: TextInputType.text),
  );

  Widget _buildCostInnerSectionHeadingWidget() {
    String title = Localization().getStringEx('panel.event2.create.event.label.cost.title', 'COST DESCRIPTION');
    String description = Localization().getStringEx('panel.event2.create.event.label.cost.description', ' (eg: \$10, Donation suggested)');
    String semanticsLabel = title + description;

    return Padding(padding: _innerSectionHeadingPadding, child:
      Semantics(label: semanticsLabel, header: true, excludeSemantics: true, child:
        Row(children: [
          Expanded(child:
            RichText(text:
              TextSpan(text: title, style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"), children: <InlineSpan>[
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
    setStateIfMounted(() {
      _costSectionExpanded = !_costSectionExpanded;
    });
  }

  void _onTapFree() {
    Analytics().logSelect(target: "Toggle Free");
    setStateIfMounted(() {
      _free = !_free;
    });
  }


  // Attributes

  Widget _buildAttributesButtonSection() => _buildButtonSectionWidget(
    heading: _buildButtonSectionHeadingWidget(
      title: Localization().getStringEx('panel.event2.create.event.button.attributes.title', 'EVENT ATTRIBUTES'),
      subTitle: (_attributes?.isEmpty ?? true) ? Localization().getStringEx('panel.event2.create.event.button.attributes.description', 'Choose attributes related to your event.') : null,
      required: true,
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
        });
      }
    });
  }


  // Sections

  static const EdgeInsetsGeometry _sectionPadding = const EdgeInsets.only(bottom: 24);
  static const EdgeInsetsGeometry _innerSectionPadding = const EdgeInsets.only(bottom: 12);

  static const EdgeInsetsGeometry _sectionHeadingPadding = const EdgeInsets.only(bottom: 8);
  static const EdgeInsetsGeometry _innerSectionHeadingPadding = const EdgeInsets.only(bottom: 4);

  static const EdgeInsetsGeometry _sectionHeadingContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  static const EdgeInsetsGeometry _sectionBodyContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsetsGeometry _dropdownButtonContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  static const EdgeInsetsGeometry _textEditContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20);
  static const EdgeInsetsGeometry _innerTextEditContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16);

  BoxDecoration get _sectionDecoration => BoxDecoration(
    border: Border.all(color: Styles().colors!.mediumGray2!, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8))
  );

  BoxDecoration get _sectionSplitterDecoration => BoxDecoration(
    border: Border(top: BorderSide(color: Styles().colors!.mediumGray2!, width: 1))
  );

  // Sections / Regular Section
  
  Widget _buildSectionWidget({
    Widget? heading, Widget? body, Widget? trailing,
    EdgeInsetsGeometry padding = _sectionPadding,
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

  Widget _buildInnerSectionWidget({ required Widget heading, required Widget body,
    EdgeInsetsGeometry padding = _innerSectionPadding,
    EdgeInsetsGeometry bodyPadding = EdgeInsets.zero
  }) => _buildSectionWidget(heading: heading, body: body, padding: padding, bodyPadding: bodyPadding);

  Widget _buildSectionHeadingWidget(String title, { bool required = false, String? prefixImageKey, String? suffixImageKey, EdgeInsetsGeometry padding = _sectionHeadingPadding }) {
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

    contentList.add(_buildSectionTitleWidget(title));
    
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

  Widget _buildInnerSectionHeadingWidget(String title, { bool required = false, String? prefixImageKey, String? suffixImageKey, EdgeInsetsGeometry padding = _innerSectionHeadingPadding }) =>
    _buildSectionHeadingWidget(title, required: required, prefixImageKey: prefixImageKey, suffixImageKey: suffixImageKey, padding : padding);

  Widget _buildSectionTitleWidget(String title) =>
    Text(title, style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"));

  Widget _buildSectionSubTitleWidget(String subTitle) =>
    Text(subTitle, style: Styles().textStyles?.getTextStyle("widget.card.detail.small.regular"));

  Widget _buildSectionRequiredWidget() => 
    Text('*', style: Styles().textStyles?.getTextStyle("widget.label.small.fat"),);

  // Sections / Dropdown Section

  Widget _buildDropdownSectionWidget({ required Widget heading, required Widget body, bool expanded = false,
    EdgeInsetsGeometry padding = _sectionPadding,
    EdgeInsetsGeometry bodyPadding = _sectionBodyContentPadding
  }) {
    return Padding(padding: padding, child:
      Container(decoration: _sectionDecoration, child:
        Column(children: [
          heading,
          Visibility(visible: expanded, child:
            Container(decoration: _sectionSplitterDecoration, child:
              Padding(padding: bodyPadding, child:
                body,
              ),
            ),
          )
        ],),

      ),
    );
  }

  Widget _buildDropdownSectionHeadingWidget(String title, {
    bool required = false,
    bool expanded = false,
    void Function()? onToggleExpanded,
    EdgeInsetsGeometry padding = _sectionHeadingContentPadding
  }) {
    List<Widget> wrapList = <Widget>[
      _buildSectionTitleWidget(title),
    ];

    if (required) {
      wrapList.add(Padding(padding: EdgeInsets.only(left: 2), child:
        _buildSectionRequiredWidget(), 
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

  Widget _buildButtonSectionWidget({ required Widget heading, Widget? body,
    EdgeInsetsGeometry padding = _sectionPadding,
    EdgeInsetsGeometry bodyPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
  }) {
    List<Widget> contentList = <Widget>[
      heading
    ];
    if (body != null) {
      contentList.add(Container(decoration: _sectionSplitterDecoration, child:
        Padding(padding: bodyPadding, child:
          body,
        ),
      ),);
    }
    return Padding(padding: padding, child:
      Container(decoration: _sectionDecoration, child:
        Column(children: contentList,),
      ),
    );
  }

  Widget _buildButtonSectionHeadingWidget({String? title, String? subTitle, bool required = false, void Function()? onTap, EdgeInsetsGeometry? padding }) {

    List<Widget> wrapList = <Widget>[];

    if (title != null) {
      wrapList.add(_buildSectionTitleWidget(title));
    }

    if (required) {
      wrapList.add(Padding(padding: EdgeInsets.only(left: 2), child:
        _buildSectionRequiredWidget(), 
      ));
    }

    Widget leftWidget = (subTitle != null) ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Wrap(children: wrapList),
      Padding(padding: EdgeInsets.only(top: 2), child:
        _buildSectionSubTitleWidget(subTitle),
      )
    ],) : Wrap(children: wrapList);

    EdgeInsetsGeometry appliedPadding = padding ?? ((subTitle != null) ?
      const EdgeInsets.symmetric(horizontal: 16, vertical: 11) :
      _sectionHeadingContentPadding
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

  Widget _buildTextEditWidget(TextEditingController controller, {
    TextInputType? keyboardType, int? maxLines = 1, EdgeInsetsGeometry padding = _textEditContentPadding
  }) =>
    TextField(
      controller: controller,
      decoration: _textEditDecoration(padding: padding),
      style: _textEditStyle,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );

  Widget _buildInnerTextEditWidget(TextEditingController controller, {
    TextInputType? keyboardType, int? maxLines = 1, EdgeInsetsGeometry padding = _innerTextEditContentPadding
  }) =>
    _buildTextEditWidget(controller, keyboardType: keyboardType, maxLines: maxLines, padding: padding);

  TextStyle? get _textEditStyle =>
    Styles().textStyles?.getTextStyle('widget.input_field.dark.text.regular.thin');

  InputDecoration _textEditDecoration({EdgeInsetsGeometry? padding}) => InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1),
      borderRadius: BorderRadius.circular(8)
    ),
    contentPadding: padding,
  );

  // Confirm URL

  Widget _buildConfirmUrlLink({
    void Function()? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.only(top: 8, bottom: 16, left: 12)
  }) {
    return Align(alignment: Alignment.centerRight, child:
      LinkButton(
        title: Localization().getStringEx('panel.event2.create.event.button.confirm_url.title', 'Confirm URL'),
        hint: Localization().getStringEx('panel.event2.create.event.button.confirm_url.hint', ''),
        onTap: onTap,
        padding: padding,
      )
    );
  }

  void _confirmLinkUrl(TextEditingController controller, { String? analyticsTarget }) {
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
}

