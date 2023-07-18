
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class Event2SetupRegistrationPanel extends StatefulWidget {
  final Event2? event;
  final Event2RegistrationDetails? registrationDetails;
  
  Event2SetupRegistrationPanel({Key? key, this.event, this.registrationDetails}) : super(key: key);

  Event2RegistrationDetails? get details => (event?.id != null) ? event?.registrationDetails : registrationDetails;
  
  @override
  State<StatefulWidget> createState() => _Event2SetupRegistrationPanelState();
}

class _Event2SetupRegistrationPanelState extends State<Event2SetupRegistrationPanel>  {

  late Event2RegistrationType _registrationType;

  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();
  final TextEditingController _capacityController = TextEditingController();

  bool _updatingRegistration = false;

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
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.registration.header.title", "Event Registration"), leadingWidget: _headerBarLeading,),
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

  // HeaderBar

  Widget get _headerBarLeading => _updatingRegistration ?
    _headerBarBackProgress : _headerBarBackButton;

  Widget get _headerBarBackButton {
    String leadingLabel = Localization().getStringEx('headerbar.back.title', 'Back');
    String leadingHint = Localization().getStringEx('headerbar.back.hint', '');
    return Semantics(label: leadingLabel, hint: leadingHint, button: true, excludeSemantics: true, child:
      IconButton(icon: Styles().images?.getImage(HeaderBar.defaultLeadingIconKey, excludeFromSemantics: true) ?? Container(), onPressed: () => _onHeaderBack())
    );
  }

  Widget get _headerBarBackProgress =>
    Padding(padding: EdgeInsets.all(20), child:
        SizedBox(width: 16, height: 16, child:
          CircularProgressIndicator(color: Styles().colors?.white, strokeWidth: 3,)
        )
    );

  // For new registration details we must return non-zero instance, for update we 
  Event2RegistrationDetails _buildRegistrationDetails() => Event2RegistrationDetails(
    type: _registrationType,
    externalLink: (_registrationType == Event2RegistrationType.external) ? Event2CreatePanel.textFieldValue(_linkController) : null,
    label: (_registrationType == Event2RegistrationType.external) ? Event2CreatePanel.textFieldValue(_labelController) : null,
    eventCapacity: (_registrationType == Event2RegistrationType.internal) ? Event2CreatePanel.textFieldIntValue(_capacityController) : null,
    registrants: ListUtils.from(widget.details?.registrants),
  );

  void _updateEventRegistrationDetails(Event2RegistrationDetails? registrationDetails) {
    if (_updatingRegistration != true) {
      setState(() {
        _updatingRegistration = true;
      });
      Events2().updateEventRegistration(widget.event?.id ?? '', registrationDetails).then((result) {
        if (mounted) {
          setState(() {
            _updatingRegistration = false;
          });
        }
        String? title, message;
        if (result is Event2) {
          title = Localization().getStringEx('panel.event2.create.message.succeeded.title', 'Succeeded');
          message = Localization().getStringEx('panel.event2.update.registration.message.succeeded.message', 'Successfully updated \"{{event_name}}\" registration.').replaceAll('{{event_name}}', result.name ?? '');
        }
        else if (result is String) {
          title = Localization().getStringEx('panel.event2.create.message.failed.title', 'Failed');
          message = result;
        }

        if (title != null) {
          Event2Popup.showMessage(context, title, message).then((_) {
            if (result is Event2) {
              Navigator.of(context).pop(result);
            }
          });
        }
      });
    }
  }


  void _onHeaderBack() {
    Event2RegistrationDetails registrationDetails = _buildRegistrationDetails();
    if (widget.event?.id != null) {
      Event2RegistrationDetails? eventRegistrationDetails = (registrationDetails.type != Event2RegistrationType.none) ? registrationDetails : null;
      if (widget.event?.registrationDetails != eventRegistrationDetails) {
        _updateEventRegistrationDetails(eventRegistrationDetails);
      }
      else {
        Navigator.of(context).pop(null);
      }
    }
    else {
      Navigator.of(context).pop(registrationDetails);
    }
  }
}
