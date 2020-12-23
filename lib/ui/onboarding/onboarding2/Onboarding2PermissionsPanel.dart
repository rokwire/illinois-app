
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Styles.dart';

class Onboarding2PermissionsPanel extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _Onboarding2PermissionsPanelState();

}
class _Onboarding2PermissionsPanelState extends State <Onboarding2PermissionsPanel>{

  @override
  void initState() {

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Styles().colors.background,
    );
  }

  _showLocationPermissionDialog(){
    //TBD
  }

  _showBluetoothPermissionDialog(){
    //TBD
  }
}