
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/ui/events2/Event2Widgets.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';

class Event2ListPanel extends StatefulWidget {
  static final String routeName = 'Event2ListPanel';

  @override
  State<StatefulWidget> createState() => _Event2ListPanelState();

  static void present(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Event2ListPanel.routeName), builder: (context) => Event2ListPanel()));
  }
}

class _Event2ListPanelState extends State<Event2ListPanel> {

  bool _loadingEvents = false;
  List<Event2>? _events;
  final int eventsPageLength = 12;

  @override
  void initState() {
    _loadingEvents = true;
    Events2().loadEvents(Events2Query(offset: 0, limit: eventsPageLength)).then((List<Event2>? events) {
      setStateIfMounted(() {
        _events = (events != null) ? List<Event2>.from(events) : null;
        _loadingEvents = false;
      });
    });
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx("panel.events2_list.header.title", "Events"), leading: RootHeaderBarLeading.Back,),
      body: _buildPanelContent(),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: uiuc.TabBar(),
    );
  }

  Widget _buildPanelContent() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildCommandBar(),
      Expanded(child:
        _buildEventsContent(),
      )
    ],);
  }

  Widget _buildCommandBar() {
    return Container(decoration: _commandBarDecoration, child:
      Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 16), child:
        Row(children: [
          Expanded(flex: 6, child: Wrap(spacing: 8, runSpacing: 8, children: [ //Row(mainAxisAlignment: MainAxisAlignment.start, children: [
            Event2FilterCommandButton(
              title: 'Filters',
              leftIconKey: 'filters',
              rightIconKey: 'chevron-right',
              onTap: _onFilters,
            ),
            Event2FilterCommandButton(
              title: 'Sort',
              leftIconKey: 'sort',
              onTap: _onSort,
            ),
          ])),
          Expanded(flex: 4, child: Wrap(alignment: WrapAlignment.end, verticalDirection: VerticalDirection.up, children: [
            LinkButton(
              title: 'Map View',
              hint: 'Tap to view map',
              onTap: _onMapView,
              padding: EdgeInsets.only(left: 0, right: 8, top: 16, bottom: 16),
              textStyle: Styles().textStyles?.getTextStyle('widget.button.title.regular.underline'),
            ),
            Event2ImageCommandButton('plus-circle',
              label: 'Create',
              hint: 'Tap to create event',
              contentPadding: EdgeInsets.only(left: 8, right: 8, top: 16, bottom: 16),
              onTap: _onCreate
            ),
            Event2ImageCommandButton('search',
              label: 'Search',
              hint: 'Tap to search events',
              contentPadding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16),
              onTap: _onSearch
            ),
          ])),
        ],)
      ),
    );
  }

  Decoration get _commandBarDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border.all(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1)
  );

  Widget _buildEventsContent() {
    if (_loadingEvents) {
      return _buildLoadingContent();
    }
    else if (_events == null) {
      return _buildMessageContent('Failed to load events.');
    }
    else if (_events?.length == 0) {
      return _buildMessageContent('There are no events matching the selected filters.');
    }
    else {
      return _buildEventsList();
    }
  }

  Widget _buildEventsList() {
    List<Widget> cardsList = <Widget>[];
    for (Event2 event in _events!) {
      cardsList.add(Padding(padding: EdgeInsets.only(left: 16, right: 16, top: cardsList.isNotEmpty ? 8 : 0), child:
        Event2Card(event),
      ),);
    }
    return RefreshIndicator(onRefresh: _onRefresh, child:
      SingleChildScrollView(child:
        Padding(padding: EdgeInsets.all(16), child:
          Column(children:  cardsList,)
        ),
      ),
    );
  }

  Widget _buildMessageContent(String message) {
    return Center(child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 32, vertical: 32), child:
        Text(message, style: Styles().textStyles?.getTextStyle('widget.item.medium.fat'),)
      )
    );
  }

  Widget _buildLoadingContent() => Center(child:
    SizedBox(width: 32, height: 32, child:
      CircularProgressIndicator(color: Styles().colors?.fillColorSecondary,)
    )
  );

  Future<void> _onRefresh() async {
  }

  void _onFilters() {
    
  }

  void _onSort() {
    
  }

  void _onSearch() {

  }

  void _onCreate() {

  }

  void _onMapView() {

  }
}
