import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/RibbonButton.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
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

  static Widget buildDescriptionWidget({required String text}) =>
      Row(children: [
        Expanded(
            child: Text(text,
                overflow: TextOverflow.ellipsis,
                maxLines: 8,
                style: Styles().textStyles.getTextStyle("widget.description.regular")))
      ]);
}

class Event2SetupSuperEventState extends State<Event2SetupSuperEventPanel> with NotificationsListener{
  final TextEditingController _subEventController = TextEditingController();

  String? _searchText;

  Event2? _event;
  List<Event2>? _bbSubEvents;
  List<Event2>? _selectedSubEvents;
  List<Event2>? _subEventCandidates;
  Client? _loadCandidatesClient;
  Client? _loadBBEventsClient;

  bool? _superEventChildDisplayOnlyUnderSuperEvent = false;
  bool _publishAllSubEvents = false;

  bool _applying = false;

  @override
  void initState() {
    _event = widget.event;
    _bbSubEvents = widget.subEvents;
    _selectedSubEvents = _bbSubEvents != null ? List.from(_bbSubEvents!) : null;
    _subEventController.text = _searchText ?? '';
    _superEventChildDisplayOnlyUnderSuperEvent = _event?.isSuperEventChild == true && _event?.grouping?.canDisplayAsIndividual == false;
    _evaluatePublishAllSubEventsField();
    _subEventController.addListener(onTextChanged);

    NotificationService().subscribe(this, [Events2.notifyUpdated,]);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(CollectionUtils.isEmpty(_selectedSubEvents)){
        _updateSubEventsFromBB(init: true);
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
      appBar: HeaderBar(title: Localization().getStringEx('panel.event2.detail.super_event.header.title', 'Super Event Settings'), actions: _headerBarActions,),
      body: _buildContent(),
      backgroundColor: Styles().colors.white,
    );
  }

  Widget _buildContent() =>
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 24), child:
          _event?.isSuperEventChild == true ? _buildSuperEventChildContent() : //Super Event child see limited options,
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Event2SetupSuperEventPanel.buildDescriptionWidget(
                  text: 'Set and manage this event as a multi-event “super event.” After creating one or more related events, you can nest those events as sub-events within a super event (e.g., sessions in a conference, performances in a festival).'
              ),
              Padding(padding: EdgeInsets.symmetric(vertical: 8),child:
              Visibility(visible: _publishAllSubEventsVisible, child:
                ToggleRibbonButton(
                  title: Localization().getStringEx("", "PUBLISH ALL LINKED SUB-EVENTS"),
                  toggled: _publishAllSubEvents,
                  textStyle: _event?.published == true ? Styles().textStyles.getTextStyle("widget.button.title.enabled") : Styles().textStyles.getTextStyle("widget.button.title.disabled"),
                  enabled: _event?.published == true,
                  onTap: (){
                    if(_event?.published == true)
                      setStateIfMounted(() {
                        _publishAllSubEvents = !_publishAllSubEvents;
                      });
                  },
                  border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
                  borderRadius: BorderRadius.all(Radius.circular(4)),
                ))),
              Padding(padding: EdgeInsets.only(bottom: 16), child: Event2SetupSuperEventPanel.buildSectionTitleWidget('SUB-EVENT(s)')),
              _buildSubEventsSection(_selectedSubEvents,
                  emptyMsg: 'This event is not linked to any sub-events. Please see below.',
                  showUnlink: true),
              Padding(padding: EdgeInsets.only(top: 12), child:
              Container(decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFF717273), width: 1))
              ), padding: EdgeInsets.only(top: 12, left: 16, right: 16)
              )),
              Padding(padding: EdgeInsets.only(bottom: 16), child: Event2SetupSuperEventPanel.buildSectionTitleWidget('LINK EVENT(s)')),
              _buildSubeventSelectionSection(),
              _buildSubEventsSection(_subEventCandidates,
                emptyMsg:  'You currently have no upcoming events. To link and create sub-events within a super event, please first create your sub-events as basic events.',
                showLink: true, ),
            ])
        ));

  Widget _buildSuperEventChildContent(){ //Sub Events see limited options
      if(_event?.isSuperEventChild != true)
        return Container();

      bool toggled = _superEventChildDisplayOnlyUnderSuperEvent == true;
      return Column(children: [
        ToggleRibbonButton(
          title: Localization().getStringEx("", "DISPLAY ONLY UNDER SUPER EVENT"),
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          toggled: toggled,
          onTap: (){
            setStateIfMounted(() {
              _superEventChildDisplayOnlyUnderSuperEvent = !toggled;
            });
          },
          border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
          borderRadius: BorderRadius.all(Radius.circular(4)),
        )
      ]);
  }

  Widget _buildSubEventsSection(events, {bool showLink = false, bool showUnlink = false, String? emptyMsg}) {
    Widget resultWidget;
    if (CollectionUtils.isEmpty(events)) {
      return Event2SetupSuperEventPanel.buildDescriptionWidget(text: emptyMsg ?? "");
    } else {
      List<Widget> eventsWidgetList = [];
      events!.forEach((event) {
        eventsWidgetList.add(Padding(
            padding: EdgeInsets.only(bottom: 10),
            child: _EventCard(key: GlobalKey(),
                event: event,
                showLink: showLink,
                showUnlink: showUnlink,
                onTapLink: _onLinkEvent,
                onTapUnlink: _onUnlinkEvent
            )
        ));
      });
      resultWidget = Column(crossAxisAlignment: CrossAxisAlignment.center, children: eventsWidgetList);
    }
    return resultWidget;
  }

  Widget _buildSubeventSelectionSection() => Event2CreatePanel.buildSectionWidget(
    body: Event2SetupSuperEventPanel.buildTextEditWidget(_subEventController, keyboardType: TextInputType.text),
  );

