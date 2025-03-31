
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';

/// //Approach with SemanticsPagesController
/// semanticsController: SemanticsPagesController(pageKeys: _groupCardKeys.values.toList()),
/// //Approach with custom association key [Group.id]
/// semanticsController: SemanticsController(keys: _groupCardKeys),
/// pageIdentifier: (index) => visibleGroups?[index].id,
/// pageSemanticsLabel: (index) => ((CollectionUtils.isNotEmpty(visibleGroups) && index < visibleCount) ? visibleGroups![index].title : null) ?? "",
/// //Approach with custom LongPress which basically do what the default lonPress is (when SemanticsController is passed)
/// onSemanticsLongPress: (index) {
///   if (CollectionUtils.isNotEmpty(visibleGroups) && index < visibleCount) {
///     GlobalKey? groupCardKey = _groupCardKeys[visibleGroups![index].id];
///     if (groupCardKey != null) {
///       AppSemantics.triggerAccessibilityFocus(groupCardKey);
///       AppSemantics.triggerAccessibilityTap(groupCardKey);
///     }
///   }
/// }
///
/// //Approach with reworking the card and use static method that simulate the tap. //If we want to directly open the Card Details instead of just focusing the card
///   onSemanticsLongPress: (index) {
///     GroupCard.handleTapGroup(context, group: _getGroupAt(index), displayType: GroupCardDisplayType.homeGroups) ,
///    }

class AccessibleViewPagerNavigationButtons<T> extends StatefulWidget{
  final PageController? controller;
  final int? initialPage;
  final int Function()? pagesCount; //This must be a function in order to receive updates if the count changes
  final void Function(int index)? onSemanticsLongPress; //If want to override default ficus page behaviour
  final String Function(int index)? semanticsPageLabel;//If want to override default ficus page behaviour
  final T Function(int index)? semanticsPageIdentifier;//Get the T key associated with the Semantics Page for the semanticsController By index// If not passed index is used as association key to find the SemanticsPage(GlobalKey)
  final SemanticsController<T>? semanticsController;//Used if we want to use the default long press -> focus page
  final Widget? centerWidget;

  const AccessibleViewPagerNavigationButtons({Key? key, this.controller, this.initialPage, this.pagesCount, this.centerWidget, this.semanticsPageLabel, this.onSemanticsLongPress, this.semanticsController, this.semanticsPageIdentifier}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccessibleViewPagerNavigationButtonsState();
}

class _AccessibleViewPagerNavigationButtonsState extends State<AccessibleViewPagerNavigationButtons>{
  int _currentPageIndex = 0;

  @override
  void initState() {
    _currentPageIndex = widget.initialPage ?? _currentPageIndex;
    widget.controller?.addListener(() {
      if (mounted) {
        setState(() {
          _currentPageIndex = widget.controller?.page?.round() ?? _currentPageIndex;
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
          widget.onSemanticsLongPress?.call(_currentPageIndex);
        } else if(widget.semanticsController != null){
          widget.semanticsController?.focusPage(_currentPageIdentifier);
          widget.semanticsController?.tapPage(_currentPageIdentifier);
        }
    }
  }

  void _onCurrentPageChanged(){
    _pronouncePageAt(_currentPageIndex);
  }

  bool get _nextButtonAvailable{
    int count = widget.pagesCount?.call() ?? 0;
    return _currentPageIndex < (count - 1);
  }

  bool get _previousButtonAvailable{
    return _currentPageIndex > 0;
  }

  //Accessibility
  void _pronouncePageAt(int index) {
    if (widget.semanticsController != null)
      AppSemantics.announceMessage(context, "Double tap and hold to focus card");
    Future.delayed(Duration(
      milliseconds: widget.semanticsController != null && Platform.isIOS ? 3000 : 0), () {
        if (widget.semanticsPageLabel != null) {
          AppSemantics.announceMessage(context,
              "Showing: " + (widget.semanticsPageLabel?.call(index) ?? ""));
        } else if(widget.semanticsController != null){
          widget.semanticsController?.pronouncePage(widget.semanticsPageIdentifier != null ? widget.semanticsPageIdentifier!(_currentPageIndex) : _currentPageIndex,
              prefix: "Showing: ");
        }
    });
  }

  dynamic get _currentPageIdentifier{
    if(widget.semanticsPageIdentifier != null)
      return widget.semanticsPageIdentifier!(_currentPageIndex);
    else if(widget.semanticsController is SemanticsController<int>)
      return _currentPageIdentifier;
    return null;
  }

  String? get _iosHint => Platform.isIOS  && _hasLongPress ? "Double tap and hold to  $_longPressHint" : "";
  String? get _longPressHint => _hasLongPress ? "focus card" : null;

  bool get _hasLongPress => AppSemantics.isAccessibilityEnabled(context) &&
      (widget.onSemanticsLongPress != null || widget.semanticsController !=null);
}


class SemanticsPagesController extends SemanticsController<int>{
  final List<GlobalKey> pageKeys;

  SemanticsPagesController({required this.pageKeys});

  @override //bypass parent keys and work with pageKeys instead
  GlobalKey<State<StatefulWidget>>? getPageKeyFor(int index) =>
      0 <= index && index < pageKeys.length ? pageKeys[index] : null;
}

class SemanticsController <T>{
  final Map<T, GlobalKey>? keys;

  SemanticsController({this.keys});

  @protected //Storage entry point
  GlobalKey? getPageKeyFor(T item) => item != null && keys != null ? keys![item] : null;

  SemanticsNode? getPageSemanticsNode(T item)  => AppSemantics.extractSemanticsNote(getPageKeyFor(item));

  void focusPage(T item) => AppSemantics.triggerAccessibilityFocus(getPageKeyFor(item));

  void tapPage(T item) => AppSemantics.triggerAccessibilityTap(getPageKeyFor(item));

  void pronouncePage(T item, {String prefix="", String suffix=""}) => AppSemantics.announceMessage(getPageKeyFor(item)?.currentContext, "$prefix "+ (getPageSemanticsNode(item)?.label ?? "") + " $suffix");
}