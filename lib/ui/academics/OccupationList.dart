import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/service/styles.dart';

class OccupationList extends StatelessWidget {
  OccupationList({Key? key}) : super(key: key);

  final List<Occupation> occupations = [
    Occupation(
      name: 'Software Developer',
      description: 'Die from segmentation fault',
      matchPercentage: 75.0,
      onetLink: '',
      skills: [],
    ),
    Occupation(
      name: 'Architect',
      description: 'Build Minecraft Structures IRL',
      matchPercentage: 20.0,
      onetLink: '',
      skills: [],
    ),
  ];

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
    return ListView.builder(
      itemBuilder: (context, index) => OccupationListTile(
        occupation: occupations[index],
      ),
      itemCount: occupations.length,
    );
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
      title: Text(occupation.name.toString()),
      subtitle: Text(occupation.description.toString()),
      trailing: Styles().images?.getImage('chevron-right'),
      onTap: () {},
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
            color: Color.lerp(Colors.red, Colors.green, matchPercentage / 100.0),
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
