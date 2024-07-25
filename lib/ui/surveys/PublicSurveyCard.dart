import 'package:flutter/material.dart';
import 'package:rokwire_plugin/model/survey.dart';
import 'package:rokwire_plugin/service/localization.dart';
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
        Padding(padding: _contentPadding, child:
          _displayContentWidget,
        )
      ),
    );

  Widget get _displayContentWidget {
    switch (displayMode) {
      case PublicSurveyCardDisplayMode.list: return _listContentWidget;
      case PublicSurveyCardDisplayMode.page: return _pageContentWidget;
    }
  }

  Widget get _listContentWidget => Row(children: [
    Expanded(child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        _titleWidget,
        if (_estimatedCompletionTime > 0)
          _estimatedCompletionTimeWidget
      ],)
    ),
    Padding(padding: const EdgeInsets.only(left: 8), child:
      Styles().images.getImage('chevron-right-bold'),
    ),
  ],);

  Widget get _pageContentWidget => Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
    _titleWidget,
    Container(padding: const EdgeInsets.only(top: 16), alignment: Alignment.centerRight, child:
      _estimatedCompletionTimeWidget,
    ),
  ],);

  Widget get _titleWidget =>
    RichText(textAlign: TextAlign.left, text: TextSpan(children:<InlineSpan>[
      TextSpan(text: survey.title, style: Styles().textStyles.getTextStyle('widget.card.title.small.fat'),),
      if (survey.completed == true)
        TextSpan(
          text: Localization().getStringEx('widget.public_survey.label.completed_suffix', ' (Completed)'),
          style: Styles().textStyles.getTextStyle('widget.label.regular.variant.fat'),
        ),
    ]));
  
  Widget get _estimatedCompletionTimeWidget =>
    Text(_estimatedCompletionTimeText, style: Styles().textStyles.getTextStyle('widget.info.small.medium_fat'),);

  String get _estimatedCompletionTimeText {
    if (_estimatedCompletionTime > 1) {
      final String _valueMacro = '{{estimated_completion_time}}';
      return Localization().getStringEx('widget.public_survey.label.estimated_completion_time.more', '$_valueMacro minutes to complete').
        replaceAll(_valueMacro, _estimatedCompletionTime.toString());
    }
    else if (_estimatedCompletionTime == 1) {
      return Localization().getStringEx('widget.public_survey.label.estimated_completion_time.one', 'A minute to complete');
    }
    else {
      return '';
    }
  }

  int get _estimatedCompletionTime => survey.estimatedCompletionTime ?? 0;

  EdgeInsets get _contentPadding {
    switch (displayMode) {
      case PublicSurveyCardDisplayMode.list: return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
      case PublicSurveyCardDisplayMode.page: return const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    }
  }

  static Decoration get contentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: contentBorderRadius,
    border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static BorderRadiusGeometry get contentBorderRadius => BorderRadius.all(Radius.circular(8));
}

