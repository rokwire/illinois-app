import 'package:flutter/material.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:illinois/ext/Event2.dart';

class Event2SetupSuperEventPanel extends StatefulWidget{
  final Event2? event;
  final List<Event2>? subEvents;

  const Event2SetupSuperEventPanel({super.key, this.event, this.subEvents});

  @override
  State<StatefulWidget> createState() => Event2SetupSuperEventState();

  static Widget buildTextEditWidget(TextEditingController controller,
      {TextInputType? keyboardType, int? maxLines = 1, EdgeInsetsGeometry padding = const EdgeInsets.all(0), void Function()? onChanged}) {
    return TextField(
        controller: controller,
        decoration: InputDecoration(
            hintText: 'Search your events by the title or description',
            border: OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.lightGray, width: 1), borderRadius: BorderRadius.circular(8)),
            contentPadding: padding),
        // style: EventDetailsPanel.textEditStyle,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: (onChanged != null) ? ((_) => onChanged) : null);
  }

  static Widget buildSectionTitleWidget(String title, {bool enabled = true, int? maxLines}) {
    return Text(title, style: (enabled ? TextStyle() : TextStyle()),maxLines: maxLines);
  }
}

class Event2SetupSuperEventState extends State<Event2SetupSuperEventPanel> {
  final TextEditingController _subEventController = TextEditingController();

  String? _searchText;
  List<Event2>? _subEvents;
  List<Event2>? _subEventCandidates;

  @override
  void initState() {
    _subEvents = _initialSubEvents != null ? List.from(_initialSubEvents!) : null;
    _subEventController.text = _searchText ?? '';
    _subEventController.addListener(_loadSubEventCandidates);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(CollectionUtils.isEmpty(_subEvents)){
        _loadSubEvents();
      }
      _loadSubEventCandidates();
    });
    super.initState();
  }

  @override
  void dispose() {
    _subEventController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.super_event.header.title', 'Super Event Settings')),
      body: _buildContent(),
      backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _buildDescriptionWidget(
                text: 'Set and manage this event as a multi-event “super event.” After creating one or more related events, you can nest those events as sub-events within a super event (e.g., sessions in a conference, performances in a festival).'
            ),
            Padding(padding: EdgeInsets.only(bottom: 16), child: Event2SetupSuperEventPanel.buildSectionTitleWidget('SUB-EVENT(s)')),
            _buildSubeventsSection(_subEvents, showUnlink: true),
            Padding(padding: EdgeInsets.only(top: 12), child:
            Container(decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFF717273), width: 1))
            ), padding: EdgeInsets.only(top: 12, left: 16, right: 16)
            )),
            Padding(padding: EdgeInsets.only(bottom: 16), child: Event2SetupSuperEventPanel.buildSectionTitleWidget('LINK EVENT(s)')),
            _buildSubeventSelectionSection(),
            _buildSubeventsSection(_subEventCandidates, showLink: true, candidates: true),
          ])
        ));

  Widget _buildDescriptionWidget({required String text}) =>
    Row(children: [
      Expanded(
          child: Text(text,
              overflow: TextOverflow.ellipsis,
              maxLines: 8,
              style: Styles().textStyles.getTextStyle("widget.description.regular")))
    ]);

  Widget _buildSubeventsSection(events, {bool showLink = false, bool showUnlink = false, bool candidates = false}) {
    Widget resultWidget;
    if (CollectionUtils.isEmpty(events)) {
      String missingEventsLabel = candidates
          ? 'You currently have no upcoming events. To link and create sub-events within a super event, please first create your sub-events as basic events from the event listing page.'
          : 'This event is not linked to any sub-events. Please see below.';
      return _buildDescriptionWidget(text: missingEventsLabel);
    } else {
      List<Widget> eventsWidgetList = [];
      events!.forEach((event) {
        eventsWidgetList.add(Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _EventCard(event: event,
                showLink: showLink,
                showUnlink: showUnlink,
                // onTapLink: () => _onTapLinkEventCard(event), //TBD
                // onTapUnlink: () => _onTapUnlinkEventCard(event) //TBD
            )));
      });
      resultWidget = Column(crossAxisAlignment: CrossAxisAlignment.center, children: eventsWidgetList);
    }
    return resultWidget;
  }

  Widget _buildSubeventSelectionSection() => Event2CreatePanel.buildSectionWidget(
    body: Event2SetupSuperEventPanel.buildTextEditWidget(_subEventController, keyboardType: TextInputType.text),
  );

//
  void _loadSubEventCandidates() {
    final text = _subEventController.text;
    if(_searchText?.compareTo(text) != 0) {
      _searchText = text;
      print('subevent title search: $text (${text.characters.length})');

      _asyncLoadCandidates()?.then((loadResult) {
        List<Event2>? events = loadResult?.events;
        if(events != null)
          events.removeWhere((Event2? event) =>
            event?.id == _event?.id //Exclude this Event
            || event?.grouping?.type == Event2GroupingType.superEvent //Exclude super events and sub events
          );
          setStateIfMounted(() {
            _subEventCandidates = events;
          });
      });
    }
  }

  void _loadSubEvents() {
    _asyncLoadSubEvents()?.then((loadResult) {
      List<Event2>? events = loadResult?.events;
        setStateIfMounted(() {
          _subEvents = events;
        });
      });
  }

  Future<Events2ListResult?>? _asyncLoadCandidates() async => Events2().loadEvents(
    Events2Query(
      searchText: _searchText,
      person:  Event2Person(role: Event2UserRole.admin, identifier: Event2PersonIdentifier(externalId: Auth2().netId))
    ));

  Future<Events2ListResult?>? _asyncLoadSubEvents() async => _event?.isSuperEvent == true ? Events2().loadEvents(
      Events2Query(grouping:  _event?.linkedEventsGroupingQuery)
  ) : null;

  Event2? get _event => widget.event;
  List<Event2>? get _initialSubEvents => widget. subEvents;
}

class _EventCard extends StatelessWidget{
  final Event2 event;

  const _EventCard({super.key, required this.event, bool? showLink, bool? showUnlink, Function()? onTapLink, Function()? onTapUnlink});
  @override
  Widget build(BuildContext context) =>
    // TBD
    Event2Card(event);

}