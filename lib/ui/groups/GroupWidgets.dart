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
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/widgets/RoundedButton.dart';
import 'package:illinois/ui/widgets/ScalableWidgets.dart';

/////////////////////////////////////
// GroupDropDownButton

typedef GroupDropDownDescriptionDataBuilder<T> = String Function(T item);

class GroupDropDownButton<T> extends StatefulWidget{
  final String emptySelectionText;
  final String buttonHint;

  final T initialSelectedValue;
  final List<T> items;
  final GroupDropDownDescriptionDataBuilder<T> constructTitle;
  final GroupDropDownDescriptionDataBuilder<T> constructDescription;
  final Function onValueChanged;

  final EdgeInsets padding;
  final BoxDecoration decoration;

  GroupDropDownButton({Key key, this.emptySelectionText,this.buttonHint, this.initialSelectedValue, this.items, this.onValueChanged,
    this.constructTitle, this.constructDescription, this.padding = const EdgeInsets.only(left: 12, right: 8), this.decoration}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _GroupDropDownButtonState<T>();
  }
}

class _GroupDropDownButtonState<T> extends State<GroupDropDownButton>{
  T selectedValue;

  @override
  void initState() {
    selectedValue = widget.initialSelectedValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    TextStyle valueStyle = TextStyle(color: Styles().colors.fillColorPrimary, fontSize: 16, fontFamily: Styles().fontFamilies.bold);
    TextStyle hintStyle = TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular);

    String buttonTitle = _getButtonTitleText();
    String buttonDescription = _getButtonDescriptionText();
    return Container (
        decoration: widget.decoration != null
            ? widget.decoration
            : BoxDecoration(
            color: Styles().colors.white,
            border: Border.all(
                color: Styles().colors.surfaceAccent,
                width: 1),
            borderRadius:
            BorderRadius.all(Radius.circular(4))),
        padding: widget.padding,
        child:
        Column( crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Semantics(
                label: buttonTitle,
                hint: widget.buttonHint,
                excludeSemantics: true,
                child: Theme(
                  data: ThemeData( /// This is as a workaround to make dropdown backcolor always white according to Miro & Zepplin wireframes
                    hoverColor: Styles().colors.white,
                    focusColor: Styles().colors.white,
                    canvasColor: Styles().colors.white,
                    primaryColor: Styles().colors.white,
                    accentColor: Styles().colors.white,
                    highlightColor: Styles().colors.white,
                    splashColor: Styles().colors.white,
                  ),
                  child: DropdownButton(
                      icon: Image.asset('images/icon-down-orange.png'),
                      isExpanded: true,
                      focusColor: Styles().colors.white,
                      underline: Container(),
                      hint: Text(buttonTitle ?? "", style: selectedValue == null?hintStyle:valueStyle),
                      items: _constructItems(),
                      onChanged: (value){
                        selectedValue = value;
                        widget.onValueChanged(value);
                        setState(() {});
                      }),
                ),
              ),
              buttonDescription==null? Container():
              Container(
                padding: EdgeInsets.only(right: 42, bottom: 12),
                child: Text(buttonDescription,
                  style: TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
                ),
              )
            ]
        )
    );
  }

  Widget _buildDropDownItem(String title, String description, bool isSelected){
    return
      Container(
          color: (Colors.white),
        child:Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Container(height: 20,),
            Row(
                mainAxisSize: MainAxisSize.max,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          title,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontFamily: isSelected? Styles().fontFamilies.bold : Styles().fontFamilies.regular,
                              color: Styles().colors.fillColorPrimary,
                              fontSize: 16),
                        ),
                      )),
                  isSelected
                      ? Image.asset("images/checkbox-selected.png")
                      : Image.asset("images/oval-orange.png")
                ]),
            description==null? Container() : Container(height: 6,),
            description==null? Container():
            Container(
              padding: EdgeInsets.only(right: 30),
              child: Text(description,
                style: TextStyle(color: Styles().colors.mediumGray, fontSize: 16, fontFamily: Styles().fontFamilies.regular),
              ),
            ),
            Container(height: 20,),
            Container(height: 1, color: Styles().colors.fillColorPrimaryTransparent03,)
          ],)
    );
  }

  String _getButtonDescriptionText(){
    if(selectedValue!=null){
      return widget.constructDescription!=null? widget.constructDescription(selectedValue) : null;
    } else {
      //empty null for now
      return null;
    }
  }

  String _getButtonTitleText(){
    if(selectedValue!=null){
      return widget.constructTitle!=null? widget.constructTitle(selectedValue) : selectedValue.toString();
    } else {
      return widget.emptySelectionText;
    }
  }

  List<DropdownMenuItem<dynamic>> _constructItems(){
    int optionsCount = widget.items?.length ?? 0;
    if (optionsCount == 0) {
      return null;
    }
    return widget.items.map((Object item) {
      String name = widget.constructTitle!=null? widget.constructTitle(item) : item?.toString();
      String description = widget.constructDescription!=null? widget.constructDescription(item) : null;
      bool isSelected = selectedValue!=null && selectedValue == item;
      return DropdownMenuItem<dynamic>(
        value: item,
        child: item!=null? _buildDropDownItem(name,description,isSelected): Container(),
      );
    }).toList();
  }

}

