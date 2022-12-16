import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AccessibleViewPagerNavigationButtons extends StatefulWidget{
  final PageController? controller;
  final int? initialPage;
  final int? pagesCount;

  const AccessibleViewPagerNavigationButtons({Key? key, this.controller, this.initialPage, this.pagesCount}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccessibleViewPagerNavigationButtonsState();

}

class _AccessibleViewPagerNavigationButtonsState extends State<AccessibleViewPagerNavigationButtons>{
  int _currentPage = 0;

  @override
  void initState() {

    _currentPage = widget.initialPage ?? _currentPage;
    if(widget.controller!=null){
      widget.controller!.addListener(() {
        if(mounted) {
          setState(() {
            _currentPage = widget.controller?.page?.round() ?? _currentPage;
          });
        }
      });
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Visibility(
              visible: _previousButtonAvailable,
              child: Semantics(
                // enabled: prevEnabled,
                  label: "Previous Page",
                  button: true,
                  child: IconButton(
                      onPressed: _onTapPrevious,
                      icon: Styles().images?.getImage('chevron-left', excludeFromSemantics: true) ?? Container()
                  )
              )
          ),
          Visibility(
              visible: _nextButtonAvailable,
              child: Semantics(
                  label: "Next Page",
                  button: true,
                  child: IconButton(
                      onPressed: _onTapNext,
                      icon: Styles().images?.getImage('chevron-right', excludeFromSemantics: true) ?? Container()
                  )
              )
          )
        ],
      ),
    );
  }

  void _onTapNext(){
    widget.controller?.nextPage(duration: Duration(seconds: 1), curve: Curves.easeIn).then((value){
      if(mounted){
        setState(() {

        });
      }
    });
  }

  void _onTapPrevious(){
    widget.controller?.previousPage(duration: Duration(seconds: 1), curve: Curves.easeIn).then((value) {
      if(mounted){
        setState(() {

        });
      }
    });
  }

  bool get _nextButtonAvailable{
    return _currentPage < ((widget.pagesCount ?? 0) -1);
  }

  bool get _previousButtonAvailable{
    return _currentPage > 0;
  }

}