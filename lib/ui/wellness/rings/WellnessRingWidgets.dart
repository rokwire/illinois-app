import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/wellness/WellnessReing.dart';
import 'package:illinois/service/WellnessRings.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

// Widgets
//////////////////

//WellnessRing
class WellnessRing extends StatefulWidget{
  final Color? backgroundColor;

  WellnessRing({this.backgroundColor = Colors.white});

  @override
  State<WellnessRing> createState() => _WellnessRingState();
}

class _WellnessRingState extends State<WellnessRing> with TickerProviderStateMixin implements NotificationsListener{
  static const int OUTER_SIZE = 250;
  static const int STROKE_SIZE = 35;
  static const int PADDING_SIZE = 2;
  static const int ANIMATION_DURATION_MILLISECONDS = 1500;
  static const int MIN_RINGS_COUNT = 4;

  List<WellnessRingData>? _ringsData ;
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
    super.dispose();
    NotificationService().unsubscribe(this);
    if(_animationControllers.isNotEmpty) {
      _animationControllers.values.forEach((controller) {
        controller.dispose();
      });
    }
    _controllerCenter.dispose();
  }

  void _loadRingsData() async {
    WellnessRings().getWellnessRings().then((value) {
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
    List<WellnessRingData> data = [];
    int fillCount = MIN_RINGS_COUNT - (_ringsData?.length ?? 0);
    if(fillCount > 0){
      for (int i=0; i<fillCount; i++){
        data.add(WellnessRingData(id: "empty_$i", goal: 1, timestamp: DateTime.now().millisecondsSinceEpoch));
      }
    }
    if(_ringsData?.isNotEmpty ?? false){
      data.addAll(_ringsData!);
    }

    return _buildRing(data: data);
  }

  Widget _buildRing({int level = 0, required List<WellnessRingData> data}){
    WellnessRingData? ringData = data.length > level? data[level] : null;
    return ringData != null ? //Recursion bottom
    _buildRingWidget(
        level: level,
        data: data[level],
        childWidget: _buildRing(level: level + 1, data: data)) : //recursion)
    _buildProfilePicture();
  }

  Widget _buildRingWidget({required int level, WellnessRingData? data, Widget? childWidget}){

    double? innerContentSize = (OUTER_SIZE - ((level) * (STROKE_SIZE + PADDING_SIZE))).toDouble();

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
            // // color: Colors.green,
            width: innerContentSize,
            height: innerContentSize,
            child: Stack(
              children: [
                Center(
                    child: GestureDetector( //TBD REMOVE TMP TEST SOLUTION
                      onTap: (){if(data.id!="empty") WellnessRings().addRecord(WellnessRingRecord(value: 1, timestamp: DateTime.now().millisecondsSinceEpoch, wellnessRingId: data.id));},
                      child: SizedBox(
                          height: innerContentSize,
                          width: innerContentSize,
                          child: CircularProgressIndicator(
                            strokeWidth: STROKE_SIZE.toDouble(),
                            value: controller!.value >= 1 ? 0.999 : controller.value,
                            // * (completion) >= 1 ? 0.999 : completion, // Simulate padding in the end
                            color: data.color,
                            backgroundColor: Colors.white,
                          )),
                    )),
                Center(
                    child:
                    Container(
                      width: innerContentSize,
                      height: innerContentSize,
                      decoration: BoxDecoration(
                          color: Styles().colors!.background!,
                          shape: BoxShape.circle
                      ),
                    )),
                Center(
                    child: Container(
                      width: innerContentSize - PADDING_SIZE,
                      height: innerContentSize - PADDING_SIZE,
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
          Container(decoration: BoxDecoration(shape: BoxShape.circle, image: DecorationImage(fit: BoxFit.cover, image: Image.asset('images/missing-photo-placeholder.png', excludeFromSemantics: true).image))),
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
      WellnessRings().getWellnessRings().then((value){
        _ringsData = value;
        if(mounted) {
          setState(() {});
        }
      });
    } else if( name == WellnessRings.notifyUserRingsAccomplished){
      if (param != null && param is String) {
        WellnessRingData? data = WellnessRings().wellnessRings
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
      _playConfetti();
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
  final bool showLeftIcon;
  final bool showRightIcon;
  final Color? color;
  final bool enabled;
  final void Function(BuildContext context) onTapWidget;
  final void Function(BuildContext context)? onTapRightWidget;

  const WellnessRingButton({Key? key, required this.label, this.description, this.showLeftIcon = false, this.showRightIcon = false, this.color, required this.onTapWidget, this.onTapRightWidget, this.enabled = true}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _WellnessRingButtonState();

}

class _WellnessRingButtonState extends State<WellnessRingButton>{

  @override
  Widget build(BuildContext context) {
    return Semantics(label: widget.label, hint: widget.description, button: true, excludeSemantics: true, child:
    GestureDetector(onTap: () => widget.enabled? widget.onTapWidget(context): null, child:
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
      Expanded(child:
      Container(decoration: BoxDecoration(color: widget.color ?? Colors.white, borderRadius: BorderRadius.all(Radius.circular(4)), border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1)), child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), child:
      Row(children: <Widget>[
        widget.showLeftIcon ? Padding(padding: EdgeInsets.only(right: 6), child: _leftIcon) : Container(),
        Expanded(child:
        Text(widget.label ,
          style: TextStyle(color:widget.enabled? (widget.color!=null? Colors.white : Styles().colors!.fillColorPrimary!) :  Styles().colors!.disabledTextColor!,
            fontFamily: Styles().fontFamilies!.bold, fontSize: 16), textAlign: TextAlign.start,),
        ),
        Expanded(child:
        Text(widget.description ?? "" ,
          style: TextStyle(color: widget.enabled? (widget.color!=null? Colors.white : Styles().colors!.textSurface!) : Styles().colors!.disabledTextColor,
            fontFamily: Styles().fontFamilies!.regular, fontSize: 14), textAlign: TextAlign.end,),
        ),
        widget.showRightIcon ? Padding(padding: EdgeInsets.only(left: 6), child: _rightIcon) : Container(),
      ],),
      ),
      )
      ),
    ],),
    ),
    );
  }

  Widget get _leftIcon{
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Image.asset('images/icon-create-event.png', excludeFromSemantics: true, color: widget.enabled ? Styles().colors!.fillColorPrimary! : Styles().colors!.disabledTextColor),
    ); //TBD
  }

  Widget get _rightIcon{
    return GestureDetector(
        onTap: (){ if (widget.onTapRightWidget!=null) widget.onTapRightWidget!(this.context);},
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Image.asset('images/icon-gear.png', excludeFromSemantics: true, color:  Styles().colors!.white!),
        ));
  }
}

class AccomplishmentCard extends StatefulWidget{
  final String? title; //Date at top
  final List<WellnessRingAccomplishment>? accomplishments;

  const AccomplishmentCard({Key? key, this.title, this.accomplishments}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _AccomplishmentCardState();

}

class _AccomplishmentCardState extends State<AccomplishmentCard>{

  @override
  Widget build(BuildContext context) {
    return CollectionUtils.isEmpty(widget.accomplishments) ? Container() :
    Container( //TBD Draw
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(width: 1, color: Styles().colors!.surfaceAccent!), borderRadius: BorderRadius.circular(5), ),
      child: _buildAccomplishmentCard(widget.title??"", widget.accomplishments),
    );
  }

  Widget _buildAccomplishmentCard(String title, List<WellnessRingAccomplishment>? accomplishedRings){
    List<Widget> accomplishmentsTextContent = [];
    List<Widget> accomplishmentsCircleContent = [];
    if(accomplishedRings==null || accomplishedRings.isEmpty){
      return Container(); //Empty scip
    }

    for(var accomplishedRingData in accomplishedRings){
      //TEXT
      accomplishmentsTextContent.add(
          Container( //Accomplished ring within Card
              child: Text("${accomplishedRingData.ringData.name?? "N/A"} ${_trimDecimal(accomplishedRingData.achievedValue)}/${_trimDecimal(accomplishedRingData.ringData.goal)}")
          ));
      accomplishmentsTextContent.add(Container(height: 2,));
      //RING
      accomplishmentsCircleContent.add(_buildRingCircle(color: accomplishedRingData.ringData.color ?? Colors.white));
      accomplishmentsCircleContent.add(Container(height: 5,));
    }

    return Container(
        child:
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Container(height: 2,),
                  Text("${widget.accomplishments?.length} Rings Completed!"),
                  Container(height: 6,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: accomplishmentsTextContent,)
                ],
              ),
            ),
            Container(
                child:Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: accomplishmentsCircleContent,
                )
            )
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
      FavoriteStarIcon(style: FavoriteIconStyle.Button, padding: EdgeInsets.symmetric(horizontal: 16))
    ]);
  }
}