/////////////////////////////////////
// GroupMembershipAddButton

class GroupMembershipAddButton extends StatelessWidget {
  final String             title;
  final GestureTapCallback onTap;
  final double             height;
  final EdgeInsetsGeometry padding;
  final bool               enabled;
  
  GroupMembershipAddButton({
    this.title,
    this.onTap,
    this.height = 42,
    this.padding = const EdgeInsets.only(left:24, right: 8,),
    this.enabled = true
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
      child: Container(height: height,
        decoration: BoxDecoration(color: Colors.white,
          border: Border.all(color: enabled ? Styles().colors.fillColorSecondary : Styles().colors.surfaceAccent, width: 2),
          borderRadius: BorderRadius.circular(height / 2),
        ),
        child: Padding(padding: EdgeInsets.only(left:16, right: 8, ),
          child: Center(
            child: Row(children: <Widget>[
              Text(title, style: TextStyle(fontFamily: Styles().fontFamilies.bold, fontSize: 16, color: enabled ? Styles().colors.fillColorPrimary : Styles().colors.surfaceAccent),),
            ],)
          )
        ),
      ),
    );
  }
}

class HeaderBackButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: Localization().getStringEx('headerbar.back.title', 'Back'),
      hint: Localization().getStringEx('headerbar.back.hint', ''),
      button: true,
      excludeSemantics: true,
      child: IconButton(
          icon: Image.asset('images/chevron-left-white.png'),
          onPressed: (){
            Analytics.instance.logSelect(target: "Back");
            Navigator.pop(context);
          }),
    );
  }
}

class GroupsConfirmationDialog extends StatelessWidget{
  final String message;
  final String buttonTitle;
  final Function onConfirmTap;

  const GroupsConfirmationDialog({Key key, this.message, this.buttonTitle, this.onConfirmTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Styles().colors.fillColorPrimary,
      child: StatefulBuilder(
          builder: (context, setStateEx){
            return Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 26),
                    child: Text(
                      message,
                      textAlign: TextAlign.left,
                      style: TextStyle(fontFamily: Styles().fontFamilies.extraBold, fontSize: 20, color: Styles().colors.white),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Expanded(child:
                        ScalableRoundedButton(
                          label: Localization().getStringEx('headerbar.back.title', "Back"),
                          fontFamily: "ProximaNovaRegular",
                          textColor: Styles().colors.fillColorPrimary,
                          borderColor: Styles().colors.white,
                          backgroundColor: Styles().colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: ()=>Navigator.pop(context),
                        )),
                      Container(width: 16,),
                      Expanded(child:
                        ScalableRoundedButton(
                          label: buttonTitle,
                          fontFamily: "ProximaNovaBold",
                          textColor: Styles().colors.fillColorPrimary,
                          borderColor: Styles().colors.fillColorSecondary,
                          backgroundColor: Styles().colors.white,
                          padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          onTap: (){
                            onConfirmTap();
                          },
                      )),
                    ],
                  ),
                ],
              ),
            );
          }),
    );
  }
}