
import 'package:flutter/material.dart';
import 'package:illinois/ext/Explore.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Config.dart';
import 'package:intl/intl.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/model/content_attributes.dart';
import 'package:rokwire_plugin/model/event2.dart';
import 'package:rokwire_plugin/service/app_datetime.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:timezone/timezone.dart';

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

class _Event2CardState extends State<Event2Card>  implements NotificationsListener {

  @override
  void initState() {
    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoriteChanged,
    ]);
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
  Widget build(BuildContext context) {
    return Semantics(label: _semanticsLabel, hint: _semanticsHint, button: true, child:
      InkWell(onTap: widget.onTap, child:
        Container(decoration: _contentDecoration, child:
          ClipRRect(borderRadius: _contentBorderRadius, child: 
            Column(mainAxisSize: MainAxisSize.min, children: [
              _imageWidget,
              _categoriesWidget,
              Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
                Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _titleWidget,
                  _detailsWidget,
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

  Widget get _imageWidget => Visibility(visible: StringUtils.isNotEmpty(widget.event.imageUrl), child:
    Container(decoration: _imageDecoration, child:
      AspectRatio(aspectRatio: 2.5, child:
        Image.network(widget.event.imageUrl ?? '', fit: BoxFit.cover, headers: Config().networkAuthHeaders, excludeFromSemantics: true)
      ),
    )
  );

  Decoration get _imageDecoration => BoxDecoration(
    border: Border(bottom: BorderSide(color: Styles().colors!.surfaceAccent!, width: 1)),
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
    Events2().contentAttributes?.displayAttributeValuesListFromSelection(widget.event.attributes, usage: ContentAttributeUsage.category);

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
    TZDateTime? dateTimeUni = widget.event.startTimeUtc?.toUniOrLocal();
    return (dateTimeUni != null) ? <Widget>[_buildTextDetailWidget(DateFormat('MMM d, ha').format(dateTimeUni), 'calendar')] : null;
  }

  List<Widget>? get _onlineDetailWidget {
    return (widget.event.online == true) ? <Widget>[
      _buildTextDetailWidget('Online', 'laptop')
    ] : null;
  }

  List<Widget>? get _locationDetailWidget {
    if (widget.event.online != true) {

      bool canLocation = widget.event.location?.isLocationCoordinateValid ?? false;
      
      List<Widget> details = <Widget>[
        InkWell(onTap: canLocation ? _onLocation : null, child:
          _buildTextDetailWidget('In Person', 'location'),
        ),
      ];

      String? locationText = (
        widget.event.location?.displayName ??
        widget.event.location?.displayAddress ??
        widget.event.location?.displayCoordinates
      );
      if (locationText != null) {
        Widget locationWidget = canLocation ?
          Text(locationText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.button.title.small.semi_bold.underline'),) :
          Text(locationText, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),);
        details.add(
          InkWell(onTap: canLocation ? _onLocation : null, child:
            _buildDetailWidget(locationWidget, 'location', iconVisible: false, contentPadding: EdgeInsets.zero)
          )
        );
      }
      return details;
    }
    return null;
  }

  Widget _buildTextDetailWidget(String text, String iconKey, {
    EdgeInsetsGeometry contentPadding = const EdgeInsets.only(top: 4),
    EdgeInsetsGeometry iconPadding = const EdgeInsets.only(right: 6),
    bool iconVisible = true
  }) =>
    _buildDetailWidget(
      Text(text, maxLines: 1, style: Styles().textStyles?.getTextStyle('widget.explore.card.detail.regular'),),
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

  void _onLocation() {
    Analytics().logSelect(target: "Location Directions: ${widget.event.name}");
    widget.event.launchDirections();
  }

  void _onFavorite() {
    Analytics().logSelect(target: "Favorite: ${widget.event.name}");
    Auth2().prefs?.toggleFavorite(widget.event);
  }
}
