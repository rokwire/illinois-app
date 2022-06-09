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
import 'package:illinois/service/Storage.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessRingsHomeContentWidget extends StatefulWidget {
  WellnessRingsHomeContentWidget();

  @override
  State<WellnessRingsHomeContentWidget> createState() => _WellnessRingsHomeContentWidgetState();
}

class _WellnessRingsHomeContentWidgetState extends State<WellnessRingsHomeContentWidget> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WellnessRing();
  }

}

class WellnessRing extends StatefulWidget{
  final Color? backgroundColor;

  WellnessRing({this.backgroundColor = Colors.white});

  @override
  State<WellnessRing> createState() => _WellnessRingState();
}

class _WellnessRingState extends State<WellnessRing> implements NotificationsListener{
  static const int OUTER_SIZE = 250;
  static const int STROKE_SIZE = 35;
  static const int PADDING_SIZE = 2;
  static const int ANIMATION_DURATION_MILLISECONDS = 1300;
  static const int MIN_RINGS_COUNT = 4;

  List<WellnessRingData>? _data ;


  @override
  void initState() { //TBD add to services, for now this is not called
    super.initState();
    NotificationService().subscribe(this, [
        WellnessRingService.notifyUserRingsUpdated,
    ]);
    _loadRingsData();
  }

  void _loadRingsData() async {
    WellnessRingService().getWellnessRings().then((value) {
      _data = value;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child:
      Center(
        // This Tween Animation Builder is Just For Demonstration, Do not use this AS-IS in Projects
        // Create and Animation Controller and Control the animation that way.
        child: _buildRingsContent()
    ));
  }

  Widget _buildRingsContent(){
    List<WellnessRingData> data = [];
    int fillCount = MIN_RINGS_COUNT - (_data?.length ?? 0);
    if(fillCount > 0){
      for (int i=0; i<fillCount; i++){
        data.add(WellnessRingData(id: "empty_$i", goal: 1));
      }
    }
    if(_data?.isNotEmpty ?? false){
      data.addAll(_data!);
    }

    return _buildRing(data: data);
  }

  Widget _buildRing({int level = 0, required List<WellnessRingData> data}){
    WellnessRingData? ringData = data.length > level? data[level] : null;
      return ringData != null ? //Recursion bottom
        _buildRingWidget(
          level: level,
          data: data[level],
          childWidget: _buildRing(level: level + 1, data: data)) : //recursion)
        _buildProfilePicture();
  }

  Widget _buildRingWidget({required int level, WellnessRingData? data, Widget? childWidget}){
    double? innerContentSize = (OUTER_SIZE - ((level) * (STROKE_SIZE + PADDING_SIZE))).toDouble();
    if(data!=null) {
      return TweenAnimationBuilder(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: Duration(
            milliseconds: (ANIMATION_DURATION_MILLISECONDS * data.getPercentage()).toInt()),
        builder: (context, timeValue, child) {
          int percentage = ((timeValue as double) * data.getPercentage() * 100)
              .ceil();
          return Container(
            // // color: Colors.green,
            width: innerContentSize,
            height: innerContentSize,
            child: Stack(
              children: [
                Center(
                  child: SizedBox(
                      height: innerContentSize,
                      width: innerContentSize,
                      child: CircularProgressIndicator(
                        strokeWidth: STROKE_SIZE.toDouble(),
                        value: timeValue *
                            (data.getPercentage() >= 1 ? 0.999 : data
                                .getPercentage()), // Simulate padding in the end
                        color: data.color,
                        backgroundColor: Colors.white,
                      )),
                ),
                Center(
                  child: Container(
                      width: innerContentSize,
                      height: innerContentSize,
                      decoration: BoxDecoration(
                          color: Styles().colors!.background!,
                          shape: BoxShape.circle
                      ),
                )),
                Center(
                    child: Container(
                      width: innerContentSize - PADDING_SIZE,
                      height: innerContentSize - PADDING_SIZE,
                      decoration: BoxDecoration(
                          color: widget.backgroundColor ??
                              Styles().colors!.white!,
                          shape: BoxShape.circle
                      ),
                      child:
                      childWidget ??
                          Center(child: Text("$percentage",
                            style: TextStyle(fontSize: 40),)),
                    )
                  ),
              ],
            ),
          );
        },
      );
    }
    return Container();
  }

  Widget _buildProfilePicture() {
    //TBD implement
    return GestureDetector(
        onTap: () async{
          //TBD REMOVE THIS IS JUST FOR TEST
          List currentRings = WellnessRingService().wellnessRings ?? [];
          if(currentRings.length >= WellnessRingService.MAX_RINGS) {
            WellnessRingService().removeRing(WellnessRingService().wellnessRings!.first); //REMOVE IF FULL
          } else {
            WellnessRingService().addRing(WellnessRingService().MOC_RINGS[currentRings.length]); //ADD IF NOT FULL
          }
        },
        child: Container(
            child: Center(
              child: Text("Profile TBD", textAlign: TextAlign.center,),
            )
        )
    );
  }

  @override
  void onNotification(String name, param) {
      if(name == WellnessRingService.notifyUserRingsUpdated){
        WellnessRingService().getWellnessRings().then((value){
          _data = value;
          setState(() {});
        });
      }
  }
}

//Data //TBD move to data model class

class WellnessRingData {
  String id;
  double goal;
  double? value;
  Color? color;
  String? name;
  String? unit;

