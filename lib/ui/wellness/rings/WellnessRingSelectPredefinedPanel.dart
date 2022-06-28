import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessReing.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';

import 'WellnessRingCreatePane.dart';

class WellnessRingSelectPredefinedPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _WellnessRingSelectPredefinedPanelState();
}

class _WellnessRingSelectPredefinedPanelState extends State<WellnessRingSelectPredefinedPanel> implements NotificationsListener{
  static const List<Map<String,dynamic>> PREDEFINED_RING_BUTTONS = [
    {"ring":{'name': "Hobby", 'goal': 2, 'color': 'e45434', 'id': "id_predefined_0", 'unit':'session'},
      "name":"Hobby Ring",
      "description":"description",
      "example": "example"},
    {"ring":{'name': "Physical Activity", 'goal': 16, 'color': 'FF4CAF50', 'id': "id_predefined_1", 'unit':'activity'},
      "name":"Movement Ring",
      "description":"description",
      "example":"example"},
    {"ring":{'name': "Mindfulness", 'goal': 10, 'color': 'FF2196F3' , 'id': "id_predefined_2", 'unit':'moment'},
      "name":"Mindfulness",
      "description":"description",
      "example": "example"},
    {"name" : "Custom Ring",
      "description":"description",
      "example": "Custom Ring example"},
  ];

  Map<String,dynamic>? _selectedButton;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      WellnessRings.notifyUserRingsUpdated,
    ]);
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.wellness.ring.select.title', 'Select Ring')),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(children: [
                      Center(child: Text("TBD \n In progress..."),),
                      Container(height: 12,),
                      _buildPredefinedButtons(),
                      Container(height: 12,),
                      // _WellnessRingButton(
                      //   label: "Create New Ring",
                      //   description: "Maximum of 4 total",
                      //   onTapWidget: (context){
                      //     Analytics().logSelect(target: "Custom ring");
                      //     _selectedRing = null;
                      //     _refreshState();
                      //   }, showLeftIcon: true,),

                    ]))),
          ),
          Container(height: 30,),
          Container(
            child: SmallRoundedButton(label: 'Next', onTap: _openDetailPanel, backgroundColor: Colors.white, rightIconPadding: EdgeInsets.only(right: 16, left: 16,), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),),
          ),
          Container(height: 50,)
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildPredefinedButtons(){
    List<Widget> content = [];
    for(Map<String, dynamic> jsonData in PREDEFINED_RING_BUTTONS){  WellnessRingData? data = WellnessRingData.fromJson(JsonUtils.mapValue(jsonData["ring"]));
      bool exists = data != null && WellnessRings().wellnessRings!= null && WellnessRings().wellnessRings!.any((var ring) => ring.id == data.id); //TODO remove check by id if it comes from server (check by name)
      if((data!=null && !exists)|| data == null){
        content.add(_WellnessRingButton(
            label: JsonUtils.stringValue(jsonData["name"])??"",
            toggled: _selectedButton == jsonData,
            description: JsonUtils.stringValue(jsonData["description"]),
            onTapWidget: (context){
              _selectedButton = jsonData;
              _refreshState();
            }));
        content.add(Container(height: 10,));
      }
    }

    return Container(
      child: Column(children: content,),
    );
  }

  void _openDetailPanel(){
    Navigator.push(context, CupertinoPageRoute(builder: (context) =>
        WellnessRingCreatePanel(
            data: WellnessRingData.fromJson(JsonUtils.mapValue(_selectedButton?["ring"])),
            examplesText: JsonUtils.stringValue(_selectedButton?["example"]),
        ))).
      then((success){
        if( success == true){
          Navigator.pop(context);
        }
    });
  }

  void _refreshState(){
    if(mounted){
      setState(() {});
    }
  }

  @override
  void onNotification(String name, param) {
    if(name == WellnessRings.notifyUserRingsUpdated){
      if(mounted) {
        setState(() {});
      }
    }
  }
}

//WellnessRingButton
class _WellnessRingButton extends StatefulWidget{
  final String label;
  final String? description;
  final bool toggled;
  final void Function(BuildContext context) onTapWidget;
  final void Function(BuildContext context)? onTapRightWidget;

  const _WellnessRingButton({Key? key, required this.label, this.description, required this.onTapWidget, this.onTapRightWidget, required this.toggled}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WellnessRingButtonState();

}

class _WellnessRingButtonState extends State<_WellnessRingButton>{

  @override
  Widget build(BuildContext context) {
    return Semantics(label: widget.label, hint: widget.description, button: true, excludeSemantics: true, child:
    GestureDetector(onTap: () => widget.onTapWidget(context), child:
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child:
      Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), child:
      Column(children: [
        Row(children: <Widget>[
          Expanded(
            child: Text(widget.label , style: TextStyle(color: Styles().colors!.fillColorPrimary!, fontFamily: Styles().fontFamilies!.bold, fontSize: 16), textAlign: TextAlign.start,),
          ),
          Container(
            child: _buildRadioButton(color: Styles().colors!.fillColorPrimary!),
          )
        ],),
        Row(
          children: [
            Expanded(
              child: Text(widget.description ?? "" , style: TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 14), textAlign: TextAlign.start),
            ),
          ],
        )
      ],)
      ),
      )
      ),
    ],),
    ),
    );
  }

  Widget _buildRadioButton ({required Color color, Color background = Colors.white,  Color dotColor = Colors.red,}){
    const double WIDGET_SIZE = 25;
    const double STROKE_SIZE = 2;
    const double PADDING_SIZE = 4;

    return Container(
        width: WIDGET_SIZE,
        height: WIDGET_SIZE,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        padding: EdgeInsets.all(STROKE_SIZE),
        child: Container(
          // width: WIDGET_SIZE - STROKE_SIZE,
          // height: WIDGET_SIZE - STROKE_SIZE,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
          ),
          padding: EdgeInsets.all(PADDING_SIZE),
          child:  Visibility(
            visible: widget.toggled,
            child: Container(
            // width: WIDGET_SIZE - STROKE_SIZE,
            // height: WIDGET_SIZE - STROKE_SIZE,
            decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: dotColor,
            ),))
        )
    );
  }
}