import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:table_calendar/table_calendar.dart';

class StreakPanel extends StatefulWidget {
  
  const StreakPanel();

  @override
  State<StreakPanel> createState() => _StreakPanelState();
}

class _StreakPanelState extends State<StreakPanel> implements NotificationsListener {

  List<DateTime> _selectedDays = [ DateTime.utc(2024, 1, 22),  DateTime.utc(2024, 1, 23),];

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Widget bigCircle = new Container(
      width: 100.0,
      height: 100.0,
      decoration: new BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('', 'Streak'),
        textStyle: Styles().textStyles.getTextStyle('header_bar'),),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          bigCircle,
                          Padding(
                            padding: const EdgeInsets.only(left: 24),
                            child: Text("2", style: TextStyle(fontSize: 80, color: Styles().colors.fillColorPrimary)),
                          )
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text("Day Streak!", style: Styles().textStyles.getTextStyle("widget.title.light.huge.fat")),
                      )
                    ],
                  ),
                  Container(
                    child: Styles().images.getImage("streak") ?? Container(),
                  )
                ],
              ),

            ),

            Padding(
              padding:EdgeInsets.only(left: 24, top: 16),
              child:Text("Calender", style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")),

            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Styles().colors.surfaceAccent),
                  borderRadius: BorderRadius.all(
                      Radius.circular(5.0) //                 <--- border radius here
                  ),
                ),
                child: TableCalendar(
                  selectedDayPredicate: (day){
                    return _selectedDays.contains(day);
                  },
                  headerStyle: HeaderStyle(
                    titleCentered: true,
                    titleTextStyle: Styles().textStyles.getTextStyle("widget.title.light.large.fat") ?? TextStyle(),
                    leftChevronIcon: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white,
                    ),
                    rightChevronIcon: Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                    )
                  ),
                  availableCalendarFormats: const {
                    CalendarFormat.month : 'Month'
                  },
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: Styles().textStyles.getTextStyle("widget.title.light.little.fat") ?? TextStyle(),
                    weekendStyle: Styles().textStyles.getTextStyle("widget.title.light.little.fat") ?? TextStyle(),
                  ),
                  calendarStyle: CalendarStyle(
                    defaultTextStyle:Styles().textStyles.getTextStyle("widget.title.light.little.fat") ?? TextStyle(),
                    weekendTextStyle: Styles().textStyles.getTextStyle("widget.title.light.little.fat") ?? TextStyle(),
                    todayDecoration: BoxDecoration(color: Styles().colors.surfaceAccent, shape: BoxShape.circle),
                    todayTextStyle: TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16.0),
                    selectedDecoration: BoxDecoration(color: Styles().colors.fillColorPrimaryTransparent03, shape: BoxShape.circle),
                  ),
                  firstDay: DateTime.utc(2010, 10, 16),
                  lastDay: DateTime.utc(2030, 3, 14),
                  focusedDay: DateTime.now(),
                ),
              ),
            ),

            Padding(
              padding:EdgeInsets.only(left: 24, top: 16),
              child:Text("Pauses", style: Styles().textStyles.getTextStyle("widget.title.light.large.fat")),

            ),
          ],
        ),
      ),
      backgroundColor: Styles().colors.fillColorPrimary,
    );
  }
  @override
  void onNotification(String name, param) {
    // TODO: implement onNotification
  }
  
}