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

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/log.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class WellnessRingsHomeContentWidget extends StatefulWidget {
  WellnessRingsHomeContentWidget();

  @override
  State<WellnessRingsHomeContentWidget> createState() => _WellnessRingsHomeContentWidgetState();
}

class _WellnessRingsHomeContentWidgetState extends State<WellnessRingsHomeContentWidget> implements NotificationsListener{


  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      WellnessRingService.notifyUserRingsUpdated,
    ]);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return
      _buildTodaysRingsContent();
  }

  _buildTodaysRingsContent(){
    return Container(
      child:
      Stack(children:[
        Column(
          children: [
            Container(height: 16,),
            WellnessRing(),
            Container(height: 16,),
            _buildButtons(),
            Container(height: 16,),
            WellnessRingButton(label: "Create New Ring", description: "Maximum of 4 total", onTapWidget: (context){}, showLeftIcon: true,),
            Container(height: 16,),
        ],
      ),
      ])
    );
  }

  Widget _buildButtons(){
    return _mocButtons;
  }

  Widget get _mocButtons{
    List<Widget> content = [];
    for(dynamic jsonData in WellnessRingService.predefinedRings){
      WellnessRingData? data = WellnessRingData.fromJson(jsonData);
      if(data!=null){
        content.add(WellnessRingButton(
            label: data.name??"",
            color: data.color,
            showRightIcon: true,
            description: "${WellnessRingService().getRingDailyValue(data.id).toInt()}/${data.goal.toInt()} ${data.unit}s",
            onTapWidget: (context){
              WellnessRingService().addRecord(WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: data.id));
            }));
        content.add(Container(height: 10,));
      }
    }

    return Container(
      child: Column(children: content,),
    );
  }

  @override
  void onNotification(String name, param) {
    if(name == WellnessRingService.notifyUserRingsUpdated){
      if(mounted) {
        setState(() {});
      }
    }
  }

}
// Widgets
//////////////////

//WellnessRing
class WellnessRing extends StatefulWidget{
  final Color? backgroundColor;

  WellnessRing({this.backgroundColor = Colors.white});

  @override
  State<WellnessRing> createState() => _WellnessRingState();
}

class _WellnessRingState extends State<WellnessRing> with TickerProviderStateMixin implements NotificationsListener{
  static const int OUTER_SIZE = 250;
  static const int STROKE_SIZE = 35;
  static const int PADDING_SIZE = 2;
  static const int ANIMATION_DURATION_MILLISECONDS = 1500;
  static const int MIN_RINGS_COUNT = 4;

