
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:illinois/ext/Event2.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

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
        Text(title ?? '', style: Styles().textStyles?.getTextStyle(titleTextStyleKey), semanticsLabel: "",)
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
            Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: contentList,)
          ),
        ),
      ),
    );
  }

  static BoxDecoration get defaultContentDecoration => BoxDecoration(
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
  final Event2CardDisplayMode displayMode;
  final Event2GroupingType? linkType;
  final Position? userLocation;
  final void Function()? onTap;
  
  final List<String>? displayCategories;
  
  Event2Card(this.event, { Key? key, this.displayMode = Event2CardDisplayMode.list, this.linkType, this.userLocation, this.onTap}) :
    displayCategories = Events2().contentAttributes?.displaySelectedLabelsFromSelection(event.attributes, usage: ContentAttributeUsage.category),
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
  Position? _userLocation; 

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged,
    ]);
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
      if ((param is Favorite) && (param.favoriteKey == widget.event.favoriteKey) && (param.favoriteId == widget.event.favoriteId) && mounted) {
        setState(() {});
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
        ],),
      ),
    );

  Widget get _pageContentWidget =>
    Stack(children: [
      Container(decoration: _pageContentDecoration, child:
        Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(padding: EdgeInsets.only(top: _pageHeadingHeight), child:
            _contentHeadingWidget,
          ),
          Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Visibility(visible: true, child:
                Expanded(flex: 3, child:
                  Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _titleWidget,
                    _detailsWidget,
                  ]),
                ),
              ),
              Visibility(visible: _hasImage, child:
                Expanded(flex: 1, child:
                  _imageDetailWidget,
                )
              ),
            ]),
          ),
        ],),
      ),
      _pageHeadingWidget,
    ],);

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
          _favoriteButton
        ],)
      ),
    );

  Widget get _linkTitleWidget {
    String? title;
    if (widget.linkType == Event2GroupingType.superEvent) {
      title = widget.event.name;
    }
    else if (widget.linkType == Event2GroupingType.recurrence) {
      title = widget.event.shortDisplayDate;
    }
    return Text(title ?? '', style: Styles().textStyles?.getTextStyle("widget.title.regular.fat"), maxLines: 2, overflow: TextOverflow.ellipsis,);
  }

  Widget get _linkDetailWidget {
    String? detail;
    if (widget.linkType == Event2GroupingType.superEvent) {
      detail = widget.event.shortDisplayDateAndTime;
    }
    else if (widget.linkType == Event2GroupingType.recurrence) {
      detail = widget.event.shortDisplayTime;
    }
    return Text(detail ?? '', style: Styles().textStyles?.getTextStyle("widget.item.small"), maxLines: 1, overflow: TextOverflow.ellipsis,);
  }

  String get _semanticsLabel => '';//'''TODO custom label if needed';
  String get _semanticsHint => '';//'''TODO custom hint if needed';

  static Decoration get _listContentDecoration => BoxDecoration(
    color: Styles().colors?.surface,
    borderRadius: _listContentBorderRadius,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 1.0, offset: Offset(0, 2))]
  );

  static BorderRadiusGeometry get _listContentBorderRadius => BorderRadius.all(Radius.circular(8));

  static Decoration get _pageContentDecoration => BoxDecoration(
    color: Styles().colors?.surface,
    borderRadius: _pageContentBorderRadius,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]
  );

  static BorderRadiusGeometry get _pageContentBorderRadius => BorderRadius.vertical(bottom: Radius.circular(4));

  static Decoration get _linkContentDecoration => BoxDecoration(
    color: Styles().colors?.white,
    borderRadius: _linkContentBorderRadius,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 1.0, blurRadius: 2.0, offset: Offset(0, 1))]
  );

  static BorderRadiusGeometry get _linkContentBorderRadius => BorderRadius.circular(4.0);

  bool get _hasImage => StringUtils.isNotEmpty(widget.event.imageUrl);

  Widget get _imageHeadingWidget => Visibility(visible: _hasImage, child:
    Container(decoration: _imageHeadingDecoration, child:
      AspectRatio(aspectRatio: 2.5, child:
        Image.network(widget.event.imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
      ),
    )
  );

  Decoration get _imageHeadingDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1)),
  );

  Widget get _pageHeadingWidget => Container(height: _pageHeadingHeight, color: widget.event.uiColor);

  double get _pageHeadingHeight => 7;

  Widget get _imageDetailWidget =>
    AspectRatio(aspectRatio: 1.3, child:
      Image.network(widget.event.imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
    );
  

  Widget get _contentHeadingWidget => 
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 8), child:
          widget.hasDisplayCategories ? _categoriesContentWidget : _titleContentWidget
        ),
      ),
      _favoriteButton
    ]);

  Widget get _categoriesContentWidget =>
    Text(widget.displayCategories?.join(', ') ?? '', overflow: TextOverflow.ellipsis, maxLines: 2, style: Styles().textStyles?.getTextStyle("widget.card.title.small.fat"));

  /*Widget get _groupingBadgeWidget {
    String? badgeLabel;
    if (widget.event.isSuperEvent) {
      badgeLabel = Localization().getStringEx('widget.event2.card.super_event.abbreviation.label', 'COMP'); // composite
    }
    else if (widget.event.isRecurring) {
      badgeLabel = Localization().getStringEx('widget.event2.card.recurring.abbreviation.label', 'REC');
    }
    return (badgeLabel != null) ? 
      Container(padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2), decoration: BoxDecoration(color: Styles().colors!.fillColorSecondary, borderRadius: BorderRadius.all(Radius.circular(2)),), child:
        Semantics(label: badgeLabel, excludeSemantics: true, child:
          Text(badgeLabel, style:  Styles().textStyles?.getTextStyle('widget.heading.small'),)
    )) : Container();
  }*/

  Widget get _favoriteButton {
    bool isFavorite = Auth2().isFavorite(widget.event);
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
            child: Padding(padding: EdgeInsets.all(16),
              child: Styles().images?.getImage(isFavorite ? 'star-filled' : 'star-outline-gray', excludeFromSemantics: true,)
            )
          ),
        ),
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
    Text(widget.event.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'), maxLines: 2, overflow: TextOverflow.ellipsis);

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
    String? dateTime = widget.event.shortDisplayDateAndTime;
    return (dateTime != null) ? <Widget>[_buildTextDetailWidget(dateTime, 'calendar')] : null;
  }

  List<Widget>? get _onlineDetailWidget {
    return widget.event.isOnline ? <Widget>[
      _buildTextDetailWidget(Localization().getStringEx('widget.event2.card.detail.online.label', 'Online'), 'laptop')
    ] : null;
  }

  List<Widget>? get _locationDetailWidget {
    if (widget.event.isInPerson) {

      List<Widget> details = <Widget>[
        _buildTextDetailWidget(Localization().getStringEx('widget.event2.card.detail.in_person.label', 'In Person'), 'location'),
      ];

      String? locationText = widget.event.location?.displayName ?? widget.event.location?.displayAddress ?? widget.event.location?.displayDescription; // ?? widget.event.location?.displayCoordinates
      if (locationText != null) {
        details.add(
          _buildDetailWidget(Text(locationText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),), 'location', iconVisible: false, contentPadding: EdgeInsets.zero)
        );
      }

      String? distanceText = widget.event.getDisplayDistance(_userLocation);
      if (distanceText != null) {
        details.add(
          _buildDetailWidget(Text(distanceText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),), 'location', iconVisible: false, contentPadding: EdgeInsets.zero)
        );
      }

      return details;
    }
    return null;
  }

  List<Widget>? get _groupingDetailWidget {
    if (widget.event.hasLinkedEvents) {
      List<Widget> details = <Widget>[];
      if (widget.event.isSuperEvent) {
        details.add(_buildTextDetailWidget(
          Localization().getStringEx('widget.event2.card.detail.super_event.label', 'Multi-Event'),
          'event',
        ));
      }
      if (widget.event.isRecurring) {
        details.add(_buildTextDetailWidget(
          Localization().getStringEx('widget.event2.card.detail.recurring.label', 'Repeats'),
          'recurrence',
        ));
      }
      return details.isNotEmpty ? details : null;
    }
    return null;
  }
  

  Widget _buildTextDetailWidget(String text, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true, int maxLines = 1,
  }) =>
    _buildDetailWidget(
      Text(text, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'), maxLines: maxLines, overflow: TextOverflow.ellipsis,),
      iconKey,
      contentPadding: contentPadding,
      iconPadding: iconPadding,
      iconVisible: iconVisible
    );

  Widget _buildDetailWidget(Widget contentWidget, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true
  }) {
    List<Widget> contentList = <Widget>[];
    Widget? iconWidget = Styles().images?.getImage(iconKey, excludeFromSemantics: true);
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

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.event.name}");
    Auth2().prefs?.toggleFavorite(widget.event);
  }
}

