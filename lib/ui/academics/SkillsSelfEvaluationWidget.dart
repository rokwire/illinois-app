// Copyright 2022 Board of Trustees of the University of Illinois.
// 
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// 
//     http://www.apache.org/licenses/LICENSE-2.0
// 
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'package:flutter/material.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';

class SkillsSelfEvaluationWidget extends StatefulWidget {

  SkillsSelfEvaluationWidget();

  @override
  _SkillsSelfEvaluationWidgetState createState() => _SkillsSelfEvaluationWidgetState();
}

class _SkillsSelfEvaluationWidgetState extends State<SkillsSelfEvaluationWidget> {
  //TODO: The completion of the UI for this widget will be addressed by #2513
  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
        RibbonButton(
          label: 'Get Started',
          onTap: _onTapStartEvaluation
        ),
      ),
      Padding(padding: EdgeInsets.only(left: 16, top: 16, right: 16), child:
        RibbonButton(
          label: 'Results',
          onTap: _onTapResults
        ),
      ),
    ]);
  }

  void _onTapStartEvaluation() {

  }

  void _onTapResults() {
    
  }
}