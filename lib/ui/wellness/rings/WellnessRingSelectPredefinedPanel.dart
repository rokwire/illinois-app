import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessRing.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/wellness/rings/WellnessRingCreatePane.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/SmallRoundedButton.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';


class WellnessRingSelectPredefinedPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _WellnessRingSelectPredefinedPanelState();
}

class _WellnessRingSelectPredefinedPanelState extends State<WellnessRingSelectPredefinedPanel> implements NotificationsListener{
  static const List<Map<String,dynamic>> PREDEFINED_RING_BUTTONS = [
    {"ring":{'name': "Hobby", 'value': 1, 'color_hex': '#f5821e', 'ring_id': "id_predefined_0", 'unit':'session'},
      "name":"Hobby Ring",
      "description":"Use this ring to motivate you to engage in a hobby in some way every day. It’s important to have your own free time, even if it’s only for a couple minutes.",
      "example": "Examples include reading, sketching, playing an instrument, or whatever hobbies you enjoy!"},
    {"ring":{'name': "Movement", 'value': 1, 'color_hex': '#54a747', 'ring_id': "id_predefined_1", 'unit':'activity'},
      "name":"Movement Ring",
      "description":"Use this ring to motivate you to do something active every day, even if it's daily stretching or taking a short walk! A small amount of physical activity every day can improve your overall mood and motivation.",
      "example":"Examples include going on a walk, rock climbing, dancing, stretching, or whatever exercise you enjoy!"},
    {"ring":{'name': "Mindfulness", 'value': 1, 'color_hex': '#09fd4' , 'ring_id': "id_predefined_2", 'unit':'moment'},
      "name":"Mindfulness",
      "description":"Use this ring to motivate you to focus on the present moment. Taking even a small amount of time for intentional practice, like journaling or breathing exercises, can help reduce overall stress.",
      "example": "Examples include journaling, breathing exercises, meditation, or whatever mindful practice you enjoy!"},
    {"name" : "Custom Ring",
      "description":"Create a ring for whatever habit you want to build or maintain for yourself! Ex: use this ring to motivate you to drink water every day!",
      "example": "Examples could include drinking a certain amount of water throughout the day, taking your daily vitamin, etc."},
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      Container(height: 14,),
                      // WellnessWidgetHelper.buildWellnessHeader(),
                      Container(height: 16,),
                      Container(
                        child: Text(Localization().getStringEx('panel.wellness.ring.select.description', 'Select a ring type or create your own custom ring.'),
                          style: Styles().textStyles?.getTextStyle('panel.wellness.ring.select_predefined.message.regular')
                      )),
                      Container(height: 12,),
                      _buildPredefinedButtons(),
                      Container(height: 12,),
                    ]))),
          ),
          Container(height: 30,),
          Container(
            child: SmallRoundedButton(label: 'Next', onTap: _openDetailPanel, backgroundColor: Colors.white, rightIconPadding: EdgeInsets.only(right: 16, left: 16, ), padding: EdgeInsets.symmetric(horizontal: 32, vertical: 6),
              enabled: _nextButtonEnabled,
              borderColor: _nextButtonEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.disabledTextColorTwo,
              textStyle: _nextButtonEnabled ? Styles().textStyles?.getTextStyle("widget.button.title.enabled") : Styles().textStyles?.getTextStyle("widget.button.disabled.title.medium.fat.variant_two"),
              rightIcon: Styles().images?.getImage(_nextButtonEnabled ? 'chevron-right-bold' : 'chevron-right-gray', excludeFromSemantics: true),
            ),
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
    for(Map<String, dynamic> jsonData in PREDEFINED_RING_BUTTONS){  WellnessRingDefinition? data = WellnessRingDefinition.fromJson(JsonUtils.mapValue(jsonData["ring"]));
      bool exists = data != null && WellnessRings().wellnessRings!= null && WellnessRings().wellnessRings!.any((var ring) => ring.name == data.name); //TODO remove check by id if it comes from server (check by name)
      if((data!=null && !exists)|| data == null){
        content.add(_WellnessRingButton(
            label: JsonUtils.stringValue(jsonData["name"])??"",
            toggled: _selectedButton == jsonData,
            description: JsonUtils.stringValue(jsonData["description"]),
            onTapWidget: (_) => _onButton(jsonData)
        ));
        content.add(Container(height: 20,));
      }
    }

    return Container(
      child: Column(children: content,),
    );
  }

  void _onButton(Map<String, dynamic> jsonData) {
    Analytics().logSelect(target: JsonUtils.stringValue(jsonData["name"]));
    _selectedButton = jsonData;
    _refreshState();
  }

  void _openDetailPanel(){
    Analytics().logSelect(target: 'Next');
    if(_selectedButton == null){
      return;
    }
    Navigator.push(context, CupertinoPageRoute(builder: (context) =>
        WellnessRingCreatePanel(
            data: WellnessRingDefinition.fromJson(JsonUtils.mapValue(_selectedButton?["ring"])),
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

  bool get _nextButtonEnabled{
    return _selectedButton != null;
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

  // ignore: unused_element
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
      Padding(padding: EdgeInsets.only(right: 19, left: 16, top:13, bottom: 19), child:
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Expanded(
            child:
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.label , style: Styles().textStyles?.getTextStyle('anel.wellness.ring.select_predefined.button.label.regular'), textAlign: TextAlign.start,),
                Container(height: 12,),
                Text(widget.description ?? "" , style: Styles().textStyles?.getTextStyle('panel.wellness.ring.select_predefined.button.description.regular'), textAlign: TextAlign.start),
          ])),
          Container(width: 7,),
          Container(
            child: _buildRadioButton(color: Styles().colors!.fillColorPrimary!),
          )
        ],),
      ),
      )
      ),
    ],),
    ),
    );
  }

  Widget _buildRadioButton ({required Color color, Color background = Colors.white,  Color dotColor = Colors.red,}){
    const double WIDGET_SIZE = 24;
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