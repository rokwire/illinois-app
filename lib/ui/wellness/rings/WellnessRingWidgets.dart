import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessReing.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// Widgets
//////////////////

//WellnessRing
class WellnessRing extends StatefulWidget{
  final Color? backgroundColor;
  final int size;
  final int strokeSize;
  final int borderWidth;
  final bool accomplishmentDialogEnabled;
  final bool accomplishmentConfettiEnabled;

  WellnessRing({this.backgroundColor = Colors.white, this.size = _WellnessRingState.OUTER_SIZE, this.strokeSize = _WellnessRingState.STROKE_SIZE, this.accomplishmentDialogEnabled = false, this.borderWidth = _WellnessRingState.PADDING_SIZE, this.accomplishmentConfettiEnabled = true});

  @override
  State<WellnessRing> createState() => _WellnessRingState();
}

class _WellnessRingState extends State<WellnessRing> with TickerProviderStateMixin implements NotificationsListener{
  static const int OUTER_SIZE = 270;
  static const int STROKE_SIZE = 35;
  static const int PADDING_SIZE = 4;
  static const int ANIMATION_DURATION_MILLISECONDS = 1500;
  static const int MIN_RINGS_COUNT = 4;

  List<WellnessRingDefinition>? _ringsData ;
  Map<String, AnimationController> _animationControllers = {};

