import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/occupation/Occupation.dart';
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
        future: OccupationsService().getAllOccupations(),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return Center(child: CircularProgressIndicator());
          }
          List<Occupation> occupations = (snapshot.data as List).cast<Occupation>();
          return ListView.builder(
            itemBuilder: (context, index) => OccupationListTile(
              occupation: occupations[index],
            ),
            itemCount: occupations.length,
          );
        });
  }
}

class OccupationListTile extends StatelessWidget {
  const OccupationListTile({Key? key, required this.occupation}) : super(key: key);

  final Occupation occupation;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: OccupationMatchCircle(
        matchPercentage: occupation.matchPercentage ?? 100.0,
      ),
      title: Text(occupation.title.toString()),
      subtitle: Text(
        occupation.description.toString(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Styles().images?.getImage('chevron-right'),
      onTap: () {
        Navigator.push(
            context,
            CupertinoPageRoute(
                builder: (context) => OccupationDetails(
                      occupationCode: occupation.code!,
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
