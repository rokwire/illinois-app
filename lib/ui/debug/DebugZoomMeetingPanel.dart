
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/ZoomUs.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class DebugZoomMeetingPanel extends StatefulWidget {
  DebugZoomMeetingPanel();

  State<StatefulWidget> createState() => _DebugZoomMeetingPanelState();
}

class _DebugZoomMeetingPanelState extends State<DebugZoomMeetingPanel> {

  TextEditingController _meetingIdController = TextEditingController();
  TextEditingController _meetingPasswordController = TextEditingController();
  String? _joinStatus;

  @override
  void initState() {
    if (kDebugMode) {
      _meetingIdController.text = '8892069629';
      _meetingPasswordController.text = 'gQ9ZXD';
    }
    super.initState();
  }
  
  void dispose() {
    _meetingIdController.dispose();
    _meetingPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: "Zoom Meeting", ),
      backgroundColor: Styles().colors!.background,
      body: Column(children: <Widget>[
        Expanded(child: 
          SingleChildScrollView(child:
            Padding(padding: EdgeInsets.all(16), child:
              SafeArea(child:
                _buildContent()
              ),
            ),
          ),
        ),
      ],),
    );
  }

  Widget _buildContent() {
    return Column(children: [
      TextFormField(
        controller: _meetingIdController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Enter Zoom Meeting ID", labelText: 'Zoom Meeting ID')
      ),
      Container(height: 8,),
      TextFormField(
        controller: _meetingPasswordController,
        keyboardType: TextInputType.visiblePassword,
        decoration: InputDecoration(border: OutlineInputBorder(), hintText: "Enter Zoom Meeting Passcode", labelText: 'Zoom Meeting Passcode')
      ),
      Container(height: 8,),
      Text(_joinStatus ?? '', style: TextStyle(color: Styles().colors?.textBackground, fontFamily: Styles().fontFamilies?.medium, fontSize: 16),),
      Container(height: 8,),

      RoundedButton(
        label: 'Join Meeting',
        backgroundColor: Styles().colors!.background,
        fontSize: 16.0,
        textColor: Styles().colors!.fillColorPrimary,
        borderColor: Styles().colors!.fillColorPrimary,
        onTap: _onTapJoinMeeting
      ),

    ],);
  }

  void _onTapJoinMeeting() {
    setState(() {
      _joinStatus = 'Joining...';
    });
    ZoomUs().joinMeeting(meetingId: _meetingIdController.text, password: _meetingPasswordController.text).then((bool? result) {
      setStateIfMounted(() {
        switch(result) {
          case true: _joinStatus = 'Joined'; break;
          case false: _joinStatus = 'Failed'; break;
          default: _joinStatus = 'Internal Error'; break;
        }
      });
    });
  }
}
