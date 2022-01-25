import 'package:flutter/material.dart';
import 'package:illinois/model/Canvas.dart';
import 'package:illinois/service/Styles.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class CanvasCourseCard extends StatelessWidget {
  final CanvasCourse course;

  CanvasCourseCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final Color defaultColor = Colors.black;
    const double cardHeight = 166;
    double cardInnerPadding = 10;
    //TBD: check from which field to take this value
    String completionPercentage = _formatDecimalValue(0);
    Color? mainColor = StringUtils.isNotEmpty(course.courseColor) ? UiColors.fromHex(course.courseColor!) : defaultColor;
    if (mainColor == null) {
      mainColor = defaultColor;
    }
    return Container(
        height: cardHeight,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: Container(color: mainColor, child: Padding(
                  padding: EdgeInsets.only(left: cardInnerPadding, top: cardInnerPadding),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        padding: EdgeInsets.symmetric(vertical: 2, horizontal: 6),
                        decoration: BoxDecoration(borderRadius: BorderRadius.circular(10), color: Styles().colors!.white),
                        child:
                        Text('$completionPercentage%', style: TextStyle(color: mainColor, fontSize: 16, fontFamily: Styles().fontFamilies!.bold)))
                  ])))),
          Expanded(
              child: Container(color: Styles().colors!.white, child: Padding(
                  padding: EdgeInsets.all(cardInnerPadding),
                  child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(StringUtils.ensureNotEmpty(course.name),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: mainColor, fontSize: 18, fontFamily: Styles().fontFamilies!.extraBold)),
                    Text(StringUtils.ensureNotEmpty(course.courseCode),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Styles().colors!.textSurface, fontSize: 16, fontFamily: Styles().fontFamilies!.bold))
                  ]))]))))
        ]));
  }

  String _formatDecimalValue(double num, {int minimumFractionDigits = 0, int maximumFractionDigits = 2}) {
    NumberFormat numFormatter = NumberFormat();
    numFormatter.minimumFractionDigits = minimumFractionDigits;
    numFormatter.maximumFractionDigits = maximumFractionDigits;
    return numFormatter.format(num);
  }
}
