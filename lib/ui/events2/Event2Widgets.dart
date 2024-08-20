
import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:geolocator/geolocator.dart';
import 'package:neom/ext/Event2.dart';
import 'package:neom/ext/Explore.dart';
import 'package:neom/service/Analytics.dart';
import 'package:neom/service/Auth2.dart';
import 'package:neom/service/Config.dart';
import 'package:neom/ui/athletics/AthleticsGameDetailPanel.dart';
import 'package:neom/ui/home/HomeWidgets.dart';
import 'package:neom/ui/events2/Event2CreatePanel.dart';
import 'package:neom/ui/events2/Event2DetailPanel.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/ribbon_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

//
// Event2FilterCommandButton
//

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

    Widget? leftIconWidget = (leftIconKey != null) ? Styles().images.getImage(leftIconKey) : null;
    if (leftIconWidget != null) {
      contentList.add(
        Padding(padding: leftIconPadding, child: leftIconWidget,)
      );
    }

    if (StringUtils.isNotEmpty(title)) {
      contentList.add(
        Text(title ?? '', style: Styles().textStyles.getTextStyle(titleTextStyleKey), semanticsLabel: "",)
      );
    }

    Widget? rightIconWidget = (rightIconKey != null) ? Styles().images.getImage(rightIconKey) : null;
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
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: contentList,)
          ),
        ),
      ),
    );
  }

  static BoxDecoration get defaultContentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    border: Border.all(color: Styles().colors.textDisabled, width: 1),
    borderRadius: BorderRadius.circular(16),
  );

}

//
// Event2ImageCommandButton
//

class Event2ImageCommandButton extends StatelessWidget {
  final Widget? image;
  final String? label;
  final String? hint;
  final EdgeInsetsGeometry contentPadding;
  final void Function()? onTap;
  Event2ImageCommandButton(this.image, { Key? key,
    this.label, this.hint,
    this.contentPadding = const EdgeInsets.all(16),
    this.onTap,
  }) : super(key: key);

   @override
  Widget build(BuildContext context) =>
    Semantics(label: label, hint: hint, button: true, child:
      InkWell(onTap: onTap, child:
        Padding(padding: contentPadding, child:
          image
        )
      ),
    );
}

//
// Event2Card
//

class Event2Card extends StatefulWidget {
  final Event2 event;
  final Group? group;
  final Event2CardDisplayMode displayMode;
  final Event2GroupingType? linkType;
  final Position? userLocation;
  final void Function()? onTap;
  
  final List<String>? displayCategories;
  
  Event2Card(this.event, { Key? key, this.group, this.displayMode = Event2CardDisplayMode.list, this.linkType, this.userLocation, this.onTap}) :
    displayCategories = Events2().displaySelectedContentAttributeLabelsFromSelection(event.attributes, usage: ContentAttributeUsage.category),
    super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2CardState();

  bool get hasDisplayCategories => (displayCategories?.isNotEmpty == true);

  static Decoration get linkContentDecoration => _Event2CardState._linkContentDecoration;
  static BorderRadiusGeometry get linkContentBorderRadius => _Event2CardState._linkContentBorderRadius;
}

class _Event2CardState extends State<Event2Card>  implements NotificationsListener {

