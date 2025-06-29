import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class SettingsContactsPage extends StatefulWidget{
  @override
  State<StatefulWidget> createState() => _SettingsContactsPageState();

}

class _SettingsContactsPageState extends State<SettingsContactsPage> {
  static BorderRadius _bottomRounding = BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10));
  static BorderRadius _topRounding = BorderRadius.only(topLeft: Radius.circular(10), topRight: Radius.circular(10));

  final String _contactEmail = "rokwire@illinois.edu";
  late GestureRecognizer _contactEmailGestureRecognizer;

  final String _contactWebsite = "m.illinois.edu";
  late GestureRecognizer _contactWebsiteGestureRecognizer;

  @override
  void initState() {
    _contactEmailGestureRecognizer = TapGestureRecognizer()..onTap = () => _processUrl("mailto:$_contactEmail");
    _contactWebsiteGestureRecognizer = TapGestureRecognizer()..onTap = () => _processUrl("https://$_contactWebsite");
    super.initState();
  }

  @override
  void dispose() {
    _contactEmailGestureRecognizer.dispose();
    _contactWebsiteGestureRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildLinkButton(label: Localization().getStringEx("panel.settings.contacts.button.help_desk.title", "CONTACT HELP DESK"),
            onTap: _onFeedback,
            borderRadius: _topRounding),
        _buildLinkButton(label: Localization().getStringEx("panel.settings.contacts.button.share_idea.title", "SHARE AN IDEA"),
            onTap: _onIdea),
        _buildLinkButton(label: Localization().getStringEx("panel.settings.contacts.button.develop_code.title", "DEVELOP CODE WITH ROKWIRE"),
            onTap: _onFeedback),
        _buildLinkButton(label: Localization().getStringEx("panel.settings.partners.button.help_desk.title", "PARTNER WITH US"),
          onTap: _onIdea),
        _buildLinkButton(label: Localization().getStringEx("panel.settings.review.button.help_desk.title", "REVIEW APP"),
            onTap: _onReviewClicked,
            borderRadius: _bottomRounding,),
        _feedbackDescriptionWidget,
        _dividerWidget,
        _contactInfoWidget,
        _appVersionWidget
      ],
    );
  }

  Widget _buildLinkButton({String? label, Function? onTap, BorderRadius? borderRadius}) =>
      RibbonButton(
          backgroundColor: Styles().colors.white,
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          rightIcon: Styles().images.getImage('external-link', size: 20),
          borderRadius: borderRadius,
          label: label,
          onTap: () => onTap?.call()
      );

  Widget get _feedbackDescriptionWidget {
    final String rokwirePlatformUrlMacro = '{{rokwire_platform_url}}';
    final String universityUrlMacro = '{{university_url}}';
    final String shciUrlMacro = '{{shci_url}}';
    final String externalLinIconMacro = '{{external_link_icon}}';
    String descriptionHtml = Localization().getStringEx("panel.settings.contact.feedback.app.description.format",
        "The Illinois app is the official campus app of the <a href='$universityUrlMacro'> University of Illinois Urbana-Champaign</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/>. The app is built on the <a href='$rokwirePlatformUrlMacro'>Rokwire</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/> open source software platform. The Rokwire project and the Illinois app are efforts of the <a href='$shciUrlMacro'>Smart, Healthy Communities Initiative</a>&nbsp;<img src='asset:{{external_link_icon}}' alt=''/> in the Office of the Provost at the University of Illinois.");
    descriptionHtml = descriptionHtml.replaceAll(rokwirePlatformUrlMacro, Config().rokwirePlatformUrl ?? '');
    descriptionHtml = descriptionHtml.replaceAll(shciUrlMacro, "https://rokwire.illinois.edu/people-page"/*Config().smartHealthyInitiativeUrl ?? ''*/); // TBD add as config value if needed
    descriptionHtml = descriptionHtml.replaceAll(universityUrlMacro, Config().universityHomepageUrl ?? '');
    descriptionHtml = descriptionHtml.replaceAll(externalLinIconMacro, 'images/external-link.png');

    return  Semantics(container: true, child:
        Container(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 20), child:
          HtmlWidget(
            StringUtils.ensureNotEmpty(descriptionHtml),
            onTapUrl : (url) {_processUrl(url); return true;},
            textStyle:  Styles().textStyles.getTextStyle("widget.item.regular.thin"),
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.textBackground)} : null
        )));
  }

  Widget get _contactInfoWidget =>
    Container(padding: EdgeInsets.symmetric(vertical: 20), child:
      Column(children: [
        Container(
          padding: const EdgeInsets.all(6),
          child: SizedBox(width: 32, height: 32, child:
          Styles().images.getImage('university-logo-dark-frame'),
          ),
        ),
        Text( Localization().getStringEx("panel.settings.contact.info.row1", "Smart, Healthy Communities Initiative | Rokwire"), textAlign: TextAlign.center, style:  Styles().textStyles.getTextStyle("widget.item.regular.fat")),
        Text( Localization().getStringEx("panel.settings.contact.info.row2", "Institute of Government and Public Affairs \n 1007 W Nevada St; Urbana, IL 61801"), textAlign: TextAlign.center, style:  Styles().textStyles.getTextStyle("widget.item.regular.thin")),
        RichText(textAlign: TextAlign.left, text:
          TextSpan(style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), children:[
              TextSpan(text: _contactEmail,
                  style: Styles().textStyles.getTextStyle("widget.item.regular_underline.thin"),
                  recognizer: _contactEmailGestureRecognizer),
              TextSpan(text: " • "),
              TextSpan(text: _contactWebsite,
                style: Styles().textStyles.getTextStyle("widget.item.regular_underline.thin"),
                recognizer: _contactWebsiteGestureRecognizer),
          ]))
      ],)
    );

  Widget get _appVersionWidget =>
      Padding(padding: const EdgeInsets.only(top: 0), child:
        RichText(textAlign: TextAlign.left, text:
        TextSpan(style: Styles().textStyles.getTextStyle("widget.item.regular.thin"), children:[
          TextSpan(text: Localization().getStringEx('panel.settings.home.version.info.label', '{{app_title}} App Version:').replaceAll('{{app_title}}', Localization().getStringEx('app.title', 'Illinois')),),
          TextSpan(text:  " $_appVersion", style : Styles().textStyles.getTextStyle("widget.item.regular.fat")),
        ])
        ),
    );

  String get _appVersion => Config().appVersion ?? '';

  Widget get _dividerWidget =>
      Container(color: Styles().colors.surfaceAccent, height: 1,);

  void _onReviewClicked() {
    Analytics().logSelect(target: "Provide Review");
    InAppReview.instance.openStoreListing(appStoreId: Config().appStoreId);
  }

  void _onFeedback() {
    String email = Uri.encodeComponent(Auth2().email ?? '');
    String name = Uri.encodeComponent(Auth2().fullName ?? '');
    String phone = Uri.encodeComponent(Auth2().phone ?? '');
    String feedbackUrl = "${Config().feedbackUrl}?email=$email&phone=$phone&name=$name";

    _processUrl(feedbackUrl);
  }

  void _onIdea() {
    _processUrl(Config().ideaUrl);
  }

  void _processUrl(String? url) {
    Analytics().logSelect(target: url);
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        UrlUtils.launchExternal(url);
      }
    }
  }
}