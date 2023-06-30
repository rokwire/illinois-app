
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2SetupRegistrationPanel extends StatefulWidget {
  final Event2SetupRegistrationParam? param;
  
  Event2SetupRegistrationPanel({Key? key, this.param}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _Event2SetupRegistrationPanelState();
}

class _Event2SetupRegistrationPanelState extends State<Event2SetupRegistrationPanel>  {

  late bool _registrationRequired;

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  @override
  void initState() {
    _registrationRequired = widget.param?.registrationRequired ?? false;
    _labelController.text = widget.param?.registrationLabel ?? '';
    _linkController.text = widget.param?.registrationLink ?? '';
    _capacityController.text = (widget.param?.eventCapacity != null) ? '${widget.param?.eventCapacity}' : '';
    super.initState();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _linkController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.registration.header.title", "Event Registration"), onLeading: _onHeaderBack,),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
      Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildRequireSection(),
            _buildCapacitySection(),
            _buildDescriptionSection(),
            _buildLabelSection(),
            _buildLinkSection(),
          ]),
        )

      ],)

    );
  }

  // Require Registration

  Widget _buildRequireSection() =>
    Padding(padding: _sectionPadding, child:
      _buildRequireToggle()
    );

  Widget _buildRequireToggle() => Semantics(toggled: _registrationRequired, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.setup.registration.require.toggle.title", "REQIRE REGISTRATION VIA THE APP"),
    hint: Localization().getStringEx("panel.event2.setup.registration.require.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.registration.require.toggle.title", "REQIRE REGISTRATION VIA THE APP"),
      padding: _togglePadding,
      toggled: _registrationRequired,
      onTap: _onTapRegistrationRequired,
      border: _toggleBorder,
      borderRadius: _toggleBorderRadius,
    ));

  EdgeInsetsGeometry get _togglePadding => const EdgeInsets.symmetric(horizontal: 12, vertical: 12);
  BoxBorder get _toggleBorder => Border.all(color: Styles().colors!.surfaceAccent!, width: 1);
  BorderRadius get _toggleBorderRadius => BorderRadius.all(Radius.circular(4));

  void _onTapRegistrationRequired() {
    Analytics().logSelect(target: "Toggle All Day");
    _hideKeyboard();
    setStateIfMounted(() {
      _registrationRequired = !_registrationRequired;
    });
  }

  // Event Capacity

  Widget _buildCapacitySection() =>
    Padding(padding: _sectionPadding, child:
      Row(children: [
        Padding(padding: EdgeInsets.only(right: 6), child:
          _buildSectionTitleWidget(Localization().getStringEx('panel.event2.setup.registration.capacity.label.title', 'EVENT CAPACITY')),
        ),
        Expanded(child:
          _buildTextEditWidget(_capacityController),
        )
      ],)
    );


  // Description

  Widget _buildDescriptionSection() =>
    Padding(padding: _sectionPadding, child:
      Row(children: [
        Expanded(child:
          Text(Localization().getStringEx('panel.event2.setup.registration.description.label.title', 'Registration within the Illinois app requires the user to log in with a NetID.'), style: _descriptionTextStype,),
        )
      ],)
    );


  // Label
  
  Widget _buildLabelSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.registration.label.label.title', 'ADD REGISTRATION LABEL')),
    body: _buildTextEditWidget(_labelController, keyboardType: TextInputType.text, maxLines: null),
  );

  // External Link
  
  Widget _buildLinkSection() => _buildSectionWidget(
    heading: _buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.registration.link.label.title', 'ADD EXTERNAL LINK FOR REGISTRATION'), suffixImageKey: 'external-link'),
    body: _buildTextEditWidget(_linkController, keyboardType: TextInputType.url, maxLines: 1),
    trailing: _buildConfirmUrlLink(onTap: (_onConfirmLink)),
  );

  void _onConfirmLink() => _confirmLinkUrl(_linkController, analyticsTarget: 'Confirm Website URL');

  // Confirm URL

  Widget _buildConfirmUrlLink({
    void Function()? onTap,
    EdgeInsetsGeometry padding = const EdgeInsets.only(top: 8, bottom: 16, left: 12)
  }) {
    return Align(alignment: Alignment.centerRight, child:
      LinkButton(
        title: Localization().getStringEx('panel.event2.create.button.confirm_url.title', 'Confirm URL'),
        hint: Localization().getStringEx('panel.event2.create.button.confirm_url.hint', ''),
        onTap: onTap,
        padding: padding,
      )
    );
  }

  void _confirmLinkUrl(TextEditingController controller, { String? analyticsTarget }) {
    Analytics().logSelect(target: analyticsTarget ?? "Confirm URL");
    if (controller.text.isNotEmpty) {
      Uri? uri = Uri.tryParse(controller.text);
      if (uri != null) {
        Uri? fixedUri = UrlUtils.fixUri(uri);
        if (fixedUri != null) {
          controller.text = fixedUri.toString();
          uri = fixedUri;
        }
        launchUrl(uri, mode: Platform.isAndroid ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      }
    }
  }

  // Helpers

  static const EdgeInsetsGeometry _sectionPadding = const EdgeInsets.only(bottom: 24);
  static const EdgeInsetsGeometry _sectionHeadingPadding = const EdgeInsets.only(bottom: 8);
  static const EdgeInsetsGeometry _textEditContentPadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 20);

  TextStyle? get _headingTextStype => Styles().textStyles?.getTextStyle("panel.create_event.title.small");
  TextStyle? get _descriptionTextStype => Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');

  Widget _buildSectionWidget({
    Widget? heading, Widget? body, Widget? trailing,
    EdgeInsetsGeometry padding = _sectionPadding,
    EdgeInsetsGeometry bodyPadding = EdgeInsets.zero
  }) {
    List<Widget> contentList = <Widget>[];
    if (heading != null) {
      contentList.add(heading);
    }
    if (body != null) {
      contentList.add(Padding(padding: bodyPadding, child: body));
    }
    if (trailing != null) {
      contentList.add(trailing);
    }

    return Padding(padding: padding, child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList,)
    );
  }

  Widget _buildSectionHeadingWidget(String title, { bool required = false, String? prefixImageKey, String? suffixImageKey, EdgeInsetsGeometry padding = _sectionHeadingPadding }) {
    String semanticsLabel = title;
    if (required) {
      semanticsLabel += ", required";
    }

    List<Widget> contentList = <Widget>[];

    Widget? prefixImageWidget = (prefixImageKey != null) ? Styles().images?.getImage(prefixImageKey) : null;
    if (prefixImageWidget != null) {
      contentList.add(Padding(padding: EdgeInsets.only(right: 6), child:
        prefixImageWidget,
      ));
    }

    contentList.add(_buildSectionTitleWidget(title));
    
    if (required) {
      contentList.add(Padding(padding: EdgeInsets.only(left: 2), child:
        Text('*', style: Styles().textStyles?.getTextStyle("widget.label.small.fat"),),
      ));
    }

    Widget? suffixImageWidget = (suffixImageKey != null) ? Styles().images?.getImage(suffixImageKey) : null;
    if (suffixImageWidget != null) {
      contentList.add(Padding(padding: EdgeInsets.only(left: 6), child:
        suffixImageWidget,
      ));
    }

    return Padding(padding: padding, child:
      Semantics(label: semanticsLabel, header: true, excludeSemantics: true, child:
        Row(children: contentList),
      ),
    );
  }

  Widget _buildSectionTitleWidget(String title) =>
    Text(title, style: _headingTextStype);

  Widget _buildTextEditWidget(TextEditingController controller, {
    TextInputType? keyboardType, int? maxLines = 1, EdgeInsetsGeometry padding = _textEditContentPadding,
    void Function()? onChanged,
  }) =>
    TextField(
      controller: controller,
      decoration: _textEditDecoration(padding: padding),
      style: _textEditStyle,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (onChanged != null) ? ((_) => onChanged) : null,
    );

  TextStyle? get _textEditStyle =>
    Styles().textStyles?.getTextStyle('widget.input_field.dark.text.regular.thin');

  InputDecoration _textEditDecoration({EdgeInsetsGeometry? padding}) => InputDecoration(
    border: OutlineInputBorder(
      borderSide: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1),
      borderRadius: BorderRadius.circular(8)
    ),
    contentPadding: padding,
  );

  void _hideKeyboard() {
    FocusScope.of(context).unfocus();
  }

  String? _textFieldValue(TextEditingController textController) =>
    textController.text.isNotEmpty ? textController.text : null;

  int? _textFieldIntValue(TextEditingController textController) =>
    textController.text.isNotEmpty ? int.tryParse(textController.text) : null;


  void _onHeaderBack() {
    Navigator.of(context).pop(Event2SetupRegistrationParam(
      registrationRequired: _registrationRequired,
      registrationLabel: _textFieldValue(_labelController),
      registrationLink: _textFieldValue(_linkController),
      eventCapacity: _textFieldIntValue(_capacityController),
    ));
  }
}

class Event2SetupRegistrationParam {
  final bool registrationRequired;
  final String? registrationLabel;
  final String? registrationLink;
  final int? eventCapacity;

  Event2SetupRegistrationParam({required this.registrationRequired, this.registrationLabel, this.registrationLink, this.eventCapacity});
}