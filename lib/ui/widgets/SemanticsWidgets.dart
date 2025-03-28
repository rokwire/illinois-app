
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AccessibleViewPagerNavigationButtons extends StatefulWidget{
  final PageController? controller;
  final int? initialPage;
  final int Function()? pagesCount; //This must be a function in order to receive updates if the count changes
  final String Function(int index)? pageSemanticsLabel;
  final void Function(int index)? onSemanticsLongPress;
  final GlobalKey<State<StatefulWidget>>? Function(dynamic index)? pageKey;//Used if we want to use the default long press -> focus page
  final Widget? centerWidget;

  const AccessibleViewPagerNavigationButtons({Key? key, this.controller, this.initialPage, this.pagesCount, this.centerWidget, this.pageSemanticsLabel, this.onSemanticsLongPress, this.pageKey}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccessibleViewPagerNavigationButtonsState();

}

class _AccessibleViewPagerNavigationButtonsState extends State<AccessibleViewPagerNavigationButtons>{
  int _currentPage = 0;

  @override
  void initState() {
    _currentPage = widget.initialPage ?? _currentPage;
    widget.controller?.addListener(() {
      if (mounted) {
        setState(() {
          _currentPage = widget.controller?.page?.round() ?? _currentPage;
        });
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(color: Colors.transparent, child:
      Row(children: [
        MergeSemantics(child: Semantics(label: "Previous Page", hint: _iosHint, onLongPressHint: _longPressHint, child:
            IconButton( icon: Styles().images.getImage(_previousButtonAvailable? 'chevron-left-bold' :  'chevron-left-gray', excludeFromSemantics: true) ?? Container(),
                onPressed: _previousButtonAvailable ? _onTapPrevious : null,
                onLongPress: _hasLongPress ? _onLongPress : null,
            )
        )),
        Expanded(child: widget.centerWidget ?? Container()),
        MergeSemantics(child:
          Semantics(label: "Next Page",
            hint:  _iosHint, onLongPressHint: _longPressHint, child:
              IconButton(onPressed:_nextButtonAvailable? _onTapNext : null,
                onLongPress: _hasLongPress ? _onLongPress : null,
                icon: Styles().images.getImage(_nextButtonAvailable? 'chevron-right-bold' :  'chevron-right-gray', excludeFromSemantics: true) ?? Container()
              )
        ))
      ],),
    );
  }

  void _onTapNext(){
    widget.controller?.nextPage(duration: Duration(seconds: 1), curve: Curves.easeIn).then((_){
      _onCurrentPageChanged();
      if(mounted){
        setState(() {

        });
      }
    });
  }

  void _onTapPrevious(){
    widget.controller?.previousPage(duration: Duration(seconds: 1), curve: Curves.easeIn).then((_) {
      _onCurrentPageChanged();
      if(mounted){
        setState(() {

        });
      }
    });
  }

  void _onLongPress(){
    if(_hasLongPress){
        if(widget.onSemanticsLongPress != null) {
          widget.onSemanticsLongPress?.call(_currentPage);
        } else if(widget.pageKey != null){
          GlobalKey? pageKey = widget.pageKey!(_currentPage);
          if(pageKey != null) {
            AppSemantics.triggerAccessibilityFocus(pageKey);
            AppSemantics.triggerAccessibilityTap(pageKey);
          }
        }
    }
  }

  void _onCurrentPageChanged(){
    _pronouncePageAt(_currentPage);
  }

  bool get _nextButtonAvailable{
    int count = widget.pagesCount?.call() ?? 0;
    return _currentPage < (count - 1);
  }

  bool get _previousButtonAvailable{
    return _currentPage > 0;
  }

  //Accessibility
  void _pronouncePageAt(int index) {
    if (widget.pageKey != null)
      AppSemantics.announceMessage(context, "Double tap and hold to focus card");
    Future.delayed(Duration(milliseconds: Platform.isIOS ? 3000 : 0), () {
      if (widget.pageSemanticsLabel != null) {
        AppSemantics.announceMessage(context,
            "Showing: " + (widget.pageSemanticsLabel?.call(index) ?? ""));
      } else if(widget.pageKey != null){
        AppSemantics.announceMessage(context, "Showing: $_pageSemanticsLabel");
      }
    });
  }

  String? get _iosHint => Platform.isIOS  && _hasLongPress ? "Double tap and hold to  $_longPressHint" : "";
  String? get _longPressHint => _hasLongPress ? "focus card" : null;

  bool get _hasLongPress => AppSemantics.isAccessibilityEnabled(context) &&
      (widget.onSemanticsLongPress != null || widget.pageKey !=null);

  String? get _pageSemanticsLabel => _pageSemanticsNode?.label;

  SemanticsNode? get _pageSemanticsNode => AppSemantics.extractSemanticsNote(widget.pageKey?.call(_currentPage));
}