//
  void onTextChanged(){
    final text = _subEventController.text;
    if(_searchText?.compareTo(text) != 0) {
      _loadSubEventCandidates();
    }
  }

  Future<void> _loadSubEventCandidates() async{
    final text = _subEventController.text;
      Client client = Client();

    _loadCandidatesClient?.close();
    _loadCandidatesClient = client;
      setStateIfMounted((){
        _searchText = text;
      });

      print('subevent title search: $text (${text.characters.length})');
      _asyncLoadCandidates(client: client)?.then((result) {
          Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
          List<Event2>? candidates = listResult?.events;

          if(identical(_loadCandidatesClient, client)) {
            candidates?.removeWhere(_skipCandidateCondition); //Additional filtering

            // var additionalCandidates = _additionalCandidates.where((additionalCandidate) =>
            //   candidates?.any((candidate) => candidate.id == additionalCandidate.id) == false); //Items which are removed but not uploaded yet
            candidates?.addAll(_additionalCandidates.where((additionalCandidate) =>
              candidates.contains(additionalCandidate) == false)); //Do not double items. When we add/remove we directly manipulate, but when we search text we lose these items

            setStateIfMounted(() {
              _subEventCandidates = candidates;
            });
          }
      });
  }

  Future<void> _updateSubEventsFromBB({bool init = false}) async {
      Client client = Client();
    _loadBBEventsClient?.close();
    _loadBBEventsClient = client;

    var loadResult = await SuperEventsController.loadSubEvents(superEvent: _event, client: client);
    if(identical(_loadBBEventsClient, client) == false) {
      return;
    }
    if (loadResult is String){
      return; //error
    }

    List<Event2>? events = loadResult is Events2ListResult ? loadResult.events : null;
    setStateIfMounted(() {
      _bbSubEvents = events;
      if(init) {
        _selectedSubEvents ??= events != null ? List.from(events) : null;
      } else {
        _selectedSubEvents = _mergeCollectionWithUpdates(collection: _selectedSubEvents, updatedCollection: events);
      }
      _evaluatePublishAllSubEventsField();
    });
  }

  Future<dynamic>? _asyncLoadCandidates({Client? client}) async => Events2().loadEventsEx( //TBD load in portions: pass offset and limit
    Events2Query(
      searchText: _searchText,
      types: {Event2TypeFilter.admin},
      grouping: Event2Grouping(type: Event2GroupingType.none), //Exclude SuperEvents and Recurring events
    ), client: client);

  void _onLinkEvent(Event2 event){
    setStateIfMounted(() {
      _subEventCandidates?.remove(event);
      if(_selectedSubEvents == null) {
        _selectedSubEvents = [];
      }
      if(_selectedSubEvents!.contains(event) == false)
      _selectedSubEvents!.add(event);

      _evaluatePublishAllSubEventsField();
    });
  }

  void _onUnlinkEvent(Event2 event){
    setStateIfMounted(() {
      if(_subEventCandidates?.contains(event) == false)
        _subEventCandidates?.add(event);
      _selectedSubEvents!.remove(event);
      _evaluatePublishAllSubEventsField();
    });
  }

  void _onApply(){
    setStateIfMounted(() => _applying = true);
    if(_event != null) {
      if(_isSuperEventChild){
        if(_isSuperEventChildModified) {
          Event2Grouping? updatedGrouping = _event?.grouping?.copyWith(displayAsIndividual: !(_superEventChildDisplayOnlyUnderSuperEvent == true));
          if(updatedGrouping != null){
            Event2? updateEventData = _event?.copyWithNullable(grouping: NullableValue(updatedGrouping));
            SuperEventsController.multiUploadUpdate(events: [updateEventData!]).then((result){
              setStateIfMounted(() => _applying = false);
              if (result.successful)
                AppAlert.showDialogResult(
                    context, 'Successfully updated ${result.data} sub events');
              else
                AppAlert.showDialogResult(
                    context, 'Unable to update: \n ${result.error}');
            });
            };
        }
      } else {
        SuperEventsController.update(
            superEvent: _event!,
            existingSubEvents: _bbSubEvents,
            updatedEventsSelection: _selectedSubEvents,
            publishLinkedEvents: _event?.published == true && _publishAllSubEvents
        ).then((result) {
           if ( result.successful){
             if(_needToApplyPushAll &&  _event?.published == true) //Need to handle publish all sub events
               SuperEventsController.applyPublishAllSubEvents(_event).then((publishResult){
                 setStateIfMounted(() => _applying = false);
                 if (result.successful)
                   AppAlert.showDialogResult(
                       context, 'Successfully updated ${(publishResult.data ?? 0) + (result.data ?? 0)} sub events');
                 else
                   AppAlert.showDialogResult(
                       context, 'Unable to update: \n ${publishResult.error}');
               });
             else {
               setStateIfMounted(() => _applying = false);
               AppAlert.showDialogResult(
                   context, 'Successfully updated ${(result.data ?? 0)} sub events');
             }
           } else {
             setStateIfMounted(() => _applying = false);
             AppAlert.showDialogResult(
                 context, 'Unable to update: \n ${result.error}');
           }
          });
      }
    }
  }

  void _evaluatePublishAllSubEventsField(){
    _publishAllSubEvents = !_hasSubEventToPublish;
  }

  bool _skipCandidateCondition(Event2 candidate) =>
      candidate.id == _event?.id //Exclude this Event
      || candidate.grouping?.type == Event2GroupingType.superEvent //Exclude super events and sub events
      || _selectedSubEvents?.contains(candidate) == true; //candidate is already selected but not uploaded yet

  Iterable<Event2> get _additionalCandidates => _bbSubEvents?.where(
          (Event2 event) => _selectedSubEvents?.contains(event) == false) ?? [];//candidates that were unlinked but not uploaded yet

  List<Widget>? get _headerBarActions {
    if (_applying) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if (_isModified) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onApply,
      )];
    }
    else {
      return null;
    }
  }

  bool get _isModified => /*!_printCollectionEquality() ||*/  //debug tool TBD remove when done
        _isSelectedSubEventsModified || //Need to apply selection change
        _isSuperEventChildModified|| //Need to apply show only under super event change
        _needToApplyPushAll; // need to apply publish to sub events

  bool get _isSelectedSubEventsModified => CollectionUtils.equals( _selectedSubEvents?.toSet(), _bbSubEvents?.toSet()) == false; //Ignore order

  bool get _needToApplyPushAll =>
      _isSuperEvent && _publishAllSubEvents == true && _hasSubEventToPublish == true;

  bool get _isSuperEventChildModified => _isSuperEventChild &&
      _superEventChildDisplayOnlyUnderSuperEvent != null &&
      _superEventChildDisplayOnlyUnderSuperEvent == _event?.grouping?.canDisplayAsIndividual;

  bool get _isSuperEventChild => _event?.isSuperEventChild == true;

  bool get _hasSubEventToPublish =>  _selectedSubEvents?.any((Event2 event) => event.published == false) == true;

  bool get _isSuperEvent => CollectionUtils.isNotEmpty(_selectedSubEvents);

  bool get _publishAllSubEventsVisible => _isSuperEvent && widget.event?.published == true;

  @override
  void onNotification(String name, param) {
    if (name == Events2.notifyUpdated) {
      _updateSubEventsFromBB().then((_){
        _loadSubEventCandidates();
      });
      if(_event?.id != null)
        Events2().loadEvent(_event!.id!).then(
                (event) => _event = event ?? _event);
    }
  }

  //Util
  List<Event2>? _mergeCollectionWithUpdates({List<Event2>? collection, List<Event2>? updatedCollection}){
    if (updatedCollection == null || updatedCollection.isEmpty)
      return collection;

    final updates = Map.fromIterable(updatedCollection,
        key: (e) => (e as Event2).id,
        value: (e) => e as Event2);

    return SuperEventsController.applyCollectionChange(collection: collection,
        change: (event) => updates[event.id] ?? event)?.toList(); //replacing each event with its updated value
  }

  //TBD Remove when Done
  // bool _printCollectionEquality(){
  //   if(CollectionUtils.isEmpty(_selectedSubEvents) ||
  //       CollectionUtils.isEmpty(_bbSubEvents) ||
  //       CollectionUtils.equals(_selectedSubEvents?.toSet(), _bbSubEvents?.toSet()))
  //     return true;
  //
  //   print('_selectedSubEvents: $_selectedSubEvents');
  //   print('_bbSubEvents: $_bbSubEvents');
  //   if(CollectionUtils.isNotEmpty(_selectedSubEvents) && CollectionUtils.isNotEmpty(_bbSubEvents)) {
  //     for (Event2 event in _bbSubEvents ?? []) {
  //       print('Event ${event.id} has Equal: ${_selectedSubEvents!.contains(event)}');
  //       if(!_selectedSubEvents!.contains(event)){
  //         var secondEvent = _selectedSubEvents!.where((selectedEvent)=> selectedEvent.id == event.id);
  //         print('Not Equal Event Data First: ${event.toJson()} \n');
  //         print('Not Equal Event Data Second: ${secondEvent.isNotEmpty ? secondEvent.first.toJson() : 'null'} \n');
  //       }
  //     }
  //     bool areListsEqual = CollectionUtils.equals(_selectedSubEvents, _bbSubEvents);
  //     bool areSetsEqual = CollectionUtils.equals(_selectedSubEvents?.toSet(), _bbSubEvents?.toSet());
  //     print('areListsEqual: $areListsEqual');
  //     print('areSetsEqual: $areSetsEqual');
  //   }
  //
  //   return true;
  // }
}

