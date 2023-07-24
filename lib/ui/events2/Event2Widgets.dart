
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
  final Position? userLocation;
  final void Function()? onTap;
  
  Event2Card(this.event, { Key? key, this.displayMode = Event2CardDisplayMode.list, this.userLocation, this.onTap}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _Event2CardState();
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
    }
  }

  Widget get _listContentWidget =>
    Container(decoration: _listContentDecoration, child:
      ClipRRect(borderRadius: _listContentBorderRadius, child: 
        Column(mainAxisSize: MainAxisSize.min, children: [
          _imageHeadingWidget,
          _categoriesWidget,
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
            _categoriesWidget,
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

  String get _semanticsLabel => '';//'''TODO custom label if needed';
  String get _semanticsHint => '';//'''TODO custom hint if needed';

  Decoration get _listContentDecoration => BoxDecoration(
    color: Styles().colors?.surface,
    borderRadius: _listContentBorderRadius,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]
  );

  BorderRadiusGeometry get _listContentBorderRadius => BorderRadius.all(Radius.circular(8));

  Decoration get _pageContentDecoration => BoxDecoration(
    color: Styles().colors?.surface,
    borderRadius: _pageContentBorderRadius,
    border: Border.all(color: Styles().colors!.surfaceAccent!, width: 1),
    boxShadow: [BoxShadow(color: Color.fromRGBO(19, 41, 75, 0.3), spreadRadius: 2.0, blurRadius: 8.0, offset: Offset(0, 2))]
  );

  BorderRadiusGeometry get _pageContentBorderRadius => BorderRadius.vertical(bottom: Radius.circular(4));

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
  

  Widget get _categoriesWidget => 
    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Expanded(child:
        Padding(padding: EdgeInsets.only(left: 16, top: 16, bottom: 8), child:
          Text(_displayCategories?.join(', ') ?? '', overflow: TextOverflow.ellipsis, maxLines: 2, style: Styles().textStyles?.getTextStyle("widget.card.title.small.fat"))
        ),
      ),
      _favoriteButton
    ]);

  List<String>? get _displayCategories =>
    Events2().contentAttributes?.displaySelectedLabelsFromSelection(widget.event.attributes, usage: ContentAttributeUsage.category);

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

  Widget get _titleWidget => Row(children: [
    Expanded(child: 
      Text(widget.event.name ?? '', style: Styles().textStyles?.getTextStyle('widget.title.large.extra_fat'), maxLines: 2,)
    ),
  ],);

  Widget get _detailsWidget {
    List<Widget> detailWidgets = <Widget>[
      ...?_dateDetailWidget,
      ...?_onlineDetailWidget,
      ...?_locationDetailWidget,
    ];

    return detailWidgets.isNotEmpty ? Padding(padding: EdgeInsets.only(top: 4), child:
      Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: detailWidgets,)
    ) : Container();
    
  }

  List<Widget>? get _dateDetailWidget {
    String? dateTime = widget.event.shortDisplayDate;
    return (dateTime != null) ? <Widget>[_buildTextDetailWidget(dateTime, 'calendar')] : null;
  }

  List<Widget>? get _onlineDetailWidget {
    return widget.event.online ? <Widget>[
      _buildTextDetailWidget('Online', 'laptop')
    ] : null;
  }

  List<Widget>? get _locationDetailWidget {
    if (widget.event.inPerson) {

      List<Widget> details = <Widget>[
        _buildTextDetailWidget('In Person', 'location'),
      ];

      String? locationText = (
        widget.event.location?.displayName ??
        widget.event.location?.displayAddress ??
        widget.event.location?.displayCoordinates
      );
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

enum Event2CardDisplayMode { list, page }

class Event2Popup {
  
  static Future<void> showMessage(BuildContext context, String title, String? message) =>
    showDialog(context: context, builder: (BuildContext context) => AlertDialog(
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(title, style: Styles().textStyles?.getTextStyle("widget.card.title.regular.fat"),),
        (message != null) ? Padding(padding: EdgeInsets.only(top: 12), child:
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
      Localization().getStringEx('panel.event2.create.message.failed.title', 'Failed'),
      StringUtils.isNotEmptyString(result) ? result : Localization().getStringEx('logic.general.unknown_error', 'Unknown Error Occurred'),
    );

}