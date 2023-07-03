
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
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
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      _buildRequireToggle()
    );

  Widget _buildRequireToggle() => Semantics(toggled: _registrationRequired, excludeSemantics: true, 
    label: Localization().getStringEx("panel.event2.setup.registration.require.toggle.title", "REQUIRE REGISTRATION VIA THE APP"),
    hint: Localization().getStringEx("panel.event2.setup.registration.require.toggle.hint", ""),
    child: ToggleRibbonButton(
      label: Localization().getStringEx("panel.event2.setup.registration.require.toggle.title", "REQUIRE REGISTRATION VIA THE APP"),
      padding: _togglePadding,
      toggled: _registrationRequired,
      onTap: _onTapRegistrationRequired,
      border: _toggleBorder,
      borderRadius: _toggleBorderRadius,
    ));

  EdgeInsetsGeometry get _togglePadding => const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  BoxBorder get _toggleBorder => Border.all(color: Styles().colors!.surfaceAccent!, width: 1);
  BorderRadius get _toggleBorderRadius => BorderRadius.all(Radius.circular(4));

  void _onTapRegistrationRequired() {
    Analytics().logSelect(target: "Toggle All Day");
    Event2CreatePanel.hideKeyboard(context);
    setStateIfMounted(() {
      _registrationRequired = !_registrationRequired;
    });
  }

  // Event Capacity

  Widget _buildCapacitySection() =>
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      Row(children: [
        Padding(padding: EdgeInsets.only(right: 6), child:
          Event2CreatePanel.buildSectionTitleWidget(Localization().getStringEx('panel.event2.setup.registration.capacity.label.title', 'EVENT CAPACITY')),
        ),
        Expanded(child:
          Event2CreatePanel.buildTextEditWidget(_capacityController),
        )
      ],)
    );


  // Description

  Widget _buildDescriptionSection() =>
    Padding(padding: Event2CreatePanel.sectionPadding, child:
      Row(children: [
        Expanded(child:
          Text(Localization().getStringEx('panel.event2.setup.registration.description.label.title', 'Registration within the Illinois app requires the user to log in with a NetID.'), style: _descriptionTextStype,),
        )
      ],)
    );

  TextStyle? get _descriptionTextStype => Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');

  // Label
  
  Widget _buildLabelSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.registration.label.label.title', 'ADD REGISTRATION LABEL')),
    body: Event2CreatePanel.buildTextEditWidget(_labelController, keyboardType: TextInputType.text, maxLines: null),
  );

  // External Link
  
  Widget _buildLinkSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.registration.link.label.title', 'ADD EXTERNAL LINK FOR REGISTRATION'), suffixImageKey: 'external-link'),
    body: Event2CreatePanel.buildTextEditWidget(_linkController, keyboardType: TextInputType.url, maxLines: 1),
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

  void _onHeaderBack() {
    Navigator.of(context).pop(Event2SetupRegistrationParam(
      registrationRequired: _registrationRequired,
      registrationLabel: Event2CreatePanel.textFieldValue(_labelController),
      registrationLink: Event2CreatePanel.textFieldValue(_linkController),
      eventCapacity: Event2CreatePanel.textFieldIntValue(_capacityController),
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