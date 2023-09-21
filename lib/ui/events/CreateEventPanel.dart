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


import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/model/event.dart';
import 'package:rokwire_plugin/model/explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:illinois/ui/explore/ExploreEventDetailPanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as timezone;
import 'package:rokwire_plugin/service/config.dart';


class CreateEventPanel extends StatefulWidget {
  final Event? editEvent;
  final Function? onEditTap;
  final Group? group;

  const CreateEventPanel({Key? key, this.editEvent, this.onEditTap, this.group}) : super(key: key);

  @override
  _CreateEventPanelState createState() => _CreateEventPanelState();
}

class _CreateEventPanelState extends State<CreateEventPanel> {
  static const String defaultEventTimeZone = "US/Central";
  static const String eventPrivacyPublic = "PUBLIC";
  static const String eventPrivacyPrivate = "PRIVATE";
  final List<dynamic> _eventTimeZones = ["US/Pacific", "US/Mountain", "US/Central", "US/Eastern"];
  final List<dynamic> _privacyTypes = [eventPrivacyPublic, eventPrivacyPrivate];

  final double _imageHeight = 208;

  List<dynamic>? _eventCategories;

  dynamic _selectedCategory;
  String? _selectedTimeZone = defaultEventTimeZone;
  String? _imageUrl;
  timezone.TZDateTime? _startDate;
  timezone.TZDateTime? _endDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _allDay = false;
  ExploreLocation? _location;
  bool _isOnline = false;
  bool _isInPerson = false;
  bool _isFree = false;
  String? _selectedPrivacy = eventPrivacyPublic;
  //TMP: bool _isAttendanceRequired = false;

  bool _loading = false;
  bool _modified = false;

  //Groups
  List<Member>? _groupMembersSelection;

  final _eventTitleController = TextEditingController();
  final _eventDescriptionController = TextEditingController();
  final _eventPurchaseUrlController = TextEditingController();
  final _eventWebsiteController = TextEditingController();
  final _eventLocationController = TextEditingController();
  final _eventLatitudeController = TextEditingController();
  final _eventLongitudeController = TextEditingController();
  final _eventVirtualUrlController = TextEditingController();
  final _eventPriceController = TextEditingController();

  @override
  void initState() {
    _populateDefaultValues();
    _loadEventCategories();
    _prepopulateWithUpdateEvent();
    _initGroupValues();
    super.initState();
  }

