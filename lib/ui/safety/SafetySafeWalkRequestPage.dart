
import 'package:flutter/material.dart';
import 'package:illinois/ui/safety/SafetyHomePanel.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';

class SafetySafeWalkRequestPage extends StatelessWidget with SafetyHomeContentPage {

  @override
  Widget build(BuildContext context) => Column(children: [
    _mainLayer,
    _detailsLayer,
  ],);

  @override
  Color get safetyPageBackgroundColor => Styles().colors.fillColorPrimaryVariant;
  
  Widget get _mainLayer => Container(color: safetyPageBackgroundColor, child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(left: 16, top: 32), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.symmetric(vertical: 8), child:
              Text(Localization().getStringEx('panel.safewalks_request.header.title', 'SafeWalks'), style: _titleTextStyle,)
            ),
          ),
          InkWell(onTap: _onTapMore, child:
            Padding(padding: EdgeInsets.all(16), child:
              Styles().images.getImage('more-white', excludeFromSemantics: true)
            )
          )
        ],),
      ),
      Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(Localization().getStringEx('panel.safewalks_request.sub_title1.text', 'Trust your instincts.'), style: _subTitleTextStyle,),
          Text(Localization().getStringEx('panel.safewalks_request.sub_title2.text', 'You never have to walk alone.'), style: _subTitleTextStyle,),
          Container(height: 12,),
          Text(Localization().getStringEx('panel.safewalks_request.info1.text', 'Request a student patrol officer to walk with you.'), style: _infoTextStyle,),
          Text(Localization().getStringEx('panel.safewalks_request.info2.text', 'Please give at least 15 minutes\' notice.'), style: _infoTextStyle,),
          Container(height: 6,),
          Text(Localization().getStringEx('panel.safewalks_request.info3.text', 'Available 9:00 p.m. to 2:30 a.m.'), style: _infoTextStyle,),
        ])
      ),
      Stack(children: [
        Positioned.fill(child:
          Column(children: [
            Expanded(child:
              Container()
            ),
            CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background, horzDir: TriangleHorzDirection.rightToLeft), child:
              Container(height: 45,),
            ),
          ],)
        ),
        Padding(padding: EdgeInsets.only(left: 16, right: 16), child:
          SafetySafeWalkRequestCard(),
        ),
      ],),
    ],)
  );

  TextStyle? get _titleTextStyle => Styles().textStyles.getTextStyle('widget.heading.extra2_large.extra_fat');
  TextStyle? get _subTitleTextStyle => Styles().textStyles.getTextStyle('panel.safewalks_request.sub_title');
  TextStyle? get _infoTextStyle => Styles().textStyles.getTextStyle('panel.safewalks_request.info');

  Widget get _detailsLayer => Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 32,), child:
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

    ],)
  );

  void _onTapMore() {

  }
}

class SafetySafeWalkRequestCard extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _SafetySafeWalkRequestCardState();
}

class _SafetySafeWalkRequestCardState extends State<SafetySafeWalkRequestCard> {
  @override
  Widget build(BuildContext context) => Container(decoration: _cardDecoration, height: 300,);

  BoxDecoration get _cardDecoration => BoxDecoration(
    color: Styles().colors.background,
    border: Border.all(color: Styles().colors.mediumGray2, width: 1),
    borderRadius: BorderRadius.all(Radius.circular(16))
  );
}