
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

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
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  @override
  void initState() {
    _timeZone = DateTimeUni.timezoneUniOrLocal;
    super.initState();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
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
            _buildDescriptionSection(),
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
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.title.title','EVENT TITLE'), required: true),
    body: _buildTextEditWidget(_titleController, maxLines: null),
  );

  Widget _buildDescriptionSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.description.title','EVENT DESCRIPTION')),
    body: _buildTextEditWidget(_descriptionController, maxLines: null),
  );

  // Date & Time

  /*Widget _buildDateAndTimeSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.date_and_time.title','DATE AND TIME'),
      required: true
    ),
    body: _buildDateAndTimeSectionBody(),
    bodyPadding: EdgeInsets.only(top: 8)
  );*/

  bool _dateTimeSectionExpanded = false;

  Widget _buildDateAndTimeDropdownSection() => _buildDropdownSectionWidget(
    heading: _buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.date_and_time.title','DATE AND TIME'),
      required: true,
      expanded: _dateTimeSectionExpanded,
      onToggleExpanded: _onDateAndTimeSection,
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
      Container(decoration: _dropdownButtonDecoration, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
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
      onTap: _onAllDay,
      border: _toggleBorder,
      borderRadius: _toggleBorderRadius,
    ));

  EdgeInsetsGeometry get _togglePadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  BoxBorder get _toggleBorder => Border.all(color: Styles().colors!.surfaceAccent!, width: 1);
  BorderRadius get _toggleBorderRadius => BorderRadius.all(Radius.circular(4));

  void _onDateAndTimeSection() {
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

  void _onAllDay() {
    Analytics().logSelect(target: "All Day");
    setStateIfMounted(() {
      _allDay = !_allDay;
    });
  }

  // Event Type and Location

  bool _typeAndLocationSectionExpanded = false;

  Widget _buildTypeAndLocationDropdownSection() => _buildDropdownSectionWidget(
    heading: _buildDropdownSectionHeadingWidget(Localization().getStringEx('panel.event2.create.event.section.type_and_location.title', 'EVENT TYPE AND LOCATION'),
      required: true,
      expanded: _typeAndLocationSectionExpanded,
      onToggleExpanded: _onTypeAndLocationSection,
    ),
    body: _buildTypeAndLocationSectionBody(),
    expanded: _typeAndLocationSectionExpanded,
  );

  Widget _buildTypeAndLocationSectionBody() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    _buildEventTypeDropdown(),
    Padding(padding: EdgeInsets.only(bottom: 12)),
    Text('More stuff to come here...', style:
      Styles().textStyles?.getTextStyle("panel.create_event.title.small")
    ),

  ]);

  Widget _buildEventTypeDropdown(){
    return Semantics(container: true, child:
      Row(children: <Widget>[
        Expanded(flex: 3, child:
          Text(Localization().getStringEx("panel.event2.create.event.label.event_type.title", "EVENT TYPE"), style:
            Styles().textStyles?.getTextStyle("panel.create_event.title.small")
          ),
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

  void _onTypeAndLocationSection() {
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

  // Section

  Widget _buildSectionWidget({ required Widget heading, required Widget body, EdgeInsetsGeometry bodyPadding = EdgeInsets.zero }) {
    return Padding(padding: _sectionPadding, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        heading,
        Padding(padding: bodyPadding, child:
          body
        )
        ,
      ],)
    );
  }

  EdgeInsetsGeometry get _sectionPadding => const EdgeInsets.only(bottom: 24);

  Widget _buildSectionHeadingWidget(String title, { bool required = false, String? prefixImageKey, String? suffixImageKey, EdgeInsetsGeometry padding = const EdgeInsets.only(bottom: 8) }) {
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

  Widget _buildSectionTitleWidget(String title) =>
    Text(title, style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"));

  Widget _buildSectionRequiredWidget() => 
    Text('*', style: Styles().textStyles?.getTextStyle("widget.label.small.fat"),);

  Widget _buildDropdownSectionWidget({ required Widget heading, required Widget body, bool expanded = false, EdgeInsetsGeometry bodyPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16) }) {
    return Padding(padding: _sectionPadding, child:
      Container(decoration: _dropdownSectionDecoration, child:
        Column(children: [
          heading,
          Visibility(visible: expanded, child:
            Container(decoration: _dropdownSectionSplitterDecoration, child:
              Padding(padding: bodyPadding, child:
                body,
              ),
            ),
          )
        ],),

      ),
    );
  }

  Widget _buildDropdownSectionHeadingWidget(String title, { bool required = false, bool expanded = false, void Function()? onToggleExpanded, EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 16) }) {
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

  BoxDecoration get _dropdownSectionDecoration => BoxDecoration(
    border: Border.all(color: Styles().colors!.mediumGray2!, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(8))
  );

  BoxDecoration get _dropdownSectionSplitterDecoration => BoxDecoration(
    border: Border(top: BorderSide(color: Styles().colors!.mediumGray2!, width: 1))
  );

  // Text Edit

  Widget _buildTextEditWidget(TextEditingController controller, { int? maxLines = 1}) =>
    TextField(
      controller: controller,
      decoration: _textEditDecoration,
      style: _textEditStyle,
      maxLines: maxLines,
      
    );

  TextStyle? get _textEditStyle =>
    Styles().textStyles?.getTextStyle('widget.input_field.dark.text.regular.thin');

  InputDecoration get _textEditDecoration => InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1),
      borderRadius: BorderRadius.circular(8)
    ),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}

