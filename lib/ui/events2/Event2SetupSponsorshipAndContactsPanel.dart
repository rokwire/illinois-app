import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2SetupContactPanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/GestureDetector.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Event2SetupSponsorshipAndContactsPanel extends StatefulWidget {
  final Event2SponsorshipAndContactsDetails? details;
  
  Event2SetupSponsorshipAndContactsPanel({Key? key, this.details}) : super(key: key);
  
  @override
  State<StatefulWidget> createState() => _Event2SetupSponsorshipAndContactsPanelState();
}

class _Event2SetupSponsorshipAndContactsPanelState extends State<Event2SetupSponsorshipAndContactsPanel>  {

  final TextEditingController _sponsorController = TextEditingController();
  late List<Event2Contact> _contacts;

  @override
  void initState() {
    _sponsorController.text = widget.details?.sponsor ?? '';
    _contacts = ListUtils.from(widget.details?.contacts) ?? <Event2Contact>[];
    super.initState();
  }

  @override
  void dispose() {
    _sponsorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(onWillPop: () => AppPopScope.back(_onHeaderBack), child: Platform.isIOS ?
      BackGestureDetector(onBack: _onHeaderBack, child:
        _buildScaffoldContent(),
      ) :
      _buildScaffoldContent()
    );
  }

  Widget _buildScaffoldContent() => Scaffold(
    appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.sponsorship_and_contacts.header.title", "Event Host Details"), onLeading: _onHeaderBack,),
    body: _buildPanelContent(),
    backgroundColor: Styles().colors!.white,
  );

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
      Column(children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
              _buildSponsorSection()
            ),
            _buildContactsSection(),
          ]),
        )
      ],)
    );
  }

  // Sponsor
  
  Widget _buildSponsorSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.sponsor.label.title', 'EVENT HOST')),
    body: Event2CreatePanel.buildTextEditWidget(_sponsorController, keyboardType: TextInputType.text),
  );

  // Contacts

  Widget _buildContactsSection() => Event2CreatePanel.buildSectionWidget(
    heading: _buildContactsSectionHeading(),
    body: _buildContactsContent(),
  );

  Widget _buildContactsSectionHeading() {
    String title = Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.contacts.label.title', 'CONTACTS');
    return Padding(padding: Event2CreatePanel.innerSectionPadding, child:
      Semantics(label: title, header: true, excludeSemantics: true, child:
        Padding(padding: EdgeInsets.only(left: 16, top: 4), child:
          Row(children: [
            Expanded(child: Event2CreatePanel.buildSectionTitleWidget(title)),
            _buildAddContactButton()
          ]),
        ),
      ),
    );
  }

  Widget _buildAddContactButton() => Event2ImageCommandButton('plus-circle',
    label: Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.contacts.button.create.title', 'Create'),
    hint: Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.contacts.button.create.hint', 'Tap to create contact'),
    contentPadding: EdgeInsets.all(16),
    onTap: _onCreateContact
  );

  void _onCreateContact() {
    Analytics().logSelect(target: 'Create Contact');
    Event2CreatePanel.hideKeyboard(context);
    Navigator.push<Event2Contact>(context, CupertinoPageRoute(builder: (context) => Event2SetupContactPanel(
    ))).then((Event2Contact? result) {
      if ((result != null) && mounted) {
        setState(() {
          _contacts.add(result);
        });
      }
    });
  }

  Widget _buildContactsContent() => Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: _contacts.isNotEmpty ?
    _buildContactsList() : _buildEmptyContactsContent()
  );

  Widget _buildEmptyContactsContent() => 
    Text(Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.contacts.label.empty.title', 'No contacts defined yet.'), style:
      Styles().textStyles?.getTextStyle('widget.description.regular'),);

  Widget _buildContactsList() {
    List<Widget> contentList = <Widget>[];
    for (int index = 0; index < _contacts.length; index++) {
      Event2Contact contact = _contacts[index];
      contentList.add(Padding(padding: EdgeInsets.only(bottom: 8), child:
        _Event2ContactCard(contact,
          onEdit: () => _onEditContact(index),
          onDelete: () => _onDeleteContact(index),
        ),
      ));
    }
    return Column(children: contentList,);
  }

  void _onEditContact(int index) {
    Analytics().logSelect(target: 'Edit Contact');
    Event2CreatePanel.hideKeyboard(context);
    if ((0 <= index) && (index < _contacts.length)) {
      Event2Contact contact = _contacts[index];

      Navigator.push<Event2Contact>(context, CupertinoPageRoute(builder: (context) => Event2SetupContactPanel(
        contact: contact,
      ))).then((Event2Contact? result) {
        if ((result != null) && mounted) {
          setState(() {
            _contacts[index] = result;
          });
        }
      });
    }
  }

  void _onDeleteContact(int index) {
    Analytics().logSelect(target: 'Delete Contact');
    Event2CreatePanel.hideKeyboard(context);
    if ((0 <= index) && (index < _contacts.length)) {
      Event2Contact contact = _contacts[index];
    
      String message = Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.contacts.prompt.confirm.delete.title', 'Delete {{name}} contact?.').replaceAll('{{name}}', contact.fullName);
      AppAlert.showConfirmationDialog(buildContext: context, message: message,
        positiveButtonLabel: Localization().getStringEx('dialog.ok.title', 'OK'),
        negativeButtonLabel: Localization().getStringEx('dialog.cancel.title', 'Cancel'),
      ).then((value) {
        if (value == true) {
          setState(() {
            _contacts.removeAt(index);
          });
        }
      });
    }
  }

  // Return Value

  void _onHeaderBack() {
    Analytics().logSelect(target: 'HeaderBar: Back');
    Navigator.of(context).pop(Event2SponsorshipAndContactsDetails(
      sponsor: Event2CreatePanel.textFieldValue(_sponsorController),
      contacts: _contacts.isNotEmpty ? _contacts : null,
    ));
  }

}