  late ConfettiController _controllerCenter;

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [
      WellnessRings.notifyUserRingsUpdated,
      WellnessRings.notifyUserRingsAccomplished,
    ]);
    _loadRingsData();
    _controllerCenter = ConfettiController(duration: const Duration(seconds: 5));
    // _animateControllers();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    if(_animationControllers.isNotEmpty) {
      _animationControllers.values.forEach((controller) {
        controller.dispose();
      });
    }
    _controllerCenter.dispose();
    super.dispose();
  }

  void _loadRingsData() async {
    WellnessRings().loadWellnessRings().then((value) {
      _ringsData = value;
      if(mounted) {
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child:
        Center(
            child: _buildRingsContent()
        ));
  }

  Widget _buildRingsContent(){
    List<WellnessRingDefinition> data = [];
    int fillCount = MIN_RINGS_COUNT - (_ringsData?.length ?? 0);
    if(fillCount > 0){
      for (int i=0; i<fillCount; i++){
        data.add(WellnessRingDefinition(id: "empty_$i", goal: 1));
      }
    }
    if(_ringsData?.isNotEmpty ?? false){
      data.addAll(_ringsData!);
    }

    return Container(
        height: widget.size.toDouble()  /*+ widget.strokeSize  + PADDING_SIZE,*/ ,
        width: widget.size.toDouble()  /*+ widget.strokeSize  + PADDING_SIZE,*/,
        decoration: BoxDecoration(
            // color: Colors.red,
          borderRadius: BorderRadius.circular(360),
          border: Border.all(width: 2, color: Styles().colors!.surfaceAccent!),
          // shape: BoxShape.circle,
          boxShadow:  [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
        ),
      child: _buildRing(data: data)
    );
  }

  Widget _buildRing({int level = 0, required List<WellnessRingDefinition> data}){
    WellnessRingDefinition? ringData = data.length > level? data[level] : null;
    return ringData != null ? //Recursion bottom
    _buildRingWidget(
        level: level,
        data: data[level],
        childWidget: _buildRing(level: level + 1, data: data)) : //recursion)
    _buildProfilePicture();
  }

  Widget _buildRingWidget({required int level, WellnessRingDefinition? data, Widget? childWidget}){

    double? innerContentSize = (widget.size - ((level + 1) * (widget.strokeSize + widget.borderWidth))).toDouble();

    if(data!=null) {
      double completion =  WellnessRings().getRingDailyCompletion(data.id);

      AnimationController? controller = _animationControllers[data.id];

      if(controller == null) {
        controller = AnimationController(
            duration: Duration(milliseconds: ANIMATION_DURATION_MILLISECONDS),
            vsync: this);

        _animationControllers[data.id] = (controller);
      }

      if(controller.value!=completion) {
        controller.animateTo(completion, );
      }

      return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Container(
            width: innerContentSize,
            height: innerContentSize,
            child: Stack(
              children: [
                Center(
                    child: SizedBox(
                          height: innerContentSize,
                          width: innerContentSize,
                          child: CircularProgressIndicator(
                            strokeWidth: widget.strokeSize.toDouble(),
                            value: controller!.value >= 1 ? 0.9975 : controller.value,
                            // * (completion) >= 1 ? 0.999 : completion, // Simulate padding in the end
                            color: data.color,
                            backgroundColor: Colors.white,
                          )),
                    ),
                Center(
                    child:
                    Container(
                      width: innerContentSize,
                      height: innerContentSize,
                      decoration: BoxDecoration(
                          color: Styles().colors!.surfaceAccent!,
                          shape: BoxShape.circle
                      ),
                    )),
                Center(
                    child: Container(
                      width: innerContentSize - widget.borderWidth,
                      height: innerContentSize - widget.borderWidth,
                      decoration: BoxDecoration(
                          color: widget.backgroundColor ??
                              Styles().colors!.white!,
                          shape: BoxShape.circle
                      ),
                      child:
                      childWidget ??
                          Center(child: Text("TBD",
                            style: TextStyle(fontSize: 40),)),
                    )
                ),
              ],
            ),
          );
        },
      );
    }
    return Container();
  }

  Widget _buildProfilePicture() { //TBD update image resource
    return
      Stack(
        children: [
          Container(
            padding: EdgeInsets.all(1),
            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white,),
            child:Container(decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(fit: BoxFit.cover, image: Image.asset('images/wellness_ring_profile.png', excludeFromSemantics: true).image))),
          ),
          Center(
              child: ConfettiWidget(
                confettiController: _controllerCenter,
                numberOfParticles: 110,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false, // start again as soon as the animation is finished
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.orange,
                  Colors.red,
                ], // manually specify the colors to be used
                // createParticlePath: drawStar, // define a custom shape/path
              ))
        ],
      );
  }

  @override
  void onNotification(String name, param) {
    if(name == WellnessRings.notifyUserRingsUpdated){
      WellnessRings().loadWellnessRings().then((value){
        _ringsData = value;
        if(mounted) {
          try { //Unhandled Exception: 'package:flutter/src/widgets/framework.dart': Failed assertion: line 4234 pos 12: '_lifecycleState != _ElementLifecycle.defunct': is not true.
            setState(() {});
          } catch (e) {print(e);}
        }
      });
    } else if( name == WellnessRings.notifyUserRingsAccomplished){
      if (widget.accomplishmentDialogEnabled && param != null && param is String) {
        WellnessRingDefinition? data = WellnessRings().wellnessRings
            ?.firstWhere((element) => element.id == param);
        if (data != null) {
          AppAlert.showCustomDialog(context: this.context, contentPadding: EdgeInsets.all(0),
              contentWidget:
              Container(
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(child:
                            Container(height: 3, color: data.color,)
                            )
                          ],
                        ),
                        Container(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Container()),
                                    Container(
                                        padding: EdgeInsets.only(left: 50, bottom: 10),
                                        child: GestureDetector(
                                          onTap: () => Navigator.of(this.context).pop(),
                                          child: Text("x", style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 22),),
                                        )),
                                  ],
                                ),
                                Container(height: 2,),
                                Row(
                                  children: [
                                    Expanded(child:
                                    Text("Congratulations!", textAlign: TextAlign.center,
                                      style :TextStyle(color: Styles().colors!.fillColorPrimary!, fontFamily: Styles().fontFamilies!.bold, fontSize: 18),
                                    )
                                    )
                                  ],
                                ),
                                Container(height: 12,),
                                Row(
                                  children: [
                                    Expanded(child:
                                    RichText(
                                        textAlign: TextAlign.center,
                                        text: TextSpan(
                                            children:[
                                              TextSpan(text:"You've completed your ",
                                                style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),),
                                              TextSpan(text:"${data.name} ", //TBD
                                                style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.bold, fontSize: 16),),
                                              TextSpan(text:"ring for ",
                                                style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.regular, fontSize: 16),),
                                              TextSpan(text:"${WellnessRings().getTotalCompletionCountString(param)} time!",
                                                style :TextStyle(color: Styles().colors!.textSurface!, fontFamily: Styles().fontFamilies!.bold, fontSize: 16),),
                                            ]
                                        ))
                                    ),
                                  ],
                                ),
                                Container(height: 12,),
                              ],)
                        )]
                  )));
        }
      }
      if(widget.accomplishmentConfettiEnabled) {
        _playConfetti();
      }
    }
  }

  void _playConfetti(){
    _controllerCenter.play();
    // Future.delayed(Duration(seconds: 5), (){_controllerCenter.stop();});
  }
}

class WellnessRingButton extends StatefulWidget{
  final String label;
  final String? description;
  final Color? color;
  final bool enabled;
  final void Function(BuildContext context)? onTapWidget;
  final void Function(BuildContext context)? onTapDecrease;
  final void Function(BuildContext context)? onTapIncrease;
  final void Function(BuildContext context)? onTapEdit;

