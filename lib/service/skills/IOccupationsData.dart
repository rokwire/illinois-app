// TODO: Fix the return values of all the

import 'package:illinois/model/occupation/Occupation.dart';

abstract class IOccupationsData /* with Service */ {
  Future<List<Occupation>> getAllOccupations();
  Future<List<Occupation>> getTop10Occupations();
  Future<List<Occupation>> getOccupationsByKeyword({required String keyword});

  Future<Occupation> getOccupation({required String occupationCode});
}
