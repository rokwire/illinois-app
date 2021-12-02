import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Localization.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/ui/guide/CampusGuidePanel.dart';
import 'package:illinois/ui/settings/SettingsManageInterestsPanel.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';

class HomeHighlightedFeatures extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeHighlightedFeaturesState();
}

class _HomeHighlightedFeaturesState extends State<HomeHighlightedFeatures>{

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          _buildHeader(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              children: [
                RibbonButton(
                  label: Localization().getStringEx('widgets.home_highlighted_features.button.personalize.title',  'Personalize this app') ,
                  hint: Localization().getStringEx('widgets.home_highlighted_features.button.edit.hint', '') ,
                  height: null,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  onTap: _onTapPersonalize,
                ),
                Container(height: 12,),
                RibbonButton(
                  label: Localization().getStringEx('widgets.home_highlighted_features.button.resources.title',  'Resources for you') ,
                  hint: Localization().getStringEx('widgets.home_highlighted_features.button.edit.hint', '') ,
                  height: null,
                  borderRadius: BorderRadius.all(Radius.circular(5)),
                  onTap: _onTapResources,
                ),
              ],
            ),
          )
        ],
      )
    );
  }

  Widget _buildHeader() {
    return Semantics(container: true ,
      child: Container(color: Styles().colors!.fillColorPrimary, child:
        Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(padding: EdgeInsets.only(right: 16), child: Image.asset('images/campus-tools.png', excludeFromSemantics: true,),),
            Expanded(child:
            Text("Highlighted features", style:
            TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20,),),),
    ],),),));
  }

  void _onTapPersonalize(){
    Analytics.instance.logSelect(target: "HomeHighlightedFeatures: Personalize");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => SettingsManageInterestsPanel()));
  }

  void _onTapResources(){
    Analytics.instance.logSelect(target: "HomeHighlightedFeatures: Resources");
    Navigator.push(context, CupertinoPageRoute(builder: (context) => CampusGuidePanel()));
  }
}