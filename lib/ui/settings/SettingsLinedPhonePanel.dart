import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

import 'SettingsWidgets.dart';

class SettingsLinkedPhonePanel extends StatefulWidget{
  //TBD Localization
  //TBD decide do we want to load this in the panel init phase
  final Auth2Type? linkedPhone;

  const SettingsLinkedPhonePanel({Key? key, this.linkedPhone}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SettingsLinkedPhoneState();
}

class _SettingsLinkedPhoneState extends State<SettingsLinkedPhonePanel>{

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx("panel.settings.linked.phone.label.title", "Alternate Phone Number"),),
        body: Column(children: <Widget>[
          Expanded(child:
          SingleChildScrollView(scrollDirection: Axis.vertical, child:
          Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(children:[
                Row(children: [ Expanded(child:
                Text(Localization().getStringEx("panel.settings.linked.phone.label.description",
                    "You may sign in using your phone number as an alternate way to sign in. Some features of the Illinois App will not be available unless you login with your NetID."),
                  style: TextStyle(fontFamily: Styles().fontFamilies?.regular, fontSize: 18, color: Styles().colors!.fillColorPrimary),
                )
                )],),
                Container(height: 48),
                LinkAccountContentWidget(linkedAccount: _linkedPhone,)
              ]))))])
    );
  }

  //TBD decide do we want to load this in the panel init phase
  Auth2Type get _linkedPhone{
    return widget.linkedPhone ?? mocData; //TODO remove moc data
  }

  Auth2Type get mocData{
    return Auth2Type(id: "22222", identifier: "+359888123456", code: "0987");
  }
}