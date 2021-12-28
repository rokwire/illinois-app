
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/LocationServices.dart';
import 'package:illinois/service/Onboarding2.dart';
import 'package:illinois/service/Styles.dart';

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
    Analytics.instance.logSelect(target: 'Share My locaiton') ;
    await LocationServices.instance.status.then((LocationServicesStatus? status){
      if (status == LocationServicesStatus.ServiceDisabled) {
        LocationServices.instance.requestService();
      }
      else if (status == LocationServicesStatus.PermissionNotDetermined) {
        LocationServices.instance.requestPermission().then((LocationServicesStatus? status) {
          //Next
          _goNext();
        });
      }
      else if (status == LocationServicesStatus.PermissionDenied) {
        //Denied  - request again
        LocationServices.instance.requestPermission().then((LocationServicesStatus? status) {
          //Next
          _goNext();
        });
      }
      else if (status == LocationServicesStatus.PermissionAllowed) {
        //Next()
        _goNext();
      }
    });
  }

  void _goNext(){
    Onboarding2().finalize(context);
  }
}