class Event2SponsorshipAndContactsDetails {
  final String? sponsor;
  final List<Event2Contact>? contacts;

  Event2SponsorshipAndContactsDetails({this.sponsor, this.contacts});
}

class _Event2ContactCard extends StatelessWidget {

  final Event2Contact contact;
  final Function()? onDelete;
  final Function()? onEdit;

  _Event2ContactCard(this.contact, { Key? key, this.onEdit, this.onDelete }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(top: 16, bottom: 8), child:
            Text(contact.fullName, style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'), overflow: TextOverflow.ellipsis, maxLines: 2,)
          )
        ),
        _deleteButton
      ],),
    ];

    if (StringUtils.isNotEmpty(contact.email)) {
      contentList.add(_buildTextDetailWidget(contact.email ?? '', 'mail'));
    }

    if (StringUtils.isNotEmpty(contact.phone)) {
      contentList.add(_buildTextDetailWidget(contact.phone ?? '', 'phone'));
    }

    if (StringUtils.isNotEmpty(contact.organization)) {
      contentList.add(_buildTextDetailWidget(contact.organization ?? '', 'organization'));
    }

    return InkWell(onTap: onEdit, child:
      Container(decoration: Event2CreatePanel.sectionDecoration, child:
        Padding(padding: EdgeInsets.only(left: 16, bottom: 16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList)
        )
      )
    );
  }

  Widget get _deleteButton => InkWell(onTap: onDelete, child:
    Padding(padding: EdgeInsets.all(16), child:
      Styles().images?.getImage('trash', excludeFromSemantics: true,)
    ),
  );

  Widget _buildTextDetailWidget(String text, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
  }) =>
    _buildDetailWidget(
      Text(text, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'), overflow: TextOverflow.ellipsis, maxLines: 1),
      iconKey,
      contentPadding: contentPadding,
      iconPadding: iconPadding,
    );

  Widget _buildDetailWidget(Widget contentWidget, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
  }) {
    List<Widget> contentList = <Widget>[];
    Widget? iconWidget = Styles().images?.getImage(iconKey, excludeFromSemantics: true);
    if (iconWidget != null) {
      contentList.add(Padding(padding: iconPadding, child:
        iconWidget,
      ));
    }
    contentList.add(Expanded(child:
      contentWidget
    ),);
    return Padding(padding: contentPadding, child:
      Row(children: contentList)
    );
  }
}