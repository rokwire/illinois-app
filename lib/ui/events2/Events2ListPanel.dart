
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:illinois/ui/widgets/TabBar.dart' as uiuc;
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class Events2ListPanel extends StatefulWidget {
  static final String routeName = 'Events2ListPanel';

  @override
  State<StatefulWidget> createState() => _Events2ListPanelState();

  static void present(BuildContext context) {
    Navigator.push(context, CupertinoPageRoute(settings: RouteSettings(name: Events2ListPanel.routeName), builder: (context) => Events2ListPanel()));
  }
}

class _Events2ListPanelState extends State<Events2ListPanel> {

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

class Event2FilterCommandButton extends StatelessWidget {
  final String? title;
  final String? hint;
  final String  titleTextStyleKey;

  final String? leftIconKey;
  final EdgeInsetsGeometry leftIconPadding;

  final String? rightIconKey;
  final EdgeInsetsGeometry rightIconPadding;

  final EdgeInsetsGeometry contentPadding;
  final Decoration? contentDecoration;

  final void Function()? onTap;

  Event2FilterCommandButton({Key? key,
    this.title, this.hint,
    this.titleTextStyleKey = 'widget.button.title.regular',
    this.leftIconKey,
    this.leftIconPadding = const EdgeInsets.only(right: 6),
    
    this.rightIconKey,
    this.rightIconPadding = const EdgeInsets.only(left: 3),

    this.contentPadding = const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
    this.contentDecoration,

    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    List<Widget> contentList = <Widget>[];

    Widget? leftIconWidget = (leftIconKey != null) ? Styles().images?.getImage(leftIconKey) : null;
    if (leftIconWidget != null) {
      contentList.add(
        Padding(padding: leftIconPadding, child: leftIconWidget,)
      );
    }

    if (StringUtils.isNotEmpty(title)) {
      contentList.add(
        Text(title ?? '', style: Styles().textStyles?.getTextStyle(titleTextStyleKey),)
      );
    }

    Widget? rightIconWidget = (rightIconKey != null) ? Styles().images?.getImage(rightIconKey) : null;
    if (rightIconWidget != null) {
      contentList.add(
        Padding(padding: rightIconPadding, child: rightIconWidget,)
      );
    }

    return Semantics(label: title, hint: hint, button: true, child:
      InkWell(onTap: onTap, child: 
        Container(decoration: contentDecoration ?? defaultContentDecoration, child:
          Padding(padding: contentPadding, child:
            //Row(mainAxisSize: MainAxisSize.min, children: contentList,),
            Wrap(children: contentList,)
          ),
        ),
      ),
    );
  }

  Decoration get defaultContentDecoration => BoxDecoration(
    color: Styles().colors?.white,
    border: Border.all(color: Styles().colors?.disabledTextColor ?? Color(0xFF717273), width: 1),
    borderRadius: BorderRadius.circular(16),
  );

}

class Event2ImageCommandButton extends StatelessWidget {
  final String imageKey;
  final String? label;
  final String? hint;
  final EdgeInsetsGeometry contentPadding;
  final void Function()? onTap;
  Event2ImageCommandButton(this.imageKey, { Key? key,
    this.label, this.hint,
    this.contentPadding = const EdgeInsets.all(16),
    this.onTap,
  }) : super(key: key);

   @override
  Widget build(BuildContext context) =>
    Semantics(label: label, hint: hint, button: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: contentPadding, child:
          Styles().images?.getImage(imageKey)
        )
      ),
    );
}

class Event2Card extends StatefulWidget {
  final Event2 event;
  final void Function()? onTap;
  
  Event2Card(this.event, { Key? key, this.onTap}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2CardState();
}

class _Event2CardState extends State<Event2Card> {

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(label: _semanticsLabel, hint: _semanticsHint, button: true, child:
      InkWell(onTap: widget.onTap, child:
        Container(decoration: _contentDecoration, child:
          ClipRRect(borderRadius: _contentBorderRadius, child: 
            Column(mainAxisSize: MainAxisSize.min, children: [
              Visibility(visible: StringUtils.isNotEmpty(widget.event.imageUrl), child:
                Container(decoration: _imageDecoration, child:
                  AspectRatio(aspectRatio: 2.5, child:
                    Image.network(widget.event.imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
                  ),
                )
              ),
              Padding(padding: EdgeInsets.all(16), child:
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.event.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'), maxLines: 2,)
                ]),
              ),

            ],),
          ),
        ),
      ),
    );
  }

  String get _semanticsLabel => 'TODO Label';
  String get _semanticsHint => 'TODO Hint';
  
  Decoration get _contentDecoration => BoxDecoration(
    color: Styles().colors?.surface,
    borderRadius: _contentBorderRadius,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    boxShadow: [ BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]
  );

  BorderRadiusGeometry get _contentBorderRadius => BorderRadius.all(Radius.circular(8));

  Decoration get _imageDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1)),
  );
}