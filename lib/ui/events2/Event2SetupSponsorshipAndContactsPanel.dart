import 'package:flutter/material.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
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
  final TextEditingController _speakerController = TextEditingController();
  late List<Event2Contact> _contacts;

  @override
  void initState() {
    _sponsorController.text = widget.details?.sponsor ?? '';
    _speakerController.text = widget.details?.speaker ?? '';
    _contacts = ListUtils.from(widget.details?.contacts) ?? <Event2Contact>[];
    super.initState();
  }

  @override
  void dispose() {
    _sponsorController.dispose();
    _speakerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx("panel.event2.setup.sponsorship_and_contacts.header.title", "Event Registration"), onLeading: _onHeaderBack,),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.white,
    );
  }

  Widget _buildPanelContent() {
    return SingleChildScrollView(child:
      Column(children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildSponsorSection(),
            _buildSpeakerSection(),
          ]),
        )
      ],)
    );
  }

  // Sponsor
  
  Widget _buildSponsorSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.sponsor.label.title', 'SPONSOR')),
    body: Event2CreatePanel.buildTextEditWidget(_sponsorController, keyboardType: TextInputType.text),
  );

  // Speaker

  Widget _buildSpeakerSection() => Event2CreatePanel.buildSectionWidget(
    heading: Event2CreatePanel.buildSectionHeadingWidget(Localization().getStringEx('panel.event2.setup.sponsorship_and_contacts.speaker.label.title', 'SPEAKER')),
    body: Event2CreatePanel.buildTextEditWidget(_speakerController, keyboardType: TextInputType.text),
  );

  void _onHeaderBack() {
    Navigator.of(context).pop(Event2SponsorshipAndContactsDetails(
      sponsor: Event2CreatePanel.textFieldValue(_sponsorController),
      speaker: Event2CreatePanel.textFieldValue(_speakerController),
      contacts: _contacts.isNotEmpty ? _contacts : null,
    ));
  }
}

class Event2SponsorshipAndContactsDetails {
  final String? sponsor;
  final String? speaker;
  final List<Event2Contact>? contacts;

  Event2SponsorshipAndContactsDetails({this.sponsor, this.speaker, this.contacts});
}