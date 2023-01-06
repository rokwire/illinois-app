import 'package:flutter/cupertino.dart';
import 'package:rokwire_plugin/service/styles.dart';

class AccessibleViewPagerNavigationButtons extends StatefulWidget{
  final PageController? controller;
  final int? initialPage;
  final int Function()? pagesCount; //This must be a function in order to receive updates if the count changes

  const AccessibleViewPagerNavigationButtons({Key? key, this.controller, this.initialPage, this.pagesCount}) : super(key: key);

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
    return Container(
      padding: EdgeInsets.only(top: 8),
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
                  child: GestureDetector(
                      onTap: _onTapPrevious,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          "<",
                          semanticsLabel: "",
                          style: TextStyle(
                            color : Styles().colors!.fillColorPrimary,
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: 26,
                          ),),)
                  )
              )
          ),
          Visibility(
              visible: _nextButtonAvailable,
              child: Semantics(
                  label: "Next Page",
                  button: true,
                  child: GestureDetector(
                      onTap: _onTapNext,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 24,),
                        child: Text(
                          ">",
                          semanticsLabel: "",
                          style: TextStyle(
                            color : Styles().colors!.fillColorPrimary,
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: 26,
                          ),),)
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
    int count = widget.pagesCount?.call() ?? 0;
    return _currentPage < (count - 1);
  }

  bool get _previousButtonAvailable{
    return _currentPage > 0;
  }

}