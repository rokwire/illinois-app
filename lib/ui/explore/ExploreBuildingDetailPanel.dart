
import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';

class ExploreBuildingDetailPanel extends StatelessWidget {
  final Building building;

  ExploreBuildingDetailPanel({Key? key, required this.building}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildContent(context),
      backgroundColor: Styles().colors!.white,
      bottomNavigationBar: uiuc.TabBar()
    );
  }

  Widget _buildContent(BuildContext context) {
    return SafeArea(child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        _buildBack(onTap: () => _onBack(context)),
        Expanded(child:
          SingleChildScrollView(child:
            Padding(padding:EdgeInsets.only(right: 20, left: 20), child:
              Column(children: <Widget>[
                _buildTitle(),
                _buildLocation(),
              ],)
            ),
          ),
        ),
      ],),
    );
  }

  Widget _buildTitle(){
    return Padding(padding: EdgeInsets.symmetric(vertical: 10), child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
        Expanded(child:
          Text(building.name ?? "", style: Styles().textStyles?.getTextStyle("widget.title.extra_large.spaced")),
        ),
      ],),
    );
  }

  Widget _buildLocation(){

    return Visibility(visible: StringUtils.isNotEmpty(building.fullAddress), child:
      InkWell(onTap: _onLocation, child:
        Padding(padding: EdgeInsets.symmetric(vertical: 10, ), child:
          Row(children: [
            Padding(padding: EdgeInsets.only(right: 6), child:
              Styles().images?.getImage('location', excludeFromSemantics: true),
            ),
            Expanded(child:
              Text(building.fullAddress ?? '', style: Styles().textStyles?.getTextStyle("widget.button.light.title.medium.underline")
              ),
            )
          ],),
        ),
      ),
    );
  }

  Widget _buildBack({void Function()? onTap}){
    return Semantics(
      label: Localization().getStringEx('headerbar.back.title', 'Back'),
      hint: Localization().getStringEx('headerbar.back.hint', ''),
      button: true,
      child:
        InkWell(onTap: onTap, child:
          SizedBox(width: 48, height: 48, child:
            Center(child:
              Styles().images?.getImage('chevron-left-bold', excludeFromSemantics: true
            ),
          ),
        ),
      ),
    );
  }

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions");
    building.launchDirections();
  }

  void _onBack(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.of(context).pop();
  }
}