class _EventCard extends StatelessWidget{
  final Event2 event;
  final bool? showLink;
  final bool? showUnlink;
  final Function(Event2)? onTapLink;
  final Function(Event2)? onTapUnlink;

  const _EventCard({super.key, required this.event, this.showLink, this.showUnlink, this.onTapLink, this.onTapUnlink});

  @override
  Widget build(BuildContext context) =>
    // TBD consider custom card with link/unlink button like in the Admin App
    Event2Card(event,
        onTap: (){
        if(this.showLink == true)
          this.onTapLink?.call(event);
        else if(showUnlink == true)
          this.onTapUnlink?.call(event);
        });
}

class Event2SuperEventResult<T>{
    String? error;
    T? data;

    Event2SuperEventResult({String? this.error, this.data});

    static Event2SuperEventResult<T> fail<T>(String? error) => Event2SuperEventResult(error: error ?? "error");

    static Event2SuperEventResult<T> success<T>({required T data}) => Event2SuperEventResult(data: data);

    bool get successful => this.error == null;
}

class SuperEventsController {

  static Future<Event2SuperEventResult<int>> update({required Event2 superEvent, List<Event2>? existingSubEvents,
    List<Event2>? updatedEventsSelection, bool? publishLinkedEvents = false}) async {
      Event2SuperEventResult<int> linkedResult = await _updateUnlinked(
          superEvent: superEvent,
          existingSubEvents: existingSubEvents,
          updatedEventsSelection: updatedEventsSelection);
      Event2SuperEventResult<int> unlinkedResult = await _updateLinked(
          superEvent: superEvent,
          existingSubEvents: existingSubEvents,
          updatedEventsSelection: updatedEventsSelection,);

      return linkedResult.successful && unlinkedResult.successful ?
        Event2SuperEventResult.success(data: (linkedResult.data ?? 0) + (unlinkedResult.data ?? 0)) :
        Event2SuperEventResult.fail("${linkedResult.error} ${unlinkedResult.error}");
  }