  // Keep a copy of the user position in the State because it gets cleared somehow in the widget
  // when sending the appliction to background in iOS.
  late Event2 _event;
  Position? _userLocation; 

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged,
      Events2.notifyUpdated,
    ]);
    _event = widget.event;
    _userLocation = widget.userLocation;
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Auth2UserPrefs.notifyFavoriteChanged) {
      if ((param is Favorite) && (param.favoriteKey == _event.favoriteKey) && (param.favoriteId == _event.favoriteId) && mounted) {
        setState(() {});
      }
    }
    else if (name == Events2.notifyUpdated) {
      if ((param is Event2) && (param.id == _event.id) && mounted) {
        setState(() {
          _event = param;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(label: _semanticsLabel, hint: _semanticsHint, button: true, child:
    InkWell(onTap: widget.onTap, child:
      Semantics(excludeSemantics: StringUtils.isNotEmpty(_semanticsLabel), child:
        _contentWidget
      )
    )
  );

  Widget get _contentWidget {
    switch (widget.displayMode) {
      case Event2CardDisplayMode.list: return _listContentWidget;
      case Event2CardDisplayMode.page: return _pageContentWidget;
      case Event2CardDisplayMode.link: return _linkContentWidget;
      case Event2CardDisplayMode.cardLink: return _cardLinkContentWidget;
    }
  }

  Widget get _listContentWidget =>
    Container(decoration: _listContentDecoration, child:
      ClipRRect(borderRadius: _listContentBorderRadius, child: 
        Column(mainAxisSize: MainAxisSize.min, children: [
          _imageHeadingWidget,
          _contentHeadingWidget,
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _titleWidget,
              _detailsWidget,
            ]),
          ),
          ..._linkedEventsPagerWidget,
        ],),
      ),
    );

  Widget get _pageContentWidget =>
    _hasImage ? _pageImageContentWidget : _pageStandardContentWidget;

  Widget get _pageStandardContentWidget =>
    Container(decoration: _pageContentDecoration, child:
      ClipRRect(borderRadius: _pageContentBorderRadius, child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          _imageHeadingWidget,
          _contentHeadingWidget,
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
            Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _titleWidget,
              _detailsWidget,
            ]),
          ),
          ..._linkedEventsPagerWidget,
        ]),
      ),
    );

  Widget get _pageImageContentWidget =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      Container(decoration: _pageTopContentDecoration, child:
        ClipRRect(borderRadius: _pageContentTopBorderRadius, child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            _imageHeadingWidget,
          ])
        ),
      ),
      Container(decoration: _pageBottomContentDecoration, child:
        ClipRRect(borderRadius: _pageContentBottomBorderRadius, child:
          Column(mainAxisSize: MainAxisSize.min, children: [
            _contentHeadingWidget,
            Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _titleWidget,
                _detailsWidget,
              ]),
            ),
            ..._linkedEventsPagerWidget,
          ]),
        ),
      ),
    ]);

  Widget get _linkContentWidget =>
    Container(decoration: _linkContentDecoration, child:
      ClipRRect(borderRadius: _linkContentBorderRadius, child:
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16, top: 14, bottom: 14), child:
              Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                _linkTitleWidget,
                _linkDetailWidget,
              ],),
            ),
          ),
          _favoriteButton,
          _groupEventOptionsButton,
        ],)
      ),
    );

  Widget get _cardLinkContentWidget =>
    Column(mainAxisSize: MainAxisSize.min, children: [
      _eventHeadingWidget,
      Container(decoration: _linkBottomContentDecoration, child:
        ClipRRect(borderRadius: _linkContentBottomBorderRadius, child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16, top: 14, bottom: 14), child:
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _linkTitleWidget,
                  _linkDetailWidget,
                ],),
              ),
            ),
            _favoriteButton,
            _groupEventOptionsButton,
          ],)
        ),
      ),
    ]);

  Widget get _linkTitleWidget {
    String? title;
    if (widget.linkType == Event2GroupingType.superEvent) {
      title = _event.name;
    }
    else if (widget.linkType == Event2GroupingType.recurrence) {
      title = _event.shortDisplayDate;
    }
    return Text(title ?? '', style: Styles().textStyles.getTextStyle("widget.title.regular.fat"), maxLines: 2, overflow: TextOverflow.ellipsis,);
  }

  Widget get _linkDetailWidget {
    String? detail;
    if (widget.linkType == Event2GroupingType.superEvent) {
      detail = _event.shortDisplayDateAndTime;
    }
    else if (widget.linkType == Event2GroupingType.recurrence) {
      detail = _event.shortDisplayTime;
    }
    return Text(detail ?? '', style: Styles().textStyles.getTextStyle("widget.item.small"), maxLines: 1, overflow: TextOverflow.ellipsis,);
  }

  String get _semanticsLabel => '';//'''TODO custom label if needed';
  String get _semanticsHint => '';//'''TODO custom hint if needed';

  static Decoration get _listContentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    // borderRadius: _listContentBorderRadius,
    // border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    // boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static BorderRadiusGeometry get _listContentBorderRadius => BorderRadius.all(Radius.circular(8));

  static Decoration get _pageContentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    // borderRadius: _pageContentBorderRadius,
    // border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    // boxShadow: _pageContentShadow
  );

  static Decoration get _pageTopContentDecoration => BoxDecoration(
    borderRadius: _pageContentTopBorderRadius,
    boxShadow: _pageContentShadow
  );

  static Decoration get _pageBottomContentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _pageContentBottomBorderRadius,
    border: Border(
      left: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
      right: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
      bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
    ),
    boxShadow: _pageContentShadow
  );

  static List<BoxShadow> get _pageContentShadow => [
    BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))
  ];

  static Radius get _pageContentRadius => Radius.circular(4.0);
  static BorderRadiusGeometry get _pageContentBorderRadius => BorderRadius.all(_pageContentRadius);
  static BorderRadiusGeometry get _pageContentTopBorderRadius => BorderRadius.vertical(top: _pageContentRadius);
  static BorderRadiusGeometry get _pageContentBottomBorderRadius => BorderRadius.vertical(bottom: _pageContentRadius);

  static Decoration get _linkContentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    // borderRadius: _linkContentBorderRadius,
    // border: Border.all(color: Styles().colors.surfaceAccent, width: 1),
    // boxShadow: _linkContentShadow
  );

  static Decoration get _linkBottomContentDecoration => BoxDecoration(
    color: Styles().colors.surface,
    borderRadius: _linkContentBottomBorderRadius,
    border: Border(
      left: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
      right: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
      bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1),
    ),
    boxShadow: _linkContentShadow
  );

  static List<BoxShadow> get _linkContentShadow => [
    BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 2.0, offset: Offset(0, 1))
  ];

  static Radius get _linkContentRadius => Radius.circular(4.0);
  static BorderRadiusGeometry get _linkContentBorderRadius => BorderRadius.all(_linkContentRadius);
  static BorderRadiusGeometry get _linkContentBottomBorderRadius => BorderRadius.vertical(bottom: _linkContentRadius);

  bool get _hasImage => StringUtils.isNotEmpty(_event.imageUrl);

  bool get _hasGroup => (widget.group != null);
  bool get _isGroupAdmin => (widget.group?.currentMember?.isAdmin ?? false);
  bool get _canEditGroupEvent => _isGroupAdmin && (_event.canUserEdit == true);
  bool get _canDeleteGroupEvent => _isGroupAdmin;
  bool get _hasGroupEventOptions => _hasGroup && (_canEditGroupEvent || _canDeleteGroupEvent);

  Widget get _imageHeadingWidget => Visibility(visible: _hasImage, child:
    Container(decoration: _imageHeadingDecoration, child:
      AspectRatio(aspectRatio: 2.5, child:
        Image.network(_event.imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
      ),
    )
  );

  Decoration get _imageHeadingDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors.surfaceAccent, width: 1)),
  );

  Widget get _eventHeadingWidget => Container(height: _eventHeadingHeight, color: _event.uiColor,);
  double get _eventHeadingHeight => 7;

  Widget get _contentHeadingWidget =>
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 8), child:
          widget.hasDisplayCategories ? _categoriesContentWidget : _titleContentWidget
        ),
      ),
      _favoriteButton,
      _groupEventOptionsButton,
    ]);

  Widget get _categoriesContentWidget =>
    Text(widget.displayCategories?.join(', ') ?? '', overflow: TextOverflow.ellipsis, maxLines: 2, style: Styles().textStyles.getTextStyle("common.title.secondary"));

  /*Widget get _groupingBadgeWidget {
    String? badgeLabel;
    if (_event.isSuperEvent) {
      badgeLabel = Localization().getStringEx('widget.event2.card.super_event.abbreviation.label', 'COMP'); // composite
    }
    else if (_event.isRecurring) {
      badgeLabel = Localization().getStringEx('widget.event2.card.recurring.abbreviation.label', 'REC');
    }
    return (badgeLabel != null) ? 
      Container(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Styles().colors.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
        Semantics(label: badgeLabel, excludeSemantics: true, child:
          Text(badgeLabel, style:  Styles().textStyles.getTextStyle('widget.heading.extra_small'),)
    )) : Container();
  }*/

  Widget get _favoriteButton {
    bool isFavorite = Auth2().isFavorite(_event);
    return Opacity(opacity: Auth2().canFavorite ? 1 : 0, child:
      Semantics(container: true,
        child: Semantics(
          label: isFavorite ?
            Localization().getStringEx('widget.card.button.favorite.off.title', 'Remove From Favorites') :
            Localization().getStringEx('widget.card.button.favorite.on.title', 'Add To Favorites'),
          hint: isFavorite ?
            Localization().getStringEx('widget.card.button.favorite.off.hint', '') :
            Localization().getStringEx('widget.card.button.favorite.on.hint', ''),
          button: true,
          child: InkWell(onTap: _onFavorite,
            child: Padding(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 8),
              child: Styles().images.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true,)
            )
          ),
        ),
      )
    );
  }

  Widget get _groupEventOptionsButton {
    return Visibility(visible: _hasGroupEventOptions, child:
      Semantics(label: Localization().getStringEx('widget.event2.card.detail.group.options.label', 'Options'), button: true, child:
        InkWell(onTap: _onGroupEventOptions, child:
          Container(padding: EdgeInsets.only(top: 16, right: 16, bottom: 16), alignment: Alignment.center, child:
            Styles().images.getImage('more')
          )
        )
      )
    );
  }

  Widget get _titleWidget => widget.hasDisplayCategories ? 
    Row(children: [
      Expanded(child: 
        _titleContentWidget
      ),
    ],) : Container();

  Widget get _titleContentWidget =>
    Text(_event.name ?? '', style: Styles().textStyles.getTextStyle('widget.title.dark.medium.fat'), maxLines: 2, overflow: TextOverflow.ellipsis);

  Widget get _detailsWidget {
    List<Widget> detailWidgets = <Widget>[
      ...?_dateDetailWidget,
      ...?_onlineDetailWidget,
      ...?_locationDetailWidget,
      ...?_groupingDetailWidget,
    ];

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 4), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: detailWidgets,)
    ) : Container();
    
  }

  List<Widget>? get _dateDetailWidget {
    String? dateTime = _event.shortDisplayDateAndTime;
    return (dateTime != null) ? <Widget>[_buildTextDetailWidget(dateTime, 'calendar')] : null;
  }

  List<Widget>? get _onlineDetailWidget {
    return _event.isOnline ? <Widget>[
      _buildTextDetailWidget(Localization().getStringEx('widget.event2.card.detail.online.label', 'Online'), 'laptop')
    ] : null;
  }

  List<Widget>? get _locationDetailWidget {
    if (_event.isInPerson) {

      List<Widget> details = <Widget>[
        _buildTextDetailWidget(Localization().getStringEx('widget.event2.card.detail.in_person.label', 'In Person'), 'location'),
      ];

      String? displayName = _event.location?.displayName;
      if (displayName != null) {
        details.add(_buildLocationTextDetailWidget(displayName));
      }

      String? displayAddress = _event.location?.displayAddress;
      if ((displayAddress != null) && (displayAddress != displayName)) {
        details.add(_buildLocationTextDetailWidget(displayAddress));
      }

      String? displayDescription = _event.location?.displayDescription; // ?? _event.location?.displayCoordinates
      if ((displayDescription != null) && (displayDescription != displayAddress) && (displayDescription != displayName)) {
        details.add(_buildLocationTextDetailWidget(displayDescription));
      }

      String? distanceText = _event.getDisplayDistance(_userLocation);
      if (distanceText != null) {
        details.add(_buildLocationTextDetailWidget(distanceText));
      }

      return details;
    }
    return null;
  }

  List<Widget>? get _groupingDetailWidget {
    if (_event.hasLinkedEvents) {
      List<Widget> details = <Widget>[];
      if (_event.isSuperEvent) {
        details.add(_buildTextDetailWidget(Localization().getStringEx('widget.event2.card.detail.super_event.label', 'Multi-Event'), 'event',));
      }
      if (_event.isRecurring) {
        details.add(_buildTextDetailWidget(Localization().getStringEx('widget.event2.card.detail.recurring.label', 'Repeats'), 'recurrence',));
      }
      return details.isNotEmpty ? details : null;
    }
    return null;
  }

  Widget _buildLocationTextDetailWidget(String text) =>
    _buildDetailWidget(Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: Styles().textStyles.getTextStyle('common.body'),), 'location', iconVisible: false, contentPadding: EdgeInsets.zero);

  Widget _buildTextDetailWidget(String text, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true, int maxLines = 1,
  }) =>
    _buildDetailWidget(
      Text(text, style: Styles().textStyles.getTextStyle('common.body'), maxLines: maxLines, overflow: TextOverflow.ellipsis,),
      iconKey, contentPadding: contentPadding, iconPadding: iconPadding, iconVisible: iconVisible
    );

  Widget _buildDetailWidget(Widget contentWidget, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true
  }) {
    List<Widget> contentList = <Widget>[];
    Widget? iconWidget = Styles().images.getImage(iconKey, excludeFromSemantics: true);
    if (iconWidget != null) {
      contentList.add(Padding(padding: iconPadding, child:
        Opacity(opacity: iconVisible ? 1 : 0, child:
          iconWidget,
        )
      ));
    }
    contentList.add(Expanded(child:
      contentWidget
    ),);
    return Padding(padding: contentPadding, child:
      Row(children: contentList)
    );
  }

  List<Widget> get _linkedEventsPagerWidget {
    Event2Grouping? linkedGroupingQuery = _event.linkedEventsGroupingQuery;
    return (linkedGroupingQuery != null) ? <Widget>[
      LinkedEvents2Pager(linkedGroupingQuery, contentBuilder: _linkedEventsPagerBuilder, userLocation: widget.userLocation)
    ] : <Widget>[];
  }

  Widget _linkedEventsPagerBuilder(LinkedEvents2PagerContentStatus state, {required Widget child}) =>
    ((state == LinkedEvents2PagerContentStatus.loading) || (state == LinkedEvents2PagerContentStatus.content)) ?
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(color: Styles().colors.surfaceAccent, height: 1,),
        Padding(padding: const EdgeInsets.symmetric(vertical: 16), child:
          child
        )
      ],) : Container();

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${_event.name}");
    Auth2().prefs?.toggleFavorite(_event);
  }

  void _onGroupEventOptions() {
    Analytics().logSelect(target: 'Group Event Options');

    List<Widget> options = <Widget>[];

    if (_canEditGroupEvent) {
      options.add(RibbonButton(
        label: Localization().getStringEx('widget.event2.card.detail.group.edit_event.label', 'Edit Event'),
        leftIconKey: 'edit',
        onTap: _onEditGroupEvent
      ));
    }

    if (_canDeleteGroupEvent) {
      options.add(RibbonButton(
        label: Localization().getStringEx('widget.event2.card.detail.group.delete_event.label', 'Remove group event'),
        leftIconKey: 'trash',
        onTap: _onDeleteGroupEvent
      ));
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      isDismissible: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
        Column(mainAxisSize: MainAxisSize.min, children: options)
      ),
    );
  }

  void _onEditGroupEvent() {
    Analytics().logSelect(target: 'Update Group Event (Option)');
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (context) => Event2CreatePanel(event: _event,)));
  }

  void _onDeleteGroupEvent() {
    Analytics().logSelect(target: 'Remove Group Event (Option)');
    showDialog(context: context, builder: (context) => _removeEventDialog).then((_) => Navigator.pop(context));
  }

  Widget get _removeEventDialog =>
    GroupsConfirmationDialog(
      message: Localization().getStringEx('widget.event2.card.detail.group.delete_event.message', 'Are you sure you want to remove this event from your group page?'),
      buttonTitle: Localization().getStringEx('widget.event2.card.detail.group.delete_event.delete.button', 'Remove'),
      onConfirmTap: _onTapRemoveGroupEvent
    );

  void _onTapRemoveGroupEvent() {
    Analytics().logSelect(target: 'Remove Group Event');
    Groups().deleteEventForGroupV3(eventId: _event.id, groupId: widget.group?.id).then((bool value) {
      if (value) {
        Navigator.of(context).pop();
      } else {
        AppAlert.showDialogResult(context, Localization().getStringEx('widget.event2.card.detail.group.delete_event.delete.failed.message', 'Failed to remove the event from group page.'));
      }
    });
  }
}

