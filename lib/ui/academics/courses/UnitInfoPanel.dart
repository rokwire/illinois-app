import 'package:flutter/material.dart';
import 'package:illinois/model/CustomCourses.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class UnitInfoPanel extends StatefulWidget {
  final Content content;
  final Map<String, dynamic>? data;
  final Color? color;
  final Color? colorAccent;
  const UnitInfoPanel({required this.content, required this.data, required this.color, required this.colorAccent});

  @override
  State<UnitInfoPanel> createState() => _UnitInfoPanelState();
}

class _UnitInfoPanelState extends State<UnitInfoPanel> implements NotificationsListener {
  late Content _content;
  Map<String, dynamic>? _data;
  Color? _color;
  Color? _colorAccent;

  @override
  void initState() {
    _content = widget.content;
    _data = widget.data != null ? Map.of(widget.data!) : null;
    _color = widget.color!;
    _colorAccent = widget.colorAccent!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: _saveProgress,
      child: Scaffold(
        appBar: HeaderBar(title: _content.name, textStyle: Styles().textStyles.getTextStyle('header_bar'), onLeading: () => _saveProgress(false),),
        body: Column(
          children: _buildUnitInfoWidgets(),
        ),
        backgroundColor: _color,
      )
    );
  }

  List<Widget> _buildUnitInfoWidgets(){
    Widget bigCircle = new Container(
      width: 93.0,
      height: 93.0,
      decoration: new BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );


    List<Widget> widgets = <Widget>[];
    widgets.add(
      SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            children: [
              Center(
                child: Stack(
                  children: [
                    bigCircle,
                    Padding(
                      padding: EdgeInsets.only(top: 4, left: 4),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Styles().images.getImage(_content.display?.icon) ?? Container(),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(8),
                          backgroundColor: _colorAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(_content.name?.toUpperCase() ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                )
              ),
              Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(_content.details ?? "", style: Styles().textStyles.getTextStyle("widget.title.light.large")),
                  )
              ),
              //TODO other content to be added here
            ],
          ),
        ),
      )
    );

    widgets.add(Expanded(child: Container(),));
    widgets.add(
      Padding(
        padding: EdgeInsets.all(16),
        child: RoundedButton(
            label: Localization().getStringEx('panel.essential_skills_coach.unit_info.button.continue.label', 'Continue'),
            textStyle: Styles().textStyles.getTextStyle("widget.title.light.regular.fat"),
            backgroundColor: _colorAccent,
            borderColor: _colorAccent,
            onTap: ()=> Navigator.pop(context)),
      )
    );

    //TODO add any extra content i.e. videos and files
    return widgets;
  }

  void _saveProgress(bool didPop) async {
    bool returnData = (_data?['complete'] != true);
    if (returnData) {
      _data ??= {};
      _data!['complete'] = true;
    }
    if (!didPop) {
      Navigator.pop(context, returnData ? _data : null);
    }
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }
  
}