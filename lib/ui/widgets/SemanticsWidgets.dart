import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AccessibleViewPagerNavigationButtons extends StatefulWidget{
  final PageController? controller;
  final int? initialPage;
  final int Function()? pagesCount; //This must be a function in order to receive updates if the count changes
  final Widget? centerWidget;

  const AccessibleViewPagerNavigationButtons({Key? key, this.controller, this.initialPage, this.pagesCount, this.centerWidget}) : super(key: key);

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
        Opacity(opacity: _previousButtonAvailable ? 1 : 0, child:
          Semantics(label: "Previous Page", button: true, child:
            IconButton(onPressed: _onTapPrevious, icon:
              Styles().images?.getImage('chevron-left-bold', excludeFromSemantics: true) ?? Container()
            )
          )
        ),
        
        Expanded(child: widget.centerWidget ?? Container()),
        
        Opacity(opacity: _nextButtonAvailable ? 1 : 0, child:
          Semantics(label: "Next Page", button: true, child:
            IconButton(onPressed: _onTapNext, icon:
              Styles().images?.getImage('chevron-right-bold', excludeFromSemantics: true) ?? Container()
            )
          )
        )
      ],),
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
    int count = widget.pagesCount?.call() ?? 0;
    return _currentPage < (count - 1);
  }

  bool get _previousButtonAvailable{
    return _currentPage > 0;
  }

}