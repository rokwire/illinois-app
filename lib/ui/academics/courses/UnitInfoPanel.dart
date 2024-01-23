
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

import '../../../model/courses/Content.dart';
import '../../widgets/HeaderBar.dart';

class UnitInfoPanel extends StatefulWidget {
  final Content? content;
  final Color? color;
  final Color? colorAccent;
  const UnitInfoPanel({required this.content, required this.color, required this.colorAccent});

  @override
  State<UnitInfoPanel> createState() => _UnitInfoPanelState();
}

class _UnitInfoPanelState extends State<UnitInfoPanel> implements NotificationsListener {

  late Content _content;
  late Color? _color;
  late Color? _colorAccent;

  @override
  void initState() {
    _content = widget.content!;
    _color = widget.color!;
    _colorAccent = widget.colorAccent!;

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('', 'Daily Activities'),
        textStyle: Styles().textStyles?.getTextStyle('header_bar'),),
      body: Column(
        children: _buildUnitInfoWidgets(),
      ),
      backgroundColor: _color,
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
                // elevated button
                child: Stack(
                  children: [
                    bigCircle,
                    Padding(
                      padding: EdgeInsets.only(top: 4, left: 4),
                      child: ElevatedButton(
                        onPressed: () {},
                        // icon of the button
                        child: Padding(
                          padding: EdgeInsets.all(4),
                          child: Styles().images?.getImage("skills-question") ?? Container(),
                        ),
                        // styling the button
                        style: ElevatedButton.styleFrom(
                          shape: CircleBorder(),
                          padding: EdgeInsets.all(8),
                          // Button color
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
                  child: Text(_content.name?.toUpperCase() ?? "Name", style: Styles().textStyles?.getTextStyle("widget.title.light.huge.fat")),
                )
              ),
              Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(_content.details ?? "details", style: Styles().textStyles?.getTextStyle("widget.title.light.large")),
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
            label: Localization().getStringEx('panel.trial.button.continue.label', 'Continue'),
            textStyle: Styles().textStyles?.getTextStyle("widget.title.light.regular.fat"),
            backgroundColor: _colorAccent,
            borderColor: _colorAccent,
            onTap: ()=> Navigator.pop(context)),
      )
    );

    //TODO add any extra content i.e. videos and files
    return widgets;
  }

  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }
  
}