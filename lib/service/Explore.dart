import 'package:illinois/model/Explore.dart';
import 'package:rokwire_plugin/model/explore.dart' as model;
import 'package:rokwire_plugin/service/service.dart';

class Explore with Service {

  ExplorePOIJsonHandler _explorePOIJsonHandler = ExplorePOIJsonHandler();

  // Service
  @override
  void createService() {
    model.Explore.addJsonHandler(_explorePOIJsonHandler);
    super.createService();
  }

  @override
  void destroyService() {
    model.Explore.removeJsonHandler(_explorePOIJsonHandler);
    super.destroyService();
  }
}