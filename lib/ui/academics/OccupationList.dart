import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/occupation/OccupationMatch.dart';
import 'package:illinois/service/skills/OccupationsService.dart';
import 'package:illinois/ui/academics/OccupationDetails.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class OccupationList extends StatelessWidget {
  OccupationList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: 'Matched Occupations',
        actions: [
          IconButton(
            onPressed: () {},
            // TODO: Change the icon to a more appropriate one
            icon: Styles().images?.getImage('edit') ?? Icon(Icons.list),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _buildOccupationListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Icon(Icons.search),
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              label: Text('Search for specific job'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOccupationListView() {
    return FutureBuilder(
        future: OccupationsService().getAllOccupationMatches(),
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
          return ListView.builder(
            itemBuilder: (context, index) => OccupationListTile(
              occupationMatch: occupationMatches[index],
            ),
            itemCount: occupationMatches.length,
          );
        });
  }
}

class OccupationListTile extends StatelessWidget {
  const OccupationListTile({Key? key, required this.occupationMatch}) : super(key: key);

  final OccupationMatch occupationMatch;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: OccupationMatchCircle(
        matchPercentage: occupationMatch.matchPercent ?? 100.0,
      ),
      title: Text(occupationMatch.occupation?.title.toString() ?? ""),
      subtitle: Text(
        occupationMatch.occupation?.description.toString() ?? "",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Styles().images?.getImage('chevron-right'),
      onTap: () {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => OccupationDetails(
                      occupationMatch: occupationMatch,
                      // survey: Config().bessiSurveyID,
                      // onComplete: _gotoResults,
                      // offlineWidget: _buildOfflineWidget(),
                      // tabBar: uiuc.TabBar(),
                    )));
      },
    );
  }
}

class OccupationMatchCircle extends StatelessWidget {
  const OccupationMatchCircle({Key? key, required this.matchPercentage}) : super(key: key);

  final double matchPercentage;

  @override
  Widget build(BuildContext context) {
    return Stack(
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
    );
  }
}
