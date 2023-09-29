import 'package:flutter/material.dart';
import 'package:illinois/model/Occupation.dart';
import 'package:illinois/service/Occupations.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:url_launcher/url_launcher_string.dart';

class SkillsSelfEvaluationOccupationDetails extends StatelessWidget {
  SkillsSelfEvaluationOccupationDetails({Key? key, required this.occupationMatch, required this.percentages}) : super(key: key);

  final OccupationMatch occupationMatch;
  final Map<String, num> percentages;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors?.background,
      appBar: HeaderBar(title: Localization().getStringEx('panel.skills_self_evaluation.occupation_details.header.title', 'Skills Self-Evaluation')),
      body: FutureBuilder(
          future: Occupations().getOccupation(occupationCode: occupationMatch.occupation?.code ?? ""),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data == null) {
              return Center(
                child: Text(
                  Localization().getStringEx('panel.skills_self_evaluation.occupation_details.unavailable.message', 'Failed to get occupation data. Please retry.'),
                  textAlign: TextAlign.center,
                  style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
                ),
              );
            }
            final Occupation occupation = snapshot.data as Occupation;
            return SingleChildScrollView(
              child: SectionSlantHeader(
                headerWidget: _buildHeader(occupation),
                slantColor: Styles().colors?.gradientColorPrimary,
                slantPainterHeadingHeight: 0,
                backgroundColor: Styles().colors?.background,
                children: Connectivity().isOffline ? _buildOfflineMessage() : _buildContent(context, occupation),
                childrenPadding: const EdgeInsets.only(top: 40, left: 24, right: 24, bottom: 24),
                childrenAlignment: CrossAxisAlignment.start,
                allowOverlap: !Connectivity().isOffline,
              ),
            );
          }),
    );
  }

  Widget _buildHeader(Occupation occupation) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
            Styles().colors?.gradientColorPrimary ?? Colors.transparent,
          ])),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(
              occupation.name!,
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.get_started.header'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              "Match Percentage: ${occupationMatch.matchPercent!.toInt()}%",
              style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            child: LinearProgressIndicator(
              backgroundColor: LinearProgressColorUtils.linearProgressIndicatorBackgroundColor(
                occupationMatch.matchPercent! / 100.0,
              ),
              color: LinearProgressColorUtils.linearProgressIndicatorColor(
                occupationMatch.matchPercent! / 100.0,
              ),
              minHeight: 20,
              value: occupationMatch.matchPercent! / 100,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16.0),
            child: Text(occupation.description!,
                textAlign: TextAlign.center, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description')),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(BuildContext context, Occupation occupation) {
    return [
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(
          Localization().getStringEx('panel.skills_self_evaluation.occupation_details.section.title', 'Your Results'),
          style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title')
        ),
      ),
      Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
        title: Text(
          Localization().getStringEx('panel.skills_self_evaluation.occupation_details.work_styles.title', 'Work Styles'),
          style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
        ),
        tilePadding: EdgeInsets.zero,
        children: [_buildScoresHeader()] + occupation.workStyles!.map((workstyle) => WorkStyleListTile(workstyle: workstyle, percentages: percentages)).toList(),
        iconColor: Styles().colors?.getColor('fillColorPrimary'),
        collapsedIconColor: Styles().colors?.getColor('fillColorPrimary'),
      )),
      Theme(data: Theme.of(context).copyWith(dividerColor: Colors.transparent), child: ExpansionTile(
        title: Text(
          Localization().getStringEx('panel.skills_self_evaluation.occupation_details.tech_skills.title', 'Technology Skills'),
          style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
        ),
        tilePadding: EdgeInsets.zero,
        children: occupation.technologySkills!.map((e) => TechnologySkillListTile(technologySkill: e)).toList(),
        iconColor: Styles().colors?.getColor('fillColorPrimary'),
        collapsedIconColor: Styles().colors?.getColor('fillColorPrimary'),
      )),
      Center(
        child: Padding(padding: const EdgeInsets.only(top: 16), child: InkWell(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: Localization().getStringEx('panel.skills_self_evaluation.occupation_details.learn_more.title', 'Learn More'),
                  style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.link'),
                ),
                WidgetSpan(
                  child: Padding(padding: const EdgeInsets.only(left: 4.0), child: Styles().images?.getImage('external-link', excludeFromSemantics: true)),
                ),
              ],
            ),
          ),
          onTap: () {
            launchUrlString('https://onetonline.org/link/summary/${occupation.code}', mode: LaunchMode.externalApplication);
          },
        ),),
      ),
    ];
  }

  Widget _buildScoresHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Divider(color: Styles().colors?.fillColorPrimary, thickness: 2),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Flexible(flex: 2, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.occupation_details.work_style_name.title', 'NAME'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header.dark'),)),
          Flexible(flex: 1, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.occupation_details.survey_scores.title', 'YOUR SCORE'), style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header.dark'),)),
          Flexible(flex: 1, fit: FlexFit.tight, child: Text(Localization().getStringEx('panel.skills_self_evaluation.occupation_details.importance.title', 'IMPORTANCE'), textAlign: TextAlign.right, style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header.dark'),)),
        ],)),
      ],
    );
  }

  List<Widget> _buildOfflineMessage() {
    return [
      Padding(
        padding: EdgeInsets.all(28),
        child: Center(
            child: Text(
                Localization().getStringEx(
                    'panel.skills_self_evaluation.occupation_details.offline.error.msg', 'Results not available while offline.'),
                textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'))),
      ),
    ];
  }
}

class WorkStyleListTile extends StatelessWidget {
  const WorkStyleListTile({Key? key, required this.workstyle, required this.percentages, this.mostRecentScore, this.comparisonScore})
      : super(key: key);

  final WorkStyle workstyle;
  final Map<String, num> percentages;
  final int? mostRecentScore;
  final int? comparisonScore;

  @override
  Widget build(BuildContext context) {
    String? bessiPercent;
    if (percentages[workstyle.bessiSection] != null) {
      bessiPercent = (percentages[workstyle.bessiSection]! * 100).toStringAsFixed(0);
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
                child: Row(
                  children: [
                    Flexible(
                        flex: 5,
                        fit: FlexFit.tight,
                        child: Text(workstyle.name ?? '', style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'))
                    ),
                    Flexible(
                        flex: 3,
                        fit: FlexFit.tight,
                        child: Text(bessiPercent ?? '--', style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.score.current'), textAlign: TextAlign.center,)
                    ),
                    Flexible(
                        flex: 3,
                        fit: FlexFit.tight,
                        child: Text(workstyle.value?.toStringAsFixed(0) ?? '--', style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.score.past'), textAlign: TextAlign.center)
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TechnologySkillListTile extends StatelessWidget {
  const TechnologySkillListTile({Key? key, required this.technologySkill}) : super(key: key);

  final TechnologySkill technologySkill;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '\u2022 ' + technologySkill.name.toString(),
              textAlign: TextAlign.start,
              style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.body'),
            ),
          ),
        ],
      ),
    );
  }
}
