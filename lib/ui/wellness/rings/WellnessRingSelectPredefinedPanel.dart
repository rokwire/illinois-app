import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/wellness/WellnessRingsHomeContentWidget.dart';
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
  WellnessRingData? _selectedRing;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      WellnessRingService.notifyUserRingsUpdated,
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
                      _WellnessRingButton(
                        label: "Create New Ring",
                        description: "Maximum of 4 total",
                        onTapWidget: (context){
                          Analytics().logSelect(target: "Custom ring");
                          _selectedRing = null;
                          _refreshState();
                        }, showLeftIcon: true,),

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
    for(Map<String, dynamic> jsonData in WellnessRingService.predefinedRings){
      WellnessRingData? data = WellnessRingData.fromJson(jsonData);
      bool exists = data != null && WellnessRingService().wellnessRings!= null && WellnessRingService().wellnessRings!.any((var ring) => ring.id == data.id); //TODO remove check by id if it comes from server (check by name)
      if(data!=null && ! exists){
        content.add(_WellnessRingButton(
            label: data.name??"",
            color: data.color,
            description: JsonUtils.stringValue(jsonData["description"]),
            showRightIcon: true,
            onTapWidget: (context){
              _selectedRing = data;
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
    Navigator.push(context, CupertinoPageRoute(builder: (context) => WellnessRingCreatePanel(data: _selectedRing )));
  }

  void _refreshState(){
    if(mounted){
      setState(() {});
    }
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

//WellnessRingButton
class _WellnessRingButton extends StatefulWidget{
  final String label;
  final String? description;
  final bool showLeftIcon;
  final bool showRightIcon;
  final Color? color;
  final void Function(BuildContext context) onTapWidget;
  final void Function(BuildContext context)? onTapRightWidget;

  const _WellnessRingButton({Key? key, required this.label, this.description, this.showLeftIcon = false, this.showRightIcon = false, this.color, required this.onTapWidget, this.onTapRightWidget}) : super(key: key);

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
        onTap: (){ if (widget.onTapRightWidget!=null) widget.onTapRightWidget!(this.context);},
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Image.asset('images/icon-gear.png', excludeFromSemantics: true, color:  Styles().colors!.white!),
        ));
  }
}