  static Future<Event2SuperEventResult<int>> _updateUnlinked({Event2? superEvent, List<Event2>?existingSubEvents,
    List<Event2>? updatedEventsSelection}) async{
      List<Event2>? unlinkedSubEvents = _filterNeedUnlink(existingSubEvents, updatedEventsSelection);

      if(CollectionUtils.isEmpty(unlinkedSubEvents))
        return Event2SuperEventResult.success(data: 0);//nothing to unlink;

      Event2SuperEventResult? uploadResult = await multiUploadUpdate(
          events: applyCollectionChange(collection: unlinkedSubEvents,
              change: (event) => event.copyWithNullable(grouping: NullableValue.empty())));;
      String error = uploadResult.error ?? "";

      if (CollectionUtils.isEmpty(updatedEventsSelection) && superEvent?.isSuperEvent == true) { //Mark Main event as regular event
        Event2? updatedEventData = superEvent!.copyWithNullable(grouping: NullableValue.empty());
        var mainEventResponse = await Events2().updateEvent(updatedEventData);
        error += mainEventResponse is Event2 ? "" : "$mainEventResponse\n";
      }

      return StringUtils.isEmpty(error) ?
        Event2SuperEventResult.success(data: uploadResult.data) :
        Event2SuperEventResult.fail(error);
  }

