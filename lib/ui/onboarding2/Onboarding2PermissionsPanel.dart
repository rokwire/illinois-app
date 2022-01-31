
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/location_services.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Onboarding2PermissionsPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _Onboarding2PermissionsPanelState();

}
class _Onboarding2PermissionsPanelState extends State <Onboarding2PermissionsPanel>{

  @override
  void initState() {
    _requestLocation(context);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors!.background,
    );
  }

  void _requestLocation(BuildContext context) async {
    Analytics().logSelect(target: 'Share My locaiton') ;
    await LocationServices().status.then((LocationServicesStatus? status){
      if (status == LocationServicesStatus.serviceDisabled) {
        LocationServices().requestService();
      }
      else if (status == LocationServicesStatus.permissionNotDetermined) {
        LocationServices().requestPermission().then((LocationServicesStatus? status) {
          //Next
          _goNext();
        });
      }
      else if (status == LocationServicesStatus.permissionDenied) {
        //Denied  - request again
        LocationServices().requestPermission().then((LocationServicesStatus? status) {
          //Next
          _goNext();
        });
      }
      else if (status == LocationServicesStatus.permissionAllowed) {
        //Next()
        _goNext();
      }
    });
  }

  void _goNext(){
    Onboarding2().finalize(context);
  }
}