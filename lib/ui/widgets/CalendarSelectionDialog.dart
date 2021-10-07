
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/DeviceCalendar.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/model/Event.dart' as ExploreEvent;

import 'RoundedButton.dart';

class CalendarSelectionDialog extends StatefulWidget {
  final List<Calendar> calendars;
  final Function onContinue;

  const CalendarSelectionDialog({Key key, this.calendars, this.onContinue}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CalendarSelectionDialogState();

  static void show({@required BuildContext context, List<Calendar> calendars, Function onContinue}){
    if(calendars == null || calendars.isEmpty){
      return;
    }

    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return CalendarSelectionDialog(calendars: calendars, onContinue: onContinue,);
        });
  }
}

class _CalendarSelectionDialogState extends State<CalendarSelectionDialog>{
  Calendar _selectedCalendar;

  @override
  void initState() {
    _selectedCalendar = DeviceCalendar().calendar;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return widget.calendars.length == 0
        ? Container()
        :
    AlertDialog(
        content:
        Row(children:[
          Expanded(child:
          Container(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey,
                    ),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: widget.calendars.length,
                    itemBuilder: (BuildContext context, int index) {
                      return new InkWell(
                        //highlightColor: Colors.red,
                        //splashColor: Colors.blueAccent,
                        onTap: () {
                          setState(() {
                            _selectedCalendar = widget.calendars[index];
                          });
                        },
                        child: _buildItem(widget.calendars[index]),
                      );
                    },
                  ),
                  Container(height: 10,),
                  RoundedButton(label: "Choose",
                    onTap: () {
                      if (widget.onContinue != null) {
                        widget.onContinue(_selectedCalendar);
                      }
                    }
                  )
                ],
              )
          )
          )]));
  }

  Widget _buildItem(Calendar calendar){
    return Container(
      padding:
      const EdgeInsets.only(left: 8.0, right: 8.0, top: 3.0, bottom: 3.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Expanded(
              child:Text(
                  calendar.name
              )),
          calendar.id == _selectedCalendar.id
              ? Icon(
            Icons.radio_button_checked,
            color: Styles().colors.fillColorPrimary,
          )
              : Icon(Icons.radio_button_unchecked),
        ],
      ),
    );
  }

}