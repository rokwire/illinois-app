
import 'package:flutter/material.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'dart:math';

import 'package:rokwire_plugin/service/notification_service.dart';

class AccessiblePageView extends StatefulWidget {
  final MainAxisSize mainAxisSize;
  final AlignmentGeometry alignment;

  final double estimatedPageSize;
  final bool allowImplicitScrolling;
  final ValueChanged<int>? onPageChanged;
  final List<Widget> children;
  final PageController? controller;

  const AccessiblePageView({
    super.key,
    required this.children,
    required this.estimatedPageSize,
    this.onPageChanged,
    this.controller,
    this.mainAxisSize = MainAxisSize.min,
    this.alignment = Alignment.centerLeft,
    this.allowImplicitScrolling = false,
  });

  @override
  State<AccessiblePageView> createState() => _AccessiblePageViewState();
}

class _AccessiblePageViewState extends State<AccessiblePageView> with NotificationsListener{
  double _maxHeight = 0.0;
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Storage.notifySettingChanged]);
    if(_needExpanding){
      _constructKeys();
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureAllPages()); //Calculate the max height of the first chink of children
    }
  }

  @override
  void onNotification(String name, param) {
    super.onNotification(name, param);
    if (name == Storage.notifySettingChanged && param == Storage.accessibilityReduceMotionKey) {
      if(_needExpanding) {
        // _maxHeight = widget.estimatedPageSize;
        // _constructKeys();
        // WidgetsBinding.instance.addPostFrameCallback((_) => _measureAllPages());
      }

      setStateIfMounted();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_needExpanding) {
      return _needMeasure ? _measurementLayout : _expandedLayout;
    } else {
      return _shrinkLayout;
    }
  }

  @override
  void didUpdateWidget(AccessiblePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if(_needExpanding) {
      if (widget.children != oldWidget.children ||
          widget.children.length != oldWidget.children.length) {
        //When children are updated we need to update the keys
        //Don't measure all children again because this cause flicking effect when hiding and then showing the PageView
        _constructKeys();
      }
    }
  }

  void _onPageChanged(int position){
    widget.onPageChanged?.call(position);
    //Instead of measuring all children after update, measure just the current page to reduce flicking but still ensure that the page will fit
    if(_needExpanding)
      _measurePage(position);
  }

  void _constructKeys(){
    _keys.clear();
    widget.children.forEach((widget) =>
        _keys.add(GlobalKey()));
  }

  void _measureAllPages() {
    if (!mounted) return;
    for (int i = 0; i < _keys.length; i ++) {
      _measurePage(i);
    }
  }

  void _measurePage(int position){
    final RenderBox? renderBox = _keys[position].currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      double pageHeight =renderBox.size.height;
      if(_maxHeight < pageHeight)
        setStateIfMounted(() =>
        _maxHeight = max(_maxHeight, pageHeight)
        );
    }
  }

  Widget get _measurementLayout => Offstage(
        offstage: true, // This makes the Stack invisible
        child: Stack(
          children: List.generate(widget.children.length, (index) {
            return Align(
              // Use alignment to prevent children from overlapping and taking up screen space
              alignment: widget.alignment,
              child: Container(
                key: _keys.length > index ? _keys[index] : GlobalKey(),
                child: widget.children.length > index ? widget.children[index] : Container()
              ),
            );
          }),
        ),
      );

  Widget get _expandedLayout =>
    SizedBox(
      height: _maxHeight,
      child: ExpandablePageView(
        onPageChanged: _onPageChanged,
        children: List.generate(widget.children.length, (index) =>
          Container(
              key: _keys.length > index ? _keys[index] : GlobalKey(),
              child: widget.children.length > index ? widget.children[index] : Container()
          )
        ),
        controller: widget.controller,
        allowImplicitScrolling: widget.allowImplicitScrolling,
        estimatedPageSize: widget.estimatedPageSize,
      )
  );

  Widget get _shrinkLayout =>
    ExpandablePageView(
        controller: widget.controller,
        children: widget.children,
        onPageChanged: _onPageChanged,
        estimatedPageSize: widget.estimatedPageSize,
        allowImplicitScrolling: widget.allowImplicitScrolling,
    );

  bool get _needMeasure => _maxHeight == 0;

  bool get _needExpanding => widget.mainAxisSize == MainAxisSize.max || _forcedExpanding;

  bool get _forcedExpanding => Storage().accessibilityReduceMotion ?? false;
}
