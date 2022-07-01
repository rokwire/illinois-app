
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/InfoPopup.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class GroupPostReportAbuse extends StatefulWidget {

  final String? groupId;
  final String? postId;

  GroupPostReportAbuse({Key? key, this.groupId, this.postId}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _GroupPostReportAbuseState();

}

class _GroupPostReportAbuseState extends State<GroupPostReportAbuse> {

  final _commentController = TextEditingController();
  bool _sending = false;
  bool _hasComment = false;
  
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.group.detail.post.report_abuse.header.title', 'Report'),),
      body: Column(children: <Widget>[
        Expanded(child:
          SingleChildScrollView(child:
            SafeArea(child:
              _buildContent(),
            ),
          ),
        ),
      ]),
      backgroundColor: Styles().colors?.background,
      bottomNavigationBar: uiuc.TabBar());
  }

  Widget _buildContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: EdgeInsets.only(top: 16), child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 24, top: 16), child:
              Text(Localization().getStringEx('panel.group.detail.post.report_abuse.description.text', 'Report violation of Student Code to Dean of Students'), textAlign: TextAlign.center,
                style: TextStyle(fontFamily: Styles().fontFamilies?.bold, fontSize: 20, color: Styles().colors?.fillColorPrimary),
              )
            )
          ),
          Semantics(button: true, excludeSemantics: true,
            label: Localization().getStringEx('panel.group_detail.button.policy.label', 'Policy'),
            hint: Localization().getStringEx('panel.group_detail.button.policy.hint', 'Tap to ready policy statement'),
            child: InkWell(onTap: _onPolicy, child:
              Padding(padding: EdgeInsets.all(16), child:
                Image.asset('images/icon-info-orange.png')
              ),
            ),
          ),
        ],),
      ),

      Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 32, bottom: 8), child:
        Text(Localization().getStringEx('panel.group.detail.post.report_abuse.comment.title', 'Please add your comment for this report:'),
          style: TextStyle(color: Styles().colors?.textSurface, fontFamily: Styles().fontFamilies?.medium, fontSize: 16)
        ),
      ),
      
      Padding(padding: EdgeInsets.only(left: 24, right: 24), child:
        Stack(children: [
          Container(
            decoration: BoxDecoration(border: Border.all(color: Styles().colors!.fillColorPrimary!, width: 1), color: Styles().colors!.white),
            child: Semantics(textField: true, excludeSemantics: true,
              label: Localization().getStringEx('panel.group.detail.post.report_abuse.comment.label', 'Comment Label'),
              hint: Localization().getStringEx('panel.group.detail.post.report_abuse.comment.hint', ''),
              child: TextField(controller: _commentController, maxLines: 10,
                onChanged: _onCommentChanged,
                style: TextStyle(color: Styles().colors!.textBackground, fontSize: 16, fontFamily: Styles().fontFamilies!.regular),
                decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(left: 8, right: 20, top: 4, bottom: 4)),
              )
            )
          ),
          Align(alignment: Alignment.topRight, child:
            Visibility(visible:  _hasComment, child:
              Semantics (button: true, excludeSemantics: true,
                label: Localization().getStringEx('dialog.clear.title', 'Clear'),
                hint: Localization().getStringEx('dialog.clear.hint', ''),
                child: GestureDetector(onTap: () { _commentController.text = ''; },
                  child: Container(width: 36, height: 36,
                    child: Align(alignment: Alignment.center,
                      child: Text('X', style: TextStyle(fontFamily: Styles().fontFamilies!.regular, fontSize: 16, color: Styles().colors!.fillColorPrimary,),),
                    ),
                  ),
                ),
              ),
            ),
          )
        ],)
      ),


      Padding(padding: EdgeInsets.only(left: 24, right: 24, top: 32), child:
        Row(children: [
          Expanded(flex: 1, child: Container()),
          Expanded(flex: 2, child: 
            RoundedButton(
              label: Localization().getStringEx("panel.group.detail.post.report_abuse.button.send.label", "Send"),
              hint: Localization().getStringEx("panel.group.detail.post.report_abuse.button.send.hint", "Tap to send report"),
              backgroundColor: Styles().colors?.white,
              borderColor: Styles().colors?.fillColorSecondary,
              textColor: Styles().colors?.fillColorPrimary,
              progress:  _sending,
              onTap: _onSend,
            ),
          ),
          Expanded(flex: 1, child: Container()),
        ],)
      ),


    ],);
  }

  void _onCommentChanged(String comment) {
    bool hasComment = comment.isNotEmpty;
    if (_hasComment != hasComment) {
      setState(() {
        _hasComment = hasComment;
      });
    }
  }

  void _onPolicy () {
    Analytics().logSelect(target: 'Policy');
    showDialog(context: context, builder: (_) =>  InfoPopup(
      backColor: Color(0xfffffcdf), //Styles().colors?.surface ?? Colors.white,
      padding: EdgeInsets.only(left: 24, right: 24, top: 28, bottom: 24),
      border: Border.all(color: Styles().colors!.textSurface!, width: 1),
      alignment: Alignment.topRight,
      infoText: Localization().getStringEx('panel.group.detail.policy.text', 'The University of Illinois takes pride in its efforts to support free speech and to foster inclusion and mutual respect. Users may report group names or content that are obscene, threatening, or harassing to group administrator(s). Users may also choose to report content in violation of Student Code to the Office of the Dean of Students.'),
      infoTextStyle: TextStyle(fontFamily: Styles().fontFamilies?.medium, fontSize: 16, color: Styles().colors?.fillColorPrimary),
      closeIcon: Image.asset('images/close-orange-small.png'),
    ),);
  }

  void _onSend() {
    Analytics().logSelect(target: 'Send');
    setState(() {
      _sending = true;
    });

    Groups().reportAbuse(groupId: widget.groupId, postId: widget.postId, comment: _commentController.text).then((bool result) {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
      _reportReportAbuse(result).then((_){
        if (result) {
          Navigator.of(context).pop();
        }
      });
    });
  }

  Future<void> _reportReportAbuse(bool result) {
    return AppAlert.showMessage(context, result ? 
      Localization().getStringEx("panel.group.detail.post.report_abuse.succeeded.msg", "Post reported successfully.") :
      Localization().getStringEx("panel.group.detail.post.report_abuse.failed.msg", "Failed to report post."),
    );
  }
}