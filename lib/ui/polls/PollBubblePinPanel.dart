/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rokwire_plugin/model/poll.dart';
import 'package:rokwire_plugin/service/connectivity.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/service/Polls.dart' as illinois;

class PollBubblePinPanel extends StatefulWidget {

  final double topOffset;

  @override
  _PollBubblePinPanelState createState() => _PollBubblePinPanelState();

  PollBubblePinPanel({this.topOffset = kToolbarHeight});
}

class _PollBubblePinPanelState extends State<PollBubblePinPanel> {

  final int _digitsCount = 4;
  
  List<TextEditingController> _digitControllers = [];
  List<FocusNode> _digitFocusNodes = [];
  RegExp _digitRegExp = RegExp('[0-9]{1}');

  bool _initialAnnounced = false;
  bool _loading = false;
  bool _showInfo = false;

  @override
  void initState() {
    super.initState();

    for (int digit = 0; digit < _digitsCount; digit++) {
      _digitControllers.add(TextEditingController());
      _digitFocusNodes.add(FocusNode());
    }

    _digitFocusNodes.first.requestFocus();
  }
  @override
  void dispose() {
    for (TextEditingController digitController in _digitControllers) {
      digitController.dispose();
    }
    _digitControllers.clear();
    
    for (FocusNode digitFocusNode in _digitFocusNodes) {
      digitFocusNode.dispose();
    }
    _digitFocusNodes.clear();

    super.dispose();
  }

  String get _pinString{
    String pin = '';
    for (TextEditingController digitController in _digitControllers) {
      pin += digitController.text;
    }
    return pin;
  }

  int? get _pinInt{
    return int.tryParse(_pinString);
  }

  bool _isDigit(String? text) {
    RegExpMatch? match = (text != null) ? _digitRegExp.firstMatch(text) : null;
    return (match != null) && (match.start == 0) && (match.end == 1);
  }

