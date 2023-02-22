import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/service/skills/IOccupationsData.dart';

class MockOccupationsData implements IOccupationsData {
  List<Occupation> _listOfOccupations = [
    Occupation(
      name: 'Software Developer',
      description: 'Die from segmentation fault',
      matchPercentage: 75.0,
      onetLink: '',
      skills: [],
      technicalSkills: [],
    ),
    Occupation(
      name: 'Architect',
      description: 'Build Minecraft Structures IRL',
      matchPercentage: 20.0,
      onetLink: '',
      skills: [],
      technicalSkills: [],
    ),
  ];

  Occupation _occupation = Occupation(
    name: 'Software Developer',
    description: 'Die from segmentation fault',
    matchPercentage: 75.0,
    onetLink: '',
    skills: [],
    technicalSkills: [],
  );

  @override
  Future<List<Occupation>> getAllOccupations() async {
    return _listOfOccupations;
  }

  @override
  Future<Occupation> getOccupation({required String occupationCode}) async {
    return _occupation;
  }

  @override
  Future<List<Occupation>> getOccupationsByKeyword({required String keyword}) async {
    return _listOfOccupations;
  }

  @override
  Future<List<Occupation>> getTop10Occupations() async {
    return _listOfOccupations;
  }
}