  WellnessRingData({required this.id , this.name, required this.goal, this.value = 0, this.unit = "times" , this.color = Colors.orange});

  static WellnessRingData? fromJson(Map<String, dynamic>? json){
    if(json!=null) {
      return WellnessRingData(
        id:     JsonUtils.stringValue(json['id']) ?? "",
        goal:   JsonUtils.doubleValue(json['goal']) ?? 1.0,
        value:  JsonUtils.doubleValue(json['value']),
        name:   JsonUtils.stringValue(json['name']),
        unit:   JsonUtils.stringValue(json['unit']),
        color:  UiColors.fromHex(JsonUtils.stringValue(json['color']))
      );
    }
    return null;
  }

  Map<String, dynamic> toJson(){
    Map<String, dynamic> json = {};
    json['id']     = id;
    json['goal']   = goal;
    json['value']  = value;
    json['name']   = name;
    json['unit']   = unit;
    json['color']  = UiColors.toHex(color);
    return json;
  }

  void updateFromOther(WellnessRingData other){
    this.id = other.id;
    this.goal = other.goal;
    this.value = other.value;
    this.color = other.color;
    this.name= other.name;
    this.unit = other.unit;
  }

  @override
  bool operator ==(dynamic other) =>
      (other is WellnessRingData) &&
          (id == other.id) &&
          (goal == other.goal) &&
          (color == other.color) &&
          (name == other.name) &&
          (unit == other.unit) &&
          (value == other.value);


  @override
  int get hashCode =>
      (id.hashCode) ^
      (goal.hashCode) ^
      (color?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (unit?.hashCode ?? 0) ^
      (value?.hashCode ?? 0);


  double getPercentage(){
    return (value ?? 0) / goal;
  }

  static List<WellnessRingData>? listFromJson(List<dynamic>? json) {
    List<WellnessRingData>? values;
    if (json != null) {
      values = <WellnessRingData>[];
      for (dynamic entry in json) {
        ListUtils.add(values, WellnessRingData.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<WellnessRingData>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (WellnessRingData? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//Service //TBD move to service class

class WellnessRingService with Service{
  static const String notifyUserRingsUpdated      = "edu.illinois.rokwire.wellness.user.rings.updated";
  static const int MAX_RINGS = 4;
  //TBD remove
  final List<WellnessRingData> MOC_RINGS = [
    WellnessRingData(name: "Sports Activity", goal: 2, color: Colors.brown ,value: 1, id: "0"),
    WellnessRingData(name: "Water ", goal: 3, color: Colors.blue ,value: 3, id: "1"),
    WellnessRingData(name: "Sleep ", goal: 8, color: Colors.orange ,value: 1, id: "3"),
    WellnessRingData(name: "Study ", goal: 4, color: Colors.yellow ,value: 4, unit: "Sessions", id: "4"),
    WellnessRingData(name: "Outdoor Activities ", goal: 4, color: Colors.green ,value: 3, unit: "Sessions", id: "5"),
    WellnessRingData(name: "Food", goal: 4, color: Colors.red ,value: 4, unit: "meals", id: "6"),
    WellnessRingData(name: "Reading", goal: 60, color: Colors.blueGrey ,value: 60, unit: "minutes", id: "7"),
  ];

  List<WellnessRingData>? _wellnessRings;

  // Singletone Factory

  static WellnessRingService? _instance;

  static WellnessRingService? get instance => _instance;

  @protected
  static set instance(WellnessRingService? value) => _instance = value;

  factory WellnessRingService() => _instance ?? (_instance = WellnessRingService.internal());

  @protected
  WellnessRingService.internal();

  @override
  Future<void> initService() {
    _loadFromStorage();
    _loadFromNet();
    return super.initService();
  }

  void _loadFromStorage(){
    _wellnessRings = Storage().userWellnessRings;
  }
  
  void _loadFromNet(){
    //TBD network API
    _storeWellnessRings();
  }
  
  void addRing(WellnessRingData data) async {
    //TBD replace network API
    if(_wellnessRings == null){
      _wellnessRings = [];
    }
    if(canAddRing){
      _wellnessRings!.add(data);
    }
    NotificationService().notify(notifyUserRingsUpdated);
    _storeWellnessRings();
  }
  
  void updateRing(WellnessRingData data) async {
    //TBD replace network API
    WellnessRingData? ringData = _wellnessRings?.firstWhere((ring) => ring.id == data.id);
    if(ringData != null && ringData != data){
      ringData.updateFromOther(data);
    }
    NotificationService().notify(notifyUserRingsUpdated);
    _storeWellnessRings();
  }
  
  void removeRing(WellnessRingData data) async {
    //TBD network API
    WellnessRingData? ringData = _wellnessRings?.firstWhere((ring) => ring.id == data.id);
    if(ringData != null){
       _wellnessRings?.remove(ringData);
    }
    NotificationService().notify(notifyUserRingsUpdated);
    _storeWellnessRings();
  }

  bool get canAddRing{
    return (_wellnessRings?.length ?? 0) < MAX_RINGS;
  }
  
  void _storeWellnessRings(){
    Storage().userWellnessRings = _wellnessRings;
  }

  Future<List<WellnessRingData>?> getWellnessRings() async {
    if(_wellnessRings == null){ //TBD REMOVE workaround while we are not added to the Services
      _loadFromStorage();
    }
    return _wellnessRings; //TBD load from net
  }

  List<WellnessRingData>? get wellnessRings{
    return _wellnessRings;
  }
}
