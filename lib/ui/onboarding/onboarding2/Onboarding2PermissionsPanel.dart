
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/BluetoothServices.dart';
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
        backgroundColor: Styles().colors.background,
    );
  }

  void _requestLocation(BuildContext context) async {
    Analytics.instance.logSelect(target: 'Share My locaiton') ;
    await LocationServices.instance.status.then((LocationServicesStatus status){
      if (status == LocationServicesStatus.ServiceDisabled) {
        LocationServices.instance.requestService();
      }
      else if (status == LocationServicesStatus.PermissionNotDetermined) {
        LocationServices.instance.requestPermission().then((LocationServicesStatus status) {
          //Next
          _showBluetoothPermissionDialog();
        });
      }
      else if (status == LocationServicesStatus.PermissionDenied) {
        //Denied  - request again
        LocationServices.instance.requestPermission().then((LocationServicesStatus status) {
          //Next
          _showBluetoothPermissionDialog();
        });
      }
      else if (status == LocationServicesStatus.PermissionAllowed) {
        //Next()
        _showBluetoothPermissionDialog();
      }
    });
  }

  _showBluetoothPermissionDialog(){
    Analytics.instance.logSelect(target: 'Enable Bluetooth') ;

    BluetoothStatus authStatus = BluetoothServices().status;
    if (authStatus == BluetoothStatus.PermissionNotDetermined) {
      BluetoothServices().requestStatus().then((_){
       //Next
        _goNext();
      });
    }
    else if (authStatus == BluetoothStatus.PermissionDenied) {
      //Denied - ask again
      BluetoothServices().requestStatus().then((_){
        //Next
        _goNext();
      });
    }
    else if (authStatus == BluetoothStatus.PermissionAllowed) {
     //Next
      _goNext();
    }
  }

  void _goNext(){
    //TBD Login Panels
    Onboarding2().finish(context);
  }
}