enum Event2CardDisplayMode { list, page, link, cardLink }

//
// LinkedEvents2Pager
//

enum LinkedEvents2PagerContentStatus { loading, error, empty, content }
typedef LinkedEvents2PagerContentBuilder = Widget Function(LinkedEvents2PagerContentStatus state, { required Widget child } );

class LinkedEvents2Pager extends StatefulWidget {
  final Event2Grouping linkedGroupingQuery;
  final LinkedEvents2PagerContentBuilder? contentBuilder;
  final Position? userLocation;
  LinkedEvents2Pager(this.linkedGroupingQuery, {super.key, this.contentBuilder, this.userLocation });

  @override
  State<StatefulWidget> createState() => _LinkedEvents2PagerState();
}


class _LinkedEvents2PagerState extends State<LinkedEvents2Pager> {

  static const int _eventsPageLength = 16;
  static const String _progressContentKey = '_progress_';

  List<Event2>? _events;
  bool? _lastPageLoadedAll;
  int? _totalEventsCount;
  String? _eventsErrorText;
  bool _loadingEvents = false;
  bool _extendingEvents = false;

  PageController? _pageController;
  Key _pageViewKey = UniqueKey();
  Map<String, GlobalKey> _contentKeys = <String, GlobalKey>{};
  final double _pageSpacing = 16;