  static  Future<Event2SuperEventResult<int>> _updateLinked({required Event2 superEvent,
    List<Event2>? existingSubEvents, List<Event2>? updatedEventsSelection}) async {
      List<Event2>? linkSubEvents = _filterNeedLink(existingSubEvents, updatedEventsSelection);

      if(CollectionUtils.isEmpty(linkSubEvents))
        return Event2SuperEventResult.success(data: 0);//nothing to add;

      final updateGroupingData = Event2Grouping(type: Event2GroupingType.superEvent, superEventId: superEvent.id, displayAsIndividual: false);
     Event2SuperEventResult? uploadResult = await multiUploadUpdate(
            events: applyCollectionChange(collection: linkSubEvents,
                change: (event) => event.copyWithNullable(grouping: NullableValue(updateGroupingData))));

     String error = uploadResult.error ?? "";
      if (superEvent.isSuperEvent == false) { //Mark Main event as super event if not marked
        Event2 updatedEventData = superEvent.copyWithNullable(grouping: NullableValue(Event2Grouping(type: Event2GroupingType.superEvent)));
        var mainEventResponse = await Events2().updateEvent(updatedEventData);
        error += mainEventResponse is Event2 ? "" : "$mainEventResponse\n";
      }

      return StringUtils.isEmpty(error) ?
      Event2SuperEventResult.success(data: uploadResult.data) :
      Event2SuperEventResult.fail(error);
  }

