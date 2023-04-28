import 'package:flutter/material.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/model/occupation/OccupationMatch.dart';
import 'package:illinois/model/occupation/TechnologySkill.dart';
import 'package:illinois/model/occupation/WorkStyles.dart';
import 'package:illinois/service/OccupationMatching.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';
import 'package:url_launcher/url_launcher_string.dart';

class OccupationDetails extends StatelessWidget {
  OccupationDetails({Key? key, required this.occupationMatch}) : super(key: key);

  final OccupationMatch occupationMatch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Styles().colors?.background,
      appBar: HeaderBar(
        title: 'Occupation Details',
      ),
      body: FutureBuilder(
          future: OccupationMatching().getOccupation(occupationCode: occupationMatch.occupation?.code ?? ""),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data == null) {
              return Center(
                child: Text(
                  'Failed to get occupation data. Please retry.',
                  textAlign: TextAlign.center,
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
                children: Connectivity().isOffline ? _buildOfflineMessage() : _buildContent(occupation),
                childrenPadding: EdgeInsets.zero,
                allowOverlap: !Connectivity().isOffline,
              ),
            );
          }),
    );
  }

  Widget _buildHeader(Occupation occupation) {
    return Container(
      padding: EdgeInsets.all(8.0),
      decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [
            Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
            Styles().colors?.gradientColorPrimary ?? Colors.transparent,
          ])),
      child: Column(
        children: [
          SizedBox(height: 12),
          Text(
            occupation.title!,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 25, color: Colors.white),
          ),
          SizedBox(height: 12),
          Text(
            "Match Percentage: ${occupationMatch.matchPercent!.toInt()}%",
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: ClipRRect(
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
          ),
          SizedBox(height: 12),
          Text(occupation.description!,
              textAlign: TextAlign.center, style: TextStyle(fontFamily: "regular", fontSize: 16, color: Colors.white)),
          SizedBox(height: 12),
        ],
      ),
    );
  }

  List<Widget> _buildContent(Occupation occupation) {
    return [
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 40, bottom: 10),
              child: Text('Your Results'),
            ),
            ExpansionTile(
                title: Text(
                  "Work Styles",
                  style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                ),
                children: occupation.workStyles!
                    .map((workstyle) => WorkStyleListTile(workstyle: workstyle))
                    .cast<Widget>()
                    .toList()),
            ExpansionTile(
              title: Text(
                "Technology Skills",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              children: occupation.technologySkills!.map((e) => TechnologySkillListTile(technologySkill: e)).toList(),
            ),
            ExpansionTile(
              title: Text(
                "Other Sections",
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
              ),
              children: <Widget>[
                ListTile(
                  title: Text('Learn More'),
                  onTap: () {
                    // TODO: Make sure launching URL works
                    launchUrlString(occupation.onetLink ?? 'https://onetonline.org');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  List<Widget> _buildOfflineMessage() {
    return [
      Padding(
        padding: EdgeInsets.all(28),
        child: Center(
            child: Text(
                Localization().getStringEx(
                    'panel.skills_self_evaluation.results.offline.error.msg', 'Results not available while offline.'),
                textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'))),
      ),
    ];
  }
}

class WorkStyleListTile extends StatelessWidget {
  const WorkStyleListTile({Key? key, required this.workstyle, this.mostRecentScore, this.comparisonScore})
      : super(key: key);

  final WorkStyle workstyle;
  final int? mostRecentScore;
  final int? comparisonScore;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Card(
            child: InkWell(
              onTap: () {},
              child: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
                child: Row(
                  children: [
                    Flexible(
                        flex: 5,
                        fit: FlexFit.tight,
                        child: Text(workstyle.name.toString(),
                            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'))),
                    Flexible(
                        flex: 3,
                        fit: FlexFit.tight,
                        child: Text(
                          // TODO: Add the actual scores here
                          "S" ?? "--",
                          style:
                              Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.score.current'),
                          textAlign: TextAlign.center,
                        )),
                    Flexible(
                        flex: 3,
                        fit: FlexFit.tight,
                        // TODO: Add the comparison scores/ranks here
                        child: Text("R" ?? "--",
                            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.score.past'),
                            textAlign: TextAlign.center)),
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
              ' • ' + technologySkill.title.toString(),
              textAlign: TextAlign.start,
              style: TextStyle(fontWeight: FontWeight.w100),
            ),
          ),
        ],
      ),
    );
  }
}
