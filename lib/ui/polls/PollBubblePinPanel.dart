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
import 'package:illinois/model/Poll.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Polls.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:illinois/service/Styles.dart';

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

  int get _pinInt{
    return int.tryParse(_pinString);
  }

  bool _isDigit(String text) {
    RegExpMatch match = (text != null) ? _digitRegExp.firstMatch(text) : null;
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
                    decoration: BoxDecoration(color: Styles().colors.fillColorPrimary, borderRadius: BorderRadius.circular(5)),
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
        icon: Image.asset('images/chevron-left-white.png'),
        onPressed: ()=>setState((){_showInfo = false;}),
      ),
      Padding(
        padding: EdgeInsets.only(left: 24, right: 24, top: 10, bottom: 52),
        child: Text(
          Localization().getStringEx("panel.poll_pin_bouble.long_info_description", "Each poll has a 4-digit code associated with it. Only the poll creator can see and share this code. To participate in their poll, have them share the 4-digit code."),
          style: TextStyle(
            fontFamily: Styles().fontFamilies.regular,
            fontSize: 16,
            color: Styles().colors.white
          ),

        ),
      )
    ];
  }

  List<Widget> _buildMainContent() {
    return <Widget>[
      Row(children: <Widget>[Expanded(child: Container(),)],),
      Semantics(label:'', excludeSemantics: true, child:
        Padding(padding: EdgeInsets.only(right: 40), child:
          RichText(
            text: TextSpan(
              text:Localization().getStringEx("panel.poll_pin_bouble.label_description", "Enter your 4-digit code to see poll.") + " ",
              style: TextStyle(color: Colors.white, fontFamily: Styles().fontFamilies.extraBold, fontSize: 24),
              children:[
                WidgetSpan(
                    child: GestureDetector(
                      onTap: ()=>setState((){_showInfo = true;}),
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          borderRadius: new BorderRadius.circular(15.0),
                          border: new Border.all(
                            width: 2.0,
                            color: Styles().colors.fillColorSecondary,
                          ),
                        ),
                        child: Center(
                          child: Text("i",
                            style: TextStyle(
                              fontFamily: Styles().fontFamilies.extraBold,
                              fontSize: 20,
                              color: Styles().colors.fillColorSecondary,
                            ),
                          ),
                        ),
                      ),
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
        ((digit+1) < _digitsCount) ? _digitFocusNodes[digit+1] : null));

    }
    return SingleChildScrollView(scrollDirection: Axis.horizontal,child:Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: widgets,));
  }

  Widget _buildPinField(TextEditingController controller, FocusNode focusNode, FocusNode prevFocusNode, FocusNode nextFocusNode){
    Function nextCallBack = (){
      if(_isDigit(controller?.value?.text)){
        if(nextFocusNode != null) {
          nextFocusNode.requestFocus();
        }
        else{
          focusNode.unfocus();
        }
      }
    };
    return Container(
      width: 20+ 20*MediaQuery.of(context).textScaleFactor,
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
          fillColor: Styles().colors.white,
          border: new OutlineInputBorder(
            borderRadius: const BorderRadius.all(
              const Radius.circular(4),
            ),
          ),
        ),
        style: TextStyle(
          fontFamily: Styles().fontFamilies.regular,
          fontSize: 36,
          color: Styles().colors.fillColorPrimary,
        ),
      ),
    );
  }

  Widget _buildContinueButton() {
    return Padding(
      padding: EdgeInsets.only(top: 20, left: 30, right: 30),
        child: Stack(children: <Widget>[
          RoundedButton(
            label: Localization().getStringEx('dialog.continue.title', 'Continue'),
            hint: Localization().getStringEx('dialog.continue.hint', ''),
            backgroundColor: Styles().colors.white,
            height: 20 + 16*MediaQuery.of(context).textScaleFactor,
            fontSize: 16.0,
            textColor: Styles().colors.fillColorPrimary,
            borderColor: Styles().colors.fillColorSecondary,
            padding: EdgeInsets.symmetric(horizontal: 24),
            onTap: () { _onContinue(); }
          ),       
          Visibility(visible: _loading,
            child: Container(
              height: 42,
              child: Align(alignment: Alignment.center,
                child: SizedBox(height: 21, width: 21,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Styles().colors.fillColorPrimary), )
                ),
              ),
            ),
          ),      
      ],),);
  } 

  Widget _buildCloseButton() {
    return Semantics(
        label: Localization().getStringEx('dialog.close.title', 'Close'),
        hint: Localization().getStringEx('dialog.close.hint', ''),
        button: true,
        excludeSemantics: true,
        child: InkWell(
            onTap : _onClose,
            child: Container(width: 48, height: 48, alignment: Alignment.center, child: Image.asset('images/close-white.png'))));
  }

  void _onContinue() {
    if(_validate()) {
      setState(() {
        _loading = true;
      });
      
      Polls().load(pollPin: _pinInt).then((Poll poll) {
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
        AppAlert.showDialogResult(context, e?.toString() ?? Localization().getStringEx('panel.poll_pin_bouble.unknown_error_description', 'Unknown error occured'));
      }).whenComplete((){
        setState(() {
          _loading = false;
        });
      });
    }
  }

  void _onClose() {
    Navigator.of(context).pop(null);
  }
}