import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/styles.dart';

enum PublicSurveyCardDisplayMode { list, page }

class PublicSurveyCard extends StatelessWidget {
  final Survey survey;
  final PublicSurveyCardDisplayMode displayMode;
  final void Function()? onTap;

  // ignore: unused_element
  PublicSurveyCard(this.survey, { super.key, required this.displayMode, this.onTap });

  factory PublicSurveyCard.listCard(Survey survey, { Key? key, void Function()? onTap }) =>
    PublicSurveyCard(survey, key: key, displayMode: PublicSurveyCardDisplayMode.list, onTap : onTap);

  factory PublicSurveyCard.pageCard(Survey survey, { Key? key, void Function()? onTap }) =>
    PublicSurveyCard(survey, key: key, displayMode: PublicSurveyCardDisplayMode.page, onTap : onTap);

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: onTap, child: _contentWidget);

  Widget get _contentWidget =>
    Container(decoration: contentDecoration, child:
      ClipRRect(borderRadius: contentBorderRadius, child:
        Padding(padding: const EdgeInsets.all(16), child:
          Row(children: [
            Expanded(child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: (displayMode == PublicSurveyCardDisplayMode.list) ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
                Text(survey.title, textAlign: (displayMode == PublicSurveyCardDisplayMode.list) ? TextAlign.left : TextAlign.center, style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),),
                // Build more details here
              ],)
            ),
            if (displayMode == PublicSurveyCardDisplayMode.list)
              Padding(padding: const EdgeInsets.only(left: 8), child:
                  Styles().images.getImage('chevron-right-bold'),
              )
          ],)
        )
      ),
    );

  static Decoration get contentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: contentBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static BorderRadiusGeometry get contentBorderRadius => BorderRadius.all(Radius.circular(8));
}

