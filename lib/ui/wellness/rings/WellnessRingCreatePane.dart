import 'package:flutter/material.dart';
import 'package:illinois/ui/wellness/WellnessRingsHomeContentWidget.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class WellnessRingCreatePanel extends StatefulWidget{
  final WellnessRingData? data;
  final bool initialCreation;

  const WellnessRingCreatePanel({Key? key, this.data, this.initialCreation = true}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WellnessRingCreatePanelState();
}

class _WellnessRingCreatePanelState extends State<WellnessRingCreatePanel>{
   WellnessRingData? _data;

  @override
  void initState() {
    super.initState();
    //TBD listener
    _data = WellnessRingData.fromJson({});
    if(widget.data!=null){
      _data?.updateFromOther(widget.data!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: _headingTitle),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
                child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(children: [
                      Center(child: Text("TBD \n In progress..."),),
                Container(height: 10,),
                Center(child: Text(widget.data?.name ?? "New"),)

                    ]))),
          ),
          Container(height: 30,),
          Container(
            child: RoundedButton(label:_buttonTitle, onTap: _onTapContinue, backgroundColor: Colors.white, rightIconPadding: EdgeInsets.only(right: 16, left: 16,), padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),),
          ),
          Container(height: 50,)
        ],
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  void _onTapContinue(){
    if(_data!= null)
      WellnessRingService().addRing(_data!);
    Navigator.of(context).pop();
  }

  String get _buttonTitle{
    return widget.initialCreation? Localization().getStringEx('panel.wellness.ring.create.button.title.create',"Create") :
      Localization().getStringEx('panel.wellness.ring.create.heading.title.update',"Update");
  }

  String get _headingTitle{
    return widget.initialCreation? Localization().getStringEx('panel.wellness.ring.create.button.title.create',"Create Wellness Ring") :
      Localization().getStringEx('panel.wellness.ring.create.heading.title.create',"Update Wellness Ring");
  }
}