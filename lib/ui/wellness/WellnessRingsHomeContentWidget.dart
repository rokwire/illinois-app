/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/styles.dart';

class WellnessRingsHomeContentWidget extends StatefulWidget {
  WellnessRingsHomeContentWidget();

  @override
  State<WellnessRingsHomeContentWidget> createState() => _WellnessRingsHomeContentWidgetState();
}

class _WellnessRingsHomeContentWidgetState extends State<WellnessRingsHomeContentWidget> {
  List<WellnessRingData>? _data ;

  @override
  void initState() {
    super.initState();
    _loadRingData();
  }

  @override
  Widget build(BuildContext context) {
    return _buildRing(0);
  }

  void _loadRingData(){
    //TODO implement
    _data = [
      WellnessRingData(name: "Sports Activity", goal: 2, color: Colors.brown ,value: 1),
      WellnessRingData(name: "Water ", goal: 3, color: Colors.blue ,value: 1),
      WellnessRingData(name: "Sleep ", goal: 8, color: Colors.orange ,value: 1),
      WellnessRingData(name: "Study ", goal: 4, color: Colors.yellow ,value: 4, unit: "Sessions"),
      WellnessRingData(name: "Outdoor Activities ", goal: 4, color: Colors.green ,value: 3, unit: "Sessions"),
      WellnessRingData(name: "Food", goal: 4, color: Colors.red ,value: 2, unit: "meals"),
      WellnessRingData(name: "Reading", goal: 60, color: Colors.blueGrey ,value: 64, unit: "minutes"),
    ];
  }

  Widget _buildRing(int index, ){
    final double mainSize = 200;
    final double stepSize = 20;

    WellnessRingData? data = (_data?.length ?? 0) > index ? _data![index] : null;
    return  data!= null ?
        WellnessRing(
          data: data,
          size : mainSize - (index * stepSize),
          child:  _buildRing(index + 1))
    : _buildProfilePicture();
  }

  Widget _buildProfilePicture(){
    //TODO implement
    return Container(
      child: Center(
        child: Text("Profile TBD", textAlign: TextAlign.center,),
      )
    );
  }
}

class WellnessRing extends StatefulWidget{
  final double size;
  final WellnessRingData data;
  final Color? backgroundColor;
  final Widget? child;

  WellnessRing({required this.data, this.child, this.size = 200, this.backgroundColor});

  @override
  State<WellnessRing> createState() => _WellnessRingState();
}

class _WellnessRingState extends State<WellnessRing>{
  final double strokeSize = 10;
  final int animationDuration = 1300;

  @override
  Widget build(BuildContext context) {
    return Container(
      child:
      Center(
        // This Tween Animation Builder is Just For Demonstration, Do not use this AS-IS in Projects
        // Create and Animation Controller and Control the animation that way.
        child: TweenAnimationBuilder(
          tween: Tween(begin: 0.0,end: 1.0),
          duration: Duration(milliseconds: (animationDuration * widget.data.getPercentage()).toInt()),
          builder: (context, value ,child){
            int percentage = ((value as double )* widget.data.getPercentage()*100).ceil();
            return Container(
              // color: Colors.green,
              width: widget.size,
              height: widget.size,
              child: Stack(
                children: [
                  SizedBox(
                  height: widget.size,
                  width: widget.size,
                   child: CircularProgressIndicator(
                     strokeWidth: strokeSize,
                    value: value* widget.data.getPercentage(),
                    color: widget.data.color,
                  )),
                  Center(
                    child: Container(
                      width: widget.size-strokeSize,
                      height: widget.size-strokeSize,
                      decoration: BoxDecoration(
                          color: widget.backgroundColor ?? Styles().colors!.background!,
                          shape: BoxShape.circle
                      ),
                      child: widget.child ??
                        Center(child: Text("$percentage",
                        style: TextStyle(fontSize: 40),)),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class WellnessRingData {
  double goal;
  double value;
  Color color;
  String name;
  String unit;

  WellnessRingData({required this.name, required this.goal, this.value = 0, this.unit = "times" , this.color = Colors.orange});

  double getPercentage(){
    return value / goal;
  }
}