  static List<Event2>? _filterNeedUnlink(List<Event2>? existingSubEvents, List<Event2>? updatedEventsSelection){
    if(CollectionUtils.isEmpty(existingSubEvents))
      return null; //nothing to update

    return CollectionUtils.isEmpty(updatedEventsSelection) ?
      existingSubEvents :
      existingSubEvents?.where((sub) =>
          !updatedEventsSelection!.map((event)=>(event.id)).contains(sub.id)
      ).toList();
  }

  static List<Event2>? _filterNeedLink(List<Event2>? existingSubEvents, List<Event2>? updatedEventsSelection){
    if(CollectionUtils.isEmpty(updatedEventsSelection))
      return null; //nothing to update

    return CollectionUtils.isEmpty(existingSubEvents) ?
      updatedEventsSelection :
      updatedEventsSelection!.where((sub)=>
          !existingSubEvents!.map((event) => (event.id)).contains(sub.id)
      ).toList();
  }

  static Future<Event2SuperEventResult<int>> multiUpload({required Iterable<Event2>? events, required Future Function(Event2) uploadAPI}) async {
    String error = "";
    int successCount = 0;
    if(CollectionUtils.isEmpty(events))
      return Event2SuperEventResult.success(data: successCount); //nothing to upload

    for (final updateEvent in events!) {
      dynamic response = await uploadAPI(updateEvent);
      bool fail = response == null || response is String;
      if (fail) {
        error += "$response\n";
        // AppAlert.showDialogResult(context, 'Failed to remove sub-event. Response: ${response.body}');
      } else {
        successCount++;
      }
    }
    return StringUtils.isEmpty(error) ?
    Event2SuperEventResult.success(data: successCount) :
    Event2SuperEventResult.fail(error);
  }

  static Future<Event2SuperEventResult<int>> multiUploadUpdate({required Iterable<Event2>? events}) async =>
      multiUpload(events: events, uploadAPI: Events2().updateEvent);

  static Future<Event2SuperEventResult<int>> applyPublishAllSubEvents(Event2? event, {List<Event2>? subEvents}) async {
      if(event?.published == false)
        return Event2SuperEventResult.success(data: 0);

      if(CollectionUtils.isEmpty(subEvents)) {
        Events2ListResult? result = await Events2().loadEvents(Events2Query(groupings: event?.linkedEventsGroupingQuery));
        subEvents = result?.events;
      }
      Iterable<Event2>? unpublishedEvents = subEvents?.where((Event2 event) => event.published == false);

      if(CollectionUtils.isEmpty(unpublishedEvents))
        return Event2SuperEventResult.success(data: 0);

      return multiUploadUpdate(events: unpublishedEvents?.map(
              (Event2 event) => event.copyWithNullable(published: NullableValue(true))));
  }

  //load
  static Future<dynamic>? loadSubEvents({Event2? superEvent, Client? client}) => superEvent?.isSuperEvent == true ? Events2().loadEventsEx(
      Events2Query(groupings: superEvent?.linkedEventsGroupingQuery),
      client: client
  ) : null;

  //Utils
  static Iterable<Event2>? applyCollectionChange({required Iterable<Event2>? collection, required Event2 Function(Event2) change})
    => collection?.map(change);
}

//If we want to keep organized instance of the subEvents
class SuperEvent {
  Event2 superEvent;
  Iterable<Event2>? subEvents;
  bool loading = false;

  SuperEvent({required  this.superEvent, this.subEvents});

  static SuperEvent? fromEvent(Event2? event) => event?.isSuperEvent == true ?
  SuperEvent(superEvent: event!) : null;

  void syncSubEvents({VoidCallback? onLoaded}) {
    loading = true;
    SuperEventsController.loadSubEvents(superEvent: superEvent)?.then((loadResult) {
      subEvents = loadResult is Events2ListResult ? loadResult.events : null;

      loading = false;
      onLoaded?.call();
    });
  }

  Future<bool> publishAllSubEvents() async =>  haveUnpublishedSubEvents ?
    ((await SuperEventsController.applyPublishAllSubEvents(superEvent, subEvents: subEvents?.toList())).successful) :
      true;
}

extension SuperEventExt on SuperEvent{
  bool get haveUnpublishedSubEvents => (subEvents?.any((Event2 event) => event.published == false) == true);
}