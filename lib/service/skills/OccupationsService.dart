import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/service/skills/IOccupationsData.dart';
// import 'package:illinois/service/skills/MockOccupationsData.dart';
import 'package:illinois/service/skills/OnetOccupationsData.dart';

class OccupationsService /* with Service */ {
  static final OccupationsService _instance = OccupationsService._internal();

  factory OccupationsService() => _instance;

  OccupationsService._internal();

  // TODO: Replace mock implmentation with real backend implementation
  // IOccupationsData _occupationsData = MockOccupationsData();
  IOccupationsData _occupationsData = OnetOccupationsData();

  Future<List<Occupation>> getAllOccupations() {
    return _occupationsData.getAllOccupations();
  }

  Future<Occupation> getOccupation({required String occupationCode}) {
    return _occupationsData.getOccupation(occupationCode: occupationCode);
  }
}