  @override
  void initState() {
    _reload();
    super.initState();
  }

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingEvents) {
      return _buildContnet(LinkedEvents2PagerContentStatus.loading, contentWidget: _progressContent);
    }
    else if (_events == null) {
      return _buildContnet(LinkedEvents2PagerContentStatus.error, contentWidget: _buildMessageContent(
        title: Localization().getStringEx('panel.events2.home.message.failed.title', 'Failed'),
        message: _eventsErrorText ?? Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred')
      ));
    }
    else if (_events?.length == 0) {
      return _buildContnet(LinkedEvents2PagerContentStatus.empty, contentWidget: _buildMessageContent(
        message: Localization().getStringEx('widget.home.event2_feed.text.empty.description', 'There are no events available.')
      ));
    }
    else {
      return _buildContnet(LinkedEvents2PagerContentStatus.content, contentWidget: _eventsPager);
    }
  }

  Widget _buildContnet(LinkedEvents2PagerContentStatus state, { required Widget contentWidget }) =>
    (widget.contentBuilder != null) ? widget.contentBuilder!(state, child: contentWidget) : contentWidget;

  Widget get _eventsPager {

    int eventsCount = _events?.length ?? 0;
    if ((_hasMoreEvents != false) || (1 < eventsCount)) {

      List<Widget> pages = <Widget>[];
      for (int index = 0; index < eventsCount; index++) {
        Event2 event = _events![index];
        String contentKey = "${event.id}-$index";
        pages.add(Padding(
          key: _contentKeys[contentKey] ??= GlobalKey(),
          padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 4),
          child: Event2Card(event,
            displayMode: Event2CardDisplayMode.cardLink,
            linkType: widget.linkedGroupingQuery.type,
            userLocation: widget.userLocation,
            onTap: () => _onTapEvent2(event),
          )
        ));
      }

      if (_hasMoreEvents != false) {
        pages.add(Padding(
          key: _contentKeys[_progressContentKey] ??= GlobalKey(),
          padding: EdgeInsets.only(right: _pageSpacing + 2, bottom: 8),
          child: HomeProgressWidget(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 36),
          ),
        ));
      }

      if (_pageController == null) {
        double screenWidth = MediaQuery.of(context).size.width - 32;
        double pageViewport = (screenWidth - 2 * _pageSpacing) / screenWidth;
        _pageController = PageController(viewportFraction: pageViewport);
      }

      return Container(constraints: BoxConstraints(minHeight: _pageHeight), child:
        ExpandablePageView(
          key: _pageViewKey,
          controller: _pageController,
          estimatedPageSize: _pageHeight,
          allowImplicitScrolling: true,
          children: pages,
          onPageChanged: _onPageChanged,
        ),
      );
    }
    else {
      return Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
        Event2Card(_events!.first,
          displayMode: Event2CardDisplayMode.cardLink,
          linkType: widget.linkedGroupingQuery.type,
          userLocation: widget.userLocation,
          onTap: () => _onTapEvent2(_events!.first)
        )
      );
    }
  }

  Widget get _progressContent =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32), child:
      Center(child:
        Container(width: 24, height: 24, child:
          CircularProgressIndicator(strokeWidth: 3, color: Styles().colors.fillColorSecondary),
        )
      ),
    );

  Widget _buildMessageContent({String? title, String? message}) =>
    Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child:
      Column(children: <Widget>[
        StringUtils.isNotEmpty(title) ? Row(children: <Widget>[
          Expanded(child:
            Padding(padding: StringUtils.isNotEmpty(message) ? EdgeInsets.only(bottom: 8) : EdgeInsets.zero, child:
              Text(title ?? '', style: Styles().textStyles.getTextStyle("widget.card.title.medium.fat"), textAlign: TextAlign.center,)
            ),
          )
        ]) : Container(),
        StringUtils.isNotEmpty(message) ? Row(children: <Widget>[
          Expanded(child:
            Text(message ?? '', style: Styles().textStyles.getTextStyle("widget.card.detail.regular"), textAlign: TextAlign.center)
          )
        ]) : Container(),
      ]),
    );

  double get _pageHeight {
    double? minContentHeight;
    for (GlobalKey contentKey in _contentKeys.values) {
      final RenderObject? renderBox = contentKey.currentContext?.findRenderObject();
      if ((renderBox is RenderBox) && renderBox.hasSize && ((minContentHeight == null) || (renderBox.size.height < minContentHeight))) {
        minContentHeight = renderBox.size.height;
      }
    }
    return minContentHeight ?? 0;
  }

  bool? get _hasMoreEvents => (_totalEventsCount != null) ?
    ((_events?.length ?? 0) < _totalEventsCount!) : _lastPageLoadedAll;

  void _onPageChanged(int index) {
    if ((_events?.length ?? 0) < (index + 1) && (_hasMoreEvents != false) && !_extendingEvents && !_loadingEvents) {
      _extend();
    }
  }

  void _onTapEvent2(Event2 event) {
    Analytics().logSelect(target: "Event: '${event.name}'", source: widget.runtimeType.toString());
    if (event.hasGame) {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => AthleticsGameDetailPanel(game: event.game, event: event)));
    } else {
      Navigator.push(context, CupertinoPageRoute(builder: (context) => Event2DetailPanel(event: event)));
    }
  }

  Future<void> _reload({ int limit = _eventsPageLength }) async {
    if (!_loadingEvents) {
      setStateIfMounted(() {
        _loadingEvents = true;
        _extendingEvents = false;
      });
      dynamic result = await Events2().loadEventsEx(Events2Query(grouping: widget.linkedGroupingQuery, limit: limit));
      Events2ListResult? listResult = (result is Events2ListResult) ? result : null;
      List<Event2>? events = listResult?.events;
      String? errorTextResult = (result is String) ? result : null;

      setStateIfMounted(() {
        _events = (events != null) ? List<Event2>.from(events) : null;
        _totalEventsCount = listResult?.totalCount;
        _lastPageLoadedAll = (events != null) ? (events.length >= limit) : null;
        _eventsErrorText = errorTextResult;
        _loadingEvents = false;
        _pageViewKey = UniqueKey();
        _contentKeys.clear();
      });
    }
  }

  Future<void> _extend() async {
    if (!_loadingEvents && !_extendingEvents) {
      setStateIfMounted(() {
        _extendingEvents = true;
      });

      Events2ListResult? loadResult = await Events2().loadEvents(Events2Query(grouping: widget.linkedGroupingQuery, offset: _events?.length ?? 0, limit: _eventsPageLength));
      List<Event2>? events = loadResult?.events;
      int? totalCount = loadResult?.totalCount;

      if (mounted && _extendingEvents && !_loadingEvents) {
        setState(() {
          if (events != null) {
            if (_events != null) {
              _events?.addAll(events);
            }
            else {
              _events = List<Event2>.from(events);
            }
            _lastPageLoadedAll = (events.length >= _eventsPageLength);
          }
          if (totalCount != null) {
            _totalEventsCount = totalCount;
          }
          _extendingEvents = false;
        });
      }
    }
  }
}

