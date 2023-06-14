
import 'package:device_calendar/device_calendar.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/device_calendar.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class CalendarSelectionDialog extends StatefulWidget {
//  final
  final Function? onContinue;

  const CalendarSelectionDialog({Key? key, this.onContinue}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _CalendarSelectionDialogState();

  static void show({required BuildContext context, Function? onContinue}){
    showDialog<void>(
        context: context,
        builder: (BuildContext context) {
          return CalendarSelectionDialog( onContinue: onContinue);
        });
  }
}

class _CalendarSelectionDialogState extends State<CalendarSelectionDialog>{
  Calendar? _selectedCalendar;
  List<Calendar> _calendars = [];

  @override
  void initState() {
    super.initState();
    _selectedCalendar = DeviceCalendar().calendar;
    _refreshCalendars();
  }

  void _refreshCalendars(){
    DeviceCalendar().refreshCalendars().then((value){
      setState(() {
        if(value!=null && value.isNotEmpty) {
          _calendars = value;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return
    AlertDialog(
        content:
        Row(children:[
          Expanded(child:
          Container(
              width: 200,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _calendars.length == 0 ? Container() :
                  ConstrainedBox(
                  constraints:BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height/2,
                    ),
                    child:
                  ListView.separated(
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.grey,
                    ),
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    itemCount: _calendars.length,
                    itemBuilder: (BuildContext context, int index) {
                      return new InkWell(
                        //highlightColor: Colors.red,
                        //splashColor: Colors.blueAccent,
                        onTap: () {
                          setState(() {
                            _selectedCalendar = _calendars[index];
                          });
                        },
                        child: _buildItem(_calendars[index]),
                      );
                    },
                  )),
                  Container(height: 10,),
                  RoundedButton(label: "Choose",
                    textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
                    borderColor: Styles().colors!.fillColorPrimary,
                    backgroundColor: Styles().colors!.fillColorPrimary,
                    onTap: () {
                      if (widget.onContinue != null) {
                        widget.onContinue!(_selectedCalendar);
                      }
                    }
                  ),
                  Container(height: 10,),
                  RoundedButton(label: "Refresh",
                    textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
                    borderColor: Styles().colors!.fillColorPrimary,
                    backgroundColor: Styles().colors!.fillColorPrimary,
                    onTap: () {
                      _refreshCalendars();
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
                  calendar.name!
              )),
          calendar.id == _selectedCalendar!.id
              ? Icon(
            Icons.radio_button_checked,
            color: Styles().colors!.fillColorPrimary,
          )
              : Icon(Icons.radio_button_unchecked),
        ],
      ),
    );
  }

}