  List<WellnessRingData>? _ringsData ;
  Map<String, AnimationController> _animationControllers = {};

  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
        WellnessRingService.notifyUserRingsUpdated,
        WellnessRingService.notifyUserRingsAccomplished,
    ]);
    _loadRingsData();
    _controllerCenter =
        ConfettiController(duration: const Duration(seconds: 5));
    // _animateControllers();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
    if(_animationControllers.isNotEmpty) {
      _animationControllers.values.forEach((controller) {
        controller.dispose();
      });
    }
    _controllerCenter.dispose();
  }

  void _loadRingsData() async {
    WellnessRingService().getWellnessRings().then((value) {
      _ringsData = value;
      setState(() {
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10),
      child:
      Center(
        child: _buildRingsContent()
    ));
  }

  Widget _buildRingsContent(){
    List<WellnessRingData> data = [];
    int fillCount = MIN_RINGS_COUNT - (_ringsData?.length ?? 0);
    if(fillCount > 0){
      for (int i=0; i<fillCount; i++){
        data.add(WellnessRingData(id: "empty", goal: 1, timestamp: DateTime.now().millisecondsSinceEpoch));
      }
    }
    if(_ringsData?.isNotEmpty ?? false){
      data.addAll(_ringsData!);
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
    double completion =  WellnessRingService().getRingDailyCompletion(data.id);

    AnimationController? controller = _animationControllers[data.id];

    if(controller == null) {
     controller = AnimationController(
          duration: Duration(milliseconds: ANIMATION_DURATION_MILLISECONDS),
          vsync: this);

     _animationControllers[data.id] = (controller);
    }

    if(controller.value!=completion) {
      controller.animateTo(completion, );
    }

      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Container(
            // // color: Colors.green,
            width: innerContentSize,
            height: innerContentSize,
            child: Stack(
              children: [
                Center(
                  child: GestureDetector( //TBD REMOVE TMP TEST SOLUTION
                  onTap: (){if(data.id!="empty") WellnessRingService().addRecord(WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: data.id));},
                  child: SizedBox(
                      height: innerContentSize,
                      width: innerContentSize,
                      child: CircularProgressIndicator(
                        strokeWidth: STROKE_SIZE.toDouble(),
                        value: controller!.value >= 1 ? 0.999 : controller.value,
                           // * (completion) >= 1 ? 0.999 : completion, // Simulate padding in the end
                        color: data.color,
                        backgroundColor: Colors.white,
                      )),
                )),
                Center(
                  child:
                  Container(
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
                          Center(child: Text("TBD",
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

  Widget _buildProfilePicture() { //TBD update image resource
    return
      Stack(
        children: [
          Container(decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(fit: BoxFit.cover, image: Image.asset('images/missing-photo-placeholder.png', excludeFromSemantics: true).image))),
          Center(
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                numberOfParticles: 110,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false, // start again as soon as the animation is finished
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.red,
                ], // manually specify the colors to be used
                // createParticlePath: drawStar, // define a custom shape/path
              ))
        ],
      );
  }

  @override
  void onNotification(String name, param) {
      if(name == WellnessRingService.notifyUserRingsUpdated){
        WellnessRingService().getWellnessRings().then((value){
          _ringsData = value;
          if(mounted) {
            setState(() {});
          }
        });
      } else if( name == WellnessRingService.notifyUserRingsAccomplished){
        if (param != null && param is String) {
          WellnessRingData? data = WellnessRingService().wellnessRings
              ?.firstWhere((element) => element.id == param);
          if (data != null) {
            AppAlert.showCustomDialog(context: context, contentPadding: EdgeInsets.all(0),
              contentWidget:
                Container(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      Row(
                        children: [
                          Expanded(child:
                            Container(height: 3, color: data.color,)
                          )
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Container()),
                                Container(
                                  padding: EdgeInsets.only(left: 50, bottom: 10),
                                  child: GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Text("x", style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 22),),
                                )),
                              ],
                            ),
                            Container(height: 2,),
                            Row(
                              children: [
                                Expanded(child:
                                  Text("Congratulations!", textAlign: TextAlign.center,
                                    style :TextStyle(color: Styles().colors!.fillColorPrimary!, fontFamily: Styles().fontFamilies!.bold, fontSize: 18),
                                  )
                                )
                              ],
                            ),
                            Container(height: 12,),
                            Row(
                              children: [
                                Expanded(child:
                                  RichText(
                                  textAlign: TextAlign.center,
                                    text: TextSpan(
                                      children:[
                                      TextSpan(text:"You've completed your ",
                                          style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),),
                                      TextSpan(text:"${data.name} ", //TBD
                                          style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.bold, fontSize: 16),),
                                      TextSpan(text:"ring for ",
                                          style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),),
                                      TextSpan(text:"${WellnessRingService().getTotalCompletionCountString(param)} time!",
                                          style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.bold, fontSize: 16),),
                                      ]
                                  ))
                                ),
                              ],
                            ),
                            Container(height: 12,),
                    ],)
            )]
            )));
          }
        }
        _playConfetti();
      }
  }

  void _playConfetti(){
    _controllerCenter.play();
    // Future.delayed(Duration(seconds: 5), (){_controllerCenter.stop();});
  }
}

//WellnessRingButton
class WellnessRingButton extends StatefulWidget{
  final String label;
  final String? description;
  final bool showLeftIcon;
  final bool showRightIcon;
  final Color? color;
  final void Function(BuildContext context) onTapWidget;
  final void Function(BuildContext context)? onTapRightWidget;

  const WellnessRingButton({Key? key, required this.label, this.description, this.showLeftIcon = false, this.showRightIcon = false, this.color, required this.onTapWidget, this.onTapRightWidget}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WellnessRingButtonState();

}

class _WellnessRingButtonState extends State<WellnessRingButton>{

