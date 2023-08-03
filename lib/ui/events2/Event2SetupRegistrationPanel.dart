
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/utils/AppUtils.dart';
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
  final TextEditingController _registrantsController = TextEditingController();

  late Event2RegistrationType _initialRegistrationType;
  late String _initialLabel;
  late String _initialLink;
  late String _initialCapacity;
  late String _initialRegistrants;

  bool _modified = false;
  bool _updatingRegistration = false;
  
  @override
  void initState() {
    _registrationType = _initialRegistrationType = widget.details?.type ?? Event2RegistrationType.none;
    
    _labelController.text = _initialLabel = ((_registrationType == Event2RegistrationType.external) && (widget.details?.label != null)) ? '${widget.details?.label}' : '';
    _linkController.text = _initialLink = ((_registrationType == Event2RegistrationType.external) && (widget.details?.externalLink != null)) ? '${widget.details?.externalLink}' : '';
    _capacityController.text = _initialCapacity = ((_registrationType == Event2RegistrationType.internal) && (widget.details?.eventCapacity != null)) ? '${widget.details?.eventCapacity}' : '';
    _registrantsController.text = _initialRegistrants = ((_registrationType == Event2RegistrationType.internal) && (widget.details?.registrants != null)) ? (widget.details?.registrants?.join(' ') ?? '')  : '';

    if (_isEditing) {
      _labelController.addListener(_checkModified);
      _linkController.addListener(_checkModified);
      _capacityController.addListener(_checkModified);
      _registrantsController.addListener(_checkModified);
    }

    super.initState();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _linkController.dispose();
    _capacityController.dispose();
    _registrantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => AppPopScope.back(_onHeaderBarBack),
      child: Scaffold(
        appBar: _headerBar,
        body: _buildPanelContent(),
        backgroundColor: Styles().colors!.white,
      ),
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
      _checkModified();
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
              Text(description, style: _infoTextStype,),
            )
          ],)
        ),
      ),
    );
  }


  TextStyle? get _infoTextStype => Styles().textStyles?.getTextStyle('widget.item.small.thin.italic');


  // Internal Details

  Widget _buildInternalSection() {
    return Visibility(visible: (_registrationType == Event2RegistrationType.internal), child:
      Container(decoration: Event2CreatePanel.sectionSplitterDecoration, padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
        Column(children: [
         _buildCapacitySection(),
         _buildRegistrantsSection(),
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
            Event2CreatePanel.buildTextEditWidget(_capacityController, keyboardType: TextInputType.number, semanticsLabel: Localization().getStringEx("panel.event2.setup.registration.capacity.field.label", "EVENT CAPACITY FIELD",)),
          )
        ],)
      ),
    );

  // Event Registrants

  Widget _buildRegistrantsSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.registration.registrants.label.title', 'NETIDS FOR ADDITIONAL REGISTRANTS')),
    body: Event2CreatePanel.buildTextEditWidget(_registrantsController, keyboardType: TextInputType.text, maxLines: null,
      semanticsLabel: Localization().getStringEx('panel.event2.setup.registration.link.field.label', 'NETIDS FOR ADDITIONAL REGISTRANTS FIELD'),
      semanticsHint: Localization().getStringEx('panel.event2.setup.registration.registrants.label.hint', 'A space or comma separated list of Net IDs.')
    ),
    trailing: _buildRegistrantsHint(),
  );

  Widget _buildRegistrantsHint() => Padding(padding: EdgeInsets.only(top: 2), child:
    Row(children: [
      Expanded(child:
        Text(Localization().getStringEx('panel.event2.setup.registration.registrants.label.hint', 'A space or comma separated list of Net IDs.'), style: _infoTextStype, semanticsLabel: "",),
      )
    ],),
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
    body: Event2CreatePanel.buildTextEditWidget(_labelController, keyboardType: TextInputType.text, maxLines: null, autocorrect: true, semanticsLabel: Localization().getStringEx("panel.event2.setup.registration.label.field.label", "ADD REGISTRATION LABEL FIELD",)),
  );

  // External Link
  
  Widget _buildLinkSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.registration.link.label.title', 'ADD EXTERNAL LINK FOR REGISTRATION'), suffixImageKey: 'external-link'),
    body: Event2CreatePanel.buildTextEditWidget(_linkController, keyboardType: TextInputType.url, maxLines: 1, semanticsHint: Localization().getStringEx("panel.event2.setup.registration.link.field.label", "ADD EXTERNAL LINK FOR REGISTRATION FIELD",)),
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

  bool get _isEditing => StringUtils.isNotEmpty(widget.event?.id);

  PreferredSizeWidget get _headerBar => HeaderBar(
    title: Localization().getStringEx("panel.event2.setup.registration.header.title", "Event Registration"),
    onLeading: _onHeaderBarBack,
    actions: _headerBarActions,
  );

  List<Widget>? get _headerBarActions {
    if (_updatingRegistration) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if (_isEditing && _modified) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onHeaderBarApply,
      )];
    }
    else {
      return null;
    }
  }
  
  void _checkModified() {
    if (_isEditing && mounted) {
      String currentLabel = (_registrationType == Event2RegistrationType.external) ? _labelController.text : '';
      String currentLink = (_registrationType == Event2RegistrationType.external) ? _linkController.text : '';
      String currentCapacity = (_registrationType == Event2RegistrationType.internal) ? _capacityController.text : '';
      String currentRegistrants = (_registrationType == Event2RegistrationType.internal) ? _registrantsController.text : '';
      
      bool modified = (_registrationType != _initialRegistrationType) ||
        (currentLabel != _initialLabel) ||
        (currentLink != _initialLink) ||
        (currentCapacity != _initialCapacity) ||
        (currentRegistrants != _initialRegistrants);

      if (_modified != modified) {
        setState(() {
          _modified = modified;
        });
      }
    }
  }

  // For new registration details we must return non-zero instance, for update we 
  Event2RegistrationDetails _buildRegistrationDetails() => Event2RegistrationDetails(
    type: _registrationType,
    externalLink: (_registrationType == Event2RegistrationType.external) ? Event2CreatePanel.textFieldValue(_linkController) : null,
    label: (_registrationType == Event2RegistrationType.external) ? Event2CreatePanel.textFieldValue(_labelController) : null,
    eventCapacity: (_registrationType == Event2RegistrationType.internal) ? Event2CreatePanel.textFieldIntValue(_capacityController) : null,
    registrants: (_registrationType == Event2RegistrationType.internal) ? ListUtils.notEmpty(ListUtils.stripEmptyStrings(_registrantsController.text.split(RegExp(r'[\s,;]+')))) : null,
  );

  void _updateEventRegistrationDetails(Event2RegistrationDetails? registrationDetails) {
    if (_isEditing && (_updatingRegistration != true)) {
      setState(() {
        _updatingRegistration = true;
      });
      Events2().updateEventRegistrationDetails(widget.event?.id ?? '', registrationDetails).then((result) {
        if (mounted) {
          setState(() {
            _updatingRegistration = false;
          });
        }

        if (result is Event2) {
          Navigator.of(context).pop(result);
        }
        else {
          Event2Popup.showErrorResult(context, result);
        }

      });
    }
  }

  void _onHeaderBarApply() {
    Analytics().logSelect(target: 'HeaderBar: Apply');
    _updateEventRegistrationDetails((_registrationType != Event2RegistrationType.none) ? _buildRegistrationDetails() : null);
  }

  void _onHeaderBarBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop(_isEditing ? null : _buildRegistrationDetails());
  }
}