  const WellnessRingButton({Key? key, required this.label, this.description, this.color, this.enabled = true, this.onTapIncrease, this.onTapEdit, this.onTapDecrease, this.onTapWidget}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WellnessRingButtonState();

}

class _WellnessRingButtonState extends State<WellnessRingButton>{

  @override
  Widget build(BuildContext context) {
    return Semantics(label: widget.label, hint: widget.description, button: true, excludeSemantics: true, child:
    GestureDetector(onTap: () => widget.enabled && widget.onTapWidget!=null? widget.onTapWidget!(context): null, child:
    Container(
      // padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child:
        Container(decoration: BoxDecoration(color: widget.color ?? Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
        Padding(padding: EdgeInsets.only(left: 8 /*+10 from icon*/, top: 8, bottom: 8, right: 8/*+10 form icon*/), child:
          Row( crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
            widget.onTapEdit != null ? Padding(padding: EdgeInsets.only(right: 6), child: _editRingButton) : Container(),
            Expanded(
              flex: 5,
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                Text(widget.label ,
                  style: TextStyle(color: Colors.white,
                    fontFamily: Styles().fontFamilies!.bold, fontSize: 14), textAlign: TextAlign.start,),
                widget.description==null ? Container():
                Text(widget.description ?? "" ,
                  style: TextStyle(color: Colors.white,
                      fontFamily: Styles().fontFamilies!.regular, fontSize: 14), textAlign: TextAlign.end,),
                ],),)),
              Container(
                child: Row(
                  children: [
                    widget.onTapDecrease == null ? Container() :
                      _decreaseValueButton,
                    Container(width: 4,),
                    _increaseValueButton,
                  ],
                ),
              ),
          ],),
          ),
        )
      ),
    ],)),
    ),
    );
  }

  Widget get _editRingButton{
    return GestureDetector(
        onTap: (){ if (widget.onTapEdit!=null) widget.onTapEdit!(this.context);},
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Image.asset('images/edit-white.png', excludeFromSemantics: true, color:  Styles().colors!.white!),
        ));
  }
  Widget get _increaseValueButton{
    return GestureDetector(
        onTap: (){ if (widget.onTapIncrease!=null) widget.onTapIncrease!(this.context);},
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Image.asset('images/icons-control-add-small-white.png', excludeFromSemantics: true, color:  Styles().colors!.white!),
        ));
  }

  Widget get _decreaseValueButton{
    return GestureDetector(
        onTap: (){ if (widget.onTapDecrease!=null) widget.onTapDecrease!(this.context);},
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Image.asset('images/group-decrease.png', excludeFromSemantics: true, color:  Styles().colors!.white!),
        ));
  }
}

class SmallWellnessRingButton extends StatefulWidget{
  final String label;
  final Color? color;
  final bool enabled;
  final void Function(BuildContext context)? onTapWidget;

  const SmallWellnessRingButton({Key? key, required this.label, this.color, this.enabled = true, this.onTapWidget}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _SmallWellnessRingButtonState();

}

class _SmallWellnessRingButtonState extends State<SmallWellnessRingButton>{

  @override
  Widget build(BuildContext context) {
    return Semantics(label: widget.label, button: true, excludeSemantics: true, child:
    GestureDetector(onTap: () => widget.enabled && widget.onTapWidget!=null? widget.onTapWidget!(context): null, child:
    Container(
      // padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
          Expanded(child:
          Container(decoration: BoxDecoration(color: widget.color ?? Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
          Padding(padding: EdgeInsets.only(left: 8 /*+10 from icon*/, top: 5, bottom: 5, right: 3/*+10 form icon*/), child:
          Row( crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                  flex: 5,
                  child: Container(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.label ,
                          style: TextStyle(color: Colors.white,
                              fontFamily: Styles().fontFamilies!.regular, fontSize: 14), textAlign: TextAlign.start,),
                      ],),)),
              Container(
                child: Row(
                  children: [
                    _increaseValueButton,
                  ],
                ),
              ),
            ],),
          ),
          )
          ),
        ],)),
    ),
    );
  }

  Widget get _increaseValueButton{
    return GestureDetector(
        onTap: (){},
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Image.asset('images/icons-control-add-small-white.png', excludeFromSemantics: true, color:  Styles().colors!.white!),
        ));
  }
}

class AccomplishmentCard extends StatefulWidget{
  final String? date; //Date at top
  final List<WellnessRingAccomplishment>? accomplishments;

  const AccomplishmentCard({Key? key, this.date, this.accomplishments}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccomplishmentCardState();

}

class _AccomplishmentCardState extends State<AccomplishmentCard>{
  