  @override
  Widget build(BuildContext context) {
    return Semantics(label: widget.label, hint: widget.description, button: true, excludeSemantics: true, child:
    GestureDetector(onTap: () => widget.onTapWidget(context), child:
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child:
      Container(decoration: BoxDecoration(color: widget.color ?? Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), child:
      Row(children: <Widget>[
        widget.showLeftIcon ? Padding(padding: EdgeInsets.only(right: 6), child: _leftIcon) : Container(),
        Expanded(child:
          Text(widget.label , style: TextStyle(color: widget.color!=null? Colors.white : Styles().colors!.fillColorPrimary!, fontFamily: Styles().fontFamilies!.bold, fontSize: 16), textAlign: TextAlign.start,),
        ),
        Expanded(child:
          Text(widget.description ?? "" , style: TextStyle(color: widget.color!=null? Colors.white : Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 14), textAlign: TextAlign.end,),
        ),
        widget.showRightIcon ? Padding(padding: EdgeInsets.only(left: 6), child: _rightIcon) : Container(),
      ],),
      ),
      )
      ),
    ],),
    ),
    );
  }

  Widget get _leftIcon{
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Image.asset('images/icon-create-event.png', excludeFromSemantics: true, color:  Styles().colors!.fillColorPrimary!),
    ); //TBD
  }

  Widget get _rightIcon{
    return GestureDetector(
      onTap: (){ if (widget.onTapRightWidget!=null) widget.onTapRightWidget!(context);},
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Image.asset('images/icon-gear.png', excludeFromSemantics: true, color:  Styles().colors!.white!),
    ));
  }
}

//Data //TBD move to data model class

class WellnessRingData {
  String id;
  double goal;
  Color? color;
  String? name;
  String? unit;
  int timestamp;

  WellnessRingData({required this.id , this.name, required this.goal, this.unit = "times" , this.color = Colors.orange, required this.timestamp});

  static WellnessRingData? fromJson(Map<String, dynamic>? json){
    if(json!=null) {
      return WellnessRingData(
        id:     JsonUtils.stringValue(json['id']) ?? "",
        goal:   JsonUtils.doubleValue(json['goal']) ?? 1.0,
        name:   JsonUtils.stringValue(json['name']),
        unit:   JsonUtils.stringValue(json['unit']),
        timestamp:   JsonUtils.intValue(json['timestamp']) ?? DateTime.now().millisecondsSinceEpoch,
        color:  UiColors.fromHex(JsonUtils.stringValue(json['color']))
      );
    }
    return null;
  }

  Map<String, dynamic> toJson(){
    Map<String, dynamic> json = {};
    json['id']     = id;
    json['goal']   = goal;
    json['name']   = name;
    json['unit']   = unit;
    json['color']  = UiColors.toHex(color);
    json['timestamp']  = timestamp;
    return json;
  }

  void updateFromOther(WellnessRingData other){
    this.id = other.id;
    this.goal = other.goal;
    this.color = other.color;
    this.name= other.name;
    this.unit = other.unit;
    this.timestamp = other.timestamp;
  }

  @override
  bool operator ==(dynamic other) =>
      (other is WellnessRingData) &&
          (id == other.id) &&
          (goal == other.goal) &&
          (color == other.color) &&
          (name == other.name) &&
          (timestamp == other.timestamp) &&
          (unit == other.unit);

  @override
  int get hashCode =>
      (id.hashCode) ^
      (goal.hashCode) ^
      (color?.hashCode ?? 0) ^
      (name?.hashCode ?? 0) ^
      (timestamp.hashCode) ^
      (unit?.hashCode ?? 0);

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

class WellnessRingRecord {
  final String wellnessRingId;
  final double value;
  final int timestamp;

  WellnessRingRecord(
      {required this.value, required this.timestamp, required this.wellnessRingId});

