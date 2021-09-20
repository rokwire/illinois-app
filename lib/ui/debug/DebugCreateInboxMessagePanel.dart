import 'package:flutter/material.dart';
import 'package:illinois/model/Inbox.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Inbox.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';

class DebugCreateInboxMessagePanel extends StatefulWidget {
  DebugCreateInboxMessagePanel();

  _DebugCreateInboxMessagePanelState createState() => _DebugCreateInboxMessagePanelState();
}

class _DebugCreateInboxMessagePanelState extends State<DebugCreateInboxMessagePanel> {

  TextEditingController _recepientsController;
  TextEditingController _subjectController;
  TextEditingController _bodyController;
  TextEditingController _dataController;

  bool _sending;
  
  @override
  void initState() {
    super.initState();

    InboxMessage lastMessage = InboxMessage.fromJson(AppJson.decodeMap(Storage().debugLastInboxMessage));

    String recepients = "";
    if (lastMessage?.recepients != null) {
      for (InboxRecepient recepient in lastMessage?.recepients) {
        if (recepients.isNotEmpty) {
          recepients += "\n";
        }
        recepients += recepient.userId;
      }
    }
    if (recepients.isEmpty) {
      recepients = Auth2().account?.authType?.uiucUser?.email ?? Auth2().account?.profile?.email ?? '';
    }

    _recepientsController = TextEditingController(text: recepients);
    _subjectController = TextEditingController(text: lastMessage?.subject ?? 'Lorem ipsum');
    _bodyController = TextEditingController(text: lastMessage?.body ?? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Donec blandit dapibus accumsan. Aenean luctus eu eros et tempor.');
    _dataController = TextEditingController(text: AppJson.encode(lastMessage?.data)  ?? '');
  }

  @override
  void dispose() {
    super.dispose();
    _recepientsController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    _dataController.dispose();
 }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SimpleHeaderBarWithBack(
        context: context,
        titleWidget: Text("Inbox Message", style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: Styles().fontFamilies.extraBold),),
      ),
      body: SafeArea(child:
        Column(children: <Widget>[
          Expanded(child:
            SingleChildScrollView(child:
              Padding(padding: EdgeInsets.all(16), child:
                _buildContent(),
              ),
            ),
          ),
          _buildSend(),
        ],),
      ),
      backgroundColor: Styles().colors.background,
    );
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment:CrossAxisAlignment.start, children: <Widget>[

      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text("Recepients:", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),
        ),
        Stack(children: <Widget>[
          Semantics(textField: true, child:Container(color: Styles().colors.white,
            child: TextField(
              maxLines: 2,
              controller: _recepientsController,
              decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
              style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground,),
            ),
          )),
          Align(alignment: Alignment.topRight,
            child: Semantics (button: true, label: "Clear",
              child: GestureDetector(onTap: () { _recepientsController.text = ''; },
                child: Container(width: 36, height: 36,
                  child: Align(alignment: Alignment.center,
                    child: Semantics( excludeSemantics: true,child:Text('X', style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.fillColorPrimary,),)),
                  ),
                ),
              ),
          )),
        ]),
      ]),

      Container(height: 16,),

      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text("Subject:", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),
        ),
        Stack(children: <Widget>[
          Semantics(textField: true, child:Container(color: Styles().colors.white,
            child: TextField(
              maxLines: 1,
              controller: _subjectController,
              decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
              style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground,),
            ),
          )),
          Align(alignment: Alignment.topRight,
            child: Semantics (button: true, label: "Clear",
              child: GestureDetector(onTap: () { _subjectController.text = ''; },
                child: Container(width: 36, height: 36,
                  child: Align(alignment: Alignment.center,
                    child: Semantics( excludeSemantics: true,child:Text('X', style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.fillColorPrimary,),)),
                  ),
                ),
              ),
          )),
        ]),
      ]),

      Container(height: 16,),

      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text("Body:", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),
        ),
        Stack(children: <Widget>[
          Semantics(textField: true, child:Container(color: Styles().colors.white,
            child: TextField(
              maxLines: 6,
              controller: _bodyController,
              decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
              style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground,),
            ),
          )),
          Align(alignment: Alignment.topRight,
            child: Semantics (button: true, label: "Clear",
              child: GestureDetector(onTap: () { _bodyController.text = ''; },
                child: Container(width: 36, height: 36,
                  child: Align(alignment: Alignment.center,
                    child: Semantics( excludeSemantics: true,child:Text('X', style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.fillColorPrimary,),)),
                  ),
                ),
              ),
          )),
        ]),
      ]),

      Container(height: 16,),

      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        Padding(padding: EdgeInsets.only(bottom: 4),
          child: Text("Data:", style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: Styles().colors.fillColorPrimary),),
        ),
        Stack(children: <Widget>[
          Semantics(textField: true, child:Container(color: Styles().colors.white,
            child: TextField(
              maxLines: 6,
              controller: _dataController,
              decoration: InputDecoration(border: OutlineInputBorder(borderSide: BorderSide(color: Colors.black, width: 1.0))),
              style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.textBackground,),
            ),
          )),
          Align(alignment: Alignment.topRight,
            child: Semantics (button: true, label: "Clear",
              child: GestureDetector(onTap: () { _dataController.text = ''; },
                child: Container(width: 36, height: 36,
                  child: Align(alignment: Alignment.center,
                    child: Semantics( excludeSemantics: true,child:Text('X', style: TextStyle(fontFamily: Styles().fontFamilies.regular, fontSize: 16, color: Styles().colors.fillColorPrimary,),)),
                  ),
                ),
              ),
          )),
        ]),
      ]),

    ]);

  }

  Widget _buildSend() {
    bool sendEnabled = true;
    return Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(children: <Widget>[
          Row(children: <Widget>[
            Expanded(child: Container(),),
            RoundedButton(label: "Send Message",
              textColor: sendEnabled ? Styles().colors.fillColorPrimary : Styles().colors.disabledTextColor,
              borderColor: sendEnabled ? Styles().colors.fillColorSecondary : Styles().colors.disabledTextColor,
              backgroundColor: Styles().colors.white,
              fontFamily: Styles().fontFamilies.bold,
              fontSize: 16,
              padding: EdgeInsets.symmetric(horizontal: 32, ),
              borderWidth: 2,
              height: 42,
              onTap:() { _onSend();  }
            ),
            Expanded(child: Container(),),
          ],),
          Visibility(visible: (_sending == true), child:
            Center(child:
              Padding(padding: EdgeInsets.only(top: 10.5), child:
               Container(width: 21, height:21, child:
                  CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorSecondary), strokeWidth: 2,)
                ),
              ),
            ),
          ),
        ],),
      );
  }

  void _onSend() {
    List<InboxRecepient> recepients = <InboxRecepient>[];
    List<String> recepientsList = _recepientsController.text.split('\n');
    for (String recepientEntry in recepientsList) {
      recepientEntry.trim();
      if (recepientEntry.isNotEmpty) {
        recepients.add(InboxRecepient(userId: recepientEntry));
      }
    }

    if (recepients.isEmpty) {
      AppAlert.showDialogResult(context, 'Please enter some recepient.');
      return;
    }

    InboxMessage message = InboxMessage(
      recepients: recepients,
      subject: _subjectController.text,
      body: _bodyController.text,
      data: AppJson.decodeMap(_dataController.text)
    );

    setState(() {
      _sending = true;
    });

    Inbox().sendMessage(message).then((bool result) {
      setState(() {
        _sending = false;
      });
      if (result) {
        Storage().debugLastInboxMessage = AppJson.encode(message.toJson());
        Navigator.of(context).pop();
      }
      else {
        AppAlert.showDialogResult(context, 'Failed to send message.');
      }
    });


  }
}