  @override
  Widget build(BuildContext context) {
    return CollectionUtils.isEmpty(widget.accomplishments) ? Container() :
    Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 0, color: Styles().colors!.surfaceAccent!), borderRadius: BorderRadius.circular(5),
        boxShadow:  [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 2.0, blurRadius: 6.0, offset: Offset(2, 2))]
      ),
      child: _buildAccomplishmentCard(widget.date??"", widget.accomplishments),
    );
  }

  Widget _buildAccomplishmentCard(String title, List<WellnessRingAccomplishment>? accomplishedRings){
    const int MIN_ROWS = 3;
    List<Widget> accomplishmentsTextContent = [];
    List<Widget> accomplishmentsCircleContent = [];
    if(accomplishedRings==null || accomplishedRings.isEmpty){
      return Container(); //Empty scip
    }

    for(var accomplishedRingData in accomplishedRings){
      //TEXT
      accomplishmentsTextContent.add(
          Container( //Accomplished ring within Card
              child: Text("${accomplishedRingData.ringData.name?? "N/A"} Ring - ${_trimDecimal(accomplishedRingData.achievedValue)}/${_trimDecimal(accomplishedRingData.ringData.goal)} ${accomplishedRingData.ringData.unit}${accomplishedRingData.ringData.goal>1?"s":""}",
                  style: TextStyle(color: Colors.black, fontSize: 14, fontFamily: Styles().fontFamilies!.regular)
              )
          ));
      accomplishmentsTextContent.add(Container(height: 4,));
      //RING
      accomplishmentsCircleContent.add(_buildRingCircle(color: accomplishedRingData.ringData.color ?? Colors.white));
      accomplishmentsCircleContent.add(Container(height: 5,));
    }
    if(accomplishedRings.length < MIN_ROWS){
      for( int i = accomplishedRings.length; i< MIN_ROWS; i++){
        accomplishmentsTextContent.add(
            Container( //Accomplished ring within Card
                child: Text(" ")
            ));
        accomplishmentsTextContent.add(Container(height: 4,));
      }
    }

    DateTime? date = DateTimeUtils.parseDateTime(widget.date ??"");
    String weekday = date!=null? DateFormat('EEE').format(date) : "";
    String day = date!=null? DateFormat('d').format(date) : "";
    String month = date!=null? DateFormat('MMM').format(date) : "";
    return Container(
        child:
        Row(
          mainAxisSize: MainAxisSize.max,
          children: [
            Container(
              constraints: BoxConstraints(minWidth: 60),
               padding: EdgeInsets.only(right: 20, top: 16, bottom: 16),
                // decoration: BoxDecoration(color: Colors.white, border: Border(right: BorderSide(color: Styles().colors!.surfaceAccent!,)),  ),
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(weekday,
                      style: TextStyle(color: Styles().colors!.fillColorSecondary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)
                    ),
                    // Container(height: 4,),
                    Text(day,
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 32, fontFamily: Styles().fontFamilies!.regular)
                    ),
                    // Container(height: 4,),
                    Text(month,
                      style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)
                    ),
                  ],
                )
            ),
            Expanded(
              child: Container(
                  padding: EdgeInsets.only(left: 20, top: 16, bottom: 16),
                  decoration: BoxDecoration(color: Colors.white, border: Border(left: BorderSide(color: Styles().colors!.surfaceAccent!, )),  ),
                child:Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("${widget.accomplishments?.length} Rings Completed!",
                    style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 14, fontFamily: Styles().fontFamilies!.bold)
                  ),
                  Container(height: 6,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: accomplishmentsTextContent,)
                ],
              )),
            ),
            // Container(
            //     child:Column(
            //       mainAxisAlignment: MainAxisAlignment.center,
            //       children: accomplishmentsCircleContent,
            //     )
            // )
          ],
        )
    );
  }

  Widget _buildRingCircle({required Color color, Color background = Colors.white}){
    const double WIDGET_SIZE = 25;
    const double STROKE_SIZE = 4;

    return Container(
        width: WIDGET_SIZE,
        height: WIDGET_SIZE,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
        ),
        padding: EdgeInsets.all(STROKE_SIZE),
        child: Container(
          // width: WIDGET_SIZE - STROKE_SIZE,
          // height: WIDGET_SIZE - STROKE_SIZE,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: background,
          ),
        )
    );
  }

  //Util

  num _trimDecimal(double value){
    return value % 1 == 0 ? value.toInt() : value;
  }
}

class WellnessWidgetHelper{
  static Widget buildWellnessHeader() {
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Text(Localization().getStringEx('panel.wellness.ring.create.header.label', 'My Daily Wellness Rings'),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Styles().colors!.fillColorPrimary, fontSize: 18, fontFamily: Styles().fontFamilies!.bold)),
      // FavoriteStarIcon(style: FavoriteIconStyle.Button, padding: EdgeInsets.symmetric(horizontal: 16))
    ]);
  }
}