  static WellnessRingRecord? fromJson(Map<String, dynamic>? json) {
    if (json != null) {
      return WellnessRingRecord(
          wellnessRingId: JsonUtils.stringValue(json['wellnessRingId']) ?? "",
          value: JsonUtils.doubleValue(json['value']) ?? 0.0,
          timestamp: JsonUtils.intValue(json['timestamp']) ?? 0
      );
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['wellnessRingId'] = wellnessRingId;
    json['value'] = value;
    json['timestamp'] = timestamp;
    return json;
  }

  @override
  bool operator ==(dynamic other) =>
      (other is WellnessRingRecord) &&
          (wellnessRingId == other.wellnessRingId) &&
          (value == other.value) &&
          (timestamp == other.timestamp);

  @override
  int get hashCode =>
      (wellnessRingId.hashCode) ^
      (value.hashCode) ^
      (timestamp.hashCode);

  static List<WellnessRingRecord>? listFromJson(List<dynamic>? json) {
    List<WellnessRingRecord>? values;
    if (json != null) {
      values = <WellnessRingRecord>[];
      for (dynamic entry in json) {
        ListUtils.add(values, WellnessRingRecord.fromJson(JsonUtils.mapValue(entry)));
      }
    }
    return values;
  }

  static List<dynamic>? listToJson(List<WellnessRingRecord>? values) {
    List<dynamic>? json;
    if (values != null) {
      json = <dynamic>[];
      for (WellnessRingRecord? value in values) {
        json.add(value?.toJson());
      }
    }
    return json;
  }
}

//Service //TBD move to service class

class WellnessRingService with Service{
  static const String notifyUserRingsUpdated = "edu.illinois.rokwire.wellness.user.ring.updated";
  static const String notifyUserRingsAccomplished = "edu.illinois.rokwire.wellness.user.ring.accomplished";
  static const int MAX_RINGS = 4;
  static const List<dynamic> predefinedRings = [
    {'name': "Hobby", 'goal': 10, 'color': 'FFF57C00' , 'id': "id_0", 'unit':'session'},
    {'name': "Physical Activity", 'goal': 10, 'color': 'FF4CAF50', 'id': "id_1", 'unit':'activity'},
    {'name': "Mindfulness", 'goal': 10, 'color': 'FF2196F3' , 'id': "id_2", 'unit':'moment'},
  ];

  // ignore: unused_field
  final List <WellnessRingRecord> _mocWellnessRecords = [
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_0",),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_0"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_0"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_1"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_1"),
    WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: "id_2"),
  ];

  List<WellnessRingData>? _wellnessRings;
  List<WellnessRingRecord>? _wellnessRecords; //TBD implement its mocced for now

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
    _wellnessRings =  WellnessRingData.listFromJson(predefinedRings);//Storage().userWellnessRings; //TBD implement from file //TBD Moc for now
    _wellnessRecords = []; //_mocWellnessRecords; //TBD Implement from file //TBD Moc for now
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

  void addRecord(WellnessRingRecord record){
    Log.d("addRecord ${record.toJson()}");
    //TBD store
    bool alreadyAccomplished = _isAccomplished(record.wellnessRingId);
    _wellnessRecords?.add(record);
    NotificationService().notify(notifyUserRingsUpdated);
    if(alreadyAccomplished == false) {
      _checkForAccomplishment(record.wellnessRingId);
    }
  }

  double getRingDailyValue(String wellnessRingId){
    Iterable<WellnessRingRecord>? selection = _wellnessRecords?.where((record) => record.wellnessRingId == wellnessRingId);
        // ?.where((record) => ((DateTimeUtils.midnight(DateTime.now())?.millisecondsSinceEpoch ?? 0) < record.timestamp));// Today records

    double value = 0.0;
    selection?.forEach((record) {
      value += record.value;
    });
    return value; //TBD implement
  }

  void _checkForAccomplishment(String id){
      if(_isAccomplished(id)){
        NotificationService().notify(notifyUserRingsAccomplished, id);
      }
  }

  bool _isAccomplished(String id){
    return(getRingData(id)?.goal ?? 0) <= getRingDailyValue(id);
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

  int getTotalCompletionCount(String id){
    //TODO
    return 3;
  }

  String getTotalCompletionCountString(String id){
    int count = getTotalCompletionCount(id);
    switch(count){
      case 1 : return "1st";
      case 2 : return "2nd";
      default :return "${count}rd";
    }
  }

  double getRingDailyCompletion(String id) {
    double value = getRingDailyValue(id);
    double goal = 1;
    try{ goal = getRingData(id)?.goal ?? 0;} catch (e){ print(e);}
    return value / goal;
  }

  WellnessRingData? getRingData(String id){
    return wellnessRings?.firstWhere((ring) => ring.id == id);
  }
}