//
// Event2Popup
//

class Event2Popup {
  
  static Future<void> showMessage(BuildContext context, { String? title, String? message}) =>
    showDialog(context: context, builder: (BuildContext context) => AlertDialog(
      surfaceTintColor: Styles().colors.surface,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        (title != null) ? Text(title, style: Styles().textStyles.getTextStyle("widget.card.title.regular.fat"),) : Container(),
        (message != null) ? Padding(padding: (title != null) ? EdgeInsets.only(top: 12) : EdgeInsets.zero, child:
          Text(message, style: Styles().textStyles.getTextStyle("widget.card.title.small"),),
        ) : Container()
      ],),
      actions: <Widget>[
        TextButton(
          child: Text(Localization().getStringEx("dialog.ok.title", "OK"), style:
            Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark")
          ),
          onPressed: () {
            Analytics().logAlert(text: message, selection: "OK");
            Navigator.pop(context);
          }
        )
      ],
    ));

  static Future<void> showErrorResult(BuildContext context, dynamic result) =>
    showMessage(context,
      title: Localization().getStringEx('panel.event2.create.message.failed.title', 'Failed'),
      message: StringUtils.isNotEmptyString(result) ? result : Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred'),
    );

  static Future<bool?> showPrompt(BuildContext context, {
    String? title, TextStyle? titleTextStyle,
    String? message, String? messageHtml, TextStyle? messageTextStyle,
    String? positiveButtonTitle, String? positiveAnalyticsTitle,
    String? negativeButtonTitle, String? negativeAnalyticsTitle,
  }) async {
    return showDialog<bool?>(context: context, builder: (BuildContext context) => AlertDialog(
      surfaceTintColor: Styles().colors.surface,
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        (title != null) ?
          Text(title, style: titleTextStyle ?? Styles().textStyles.getTextStyle("widget.card.title.regular.fat"),)
        : Container(),
        (message != null) ? Padding(padding: EdgeInsets.only(top: 12), child:
          Text(message, style: messageTextStyle ?? Styles().textStyles.getTextStyle("widget.message.regular.semi_fat"),),
        ) : Container(),
        (messageHtml != null) ? Padding(padding: EdgeInsets.only(top: 12), child:
          HtmlWidget(
            messageHtml,
            textStyle:  messageTextStyle ?? Styles().textStyles.getTextStyle("widget.message.regular.semi_fat"),
            customStylesBuilder: (element) => (element.localName == "a") ? {"color": ColorUtils.toHex(Styles().colors.fillColorSecondary)} : null
          )
        ) : Container(),
      ],),
      contentPadding: EdgeInsets.only(top: 8, left: 16, right: 16),
      actions: <Widget>[
        TextButton(
          child: Text(positiveButtonTitle ?? Localization().getStringEx("dialog.ok.title", "OK"), style:
            Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark")
          ),
          onPressed: () {
            Analytics().logAlert(text: message, selection: positiveAnalyticsTitle ?? positiveButtonTitle ?? "OK");
            Navigator.pop(context, true);
          }
        ),
        TextButton(
          child: Text(negativeButtonTitle ?? Localization().getStringEx("dialog.cancel.title", "Cancel"), style:
            Styles().textStyles.getTextStyle("widget.button.title.medium.fat.dark")
          ),
          onPressed: () {
            Analytics().logAlert(text: message, selection: negativeAnalyticsTitle ?? negativeButtonTitle ?? "Cancel");
            Navigator.pop(context, false);
          }
        )
      ],
      actionsPadding: EdgeInsets.zero,
    ));
  }
}