  bool _validate(){
    for (int digit = 0; digit < _digitsCount; digit++) {
      if (!_isDigit(_digitControllers[digit].text)) {
        AppAlert.showDialogResult(context, Localization().getStringEx("panel.poll_pin_bouble.validation_description", "Please enter correct four digit pin"))
          .then((_){_digitFocusNodes[digit].requestFocus();});
        return false;
      }
      
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black.withOpacity(0.3), //Colors.transparent,
        body: SafeArea(
          child:
//          Padding(
//            padding: EdgeInsets.only(top: widget.topOffset),
//            child:
            Padding(
              padding: EdgeInsets.only(left:5, right: 5, top: /*widget.topOffset*/30, bottom: 5),
              child:
              Stack(children: <Widget>[
                SingleChildScrollView(child:
                Column(children: <Widget>[
                  Container(
                    decoration: BoxDecoration(color: Styles().colors!.fillColorPrimary, borderRadius: BorderRadius.circular(5)),
                    child: Padding(padding: EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: _buildContent(),),),
                  ),
                ],)),
                Container(alignment: Alignment.topRight, child: _buildCloseButton()),
              ]),
            )
//          ),
        ),

    );
  }

  List<Widget> _buildContent() {
    return _showInfo ? _buildInfoContent() : _buildMainContent();
  }

  List<Widget> _buildInfoContent() {
    return <Widget>[
      IconButton(
        icon: Semantics(label: "Back", child: Styles().images?.getImage('chevron-left-white', excludeFromSemantics: true)),
        onPressed: ()=>setState((){_showInfo = false;}),
      ),
      Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 52),
        child: Text(
          Localization().getStringEx("panel.poll_pin_bouble.long_info_description", "Each poll has a four-digit number. The poll creator can share this code so others can respond."),
          style: Styles().textStyles?.getTextStyle("widget.dialog.message.medium.thin")

        ),
      )
    ];
  }

  List<Widget> _buildMainContent() {
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Semantics(label:'', excludeSemantics: false, focusable: true, focused: true, child:
        Padding(padding: EdgeInsets.only(right: 40), child:
          RichText(
            text: TextSpan(
              text:Localization().getStringEx("panel.poll_pin_bouble.label_description", "Enter the four-digit poll number to see the poll.") + " ",
              style: Styles().textStyles?.getTextStyle("widget.dialog.message.large.extra_fat"),
              children:[
                WidgetSpan(
                    child: Semantics(label: "Info", container:true, button: true,
                      child: GestureDetector(
                        onTap: ()=>setState((){_showInfo = true;}),
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: new BorderRadius.circular(15.0),
                            border: new Border.all(
                              width: 2.0,
                              color: Styles().colors!.fillColorSecondary!,
                            ),
                          ),
                          child: Center(
                            child: Text("i",
                              semanticsLabel: "",
                              style:  Styles().textStyles?.getTextStyle("panel.poll.bubble.pin.button.info"),
                            ),
                          ),
                        ),
                      )
                    )
                )
              ],
            ),
          ),
        ),
      ),
      Container(height: 20,),
      _buildFieldsContent(),
      _buildContinueButton(),
    ];
  }

  Widget _buildFieldsContent(){
    List<Widget> widgets = [];
    for (int digit = 0; digit < _digitsCount; digit++) {
      if (0 < widgets.length) {
        widgets.add(Container(width: 10,),);
      }
      widgets.add(_buildPinField(
        _digitControllers[digit],
        _digitFocusNodes[digit],
        (0 <= (digit-1)) ? _digitFocusNodes[digit-1] : null,
        ((digit+1) < _digitsCount) ? _digitFocusNodes[digit+1] : null,
        position: digit
      ),
      );

    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal,child:Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets,));
  }

  Widget _buildPinField(TextEditingController controller, FocusNode focusNode, FocusNode? prevFocusNode, FocusNode? nextFocusNode, {int position = 0}){
    Function nextCallBack = (){
      if(_isDigit(controller.value.text)){
        if(nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
        else{
          focusNode.unfocus();
        }
      }
    };
    return Container(
      width: 24+ 24*MediaQuery.of(context).textScaleFactor,
      child: Semantics(
        label: _initialSemanticsAnnouncement(position),
        hint: " ${position + 1} of $_digitsCount",
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [new LengthLimitingTextInputFormatter(1),],
          textAlign: TextAlign.center,
          onEditingComplete: ()=> nextCallBack(),
          onChanged: (values)=> nextCallBack(),
          decoration: new InputDecoration(
            filled: true,
            fillColor: Styles().colors!.white,
            border: new OutlineInputBorder(
              borderRadius: const BorderRadius.all(
                const Radius.circular(4),
              ),
            ),
          ),
          style: Styles().textStyles?.getTextStyle("panel.poll.bubble.pin.field.text")
        ),
      )
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 30, right: 30),
        child: RoundedButton(
            label: Localization().getStringEx('dialog.continue.title', 'Continue'),
            hint: Localization().getStringEx('dialog.continue.hint', ''),
            textStyle: Styles().textStyles?.getTextStyle("widget.button.title.enabled"),
            backgroundColor: Styles().colors!.white,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            progress: _loading,
            borderColor: Styles().colors!.fillColorSecondary,
            onTap: () { _onContinue(); }
          ),       
      );
  } 

  Widget _buildCloseButton() {
    return Semantics(
        label: Localization().getStringEx('dialog.close.title', 'Close'),
        hint: Localization().getStringEx('dialog.close.hint', ''),
        button: true,
        child: InkWell(
            onTap : _onClose,
            child: Container(width: 48, height: 48, alignment: Alignment.center, child: Styles().images?.getImage('close-circle-white', excludeFromSemantics: true))));
  }

  //Workaround to pronounce the Dialog Message when entering the first field for first time.
  //Needed because we can't manipulate the Semantics focus in order to focus and pronounce the message first.
  String _initialSemanticsAnnouncement(int position){
    if(position == 0 && _initialAnnounced == false) {
      _initialAnnounced = true;
      return Localization().getStringEx(
          "panel.poll_pin_bouble.label_description",
          "Enter the four-digit poll number to see the poll.");
    }

    return "";
  }

  void _onContinue() {
    if(_validate()) {

      if (!Connectivity().isNotOffline) {
        AppAlert.showDialogResult(context, Localization().getStringEx('common.message.offline', 'You appear to be offline'));
      }
      else {
        setState(() {
          _loading = true;
        });
        
        Polls().load(pollPin: _pinInt).then((Poll? poll) {
          if (poll == null) {
            AppAlert.showDialogResult(context, Localization().getStringEx('panel.poll_pin_bouble.unable_to_load_poll', 'Unable to load poll'));
          }
          else if (poll.status == PollStatus.created) {
            AppAlert.showDialogResult(context, Localization().getStringEx('panel.poll_pin_bouble.poll_not_opened', 'Poll is not opened yet'));
          }
          else if (poll.status == PollStatus.closed) {
            AppAlert.showDialogResult(context, Localization().getStringEx('panel.poll_pin_bouble.poll_closed', 'Poll is already closed'));
          }
          else {
            Navigator.of(context).pop(poll);
          }
        }).catchError((e){
          AppAlert.showDialogResult(context, illinois.Polls.localizedErrorString(e));
        }).whenComplete((){
          setState(() {
            _loading = false;
          });
        });
      }
    }
  }

  void _onClose() {
    Navigator.of(context).pop(null);
  }
}