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
  double _oldMaxHeight = 0.0;
  final List<GlobalKey> _keys = [];
  final GlobalKey _sizedPageViewKey = GlobalKey();

  int _lastKnownPage = 0;
  bool _isAfterMeasurement = false;

  @override
  void initState() {
    super.initState();
  _constructChildrenKeys();
    if (widget.controller != null) {
      try {
        _lastKnownPage = widget.controller!.initialPage;
      } catch (e) {
        // If controller.initialPage throws (e.g., if it's a late final not yet set, though unlikely for PageController)
        _lastKnownPage = 0;
      }
      widget.controller!.addListener(_updateLastKnownPage);
    }
  // _prepareCopiedChildren();
    // Measure widgets after the first frame is rendered
    if(_needSizing)
      WidgetsBinding.instance.addPostFrameCallback((_) => _measureWidgets());
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_updateLastKnownPage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isAfterMeasurement && _needSizing && !_needMeasure) {
      // We just finished measuring, and _sizedLayout is about to be built.
      // Schedule page restoration for after this frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _restorePagePosition();
        }
      });
    }
    if (_needSizing) {
      if (_needMeasure) { // _maxHeight == 0.0
        return _measurementLayout;
      } else {
        // _maxHeight > 0.0
        return _sizedLayout;
      }
    } else {
      return _pageViewLayout; // ExpandablePageView
    }
  }

  @override
  void didUpdateWidget(AccessiblePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?.removeListener(_updateLastKnownPage);
      if (widget.controller != null) {
        try {
          _lastKnownPage = widget.controller!.initialPage;
        } catch (e) {
          _lastKnownPage = 0;
        }
        widget.controller!.addListener(_updateLastKnownPage);
      } else {
        _lastKnownPage = 0;
      }
    }

    if (widget.children != oldWidget.children || widget.children.length != oldWidget.children.length) {
      _keys.clear();
      _constructChildrenKeys();
      if (_maxHeight > 0) { // If it was previously measured
        _isAfterMeasurement = true; // Signal that the next build of _sizedLayout is after a re-measurement
      }
      _oldMaxHeight = _maxHeight;
      _maxHeight = 0;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { // Ensure the widget is still in the tree
          _measureWidgets();
        }
      });
    }
  }

  void _constructChildrenKeys(){
    for (int i = 0; i < widget.children.length; i++) {
      _keys.add(GlobalKey());
    }
  }

  void _measureWidgets() {
    if (!mounted) return;

    double maxHeight = _oldMaxHeight;
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
                child: widget.children[index]
              ),
            );
          }),
        ),
      );
  Widget get _sizedLayout => Offstage(
    offstage: _needMeasure == true,
    child: SizedBox(
      height: _maxHeight,
      child: PageView(
        key: _sizedPageViewKey,
        controller: widget.controller,
        children: widget.children,
        onPageChanged: widget.onPageChanged,
        allowImplicitScrolling: widget.allowImplicitScrolling,
      )
  ));

    Widget get _pageViewLayout =>
      ExpandablePageView(
          controller: widget.controller,
          children: widget.children,
          onPageChanged: widget.onPageChanged,
          estimatedPageSize: widget.estimatedPageSize,
          allowImplicitScrolling: widget.allowImplicitScrolling,
      );

  void _updateLastKnownPage() {
    if (widget.controller != null && widget.controller!.hasClients && widget.controller!.page != null) {
      final currentPage = widget.controller!.page!.round();
      if (currentPage != _lastKnownPage) {
        _lastKnownPage = currentPage;
        // print("ACCESSIBLE_PV: Controller page changed to $_lastKnownPage");
      }
    }
  }

  void _restorePagePosition() {
    if (widget.controller != null && widget.controller!.hasClients) {
      // Check if the current page on the controller is different from our last known page.
      // This can happen if the PageView reset itself to 0 despite the controller.
      final controllerCurrentPage = widget.controller!.page!.round();
      if (controllerCurrentPage != _lastKnownPage) {
        print("ACCESSIBLE_PV: Restoring page to $_lastKnownPage from ${controllerCurrentPage}");
        widget.controller!.jumpToPage(_lastKnownPage);
      }
    }
    _isAfterMeasurement = false; // Reset the flag
  }

  bool get _needSizing => widget.mainAxisSize == MainAxisSize.max;

  bool get _needMeasure => _maxHeight == 0;
}
