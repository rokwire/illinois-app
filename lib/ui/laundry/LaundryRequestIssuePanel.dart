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

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Laundries.dart';
import 'package:illinois/ui/laundry/LaundryIssuesDetailPanel.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class LaundryRequestIssuePanel extends StatefulWidget {
  static final String routeSettingsName = 'LaundryRequestIssuePanel';
  
  @override
  _LaundryRequestIssuePanelState createState() => _LaundryRequestIssuePanelState();
}

class _LaundryRequestIssuePanelState extends State<LaundryRequestIssuePanel> {
  final Color _inputDecorationColor = Styles().colors!.mediumGray2!;

  final int _machineIdSymbolsCount = 6;
  List<TextEditingController> _symbolsControllers = [];
  List<FocusNode> _symbolsFocusNodes = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initInputFields();
  }

  @override
  void dispose() {
    _disposeInputFields();
    super.dispose();
  }

  void _initInputFields() {
    if (_machineIdSymbolsCount > 0) {
      for (int symbolIndex = 0; symbolIndex < _machineIdSymbolsCount; symbolIndex++) {
        _symbolsControllers.add(TextEditingController());
        _symbolsFocusNodes.add(FocusNode());
      }
      _symbolsFocusNodes.first.requestFocus();
    }
  }

  void _disposeInputFields() {
    if (CollectionUtils.isNotEmpty(_symbolsControllers)) {
      for (TextEditingController symbolController in _symbolsControllers) {
        symbolController.dispose();
      }
      _symbolsControllers.clear();
    }

    if (CollectionUtils.isNotEmpty(_symbolsFocusNodes)) {
      for (FocusNode symbolFocusNode in _symbolsFocusNodes) {
        symbolFocusNode.dispose();
      }
      _symbolsFocusNodes.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: HeaderBar(title: Localization().getStringEx('panel.laundry.request_issue.header.title', 'Laundry')),
        body: SingleChildScrollView(
            child: Column(children: [
          _buildLaundryColorSection(),
          Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [_buildMachineIdSection(), _buildSubmitSection(), _buildIdExampleSection()]))
        ])),
        backgroundColor: Styles().colors?.background,
        bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildLaundryColorSection() {
    return Container(color: Styles().colors?.accentColor2, height: 4);
  }

  Widget _buildMachineIdSection() {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(
              padding: EdgeInsets.only(bottom: 22),
              child: Text(Localization().getStringEx('panel.laundry.request_issue.machine_id.enter.label', 'Please enter the Machine ID'),
                  textAlign: TextAlign.center,
                  style: Styles().textStyles?.getTextStyle("widget.description.extra_large"))),
          Container(
              padding: EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Styles().colors!.white,
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                  boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: _buildMachineIdInputFields()))
        ]));
  }

  List<Widget> _buildMachineIdInputFields() {
    int itemsCount = _machineIdSymbolsCount + 1; // 1 is for the dash
    int dashIndex = itemsCount ~/ 2;
    List<Widget> widgetList = <Widget>[];
    for (int i = 0; i < itemsCount; i++) {
      if (i == dashIndex) {
        widgetList.add(Center(child: Container(height: 2, width: 20, color: _inputDecorationColor)));
      } else {
        widgetList.add(_buildSymbolInputField((i < dashIndex) ? i : (i - 1)));
      }
    }
    return widgetList;
  }

  Widget _buildSymbolInputField(int fieldIndex) {
    return Container(
        width: 40,
        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: _inputDecorationColor, width: 2))),
        child: Center(
            child: TextField(
                inputFormatters: [LengthLimitingTextInputFormatter(1)],
                onChanged: (textValue) {
                  if (StringUtils.isEmpty(textValue)) {
                    return;
                  }
                  if(fieldIndex < (_machineIdSymbolsCount - 1) && (fieldIndex < _symbolsFocusNodes.length)) {
                    _symbolsFocusNodes[(fieldIndex + 1)].requestFocus();
                  } else {
                    _symbolsFocusNodes[fieldIndex].unfocus();
                  }
                },
                focusNode: _symbolsFocusNodes[fieldIndex],
                controller: _symbolsControllers[fieldIndex],
                cursorColor: _inputDecorationColor,
                textCapitalization: TextCapitalization.characters,
                autocorrect: false,
                enableSuggestions: false,
                textAlign: TextAlign.center,
                style: Styles().textStyles?.getTextStyle("widget.input_field.enable.text.extra_large"),
                decoration: InputDecoration(border: InputBorder.none))));
  }

  Widget _buildSubmitSection() {
    return Padding(
        padding: EdgeInsets.only(bottom: 40),
        child: Stack(alignment: Alignment.center, children: [
          RoundedButton(
              label: Localization().getStringEx('panel.laundry.request_issue.button.submit.label', 'Submit'),
              textStyle: Styles().textStyles?.getTextStyle("widget.colourful_button.title.large.accent"),
              backgroundColor: Styles().colors!.fillColorPrimary,
              contentWeight: 0.5,
              borderColor: Styles().colors!.fillColorPrimary,
              onTap: _onTapSubmit,
              rightIcon: Styles().images?.getImage('chevron-right-white', excludeFromSemantics: true)),
          Visibility(visible: _isLoading, child: CircularProgressIndicator())
        ]));
  }

  Widget _buildIdExampleSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Padding(
          padding: EdgeInsets.only(bottom: 18),
          child: Text(Localization().getStringEx('panel.laundry.request_issue.machine_id.example.label', 'Machine ID Example'),
              textAlign: TextAlign.center,
              style: Styles().textStyles?.getTextStyle("widget.title.medium.fat"))),
      Styles().images?.getImage('laundry-placeholder') ?? Container(),
    ]);
  }

  void _onTapSubmit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_isLoading) {
      return;
    }
    for (TextEditingController controller in _symbolsControllers) {
      if (controller.text.isEmpty) {
        AppAlert.showDialogResult(
            context, Localization().getStringEx('panel.laundry.request_issue.validation.empty_field', 'Please, fill all fields.'));
        return;
      }
    }
    _setLoading(true);
    String machineId = '';
    int itemsCount = _symbolsControllers.length + 1; // 1 is for the dash
    int dashIndex = itemsCount ~/ 2;
    String currentSymbol;
    for (int i = 0; i < itemsCount; i++) {
      if (i < dashIndex) {
        currentSymbol = _symbolsControllers[i].text;
      } else if (i == dashIndex) {
        currentSymbol = '-';
      } else {
        currentSymbol = _symbolsControllers[i - 1].text;
      }
      machineId += currentSymbol;
    }

    Laundries().loadMachineServiceIssues(machineId: machineId).then((machineIssues) {
      if (machineIssues != null) {
        Analytics().logSelect(target: "Laundry: Issues");
        Navigator.push(context, CupertinoPageRoute(builder: (context) => LaundryIssuesDetailPanel(issues: machineIssues)));
      } else {
        AppAlert.showDialogResult(
            context,
            Localization().getStringEx(
                'panel.laundry.request_issue.submit.failed', 'Failed to load machine details. Please, type correct machine id.'));
      }
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (mounted) {
      setState(() {});
    }
  }
}
