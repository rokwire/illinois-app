
import 'package:universal_io/io.dart';

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

class AccessibleViewPagerNavigationButtons extends StatefulWidget{
  final PageController? controller;
  final int? initialPage;
  final int Function()? pagesCount; //This must be a function in order to receive updates if the count changes
  final void Function(int index)? onSemanticsLongPress; //If want to override default ficus page behaviour
  final String Function(int index)? semanticsPageLabel;//If want to override default ficus page behaviour
  final SemanticsController? semanticsController;//Used if we want to use the default long press -> focus page
  final Widget? centerWidget;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry iconPadding;

  const AccessibleViewPagerNavigationButtons({Key? key,
    this.controller, this.initialPage, this.pagesCount,
    this.semanticsPageLabel, this.onSemanticsLongPress, this.semanticsController,
    this.centerWidget,
    this.padding = EdgeInsets.zero,
    this.iconPadding = const EdgeInsets.all(16),
  }) : super(key: key);

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
      Padding(padding: widget.padding, child:
        Row(children: [
          MergeSemantics(child:
            Semantics(label: "Previous Page", hint: _iosHint, onLongPressHint: _longPressHint, child:
              IconButton(
                icon: Styles().images.getImage(_previousButtonAvailable ? 'chevron-left-bold' :  'chevron-left-gray', size: 12, excludeFromSemantics: true) ?? Container(),
                padding: widget.iconPadding,
                constraints: const BoxConstraints(), // make box constraints empty
                style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap), // And this sstyle
                onPressed: _previousButtonAvailable ? _onTapPrevious : null,
                onLongPress: _hasLongPress ? _onLongPress : null,
              )
            )
          ),
          Expanded(child: widget.centerWidget ?? Container()),
          MergeSemantics(child:
            Semantics(label: "Next Page", hint:  _iosHint, onLongPressHint: _longPressHint, child:
              IconButton(
                icon: Styles().images.getImage(_nextButtonAvailable ? 'chevron-right-bold' :  'chevron-right-gray', size: 12, excludeFromSemantics: true) ?? Container(),
                padding: widget.iconPadding,
                constraints: const BoxConstraints(), // make box constraints empty
                style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap), // And this sstyle
                onPressed:_nextButtonAvailable? _onTapNext : null,
                onLongPress: _hasLongPress ? _onLongPress : null,
              )
            )
          )
        ],),
      ),
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
          widget.semanticsController?.pronouncePage(_currentPageIdentifier, prefix: "Showing: ");
        }
    });
  }

  dynamic get _currentPageIdentifier => _currentPageIndex;

  String? get _iosHint => Platform.isIOS  && _hasLongPress ? "Double tap and hold to  $_longPressHint" : "";
  String? get _longPressHint => _hasLongPress ? "focus card" : null;

  bool get _hasLongPress => AppSemantics.isAccessibilityEnabled(context) &&
      (widget.onSemanticsLongPress != null || widget.semanticsController !=null);
}

class SemanticsController <T>{
  final SemanticsPageAdapter<T>? adapter;

  SemanticsController({required this.adapter});

  GlobalKey? getPage(dynamic key) => adapter?.getPageFor(key);

  SemanticsNode? getPageSemanticsNode(dynamic item)  => AppSemantics.extractSemanticsNote(getPage(item));

  void focusPage(dynamic item) =>AppSemantics.triggerAccessibilityFocus(getPage(item));

  void tapPage(dynamic item) => AppSemantics.triggerAccessibilityTap(getPage(item));

  void pronouncePage(dynamic item, {String prefix="", String suffix=""}) => AppSemantics.announceMessage(getPage(item)?.currentContext,
      "$prefix "+ (getPageSemanticsNode(item)?.label ?? "") + " $suffix");
}

class SemanticsPageMapAdapter<T> extends SemanticsPageAdapter<T> {
  final Map<T, GlobalKey> keys;
  SemanticsPageMapAdapter({required this.keys, super.mapper});

  @override
  GlobalKey? getPage(T key) => keys[key];
}

class SemanticsPageListAdapter extends SemanticsPageAdapter<int> { // Should be <int>, but it is not in order to support SemanticsPageAdapter.fromList
  final List<GlobalKey> keys;
  SemanticsPageListAdapter({required this.keys, super.mapper});

  @override
  GlobalKey<State<StatefulWidget>>? getPage(int index) =>
      0 <= index && index < keys.length ? keys[index] : null;
}

typedef SemanticsPageMapper<T> = T? Function(dynamic mappedKey);

abstract class SemanticsPageAdapter<T> {
  final SemanticsPageMapper<T>? mapper;// Optional mapping function
  SemanticsPageAdapter({this.mapper});

  //Factory
  static  SemanticsPageAdapter<int> fromList({required List<GlobalKey> keys, SemanticsPageMapper<int>? mapper}) =>
      SemanticsPageListAdapter(keys: keys, mapper: mapper);

  static  SemanticsPageAdapter<T> fromMap<T>({required Map<T, GlobalKey> keys, SemanticsPageMapper<T>? mapper}) =>
      SemanticsPageMapAdapter(keys: keys, mapper: mapper);

    GlobalKey? getPage(T key);

    @protected
    GlobalKey? getPageFor(dynamic key){
      T? mappedKey = _mapper.call(key);
      if(mappedKey != null)
        return getPage(mappedKey);

      return null;
    }

    SemanticsPageMapper<T> get _mapper => this.mapper ?? _defaultMapper;
    SemanticsPageMapper<T>  get _defaultMapper => (key) => key is T  ? key : null;
}

class AccessibleDropDownMenuItem <T> extends DropdownMenuItem <T>{
  AccessibleDropDownMenuItem({required Widget child,  super.key,  super.value, String? semanticsLabel}) :
      super(child: Semantics(label: semanticsLabel, button: true, inMutuallyExclusiveGroup: true, container: true, child: child));

  @override
  Widget build(BuildContext context) => MergeSemantics(child: Semantics(container: true, child:
      super.build(context)
  ));
}

class WebFocusableSemanticsWidget extends StatelessWidget {
  final Widget child;
  final Function? onSelect;

  WebFocusableSemanticsWidget({required this.child, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
        focusNode: FocusNode(),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<Intent>(onInvoke: (_) {
            if (onSelect != null) {
              onSelect?.call();
            }
            return null;
          }),
        },
        child: child);
  }
}