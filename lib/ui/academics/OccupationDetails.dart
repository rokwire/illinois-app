import 'package:flutter/material.dart';
import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/model/occupation/OccupationMatch.dart';
import 'package:illinois/model/occupation/Skill.dart';
import 'package:illinois/service/skills/OccupationsService.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/Utils.dart';

class OccupationDetails extends StatelessWidget {
  OccupationDetails({Key? key, required this.occupationMatch}) : super(key: key);

  final OccupationMatch occupationMatch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(
        title: 'Occupation Details',
      ),
      body: FutureBuilder(
          future: OccupationsService().getOccupation(occupationCode: occupationMatch.occupation?.code ?? ""),
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
              child: Column(
                children: [
                  SizedBox(
                    height: 12,
                  ),
                  Text(
                    occupation.title!,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 25),
                  ),
                  SizedBox(
                    height: 12,
                  ),
                  Text("Match Percentage: ${occupationMatch.matchPercent!.toInt()}%"),
                  SizedBox(
                    height: 12,
                  ),
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
                  SizedBox(
                    height: 12,
                  ),
                  Text(occupation.description!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontFamily: "regular", fontSize: 16, color: Colors.black)),
                  SizedBox(
                    height: 12,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: <Widget>[
                        SizedBox(height: 20.0),
                        ExpansionTile(
                            title: Text(
                              "Soft Skills",
                              style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                            ),
                            children: occupation.skills!.map((e) => SkillListTile(skill: e)).toList()),
                        ExpansionTile(
                          title: Text(
                            "Technical Skills",
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          children: occupation.technicalSkills!.map((e) => SkillListTile(skill: e)).toList(),
                        ),
                        ExpansionTile(
                          title: Text(
                            "Other Sections",
                            style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold),
                          ),
                          children: <Widget>[
                            ListTile(
                              title: Text('Learn More'),
                            ),
                            ListTile(
                              title: Text('?'),
                            ),
                            ListTile(
                              title: Text('?'),
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }
}

class SkillListTile extends StatelessWidget {
  const SkillListTile({Key? key, required this.skill}) : super(key: key);

  final Skill skill;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: Text(skill.name.toString()),
          subtitle: Text(skill.description.toString()),
          trailing: Text(skill.matchPercentage!.toInt().toString() + "%"),
          onTap: () {},
        ),
        ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(20)),
          child: LinearProgressIndicator(
            backgroundColor: LinearProgressColorUtils.linearProgressIndicatorBackgroundColor(
              skill.matchPercentage! / 100.0,
            ),
            color: LinearProgressColorUtils.linearProgressIndicatorColor(
              skill.matchPercentage! / 100.0,
            ),
            // valueColor: AlwaysStoppedAnimation(,),
            minHeight: 10,
            value: skill.matchPercentage! / 100,
          ),
        ),
      ],
    );
  }
}
