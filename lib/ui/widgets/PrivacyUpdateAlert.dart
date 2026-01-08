import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class PrivacyUpdateAlert extends StatelessWidget {

  final bool updateRequired;

  PrivacyUpdateAlert._({this.updateRequired = false});

  static Future<bool?> present(BuildContext context, { bool updateRequired = false }) => showDialog<bool>(
    context: context,
    barrierDismissible: (updateRequired != true),
    builder: (BuildContext context) => PrivacyUpdateAlert._(updateRequired: updateRequired),
  );

  @override
  Widget build(BuildContext context) =>
    ClipRRect(borderRadius: BorderRadius.all(Radius.circular(8)), child:
      Dialog(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8),), backgroundColor: Styles().colors.surface, child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(mainAxisSize: MainAxisSize.min, children: <Widget>[
            Text(_title(), style: Styles().textStyles.getTextStyle('widget.title.regular.fat'), textAlign: TextAlign.center,),
            Padding(padding: EdgeInsets.only(top: 12, bottom: 24), child:
              Text(_description(), style: Styles().textStyles.getTextStyle('widget.title.regular'), textAlign: TextAlign.center,),
            ),
            _commandBar(context),
          ])
        )
      )
    );


  String _title([String? lang]) => AppTextUtils.appBrandString('widget.privacy_update.alert.title', 'The ${AppTextUtils.appTitleMacro} app has been updated', language: lang);

  String _description([String? lang]) => updateRequired ? _descriptionRequired(lang) : _descriptionOptional(lang);
  String _descriptionOptional([String? lang]) => AppTextUtils.appBrandString('widget.privacy_update.alert.description.optional', 'Some privacy details have changed. Would you like to review your privacy settings?', language: lang);
  String _descriptionRequired([String? lang]) => AppTextUtils.appBrandString('widget.privacy_update.alert.description.required', 'Some privacy details have changed. Please review your privacy settings.', language: lang);

  Widget _commandBar(BuildContext context) => updateRequired ? _commandBarRequired(context) : _commandBarOptional(context);

  Widget _commandBarOptional(BuildContext context) => Row(children: [
    Expanded(child:
      RoundedButton(
        label: _buttonTitleNo(),
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium'),
        padding: _buttonPadding,
        onTap: () => _onPromptNo(context),
      )
    ),
    SizedBox(width: 8,),
    Expanded(child:
      RoundedButton(
        label: _buttonTitleYes(),
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium'),
        padding: _buttonPadding,
        onTap: () => _onPromptYes(context),
      )
    ),
  ],);

  Widget _commandBarRequired(BuildContext context) => Row(children: [
    Expanded(flex: 1, child: Container()),
    Expanded(flex: 3, child:
      RoundedButton(
        label: _buttonTitleSet(),
        textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium'),
        padding: _buttonPadding,
        onTap: () => _onPromptSetPrivacy(context),
      )
    ),
    Expanded(flex: 1, child: Container()),
  ]);

  static const EdgeInsetsGeometry _buttonPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6);

  String _buttonTitleNo([String? lang]) => AppTextUtils.appBrandString('dialog.no.title', 'No', language: lang);
  String _buttonTitleYes([String? lang]) => AppTextUtils.appBrandString('dialog.yes.title', 'Yes', language: lang);
  String _buttonTitleSet([String? lang]) => AppTextUtils.appBrandString('widget.privacy_update.alert.button.review.title', 'Set My Privacy', language: lang);

  void _onPromptNo(BuildContext context) {
    Analytics().logAlert(text: _description('en'), selection: _buttonTitleNo('en'));
    Navigator.pop(context, false);
  }

  void _onPromptYes(BuildContext context) {
    Analytics().logAlert(text: _description('en'), selection: _buttonTitleYes('en'));
    Navigator.pop(context, true);
  }

  void _onPromptSetPrivacy(BuildContext context) {
    Analytics().logAlert(text: _description('en'), selection: _buttonTitleSet('en'));
    Navigator.pop(context, true);
  }
}