enum Event2CardDisplayMode { list, page, link }

class Event2Popup {
  
  static Future<void> showMessage(BuildContext context, { String? title, String? message}) =>
    showDialog(context: context, builder: (BuildContext context) => AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        (title != null) ? Text(title, style: Styles().textStyles?.getTextStyle("widget.card.title.regular.fat"),) : Container(),
        (message != null) ? Padding(padding: (title != null) ? EdgeInsets.only(top: 12) : EdgeInsets.zero, child:
          Text(message, style: Styles().textStyles?.getTextStyle("widget.card.title.small"),),
        ) : Container()
      ],),
      actions: <Widget>[
        TextButton(
          child: Text(Localization().getStringEx("dialog.ok.title", "OK"), style:
            Styles().textStyles?.getTextStyle("widget.button.title.medium.fat")
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

  static Future<bool?> showPrompt(BuildContext context, String title, String? message, {
    String? positiveButtonTitle, String? positiveAnalyticsTitle,
    String? negativeButtonTitle, String? negativeAnalyticsTitle,
  }) async {
    return showDialog<bool?>(context: context, builder: (BuildContext context) => AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: Styles().textStyles?.getTextStyle("widget.card.title.regular.fat"),),
        (message != null) ? Padding(padding: EdgeInsets.only(top: 12), child:
          Text(message, style: Styles().textStyles?.getTextStyle("widget.card.title.small"),),
        ) : Container()
      ],),
      actions: <Widget>[
        TextButton(
          child: Text(positiveButtonTitle ?? Localization().getStringEx("dialog.ok.title", "OK"), style:
            Styles().textStyles?.getTextStyle("widget.button.title.medium.fat")
          ),
          onPressed: () {
            Analytics().logAlert(text: message, selection: positiveAnalyticsTitle ?? positiveButtonTitle ?? "OK");
            Navigator.pop(context, true);
          }
        ),
        TextButton(
          child: Text(negativeButtonTitle ?? Localization().getStringEx("dialog.cancel.title", "Cancel"), style:
            Styles().textStyles?.getTextStyle("widget.button.title.medium.fat")
          ),
          onPressed: () {
            Analytics().logAlert(text: message, selection: negativeAnalyticsTitle ?? negativeButtonTitle ?? "Cancel");
            Navigator.pop(context, false);
          }
        )
      ],
    ));
  }
}