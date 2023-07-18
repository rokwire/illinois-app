
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2SetupRegistrationPanel extends StatefulWidget {
  final Event2RegistrationDetails? details;
  
  Event2SetupRegistrationPanel({Key? key, this.details}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _Event2SetupRegistrationPanelState();
}

class _Event2SetupRegistrationPanelState extends State<Event2SetupRegistrationPanel>  {

  late Event2RegistrationType _registrationType;

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  @override
  void initState() {
    _registrationType = widget.details?.type ?? Event2RegistrationType.none;
    _labelController.text = ((_registrationType == Event2RegistrationType.external) && (widget.details?.label != null)) ? '${widget.details?.label}' : '';
    _linkController.text = ((_registrationType == Event2RegistrationType.external) && (widget.details?.externalLink != null)) ? '${widget.details?.externalLink}' : '';
    _capacityController.text = ((_registrationType == Event2RegistrationType.internal) && (widget.details?.eventCapacity != null)) ? '${widget.details?.eventCapacity}' : '';
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
        Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _buildRegistrationTypeSection(),
                _buildDescriptionSection(),
              ]),
            ),
            _buildInternalSection(),
            _buildExternalSection(),
          ]),
        )

      ],)

    );
  }

  // Registration Type

  Widget _buildRegistrationTypeSection() {
    String title = Localization().getStringEx('panel.event2.setup.registration.type.title', 'REQUIRE REGISTRATION');
    return Padding(padding: EdgeInsets.zero, child:
      Semantics(container: true, child:
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Expanded(child:
            Wrap(children: [
              Event2CreatePanel.buildSectionTitleWidget(title),
              //Event2CreatePanel.buildSectionRequiredWidget(), 
            ]),
          ),
          Expanded(child:
            Container(decoration: Event2CreatePanel.dropdownButtonDecoration, child:
              Padding(padding: EdgeInsets.only(left: 12, right: 8), child:
                DropdownButtonHideUnderline(child:
                  DropdownButton<Event2RegistrationType>(
                    icon: Styles().images?.getImage('chevron-down'),
                    isExpanded: true,
                    style: Styles().textStyles?.getTextStyle("panel.create_event.dropdown_button.title.regular"),
                    hint: Text(event2RegistrationToDisplayString(_registrationType)),
                    items: _buildRegistrationTypeDropDownItems(),
                    onChanged: _onRegistrationTypeChanged
                  ),
                ),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  List<DropdownMenuItem<Event2RegistrationType>>? _buildRegistrationTypeDropDownItems() {
    List<DropdownMenuItem<Event2RegistrationType>> menuItems = <DropdownMenuItem<Event2RegistrationType>>[];
    for (Event2RegistrationType value in Event2RegistrationType.values) {
      menuItems.add(DropdownMenuItem<Event2RegistrationType>(
        value: value,
        child: Text(event2RegistrationToDisplayString(value),),
      ));
    }
    return menuItems;
  }

  void _onRegistrationTypeChanged(Event2RegistrationType? value) {
    Analytics().logSelect(target: "Require registration: ${(value != null) ? event2RegistrationToDisplayString(value) : 'null'}");
    Event2CreatePanel.hideKeyboard(context);
    if ((value != null) && mounted) {
      setState(() {
        _registrationType = value;
      });
    }
  }


  // Description

  Widget _buildDescriptionSection() {
    String description = (_registrationType == Event2RegistrationType.internal) ?
      Localization().getStringEx('panel.event2.setup.registration.description.label.title', 'Registration within the Illinois app requires the user to log in with a NetID.') : '';

    return Padding(padding: Event2CreatePanel.sectionPadding, child:
      Visibility(visible: description.isNotEmpty, child:
        Padding(padding: EdgeInsets.only(top: 12), child:
          Row(children: [
            Expanded(child:
              Text(description, style: _descriptionTextStype,),
            )
          ],)
        ),
      ),
    );
  }


  TextStyle? get _descriptionTextStype => Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');


  // Internal Details

  Widget _buildInternalSection() {
    return Visibility(visible: (_registrationType == Event2RegistrationType.internal), child:
      Container(decoration: Event2CreatePanel.sectionSplitterDecoration, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
        Column(children: [
         _buildCapacitySection(),
        ],),
      ),
    );
  }

  // Event Capacity

  Widget _buildCapacitySection() =>
    Visibility(visible: (_registrationType == Event2RegistrationType.internal), child:
      Padding(padding: Event2CreatePanel.sectionPadding, child:
        Row(children: [
          Padding(padding: EdgeInsets.only(right: 6), child:
            Event2CreatePanel.buildSectionTitleWidget(Localization().getStringEx('panel.event2.setup.registration.capacity.label.title', 'EVENT CAPACITY')),
          ),
          Expanded(child:
            Event2CreatePanel.buildTextEditWidget(_capacityController),
          )
        ],)
      ),
    );

  // External Details

  Widget _buildExternalSection() {
    return Visibility(visible: (_registrationType == Event2RegistrationType.external), child:
      Container(decoration: Event2CreatePanel.sectionSplitterDecoration, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
        Column(children: [
         _buildLinkSection(),
         _buildLabelSection(), 
        ],),
      ),
    );
  }

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
    padding: EdgeInsets.zero
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
    Navigator.of(context).pop(Event2RegistrationDetails(
      type: _registrationType,
      externalLink: (_registrationType == Event2RegistrationType.external) ? Event2CreatePanel.textFieldValue(_linkController) : null,
      label: (_registrationType == Event2RegistrationType.external) ? Event2CreatePanel.textFieldValue(_labelController) : null,
      eventCapacity: (_registrationType == Event2RegistrationType.internal) ? Event2CreatePanel.textFieldIntValue(_capacityController) : null,
      registrants: ListUtils.from(widget.details?.registrants),
    ));
  }
}
