
import 'package:flutter/material.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';

class Event2SetupContactPanel extends StatefulWidget {
  final Event2Contact? contact;
  
  Event2SetupContactPanel({Key? key, this.contact}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _Event2SetupContactPanelState();
}

class _Event2SetupContactPanelState extends State<Event2SetupContactPanel>  {

  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _organizationController = TextEditingController();

  late bool _hasFirstName;
  late bool _hasLastName;
  late bool _hasEmail;
  late bool _hasPhone;

  @override
  void initState() {
    _firstNameController.text = widget.contact?.firstName ?? '';
    _hasFirstName = _firstNameController.text.isNotEmpty;
    _firstNameController.addListener(_onFirstNameChanged);

    _lastNameController.text = widget.contact?.lastName ?? '';
    _hasLastName = _lastNameController.text.isNotEmpty;
    _lastNameController.addListener(_onLastNameChanged);

    _emailController.text = widget.contact?.email ?? '';
    _hasEmail = _emailController.text.isNotEmpty;
    _emailController.addListener(_onEmailChanged);

    _phoneController.text = widget.contact?.phone ?? '';
    _hasPhone = _phoneController.text.isNotEmpty;
    _phoneController.addListener(_onPhoneChanged);

    _organizationController.text = widget.contact?.organization ?? '';

    super.initState();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _organizationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.contact.header.title", "Event Contact")),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildFirstNameSection(),
            _buildLastNameSection(),
            _buildEmailSection(),
            _buildPhoneSection(),
            _buildOrganizationSection(),
            _buildSubmitButton(),
          ]),
        )
    );
  }

  // First Name
  
  Widget _buildFirstNameSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.contact.first_name.label.title', 'FIRST NAME'), required: true,),
    body: Event2CreatePanel.buildTextEditWidget(_firstNameController, keyboardType: TextInputType.text),
  );

  void _onFirstNameChanged() {
    bool hasFirstName = _firstNameController.text.isNotEmpty;
    if ((_hasFirstName != hasFirstName) && mounted) {
      setState(() {
        _hasFirstName = hasFirstName;
      });
    }
  }

  // Last Name
  
  Widget _buildLastNameSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.contact.last_name.label.title', 'LAST NAME'), required: true,),
    body: Event2CreatePanel.buildTextEditWidget(_lastNameController, keyboardType: TextInputType.text),
  );

  void _onLastNameChanged() {
    bool hasLastName = _lastNameController.text.isNotEmpty;
    if ((_hasLastName != hasLastName) && mounted) {
      setState(() {
        _hasLastName = hasLastName;
      });
    }
  }

  // Email
  
  Widget _buildEmailSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.contact.email.label.title', 'EMAIL'), required: _emailRequired),
    body: Event2CreatePanel.buildTextEditWidget(_emailController, keyboardType: TextInputType.emailAddress),
  );

  bool get _emailRequired => _emailController.text.isNotEmpty || _phoneController.text.isEmpty;

  void _onEmailChanged() {
    bool hasEmail = _emailController.text.isNotEmpty;
    if ((_hasEmail != hasEmail) && mounted) {
      setState(() {
        _hasEmail = hasEmail;
      });
    }
  }

  // PHONE
  
  Widget _buildPhoneSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.contact.phone.label.title', 'PHONE NUMBER'), required: _phoneRequired),
    body: Event2CreatePanel.buildTextEditWidget(_phoneController, keyboardType: TextInputType.phone),
  );

  bool get _phoneRequired => _phoneController.text.isNotEmpty || _emailController.text.isEmpty;

  void _onPhoneChanged() {
    bool hasPhone = _phoneController.text.isNotEmpty;
    if ((_hasPhone != hasPhone) && mounted) {
      setState(() {
        _hasPhone = hasPhone;
      });
    }
  }

  // ORGANIZATION
  
  Widget _buildOrganizationSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.contact.organization.label.title', 'ORGANIZATION'),),
    body: Event2CreatePanel.buildTextEditWidget(_organizationController, keyboardType: TextInputType.text, autocorrect: true),
  );

  // Submit

  bool get _createNewContact => widget.contact == null;

  bool get _canCreateContact => _hasFirstName && _hasLastName &&
    (_hasEmail || _hasPhone);

  Widget _buildSubmitButton() {
    String buttonTitle = _createNewContact ?
      Localization().getStringEx("panel.event2.setup.contact.create.title", "Create") :
      Localization().getStringEx("panel.event2.setup.contact.update.title", "Update");
    String buttonHint = _createNewContact ?
      Localization().getStringEx("panel.event2.setup.contact.create.hint", "Tap to create contact") :
      Localization().getStringEx("panel.event2.setup.contact.update.hint", "Tap to update contact");
    bool buttonEnabled = _canCreateContact;

    return Semantics(label: buttonTitle, hint: buttonHint, button: true, excludeSemantics: true, child:
      RoundedButton(
        label: buttonTitle,
        textStyle: buttonEnabled ? Styles().textStyles?.getTextStyle('widget.button.title.large.fat') : Styles().textStyles?.getTextStyle('widget.button.disabled.title.large.fat'),
        onTap: buttonEnabled ? _onSubmit : null,
        backgroundColor: Styles().colors!.white,
        borderColor: buttonEnabled ? Styles().colors!.fillColorSecondary : Styles().colors!.surfaceAccent,
      )
    );
  }

  void _onSubmit() {
    Analytics().logSelect(target: _createNewContact ? 'Create' : 'Update');
    Navigator.of(context).pop(Event2Contact(
      firstName: Event2CreatePanel.textFieldValue(_firstNameController),
      lastName: Event2CreatePanel.textFieldValue(_lastNameController),
      email: Event2CreatePanel.textFieldValue(_emailController),
      phone: Event2CreatePanel.textFieldValue(_phoneController),
      organization: Event2CreatePanel.textFieldValue(_organizationController),
    ));
  }
}