  @override
  void dispose() {
    _eventTitleController.dispose();
    _eventDescriptionController.dispose();
    _eventPurchaseUrlController.dispose();
    _eventWebsiteController.dispose();
    _eventLocationController.dispose();
    _eventLatitudeController.dispose();
    _eventLongitudeController.dispose();
    _eventPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(
          title: _panelTitleText,
          onLeading: _onTapBack,
        ),
        body: _buildContent(),
        backgroundColor: Styles().colors!.background,
        bottomNavigationBar: uiuc.TabBar(),
    );
}

  Widget _buildContent() {
    bool isEdit = widget.editEvent!=null;
    bool isValid = _isFormValid();
    return Stack(children: <Widget>[
          Container(
            color: Colors.white,
            child: _loading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        Semantics(label:_panelTitleText,
                        hint: Localization().getStringEx("panel.create_event.hint", ""), header: true, excludeSemantics: true, child:
                          Container(
                            color: Styles().colors!.fillColorPrimaryVariant,
                            height: 56,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: <Widget>[
                                  Styles().images?.getImage('plus-circle') ?? Container(),
                                  Padding(
                                    padding: EdgeInsets.only(left: 12),
                                    child: Text(_panelTitleText!,
                                      style: Styles().textStyles?.getTextStyle("widget.heading.large.extra_fat")
                                    ),
                                  )
                                ],
                              ),
                            ),
                          )
                        ),
                        Container(
                          height: 200,
                          color: Styles().colors!.background,
                          child: Stack(
                            alignment: Alignment.bottomCenter,
                            children: <Widget>[
                              StringUtils.isNotEmpty(_imageUrl)
                                  ? Positioned.fill(child: Image.network(_imageUrl!, excludeFromSemantics: true, fit: BoxFit.cover, headers: Config().networkAuthHeaders))
                                  : Container(),
                              CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.fillColorSecondaryTransparent05, horzDir: TriangleHorzDirection.leftToRight), child: Container(height: 53)),
                              CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.white), child: Container(height: 30)),
                              Container(
                                height: _imageHeight,
                                child: Center(
                                  child:
                                  Semantics(label: _imageUrl != null ? Localization().getStringEx("panel.create_event.modify_image", "Modify event image") : Localization().getStringEx("panel.create_event.add_image","Add event image"),
                                    hint: _imageUrl != null ? Localization().getStringEx("panel.create_event.modify_image.hint","") : Localization().getStringEx("panel.create_event.add_image.hint",""), button: true, excludeSemantics: true, child:
                                    RoundedButton(
                                      label: _imageUrl != null ? Localization().getStringEx("panel.create_event.modify_image", "Modify event image") : Localization().getStringEx("panel.create_event.add_image","Add event image"),
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
                        ),
                        _buildCategorySection(),
                        _buildTitleSection(),
                        _buildDescriptionSection(),
                        Container(), //TMP: _isGroupEvent? _buildAttendanceSwitch() : Container(),
                        Padding(
                            padding: EdgeInsets.only(left:16, right:16),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child:
                                    Semantics(label:Localization().getStringEx("panel.create_event.date_time.title","Date and time"),
                                      hint: Localization().getStringEx("panel.create_event.date_time.hint",""), header: true, excludeSemantics: true, child:
                                      Row(
                                        children: <Widget>[
                                          Styles().images?.getImage('calendar') ?? Container(),
                                          Padding(
                                            padding: EdgeInsets.only(left: 3),
                                            child: Text(
                                              Localization().getStringEx("panel.create_event.date_time.title","Date and time"),
                                              style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"),
                                            ),
                                          )
                                        ],
                                      ),
                                    )
                                  ),
                                  _buildTimeZoneDropdown(),
                                  Container(height: 8,),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                       Expanded(
                                         flex:2,
                                         child: Semantics(label:Localization().getStringEx("panel.create_event.date_time.start_date.title","START DATE"),
                                             hint: Localization().getStringEx("panel.create_event.date_time.start_date.hint","required"), button: true, excludeSemantics: true, child:
                                             Column(
                                               crossAxisAlignment:
                                               CrossAxisAlignment.start,
                                               children: <Widget>[
                                                 Padding(
                                                   padding:
                                                   EdgeInsets.only(bottom: 8),
                                                   child:
                                                   Row(
                                                     children: <Widget>[
                                                       Text(
                                                         Localization().getStringEx("panel.create_event.date_time.start_date.title","START DATE"),
                                                         style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"),
                                                       ),
                                                       Padding(
                                                         padding: EdgeInsets.only(
                                                             left: 2),
                                                         child: Text(
                                                           '*',
                                                           style: Styles().textStyles?.getTextStyle("widget.label.small.fat")
                                                         ),
                                                       )
                                                     ],
                                                   ),
                                                 ),
                                                 _EventDateDisplayView(
                                                   label: _startDate != null
                                                       ? AppDateTime()
                                                       .formatDateTime(
                                                       _startDate,
                                                       format: "EEE, MMM dd, yyyy")
                                                       : "-",
                                                   onTap: _onTapStartDate,
                                                 )
                                               ],
                                             )
                                         ),
                                       ),
                                    Visibility(visible: !_allDay, child: Container(width: 10)),
                                    Visibility(visible: !_allDay, child: Expanded(
                                      flex: 1,
                                      child: Semantics(label:Localization().getStringEx("panel.create_event.date_time.start_time.title",'START TIME'),
                                          hint: Localization().getStringEx("panel.create_event.date_time.start_time.hint","required"), button: true, excludeSemantics: true, child:
                                          Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: <Widget>[
                                              Padding(
                                                padding:
                                                EdgeInsets.only(bottom: 8),
                                                child:
                                                Row(
                                                  children: <Widget>[
                                                    Text(
                                                      Localization().getStringEx("panel.create_event.date_time.start_time.title","START TIME"),
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                                                    ),
                                                    Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 2),
                                                      child: Text(
                                                        '*',
                                                        style: Styles().textStyles?.getTextStyle("widget.label.small.fat"),
                                                      ),
                                                    )
                                                  ],
                                                ),
                                              ),
                                              _EventDateDisplayView(
                                                label: _startTime != null &&
                                                    !_allDay
                                                    ? DateFormat("h:mma").format(
                                                    _populateDateTimeWithTimeOfDay(
                                                        _startDate,
                                                        _startTime) ??
                                                        _populateDateTimeWithTimeOfDay(
                                                            timezone.TZDateTime.now(timezone.getLocation(_selectedTimeZone!)),
                                                            _startTime)!)
                                                    : "-",
                                                onTap: _onTapStartTime,
                                              )
                                            ],
                                          )
                                      ),
                                    )),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.only(bottom: 16),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        Expanded(
                                          flex: 2,
                                          child: Semantics(label:Localization().getStringEx("panel.create_event.date_time.end_date.title",'END DATE'),
                                              hint: Localization().getStringEx("panel.create_event.date_time.end_date.hint","required"), button: true, excludeSemantics: true, child:
                                              Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: <Widget>[
                                                  Padding(
                                                    padding:
                                                    EdgeInsets.only(bottom: 8),
                                                    child:
                                                    Row(
                                                      children: <Widget>[
                                                        Text(
                                                          Localization().getStringEx("panel.create_event.date_time.end_date.title",'END DATE'),
                                                          style: Styles().textStyles?.getTextStyle("panel.create_event.title.small"),
                                                        ),
                                                        Padding(
                                                          padding: EdgeInsets.only(left: 2),
                                                          child: Text(
                                                            '*',
                                                            style: Styles().textStyles?.getTextStyle("widget.label.small.fat")
                                                          ),
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                  _EventDateDisplayView(
                                                    label: _endDate != null
                                                        ? AppDateTime()
                                                        .formatDateTime(
                                                        _endDate,
                                                        format: "EEE, MMM dd, yyyy")
                                                        : "-",
                                                    onTap: _onTapEndDate,
                                                  )
                                                ],
                                              )
                                          ),
                                        ),
                                        Visibility(visible: !_allDay, child: Container(width: 10)),
                                        Visibility(visible: !_allDay, child: Expanded(
                                            flex: 1,
                                            child: Semantics(label:Localization().getStringEx("panel.create_event.date_time.end_time.title",'END TIME'),
                                                hint: Localization().getStringEx("panel.create_event.date_time.end_time.hint","required"), button: true, excludeSemantics: true, child:
                                                Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: <Widget>[
                                                    Padding(
                                                      padding:
                                                      EdgeInsets.only(bottom: 8),
                                                      child:
                                                      Row(
                                                        children: <Widget>[
                                                          Text(
                                                            Localization().getStringEx("panel.create_event.date_time.end_time.title","END TIME"),
                                                            maxLines: 1,
                                                            overflow: TextOverflow.ellipsis,
                                                            style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                                                          ),
                                                          Padding(
                                                            padding: EdgeInsets.only(
                                                                left: 2),
                                                            child: Text(
                                                              '*',
                                                              style: Styles().textStyles?.getTextStyle("widget.label.small.fat")
                                                            ),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    _EventDateDisplayView(
                                                      label: _endTime != null && !_allDay
                                                          ? DateFormat("h:mma").format(
                                                          _populateDateTimeWithTimeOfDay(
                                                              _endDate,
                                                              _endTime) ??
                                                              (_populateDateTimeWithTimeOfDay(
                                                                  _startDate,
                                                                  _endTime) ??
                                                                  _populateDateTimeWithTimeOfDay(
                                                                      timezone.TZDateTime.now(timezone.getLocation(_selectedTimeZone!)),
                                                                      _endTime)!))
                                                          : "-",
                                                      onTap: _onTapEndTime,
                                                    )
                                                  ],
                                                )
                                            )
                                        )),
                                      ],
                                    ),
                                  ),
                                  Semantics(label:Localization().getStringEx("panel.create_event.date_time.all_day","All day"),
                                      hint: Localization().getStringEx("panel.create_event.date_time.all_day.hint",""), toggled: _allDay, excludeSemantics: true, child:
                                  ToggleRibbonButton(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                    label: Localization().getStringEx("panel.create_event.date_time.all_day","All day"),
                                    toggled: _allDay,
                                    onTap: _onAllDayToggled,
                                    borderRadius:
                                        BorderRadius.all(Radius.circular(4)),
                                    border: Border.all(color: Styles().colors!.fillColorPrimary!),
                                  )),
                                  Container(height: 8,),
                                  Semantics(label:Localization().getStringEx("panel.create_event.date_time.online","Make this an online event"),
                                      hint: Localization().getStringEx("panel.create_event.date_time.all_day.hint",""), toggled: _isOnline, excludeSemantics: true, child:
                                      ToggleRibbonButton(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        label: Localization().getStringEx("panel.create_event.date_time.online","Make this an online event"),
                                        toggled: _isOnline,
                                        onTap: _onOnlineToggled,
                                        border: Border.all(color: Styles().colors!.fillColorPrimary!),
                                        borderRadius: BorderRadius.all(Radius.circular(4)),
                                      )),
                                  Container(height: 8,),
                                  Semantics(label:Localization().getStringEx("panel.create_event.date_time.in_person","Make this an in-person event"),
                                      hint: Localization().getStringEx("panel.create_event.date_time.all_day.hint",""), toggled: _isInPerson, excludeSemantics: true, child:
                                      ToggleRibbonButton(
                                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        label: Localization().getStringEx("panel.create_event.date_time.in_person","Make this an in-person event"),
                                        toggled: _isInPerson,
                                        onTap: _onInPersonToggled,
                                        border: Border.all(color: Styles().colors!.fillColorPrimary!),
                                        borderRadius: BorderRadius.all(Radius.circular(4)),
                                      ))
                                ])),
                        Container(height: 6,),
                        _buildLocationSection(),
                        _buildPriceSection(),
                        _buildPrivacyDropdown(),
                        Container(
                          color: Styles().colors!.background,
                          child: Padding(
                            padding: EdgeInsets.only(
                                left: 16, right: 16, top: 2, bottom: 2),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
//                                Semantics(label:Localization().getStringEx("panel.create_event.additional_info.title","Additional event information"),
//                                    header: true, excludeSemantics: true, child:
//                                    Padding(
//                                      padding: EdgeInsets.only(bottom: 24),
//                                      child: Row(
//                                        children: <Widget>[
//                                          Image.asset(
//                                              'images/icon-campus-tools.png'),
//                                          Expanded(child:
//                                            Padding(
//                                              padding: EdgeInsets.only(left: 3),
//                                              child: Text(
//                                                Localization().getStringEx("panel.create_event.additional_info.title","Additional event information"),
//                                                style: TextStyle(
//                                                    color: Styles().colors.fillColorPrimary,
//                                                    fontSize: 16,
//                                                    fontFamily: Styles().fontFamilies.bold),
//                                              ),
//                                            )
//                                          )
//                                        ],
//                                      ),
//                                    )
//                                ),
                                  Container(
                                    padding: EdgeInsets.only(top: 0),
                                    child: Text(
                                      _isPrivateEvent?
                                      Localization().getStringEx("panel.create_event.additional_info.group.description.private","This event will only show up on your group's page."):
                                      Localization().getStringEx("panel.create_event.additional_info.group.description.public","This event will show up on your group's page and also on the event's page."),
                                      style: Styles().textStyles?.getTextStyle("widget.info.regular.thin")
                                    ),
                                  ),
                                Container(height: 8,),
                                Visibility(
                                  visible: widget.group!=null,
                                  child: Container(height: 10,)),
                                Visibility(
                                  visible: widget.group!=null,
                                  child: Text(
                                    "Please select the group members who can also see this event",
                                    style: Styles().textStyles?.getTextStyle("widget.info.regular.thin")),
                                ),
                                Visibility(
                                    visible: widget.group!=null,
                                    child: Container(height: 6,)),
                                Visibility(
                                  visible: widget.group!=null,
                                  child: GroupMembersSelectionWidget(
                                    selectedMembers: _groupMembersSelection,
                                    groupId: widget.group?.id,
                                    groupPrivacy: widget.group?.privacy,
                                    onSelectionChanged: (members){
                                      setState(() {
                                        _groupMembersSelection = members;
                                      });
                                    },),)

                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              (widget.group!=null)? Container():
                              Expanded(
                                  child: RoundedButton(
                                    label:  Localization().getStringEx("panel.create_event.additional_info.button.cancel.title","Cancel"),
                                    textStyle: Styles().textStyles?.getTextStyle("widget.button.title.large.fat"),
                                    backgroundColor: Colors.white,
                                    borderColor: Styles().colors!.fillColorPrimary,
                                    onTap: _onTapCancel,
                                  )),
                              (widget.group!=null)? Container():
                              Container(
                                width: 6,
                              ),
                              (widget.group!=null)? Container():
                              Expanded(
                                  child: RoundedButton(
                                label: isEdit?  Localization().getStringEx("panel.create_event.additional_info.button.edint.title","Update Event"):
                                                Localization().getStringEx("panel.create_event.additional_info.button.preview.title","Preview"),
                                textStyle: isValid ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat"),
                                backgroundColor: Colors.white,
                                borderColor: isValid ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                                onTap: isEdit? _onTapUpdate : _onTapPreview,
                              )),
                              (widget.group==null)? Container():
                              Expanded(
                                  child: RoundedButton(
                                    label: isEdit?  Localization().getStringEx("panel.create_event.additional_info.button.edint.title","Update Event"):
                                    Localization().getStringEx("panel.create_event.additional_info.button.create.title","Create event"),
                                    textStyle: isValid ? Styles().textStyles?.getTextStyle("widget.button.title.large.fat") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.large.fat"),
                                    backgroundColor: Colors.white,
                                    borderColor: isValid ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
                                    onTap: isEdit? _onTapUpdate : _onTapCreate,
                                  ))
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
          ),
        ]);
  }

  Widget _buildCategorySection(){
    return
      Padding(
        padding: EdgeInsets.only(
            left: 16, right: 24, top: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Semantics(label:Localization().getStringEx("panel.create_event.category.title","EVENT CATEGORY") + ", required",
                hint: Localization().getStringEx("panel.create_event.category.title.hint","Choose the category your event may be filtered by."), header: true, excludeSemantics: true, child:
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(
                            Localization().getStringEx("panel.create_event.category.title","EVENT CATEGORY"),
                            style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Text(
                              '*',
                              style: Styles().textStyles?.getTextStyle("widget.label.small.fat")
                            ),
                          )
                        ],
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 2, bottom: 8),
                        child: Text(
                          Localization().getStringEx("panel.create_event.category.description",'Choose the category your event may be filtered by.'),
                          maxLines: 2,
                          style: Styles().textStyles?.getTextStyle("widget.item.small.thin")
                        ),
                      ),
                    ])),
            Padding(
              padding: EdgeInsets.only(bottom: 24),
              child: Container(
                decoration: BoxDecoration(
                    border: Border.all(
                        color: Styles().colors!.surfaceAccent!,
                        width: 1),
                    borderRadius:
                    BorderRadius.all(Radius.circular(4))),
                child: Padding(
                  padding:
                  EdgeInsets.only(left: 12, right: 8),
                  child: DropdownButtonHideUnderline(
                      child: DropdownButton(
                          icon: Styles().images?.getImage('chevron-down'),
                          isExpanded: true,
                          style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                          hint: Text(
                            (_selectedCategory != null)
                                ? _selectedCategory[
                            'category']
                                : Localization().getStringEx("panel.create_event.category.default","Category"),
                          ),
                          items: _buildCategoryDropDownItems(),
                          onChanged:
                          _onCategoryDropDownValueChanged)),
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildTitleSection(){
    return Padding(
      padding: EdgeInsets.only(left: 16, right: 16, bottom: 24),
      child:Column(
        children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child:
                    Semantics(label:Localization().getStringEx("panel.create_event.title.title","EVENT TITLE") + ", required",
                      hint: Localization().getStringEx("panel.create_event.title.title.hint",""), header: true, excludeSemantics: true, child:
                      Row(
                        children: <Widget>[
                          Text(
                            Localization().getStringEx("panel.create_event.title.title","EVENT TITLE"),
                            style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 2),
                            child: Text(
                              '*',
                              style: Styles().textStyles?.getTextStyle("widget.label.small.fat"),
                            ),
                          )
                        ],
                      ),
                    )
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Styles().colors!.fillColorPrimary!,
                          width: 1)),
                  constraints: BoxConstraints(
                    minHeight: 90,
                    maxHeight: 150,
                  ),
                  // height: 90,
                  child:
                  Semantics(label:Localization().getStringEx("panel.create_event.title.field","EVENT TITLE FIELD"),
                      hint: Localization().getStringEx("panel.create_event.title.title.hint",""), textField: true, excludeSemantics: true, child:
                      TextField(
                        controller: _eventTitleController,
                        onChanged: _onTextChanged,
                        decoration: InputDecoration(border: InputBorder.none),
                        maxLines: null,
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.large")
                      )
                  ),
                )
              ],
            ),
        ],
      )
    );
  }

  Widget _buildDescriptionSection(){
    return
        Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 6),
          child:
          Column(children: [
            Semantics(label:Localization().getStringEx("panel.create_event.additional_info.description.title","DESCRIPTION"),
                header: true, excludeSemantics: true, child:
                Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      Text(
                        Localization().getStringEx("panel.create_event.additional_info.description.title","DESCRIPTION"),
                        style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                      )
                    ],
                  ),
                )
            ),
            Semantics(label:Localization().getStringEx("panel.create_event.additional_info.event.description","Tell the campus what your event is about."),
                hint: Localization().getStringEx("panel.create_event.additional_info.event.description.hint","Type something"), textField: true, excludeSemantics: true, child:
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          Localization().getStringEx("panel.create_event.additional_info.event.description","Tell the campus what your event is about."),
                          maxLines: 2,
                          style: Styles().textStyles?.getTextStyle("widget.item.small.thin")
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(bottom: 0),
                        child: Container(
                          padding:
                          EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(
                                  color: Styles().colors!.fillColorPrimary!,
                                  width: 1)),
                          height: 120,
                          child: TextField(
                            controller: _eventDescriptionController,
                            onChanged: _onTextChanged,
                            // minLines: 1 ,
                            maxLines:  null,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: Localization().getStringEx("panel.create_event.additional_info.event.description.hint","Type something"),
                                hintStyle: Styles().textStyles?.getTextStyle("widget.item.regular.thin")
                            ),
                            style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.regular.thin")
                          ),
                        ),
                      ),
                    ])),
          ],)
        );
  }

  Widget _buildTimeZoneDropdown(){
    return
      Semantics(container: true, child:
      Container(
      child: Padding(
        padding: EdgeInsets.only(bottom: 0),
        child: Row(
          mainAxisAlignment:
          MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              flex: 3,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(child:
                    Text(
                      Localization().getStringEx("panel.create_event.date_time.time_zone.title","TIME ZONE"),
                      style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                  ))
                ],
              ),
            ),
            Container(
              width: 16,
            ),
            Expanded(
              flex: 7,
              child: Container(
                padding: EdgeInsets.only(bottom: 0),
                child: Container(
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Styles().colors!.surfaceAccent!,
                          width: 1),
                      borderRadius:
                      BorderRadius.all(Radius.circular(4))),
                  child: Padding(
                    padding:
                    EdgeInsets.only(left: 12, right: 8),
                    child: DropdownButtonHideUnderline(
                        child: DropdownButton(
                            icon: Styles().images?.getImage('chevron-down'),
                            isExpanded: true,
                            style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                            hint: Text(
                              (_selectedTimeZone) ?? Localization().getStringEx("panel.create_event.timeZone.default","Time Zone"),
                            ),
                            items: _buildTimeZoneDropDownItems(),
                            onChanged:
                            _onTimeZoneDropDownValueChanged)),
                  ),
                ),
              ),
            )
          ]
        )
      )
    ));
  }

  _buildLocationSection(){
    return Container(
      color: Styles().colors!.background,
      child: Column(children: [
      Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                (!_isInPerson) ? Container():
                Column(
                    children: [
                      Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child:
                          Semantics(label:Localization().getStringEx("panel.create_event.location.button_title","Location"),
                            header: true, excludeSemantics: true, child:
                            Row(
                              children: <Widget>[
                                Styles().images?.getImage('location') ?? Container(),
                                Padding(
                                  padding: EdgeInsets.only(left: 3),
                                  child: Text(
                                    Localization().getStringEx("panel.create_event.location.button_title","Location"),
                                    style: Styles().textStyles?.getTextStyle("widget.title.regular.fat")
                                  ),
                                )
                              ],
                            ),
                          )
                      ),
                      Semantics(label:Localization().getStringEx("panel.create_event.location.adress.title",'EVENT ADDRESS'),
                          header: true, excludeSemantics: true, child:
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  Localization().getStringEx("panel.create_event.location.adress.title",'EVENT ADDRESS'),
                                  style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                                )
                              ],
                            ),
                          )
                      ),
                      Semantics(label:Localization().getStringEx("panel.create_event.location.adress.title",'EVENT ADDRESS'),
                          hint: Localization().getStringEx("panel.create_event.location.adress.title.hint",''), textField: true, excludeSemantics: true, child:
                          Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding:
                              EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Styles().colors!.white,
                                  border: Border.all(
                                      color: Styles().colors!.fillColorPrimary!,
                                      width: 1)),
                              height: 48,
                              child: TextField(
                                controller: _eventLocationController,
                                onChanged: _onTextChanged,
                                decoration: InputDecoration(
                                    border: InputBorder.none),
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.large")
                              ),
                            ),
                          )
                      ),
                      Container(height: 8,),
                      Semantics(label:Localization().getStringEx("panel.create_event.location.lat.title",'EVENT LATITUDE'),
                          header: true, excludeSemantics: true, child:
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  Localization().getStringEx("panel.create_event.location.lat.title",'EVENT LATITUDE'),
                                  style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                                )
                              ],
                            ),
                          )
                      ),
                      Semantics(label:Localization().getStringEx("panel.create_event.location.lat.title",'EVENT LATITUDE'),
                          hint: Localization().getStringEx("panel.create_event.location.lat.title.hint",''), textField: true, excludeSemantics: true, child:
                          Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding:
                              EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Styles().colors!.white,
                                  border: Border.all(
                                      color: Styles().colors!.fillColorPrimary!,
                                      width: 1)),
                              height: 48,
                              child: TextField(
                                controller: _eventLatitudeController,
                                onChanged: _onTextChanged,
                                decoration: InputDecoration(
                                    border: InputBorder.none),
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.large"),
                              ),
                            ),
                          )
                      ),
                      Container(height: 8,),
                      Semantics(label:Localization().getStringEx("panel.create_event.location.long.title",'EVENT LONGITUDE'),
                          header: true, excludeSemantics: true, child:
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: <Widget>[
                                Text(
                                  Localization().getStringEx("panel.create_event.location.long.title",'EVENT LONGITUDE'),
                                  style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                                )
                              ],
                            ),
                          )
                      ),
                      Semantics(label:Localization().getStringEx("panel.create_event.location.long.title",'EVENT LONGITUDE'),
                          hint: Localization().getStringEx("panel.create_event.location.adress.title.hint",''), textField: true, excludeSemantics: true, child:
                          Padding(
                            padding: EdgeInsets.only(bottom: 16),
                            child: Container(
                              padding:
                              EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Styles().colors!.white,
                                  border: Border.all(
                                      color: Styles().colors!.fillColorPrimary!,
                                      width: 1)),
                              height: 48,
                              child: TextField(
                                controller: _eventLongitudeController,
                                onChanged: _onTextChanged,
                                decoration: InputDecoration(
                                    border: InputBorder.none),
                                maxLengthEnforcement: MaxLengthEnforcement.enforced,
                                style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.large")
                              ),
                            ),
                          )
                      ),
                      Semantics(label:Localization().getStringEx("panel.create_event.location.button.select_location.title","Select location on a map"),
                          hint: Localization().getStringEx("panel.create_event.location.button.select_location.button.hint",""), button: true, excludeSemantics: true, child:
                          Row(
                            children: <Widget>[
                              Expanded(
                                  child: RoundedButton(
                                    label: Localization().getStringEx("panel.create_event.location.button.select_location.title","Select location on a map"),
                                    textStyle: Styles().textStyles?.getTextStyle("widget.button.title.medium.fat"),
                                    backgroundColor: Styles().colors!.white,
                                    borderColor: Styles().colors!.fillColorSecondary,
                                    onTap: _onTapSelectLocation,
                                  ))
                            ],
                          )),
                      Container(height: 10,),
                    ]),
                Semantics(label:Localization().getStringEx("panel.create_event.additional_info.purchase_tickets.title","ADD LINK FOR REGISTRATION"),
                    hint: Localization().getStringEx("panel.create_event.additional_info.purchase_tickets.hint",""), textField: true, excludeSemantics: true, child:
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              Localization().getStringEx("panel.create_event.additional_info.purchase_tickets.title","ADD LINK FOR REGISTRATION"),
                              style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding:
                              EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Styles().colors!.fillColorPrimary!,
                                      width: 1)),
                              height: 48,
                              child: TextField(
                                controller: _eventPurchaseUrlController,
                                onChanged: _onTextChanged,
                                decoration: InputDecoration(
                                    border: InputBorder.none),
                                style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.regular.thin")
                              ),
                            ),
                          ),
                        ])),
                Semantics(label:Localization().getStringEx("panel.create_event.additional_info.button.confirm.purchase_tickets",'Confirm link for registration url'),
                  hint: Localization().getStringEx("panel.create_event.additional_info.button.confirm.hint",""), button: true, excludeSemantics: true, child:
                  Padding(
                    padding: EdgeInsets.only(bottom: 24),
                    child: GestureDetector(
                      onTap: _onTapConfirmPurchaseUrl,
                      child: Text(
                        Localization().getStringEx("panel.create_event.additional_info.button.confirm.title",'Confirm URL'),
                        style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline"),
                      ),
                    ),
                  ),
                ),
                Semantics(label:Localization().getStringEx("panel.create_event.additional_info.website.title",'ADD EVENT WEBSITE LINK'),
                    hint: Localization().getStringEx("panel.create_event.additional_info.website.hint",""), textField: true, excludeSemantics: true, child:
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Padding(
                            padding: EdgeInsets.only(bottom: 8),
                            child: Text(
                              Localization().getStringEx("panel.create_event.additional_info.website.title",'ADD EVENT WEBSITE LINK'),
                              style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding:
                              EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: Styles().colors!.fillColorPrimary!,
                                      width: 1)),
                              height: 48,
                              child: TextField(
                                controller: _eventWebsiteController,
                                onChanged: _onTextChanged,
                                decoration: InputDecoration(
                                    border: InputBorder.none),
                                style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.regular.thin")
                              ),
                            ),
                          ),
                        ]
                    )
                ),
                Semantics(label:Localization().getStringEx("panel.create_event.additional_info.button.confirm.website",'Confirm website URL'),
                    hint: Localization().getStringEx("panel.create_event.additional_info.button.confirm.hint",""), button: true, excludeSemantics: true, child:
                    GestureDetector(
                      onTap: _onTapConfirmWebsiteUrl,
                      child: Text(
                        Localization().getStringEx("panel.create_event.additional_info.button.confirm.title",'Confirm URL'),
                        style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline")
                      ),
                    )
                ),
                (!_isOnline) ? Container():
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(height: 10,),
                    Semantics(label:Localization().getStringEx("panel.create_event.additional_info.call_url.title","ADD ONLINE EVENT LINK"),
                        hint: Localization().getStringEx("panel.create_event.additional_info.call_url.hint",""), textField: true, excludeSemantics: true, child:
                        Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: <Widget>[
                              Container(
                                padding: EdgeInsets.only(bottom: 8),
                                child: Text(
                                  Localization().getStringEx("panel.create_event.additional_info.call_url.title","ADD ONLINE EVENT LINK"),
                                  style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.only(bottom: 12),
                                child: Container(
                                  padding:
                                  EdgeInsets.symmetric(horizontal: 12),
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                          color: Styles().colors!.fillColorPrimary!,
                                          width: 1)),
                                  height: 48,
                                  child: TextField(
                                    controller: _eventVirtualUrlController,
                                    onChanged: _onTextChanged,
                                    decoration: InputDecoration(
                                        border: InputBorder.none),
                                    style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.regular.thin")
                                  ),
                                ),
                              ),
                            ])),
                    Semantics(label:Localization().getStringEx("panel.create_event.additional_info.button.confirm.call_url",'Confirm online event link URL'),
                      hint: Localization().getStringEx("panel.create_event.additional_info.button.confirm.hint",""), button: true, excludeSemantics: true, child:
                      Padding(
                        padding: EdgeInsets.only(bottom: 24),
                        child: GestureDetector(
                          onTap: _onTapConfirmCallUrl,
                          child: Text(
                            Localization().getStringEx("panel.create_event.additional_info.button.confirm.title",'Confirm URL'),
                            style: Styles().textStyles?.getTextStyle("widget.button.title.medium.underline")
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Container(height: 18,),
              ])),
    ],),);
  }

  Widget _buildPriceSection(){
    return Container(
      color: Styles().colors!.background,
      padding: EdgeInsets.symmetric(horizontal: 16),
      child: Column(children: [
        Semantics(label:Localization().getStringEx("panel.create_event.button.free.title","Is this event free?"),
            hint: Localization().getStringEx("panel.create_event.button.free.hint",""), toggled: _isFree, excludeSemantics: true, child:
            ToggleRibbonButton(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              label: Localization().getStringEx("panel.create_event.button.free.title","Is this event free?"),
              toggled: _isFree,
              onTap: _onFreeToggled,
              border: Border.all(color: Styles().colors!.fillColorPrimary!),
              borderRadius:
              BorderRadius.all(Radius.circular(4)),
            )),
        Container(height: 8,),
//        _isFree? Container():
        Column(
          mainAxisAlignment:
          MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Expanded(
                  child: Text(
                    Localization().getStringEx("panel.create_event.price.label.title","Cost Description (eg: \$10, Donation suggested)"),
                    style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                  ))
                ],
              ),
            Container(
              width: 16,
            ),
            Semantics(label:Localization().getStringEx("panel.create_event.price.field.title",'Price'),
                  hint: Localization().getStringEx("panel.create_event.location.lat.title.hint",''), textField: true, excludeSemantics: true, child:
                  Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                          color: Colors.white,
                          border: Border.all(
                              color: Styles().colors!.fillColorPrimary!,
                              width: 1),
                          borderRadius:
                          BorderRadius.all(Radius.circular(4))),
                      height: 48,
                      child: TextField(
                        controller: _eventPriceController,
                        onChanged: _onTextChanged,
                        decoration: InputDecoration(
                            border: InputBorder.none),
                        maxLengthEnforcement: MaxLengthEnforcement.enforced,
                        style: Styles().textStyles?.getTextStyle("widget.input_field.dark.text.large")
                      ),
                    ),
                  )
              )
          ]
        )
      ],)
    );
  }

  Widget _buildPrivacyDropdown(){
    return Semantics(container: true, child: Container(
        color: Styles().colors!.background,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
                mainAxisAlignment:
                MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Expanded(
                    flex: 3,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Expanded(child:
                        Text(
                          Localization().getStringEx("panel.create_event.privacy.title","VISIBILITY"),
                          style: Styles().textStyles?.getTextStyle("panel.create_event.title.small")
                        ))
                      ],
                    ),
                  ),
                  Container(
                    width: 16,
                  ),
                  Expanded(
                    flex: 7,
                    child: Container(
                      padding: EdgeInsets.only(bottom: 0),
                      child: Container(
                        decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(
                                color: Styles().colors!.fillColorPrimary!,
                                width: 1),
                            borderRadius:
                            BorderRadius.all(Radius.circular(4))),
                        child: Padding(
                          padding:
                          EdgeInsets.only(left: 12, right: 8),
                          child: DropdownButtonHideUnderline(
                              child: DropdownButton(
                                  icon: Styles().images?.getImage('chevron-down', excludeFromSemantics: true),
                                  isExpanded: true,
                                  style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                                  hint: Text(
                                    (_selectedPrivacy) ?? Localization().getStringEx("panel.create_event.privacy.default","Privacy"),
                                  ),
                                  items: _privacyTypes.map((dynamic type) {
                                    return DropdownMenuItem<dynamic>(
                                      value: type,
                                      child: Text(
                                        type,
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: _onPrivacyDropDownValueChanged
                              )),
                        ),
                      ),
                    ),
                  )
                ]
            )
        )
    ));
  }

  /* TMP: Widget _buildAttendanceSwitch(){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Semantics(label:Localization().getStringEx("panel.create_event.button.attendance.title","Attendance required"),
        hint: Localization().getStringEx("panel.create_event.button.attendance..hint",""), toggled: true, excludeSemantics: true, child:
        ToggleRibbonButton(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          label: Localization().getStringEx("panel.create_event.button.attendance.title","Attendance required"),
          toggled: _isAttendanceRequired,
          onTap: _onAttendanceRequiredToggled,
          border: Border.all(color: Styles().colors.fillColorPrimary),
          borderRadius:
          BorderRadius.all(Radius.circular(4)),
        )));
  }*/

  void _prepopulateWithUpdateEvent(){
    Event? event = widget.editEvent;

    if(event!=null) {
      _imageUrl = event.imageURL;
//      event.category = _selectedCategory != null ? _selectedCategory["category"] : null;
      if (event.category != null)
        _selectedCategory = {"category": event.category};

      _eventTitleController.text = event.title!;
      if(event.startDateGmt!=null) {
        _startDate =  timezone.TZDateTime.from(event.startDateGmt!, timezone.getLocation(_selectedTimeZone!));
        _startTime = TimeOfDay.fromDateTime(_startDate!);
      }
      if(event.endDateGmt!=null) {
        _endDate = timezone.TZDateTime.from(event.endDateGmt!, timezone.getLocation(_selectedTimeZone!));
        _endTime = TimeOfDay.fromDateTime(_endDate!);
      }
      _allDay = event.allDay ?? false;
      _isOnline = event.isVirtual ?? false;
      _isInPerson = event.isInPerson ?? false;
      _isFree = event.isEventFree?? false;
      _location = event.location;
      if (event.description != null) {
        _eventDescriptionController.text = event.description!;
      }
      if (event.registrationUrl != null) {
        _eventPurchaseUrlController.text = event.registrationUrl!;
      }
      if (event.titleUrl != null) {
        _eventWebsiteController.text = event.titleUrl!;
      }
      if (event.cost != null) {
        _eventPriceController.text = event.cost!;
      }
      _selectedPrivacy = (event.isGroupPrivate??false) ? eventPrivacyPrivate : eventPrivacyPublic;

      // if (_isOnline) {
        _eventVirtualUrlController.text = event.virtualEventUrl ?? /*Support old records*/
            ((Uri.tryParse(event.location?.description??"")?.isAbsolute ?? false) ?
              event.location?.description ?? "" :
            "");
      // }

      if(event.location!=null){
        _eventLocationController.text = _location!.description!;
        _eventLatitudeController.text = event.location?.latitude?.toString()??"";
        _eventLongitudeController.text = event.location?.longitude?.toString()??"";
      }
    }
  }

  void _populateDefaultValues(){
    if(widget.group?.privacy!=null){
      _selectedPrivacy = (widget.group?.privacy == GroupPrivacy.private) ? eventPrivacyPrivate : eventPrivacyPublic;
    }
  }

  void _initGroupValues(){
    if(widget.group!=null && widget.editEvent!=null) {
      Groups().loadGroupEventMemberSelection(widget.group?.id, widget.editEvent?.id).then((memberSelection) {
        if (mounted) {
          setState(() {
            _groupMembersSelection = memberSelection;
          });
        }
      });
    }
  }

  void _loadEventCategories() async {
    _setLoading(true);
    _eventCategories = await Events().loadEventCategories();
    _setLoading(false);
  }

  List<DropdownMenuItem<dynamic>>? _buildCategoryDropDownItems() {
    int categoriesCount = _eventCategories?.length ?? 0;
    if (categoriesCount == 0) {
      return null;
    }
    return _eventCategories!.map((dynamic category) {
      return DropdownMenuItem<dynamic>(
        value: category,
        child: Text(
          category['category'],
        ),
      );
    }).toList();
  }

  void _onCategoryDropDownValueChanged(dynamic value) {
    Analytics().logSelect(target: "Category selected: $value");
    setState(() {
      _selectedCategory = value;
      _modified = true;
    });
  }

  List<DropdownMenuItem<dynamic>>?  _buildTimeZoneDropDownItems() {
    int zonesCount = _eventCategories?.length ?? 0;
    if (zonesCount == 0) {
      return null;
    }
    return _eventTimeZones.map((dynamic zone) {
      return DropdownMenuItem<dynamic>(
        value: zone,
        child: Text(
          zone,
        ),
      );
    }).toList();
  }

  void _onTimeZoneDropDownValueChanged(dynamic value) {
    Analytics().logSelect(target: "Time Zone selected: $value");
    setState(() {
      _selectedTimeZone = value;
      _modified = true;
    });
  }

  void _onPrivacyDropDownValueChanged(dynamic value) {
    Analytics().logSelect(target: "Privacy selected: $value");
    setState(() {
      _selectedPrivacy = value;
      _modified = true;
    });
  }

  void _onTapAddImage() async {
    Analytics().logSelect(target: "Add Image");
    String? updateUrl = await  GroupAddImageWidget.show(context: context, updateUrl: _imageUrl);
    if (StringUtils.isNotEmpty(updateUrl) && (_imageUrl != updateUrl)) {
      if(mounted){
        setState(() {
          _imageUrl = updateUrl;
          _modified = true;
        });
      }
    }
  }

  void _onTextChanged(_) {
    _modified = true;
  }

  void _onAllDayToggled() {
    _allDay = !_allDay;
    _modified = true;
    setState(() {});
  }

  void _onOnlineToggled() {
    _isOnline = !_isOnline;
    _modified = true;
    setState(() {});
  }

  void _onInPersonToggled() {
    _isInPerson = !_isInPerson;
    _modified = true;
    setState(() {});
  }

  void _onFreeToggled() {
    _isFree = !_isFree;
    _modified = true;
    setState(() {});
  }

  /* TMP: void _onAttendanceRequiredToggled() {
    _isAttendanceRequired = !_isAttendanceRequired;
    _modified = true;
    setState(() {});
  }*/

  void _onTapSelectLocation() {
    Analytics().logSelect(target: "Select Location");
    _performSelectLocation();
  }

  void _performSelectLocation() async {
    _setLoading(true);

    /* TBD Map2 String? location = await NativeCommunicator().launchSelectLocation(explore: _constructEventFromData());
    _setLoading(false);
    if (location != null) {
      Map<String, dynamic>? locationSelectionResult = jsonDecode(location);
      if (locationSelectionResult != null &&
          locationSelectionResult.isNotEmpty) {
        Map<String, dynamic>? locationData = locationSelectionResult["location"];
        if (locationData != null) {
          _location = ExploreLocation.fromJson(locationData);
          _modified = true;
          _populateLocationField();
          setState(() {});
        }
      }
    }*/
  }

  /* void _populateLocationField() {
    if (_location != null) {
      String? locationName;
      if ((_location!.name != null) && _location!.name!.isNotEmpty) {
        locationName = _location!.name;
      }
      else if ((_location!.address != null) && _location!.address!.isNotEmpty) {
        locationName = _location!.address;
      }

      _location!.name = locationName;
      _eventLocationController.text = StringUtils.ensureNotEmpty(locationName);

      if(StringUtils.isNotEmpty(_location!.description)){
        // if (_isOnline) {
        //   _eventVirtualUrlController.text = _location!.description!;
        // }
        // else {
          _eventLocationController.text = _location!.description!;
        // }
      }

      if(_location?.latitude!=null){
        _eventLatitudeController.text = _location?.latitude?.toString() ?? '';
      }

      if(_location?.longitude!=null){
        _eventLongitudeController.text = _location?.longitude?.toString() ?? '';
      }
    }
  } */

  void _onTapConfirmPurchaseUrl() {
    Analytics().logSelect(target: "Confirm Purchase url");
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) =>
                WebPanel(url: _eventPurchaseUrlController.text)));
  }

  void _onTapConfirmCallUrl() {
    Analytics().logSelect(target: "Confirm Purchase url");
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) =>
                WebPanel(url: _eventVirtualUrlController.text)));
  }

  void _onTapConfirmWebsiteUrl() {
    Analytics().logSelect(target: "Confirm Website url");
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (context) => WebPanel(url: _eventWebsiteController.text)));
  }

  void _onTapCancel() {
    Analytics().logSelect(target: "Cancel");
    Navigator.pop(context);
    //TBD: prompt
  }

  void _onTapBack() {
    if (_modified) {
      _promptBack().then((bool? result) {
        if (result!) {
          if (widget.editEvent != null) {
            _onTapUpdate();
          }
          else {
            _onTapCreate();
          }
        }
        else {
          Navigator.pop(context);
        }
      });
    }
    else {
      Navigator.pop(context);
    }
  }

  Future<bool?> _promptBack() async {
    String message = Localization().getStringEx('panel.create_event.back.prompt', 'Do you want to save your changes?');
    return await showDialog(context: context, builder: (BuildContext context) {
      return AlertDialog(
        content: Text(message),
        actions: <Widget>[
          TextButton(child: Text(Localization().getStringEx("dialog.yes.title", "Yes")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "Yes");
              Navigator.pop(context, true);
            }),
          TextButton(child: Text(Localization().getStringEx("dialog.no.title", "No")),
            onPressed:(){
              Analytics().logAlert(text: message, selection: "No");
              Navigator.pop(context, false);
            }),
        ]
      );
    });
  }

  void _onTapPreview() async {
    Analytics().logSelect(target: "Preview");
    if (_validateWithResult()) {
      Event event = _constructEventFromData();
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => ExploreEventDetailPanel(
                  event: event, previewMode: true))).then((dynamic data) {
        if (data != null) {
          Navigator.pop(context);
        }
      });
    }
  }

  ///
  /// Creates event
  /// If this event is group event then the admin user is allowed to select all the groups that he is admin of.
  /// In this case, the event is created for all the selected groups.
  ///
  /// If even one event is saved successfully - redirect the user to event detail panel.
  /// Display all group titles that event is failed to be created or linked to.
  ///
  Future<void> _onTapCreate() async {
    Analytics().logSelect(target: "Create");
    if (_validateWithResult()) {
      _setLoading(true);
      bool hasGroup = (widget.group != null);
      Event mainEvent = _constructEventFromData();
      Event? eventToDisplay;
      // Group? groupToDisplay; //deprecated
      List<String> createEventFailedForGroupNames = [];
      List<Group>? otherGroupsToSave;

      // If the event is part of a group - allow the admin to select other groups that one wants to save the event as well.
      //If event has membersSelection then do not allow linking to other groups
      if (hasGroup && CollectionUtils.isEmpty(_groupMembersSelection)) {
        List<Group>? otherGroups = await _loadOtherAdminUserGroups();
        if (CollectionUtils.isNotEmpty(otherGroups)) {
          otherGroupsToSave = await showDialog(context: context, barrierDismissible: true, builder: (_) => GroupsSelectionPopup(groups: otherGroups));
        }
      }

      // Save the initial event and link it to group if it's part of such one.
      String? mainEventId = await Events().postNewEvent(mainEvent);
      if (StringUtils.isNotEmpty(mainEventId)) {
        // Succeeded to create the main event
        if (hasGroup) {
          bool eventLinkedToGroup = await Groups().linkEventToGroup(groupId: mainEvent.createdByGroupId, eventId: mainEventId, toMembers: _groupMembersSelection);
          if (eventLinkedToGroup) {
            // Succeeded to link event to group
            eventToDisplay = mainEvent;
            // groupToDisplay = widget.group;
          } else {
            // Failed to link event to group
            ListUtils.add(createEventFailedForGroupNames, widget.group?.title);
          }
        } else {
          // Succeeded to create event that has no group
          eventToDisplay = mainEvent;
        }
      } else if (hasGroup) {
        ListUtils.add(createEventFailedForGroupNames, widget.group?.title);
      }

      // Save the event to the other selected groups that the user is admin.
      if (hasGroup && CollectionUtils.isNotEmpty(otherGroupsToSave)) {
        for (Group group in otherGroupsToSave!) {
          if (StringUtils.isNotEmpty(mainEventId)) {
            bool eventLinkedToGroup = await Groups().linkEventToGroup(groupId: group.id, eventId: mainEventId, toMembers: _groupMembersSelection);
            if (eventLinkedToGroup) {
              // Succeeded to link event to group
              if (eventToDisplay == null) {
                eventToDisplay = mainEvent;
                // groupToDisplay = group;
              }
            } else {
              // Failed to link event to group
              ListUtils.add(createEventFailedForGroupNames, group.title);
            }
          } else {
            // Failed to create event for group
            ListUtils.add(createEventFailedForGroupNames, group.title);
          }
        }
      }

      String failedMsg;
      if (CollectionUtils.isNotEmpty(createEventFailedForGroupNames)) {
        failedMsg = Localization().getStringEx('panel.create_event.groups.failed.msg', 'There was an error binding this event to the following groups: ');
        failedMsg += createEventFailedForGroupNames.join(', ');
      } else if (StringUtils.isEmpty(mainEventId)) {
        failedMsg = Localization().getStringEx('panel.create_event.failed.msg', 'There was an error creating this event.');
      }
      else {
        failedMsg = '';
      }

      _setLoading(false);
      if (StringUtils.isNotEmpty(failedMsg)) {
        AppAlert.showDialogResult(context, failedMsg);
      }

      if (eventToDisplay != null) {
        //deprecated. Now using Events2
        // Navigator.pushReplacement(
        //     context, CupertinoPageRoute(builder: (context) => GroupEventDetailPanel(event: eventToDisplay, group: groupToDisplay, previewMode: true)));
      }
    }
  }

  ///
  /// Returns the groups that current user is admin of without the current group
  ///
  Future<List<Group>?> _loadOtherAdminUserGroups() async {
    List<Group>? userGroups = await Groups().loadGroups(contentType: GroupsContentType.my);
    List<Group>? userAdminGroups;
    if (CollectionUtils.isNotEmpty(userGroups)) {
      userAdminGroups = [];
      String? currentGroupId = widget.group?.id;
      for (Group? group in userGroups!) {
        if (group!.currentUserIsAdmin && (group.id != currentGroupId)) {
          userAdminGroups.add(group);
        }
      }
    }
    return userAdminGroups;
  }

  void _onTapUpdate() {
    widget.onEditTap!(context, _populateEventWithData(widget.editEvent!), _groupMembersSelection);
  }
  
  Event _populateEventWithData(Event event){

    _location = ExploreLocation.fromOther(_location,
      description: _eventLocationController.text,
      latitude: double.tryParse(_eventLatitudeController.text),
      longitude: double.tryParse(_eventLongitudeController.text),
    );

    event.imageURL = _imageUrl;
    event.category = _selectedCategory != null ? _selectedCategory["category"] : "";
    event.title = _eventTitleController.text;
    if(_startDate!=null) {
      timezone.TZDateTime? startTime = DateTimeUtils.changeTimeZoneToDate(_startDate!, timezone.getLocation(_selectedTimeZone!));
      timezone.TZDateTime? utcTTime = startTime?.toUtc();
      event.startDateString = AppDateTime().formatDateTime(
          utcTTime?.toUtc(), format: Event.serverRequestDateTimeFormat, ignoreTimeZone: true);
      event.startDateGmt = utcTTime?.toUtc();
    }
    if(_endDate!=null) {
      timezone.TZDateTime? startTime = DateTimeUtils.changeTimeZoneToDate(_endDate!, timezone.getLocation(_selectedTimeZone!));
      timezone.TZDateTime? utcTTime = startTime?.toUtc();
      event.endDateString = AppDateTime().formatDateTime(
          utcTTime?.toUtc(), format: Event.serverRequestDateTimeFormat, ignoreTimeZone: true);
      event.endDateGmt = utcTTime?.toUtc();
    }
    event.allDay = _allDay;
    event.location = _location;
    event.description = _eventDescriptionController.text;
    event.registrationUrl = StringUtils.isNotEmpty(_eventPurchaseUrlController.text)?_eventPurchaseUrlController.text : null;
    event.titleUrl = _eventWebsiteController.text;
    event.isVirtual = _isOnline;
    event.virtualEventUrl =  StringUtils.isNotEmpty(_eventVirtualUrlController.text)?_eventVirtualUrlController.text : null;
    event.isInPerson = _isInPerson;
    event.recurringFlag = false;//decide do we need it
    event.cost = _eventPriceController.text.toString();//decide do we need it
    event.isGroupPrivate = _isPrivateEvent;
    event.isEventFree = _isFree;
    if(widget.group?.id!=null) {
      event.createdByGroupId = widget.group?.id;
    }
    //TBD populate Attendance required value

    return event;
  }

  Event _constructEventFromData(){
    Event event = Event();
    return _populateEventWithData(event);
  }

  void _onTapStartDate() async {
    Analytics().logSelect(target: "Start Date");
    timezone.TZDateTime? date = await _pickDate(_startDate, null);

    if (date != null) {
      _startDate = date;
      _startDate = _populateDateTimeWithTimeOfDay(date, _startTime);
      _modified = true;
    }
    setState(() {});
  }

  void _onTapStartTime() async {
    Analytics().logSelect(target: "Start Time");
    timezone.TZDateTime start = _startDate ?? timezone.TZDateTime.now(timezone.getLocation(_selectedTimeZone!));
    TimeOfDay? time =
        await _pickTime(_startTime ?? (new TimeOfDay.fromDateTime(start)));
    if (time != null) _startTime = time;

    _startDate = _populateDateTimeWithTimeOfDay(start, _startTime);
    _modified = true;
    setState(() {});
  }

  void _onTapEndDate() async {
    Analytics().logSelect(target: "End Date");
    timezone.TZDateTime? date = await _pickDate(_endDate, _startDate);

    if (date != null) {
      _endDate = date;
      _endDate = _populateDateTimeWithTimeOfDay(date, _endTime);
      _modified = true;
    }
    setState(() {});
  }

  void _onTapEndTime() async {
    Analytics().logSelect(target: "End Time");
    timezone.TZDateTime end = _endDate ?? timezone.TZDateTime.now(timezone.getLocation(_selectedTimeZone!));
    TimeOfDay? time =
        await _pickTime(_endTime ?? (new TimeOfDay.fromDateTime(end)));
    if (time != null) _endTime = time;

    _endDate = _populateDateTimeWithTimeOfDay(end, _endTime);
    _modified = true;
    setState(() {});
  }

  void _setLoading(bool loading) {
    if (mounted) {
      setState(() {
        _loading = loading;
      });
    }
  }

  Future<timezone.TZDateTime?> _pickDate(timezone.TZDateTime? date, timezone.TZDateTime? startDate) async {
    timezone.TZDateTime firstDate = startDate ?? timezone.TZDateTime.now(timezone.getLocation(_selectedTimeZone!));
    date = date ?? firstDate;
    timezone.TZDateTime initialDate = date;
    if (firstDate.isAfter(date)) {
      firstDate = initialDate; //Fix exception
    }
    timezone.TZDateTime lastDate =
    timezone.TZDateTime.fromMillisecondsSinceEpoch(timezone.getLocation(_selectedTimeZone!),initialDate.millisecondsSinceEpoch)
            .add(Duration(days: 365));
    DateTime? resultDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light(),
          child: child!,
        );
      },
    );

    return (resultDate != null) ? DateTimeUtils.changeTimeZoneToDate(resultDate, timezone.getLocation(_selectedTimeZone!)) : null;
  }

  Future<TimeOfDay?> _pickTime(TimeOfDay initialTime) async {
    TimeOfDay? time =
        await showTimePicker(context: context, initialTime: initialTime);
    return time;
  }

  timezone.TZDateTime? _populateDateTimeWithTimeOfDay(timezone.TZDateTime? date, TimeOfDay? time) {
    if (date != null) {
      int endHour = time != null ? time.hour : date.hour;
      int endMinute = time != null ? time.minute : date.minute;
      date = new timezone.TZDateTime(date.location,date.year, date.month, date.day, endHour, endMinute);
    }

    return date;
  }

  bool _isFormValid() {
    bool _categoryValidation = _selectedCategory != null;
    bool _titleValidation = StringUtils.isNotEmpty(_eventTitleController.text);
    bool _startDateValidation = _startDate != null;
    bool _startTimeValidation = _startTime != null || _allDay;
    bool _endDateValidation = _endDate != null;
    bool _endTimeValidation = _endTime != null || _allDay;
    bool _propperStartEndTimeInterval = (_endDate != null) ? !(_startDate?.isAfter(_endDate!) ?? true) : true;
    return _categoryValidation && _titleValidation && _startDateValidation && _startTimeValidation &&
        _endDateValidation && _endTimeValidation && _propperStartEndTimeInterval;
  }

  bool _validateWithResult() {
    bool _categoryValidation = _selectedCategory != null;
    bool _titleValidation =
        StringUtils.isNotEmpty(_eventTitleController.text);
    bool _startDateValidation = _startDate != null;
    bool _startTimeValidation = _startTime != null || _allDay;
    bool _endDateValidation = _endDate != null;
    bool _endTimeValidation = _endTime != null || _allDay;
    bool _propperStartEndTimeInterval = (_endDate != null) ? !(_startDate?.isAfter(_endDate!) ?? true) : true;
//    bool subCategoryIsValid = _subCategoryController.text?.isNotEmpty;

    if (!_categoryValidation) {
      AppAlert.showDialogResult(context,  Localization().getStringEx("panel.create_event.verification.category","Please select category"));
      return false;
    } else if (!_titleValidation) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.create_event.verification.title","Please add title"));
      return false;
    } else if (!_startDateValidation) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.create_event.verification.start_date","Please select start date"));
      return false;
    } else if (!_startTimeValidation) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.create_event.verification.start_time","Please select start time"));
      return false;
    } else if (!_endDateValidation) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.create_event.verification.end_date","Please select end date"));
      return false;
    } else if (!_endTimeValidation) {
      AppAlert.showDialogResult(context, Localization().getStringEx("panel.create_event.verification.end_time","Please select end time"));
      return false;
    } else if (!_propperStartEndTimeInterval) {
      AppAlert.showDialogResult(context,
          Localization().getStringEx("panel.create_event.verification.date_time","Please select propper time interval. Start date cannot be after end date"));
      return false;
    }
    return true;
  }

  /*bool get _isGroupEvent{
    return widget.group!=null;
  }*/

  bool get _isPrivateEvent{
   return _selectedPrivacy == eventPrivacyPrivate;
  }

  /*bool get _isEditMode{
    return widget.editEvent != null;
  }*/

  String? get _panelTitleText{
    return widget.editEvent!=null ? "Update Event" : Localization().getStringEx("panel.create_event.header.title", "Create An Event");
  }
}

class _EventDateDisplayView extends StatelessWidget {
  final String? label;
  final GestureTapCallback? onTap;

  _EventDateDisplayView({this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
//        width: 142,
        decoration: BoxDecoration(
            border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
            borderRadius: BorderRadius.all(Radius.circular(4))),
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              StringUtils.ensureNotEmpty(label, defaultValue: '-'),
              style: Styles().textStyles?.getTextStyle("widget.title.regular"),
            ),
            Styles().images?.getImage('chevron-down') ?? Container()
          ],
        ),
      ),
    );
  }
}
