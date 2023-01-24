
import 'package:flutter/material.dart';
import 'package:illinois/model/StudentCourse.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/NativeCommunicator.dart';
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
          Text(building.name ?? "", style: TextStyle(fontSize: 24, color: Styles().colors!.fillColorPrimary, letterSpacing: 1),),
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
              Text(building.fullAddress ?? '', style:
                TextStyle(color: Styles().colors?.textBackground, fontFamily: Styles().fontFamilies?.medium, fontSize: 16,
                  decoration: TextDecoration.underline, decorationColor: Styles().colors?.fillColorSecondary, decorationStyle: TextDecorationStyle.solid, decorationThickness: 1
                ),
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
    Analytics().logSelect(target: "Location Detail");
    NativeCommunicator().launchMapDirections(jsonData: building.toJson());
  }

  void _onBack(BuildContext context) {
    Analytics().logSelect(target: "Back");
    Navigator.of(context).pop();
  }
}