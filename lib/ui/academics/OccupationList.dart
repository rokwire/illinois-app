import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/occupation/OccupationMatch.dart';
import 'package:illinois/service/OccupationMatching.dart';
import 'package:illinois/ui/academics/OccupationDetails.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/section_header.dart';

class OccupationList extends StatelessWidget {
  OccupationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: 'Results'),
      body: SingleChildScrollView(
        child: SectionSlantHeader(
          headerWidget: _buildHeader(),
          slantColor: Styles().colors?.gradientColorPrimary,
          slantPainterHeadingHeight: 0,
          backgroundColor: Styles().colors?.background,
          children: Connectivity().isOffline ? _buildOfflineMessage() : _buildOccupationListView(),
          childrenPadding: EdgeInsets.zero,
          allowOverlap: !Connectivity().isOffline,
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(top: 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Localization().getStringEx('panel.skills_self_evaluation.results.career_explorer.title', 'Career Explorer'),
            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.header'),
            textAlign: TextAlign.center,
          ),
          Text(
            Localization().getStringEx('panel.skills_self_evaluation.results.score.description', 'Skills Domain Score'),
            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'),
            textAlign: TextAlign.center,
          ),
          Text(
            Localization().getStringEx('panel.skills_self_evaluation.results.score.scale', '(0-100)'),
            style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.header.description'),
            textAlign: TextAlign.center,
          ),
          _buildOccupationsHeader(),
        ],
      ),
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Styles().colors?.fillColorPrimaryVariant ?? Colors.transparent,
            Styles().colors?.gradientColorPrimary ?? Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildOccupationsHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 20, left: 28, right: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Divider(color: Styles().colors?.surface, thickness: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                    flex: 5,
                    fit: FlexFit.tight,
                    child: Text(
                      Localization().getStringEx('panel.skills_self_evaluation.results.occupation.title', 'OCCUPATION'),
                      style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'),
                    )),
                Flexible(
                  flex: 3,
                  fit: FlexFit.tight,
                  child: Text(
                    Localization()
                        .getStringEx('panel.skills_self_evaluation.results.match_percentage.title', 'MATCH PERCENTAGE'),
                    style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.results.table.header'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
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

  List<Widget> _buildOccupationListView() {
    return [
      FutureBuilder(
          future: OccupationMatching().getAllOccupationMatches(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.data == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'You do not have any matched occupations currently. Please take the survey first and wait for results to be processed.',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }
            List<OccupationMatch> occupationMatches = (snapshot.data as List).cast<OccupationMatch>();
            return Column(
              children: occupationMatches
                  .map(
                    (occupationMatch) => OccupationListTile(
                      occupationMatch: occupationMatch,
                    ),
                  )
                  .toList(),
            );
          })
    ];
  }
}

class OccupationListTile extends StatelessWidget {
  const OccupationListTile({Key? key, required this.occupationMatch}) : super(key: key);

  final OccupationMatch occupationMatch;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Card(
        child: InkWell(
          onTap: () {
            Navigator.push(
                context, CupertinoPageRoute(builder: (context) => OccupationDetails(occupationMatch: occupationMatch)));
          },
          child: Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 12, left: 16),
            child: Row(
              children: [
                Flexible(
                  flex: 5,
                  fit: FlexFit.tight,
                  child: Text(
                    occupationMatch.occupation?.title.toString() ?? "",
                    style: Styles().textStyles?.getTextStyle('panel.skills_self_evaluation.content.title'),
                  ),
                ),
                Spacer(),
                Flexible(
                  child: OccupationMatchCircle(
                    matchPercentage: occupationMatch.matchPercent ?? 100.0,
                  ),
                ),
                Flexible(
                    flex: 1,
                    fit: FlexFit.tight,
                    child: SizedBox(
                        height: 16.0,
                        child: Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OccupationMatchCircle extends StatelessWidget {
  const OccupationMatchCircle({Key? key, required this.matchPercentage}) : super(key: key);

  final double matchPercentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Stack(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(math.pi),
            child: CircularProgressIndicator(
              strokeWidth: 8.0,
              backgroundColor: LinearProgressColorUtils.linearProgressIndicatorBackgroundColor(
                matchPercentage / 100.0,
              ),
              color: LinearProgressColorUtils.linearProgressIndicatorColor(
                matchPercentage / 100.0,
              ),
              value: matchPercentage / 100,
            ),
          ),
          Positioned.fill(
            child: Center(child: Text(matchPercentage.toInt().toString())),
          ),
        ],
      ),
    );
  }
}
