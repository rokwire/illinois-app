import 'package:illinois/model/occupation/Occupation.dart';
import 'package:illinois/service/skills/IOccupationsData.dart';
import 'package:illinois/service/skills/MockOccupationsData.dart';

class OccupationsService /* with Service */ {
  static final OccupationsService _instance = OccupationsService._internal();

  factory OccupationsService() => _instance;

  OccupationsService._internal();

  // TODO: Replace mock implmentation with real backend implementation
  IOccupationsData _occupationsData = MockOccupationsData();

  Future<List<Occupation>> getAllOccupations() {
    return _occupationsData.getAllOccupations();
  }
}
