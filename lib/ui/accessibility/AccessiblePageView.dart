import 'package:flutter/material.dart';
import 'package:expandable_page_view/expandable_page_view.dart';
import 'dart:math';


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
    this.onPageChanged,
    this.controller,
    this.mainAxisSize = MainAxisSize.max,
    this.alignment = Alignment.centerLeft,
    this.estimatedPageSize = 0.0,
    this.allowImplicitScrolling = false,
  });

  @override
  State<AccessiblePageView> createState() => _AccessiblePageViewState();
}

class _AccessiblePageViewState extends State<AccessiblePageView> {
  double _maxHeight = 0.0;
  final List<GlobalKey> _keys = [];

  @override
  void initState() {
    super.initState();
    // Assign a GlobalKey to each child
    for (int i = 0; i < widget.children.length; i++) {
      _keys.add(GlobalKey());
    }

    // Measure widgets after the first frame is rendered
    if(_needSizing)
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidgets());
  }

  @override
  Widget build(BuildContext context) => (_needSizing && _maxHeight == 0.0) ?   // If height is not calculated yet, show a measurement layout
    _measurementLayout : // Once measured, build the PageView with a fixed height
      _needSizing ? _sizedLayout : _pageViewLayout;

  void _measureWidgets() {
    if (!mounted) return;

    double maxHeight = 0;
    for (final key in _keys) {
      final RenderBox? renderBox = key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        maxHeight = max(maxHeight, renderBox.size.height);
      }
    }

    if (maxHeight > 0 && maxHeight != _maxHeight) {
      setState(() {
        _maxHeight = maxHeight;
      });
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
                key: _keys[index],
                child: widget.children[index],
              ),
            );
          }),
        ),
      );
  Widget get _sizedLayout => SizedBox(
    height: _maxHeight,
    child: PageView(
      controller: widget.controller,
      children: widget.children,
      onPageChanged: widget.onPageChanged,
      allowImplicitScrolling: widget.allowImplicitScrolling,
    )
  );

    Widget get _pageViewLayout =>
      ExpandablePageView(
          controller: widget.controller,
          children: widget.children,
          onPageChanged: widget.onPageChanged,
          estimatedPageSize: widget.estimatedPageSize,
          allowImplicitScrolling: widget.allowImplicitScrolling,
      );

  bool get _needSizing => widget.mainAxisSize == MainAxisSize.max;
}
