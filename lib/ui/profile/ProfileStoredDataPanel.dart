
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Appointments.dart';
import 'package:illinois/service/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/Canvas.dart';
import 'package:illinois/service/Gateway.dart';
import 'package:illinois/service/Identity.dart';
import 'package:illinois/service/Occupations.dart';
import 'package:illinois/service/Rewards.dart';
import 'package:illinois/service/Transportation.dart';
import 'package:illinois/service/Wellness.dart';
import 'package:illinois/ui/widgets/LinkButton.dart';
import 'package:rokwire_plugin/service/events2.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/inbox.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/polls.dart';
import 'package:rokwire_plugin/service/social.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/service/surveys.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class ProfileStoredDataPanel extends StatefulWidget {
  static const String _notifyRefresh  = "edu.illinois.rokwire.home.refresh";

  ProfileStoredDataPanel._();

  static void present(BuildContext context) {
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors.white,
      constraints: BoxConstraints(maxHeight: height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => ProfileStoredDataPanel._(),
    );
  }

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataPanelState();
}


typedef _UserDataProvider = Future<Map<String, dynamic>?> Function();

enum _StoredDataSource {
  core,
  identity,
  rewards,
  notifications,
  social,

  calendar,
  groups,
  polls,
  surveys,

  lms,
  appointments,
  occupations,

  transportation,
  wellness,
  assistant,
  gateway,

  // icard.uillinois.edu
  // housing.illinois.edu
  // storage
}

class _ProfileStoredDataPanelState extends State<ProfileStoredDataPanel> {

  final StreamController<String> _updateController = StreamController.broadcast();
  final Map<_StoredDataSource, GlobalKey<_ProfileStoredDataWidgetState>> _storedDataKeys = <_StoredDataSource, GlobalKey<_ProfileStoredDataWidgetState>>{};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
    Column(children: [
      _headerBar,
      _contentSplitter,
      Expanded(child:
        _scaffoldContent
      ),
    ],);

  Widget get _scaffoldContent => SafeArea(child:
    RefreshIndicator(onRefresh: _onRefresh, child:
      Scrollbar(child:
        SingleChildScrollView(physics: AlwaysScrollableScrollPhysics(), child:
          _panelContent,
        ),
      ),
    ),
  );

  Widget get _panelContent {

    List<Widget> contentList = <Widget>[_splitterLine];
    for (_StoredDataSource dataSource in _StoredDataSource.values) {
      contentList.add(_dataSourceContent(dataSource));
      contentList.add(_splitterLine);
    }

    return Padding(padding: EdgeInsets.symmetric(vertical: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: contentList),
    );
  }

  Widget _dataSourceContent(_StoredDataSource dataSource) {
    switch (dataSource) {
      case _StoredDataSource.core: return _coreContent;
      case _StoredDataSource.identity: return _identityContent;
      case _StoredDataSource.rewards: return _rewardsContent;
      case _StoredDataSource.notifications: return _notificationsContent;
      case _StoredDataSource.social: return _socialContent;

      case _StoredDataSource.calendar: return _calendarContent;
      case _StoredDataSource.groups: return _groupsContent;
      case _StoredDataSource.polls: return _pollsContent;
      case _StoredDataSource.surveys: return _surveysContent;

      case _StoredDataSource.lms: return _lmsContent;
      case _StoredDataSource.appointments: return _appointmentsContent;
      case _StoredDataSource.occupations: return _occupationsContent;

      case _StoredDataSource.transportation: return _transportationContent;
      case _StoredDataSource.wellness: return _wellnessContent;
      case _StoredDataSource.assistant: return _assistantContent;
      case _StoredDataSource.gateway: return _gatewayContent;
    }
  }


  Widget get _coreContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.core] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.core,
      dataProvider: () => Auth2().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.source.core.title', "Core"),
      updateController: _updateController,
    );

  Widget get _identityContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.identity] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.identity,
      dataProvider: () => Identity().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.source.identity.title', "Identity"),
      updateController: _updateController,
    );

  Widget get _rewardsContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.rewards] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.rewards,
      dataProvider: () => Rewards().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.source.rewards.title', "Rewards"),
      updateController: _updateController,
    );

  Widget get _notificationsContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.notifications] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.notifications,
      dataProvider: () => Inbox().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.notifications.title', "Notifications"),
      updateController: _updateController,
    );

  Widget get _socialContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.social] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.social,
      dataProvider: () => Social().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.social.title', "Social"),
      updateController: _updateController,
    );

  Widget get _calendarContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.calendar] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.calendar,
      dataProvider: () => Events2().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.calendar.title', "Calendar"),
      updateController: _updateController,
    );

  Widget get _groupsContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.groups] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.groups,
      dataProvider: () => Groups().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.groups.title', "Groups"),
      updateController: _updateController,
    );

  Widget get _pollsContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.polls] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.polls,
      dataProvider: () => Polls().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.polls.title', "Polls"),
      updateController: _updateController,
    );

  Widget get _surveysContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.surveys] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataProvider: () => Surveys().loadUserDataJson(),
      dataSource: _StoredDataSource.surveys,
      title: Localization().getStringEx('panel.profile.stored_data.surveys.title', "Surveys"),
      updateController: _updateController,
    );

  Widget get _lmsContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.lms] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataProvider: () => Canvas().loadUserDataJson(),
      dataSource: _StoredDataSource.lms,
      title: Localization().getStringEx('panel.profile.stored_data.lms.title', "Courses"),
      updateController: _updateController,
    );

  Widget get _appointmentsContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.appointments] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.appointments,
      dataProvider: () => Appointments().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.appointments.title', "Appointments"),
      updateController: _updateController,
    );

  Widget get _occupationsContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.occupations] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.occupations,
      dataProvider: () => Occupations().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.occupations.title', "Occupations"),
      updateController: _updateController,
    );

  Widget get _transportationContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.transportation] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.transportation,
      dataProvider: () => Transportation().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.transportation.title', "Transportation"),
      updateController: _updateController,
    );

  Widget get _wellnessContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.wellness] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.wellness,
      dataProvider: () => Wellness().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.wellness.title', "Wellness"),
      updateController: _updateController,
    );

  Widget get _assistantContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.assistant] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.assistant,
      dataProvider: () => Assistant().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.assistant.title', "Assistant"),
      updateController: _updateController,
    );

  Widget get _gatewayContent =>
    _ProfileStoredDataWidget(
      key: _storedDataKeys[_StoredDataSource.gateway] ??= GlobalKey<_ProfileStoredDataWidgetState>(),
      dataSource: _StoredDataSource.gateway,
      dataProvider: () => Gateway().loadUserDataJson(),
      title: Localization().getStringEx('panel.profile.stored_data.gateway.title', "External Services"),
      updateController: _updateController,
    );

  // Splitter

  Widget get _splitterLine =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Container(height: 1, color: Styles().colors.surfaceAccent,)
    );


  // Header Bar

  Widget get _headerBar => Row(children: [
    Expanded(child:
      Padding(padding: EdgeInsets.only(left: 16), child:
        Text(Localization().getStringEx("panel.profile.stored_data.header.title", "My Stored Information"),
          style: Styles().textStyles.getTextStyle('widget.title.medium.fat'), // widget.label.regular.fat
        ),
      )
    ),
    _copyAllButton,
    _closeButton,
  ],);

  Widget get _copyAllButton => LinkButton(
    title: Localization().getStringEx("panel.profile.stored_data.button.copy_all.title", "Copy All"),
    textStyle: Styles().textStyles.getTextStyle('widget.button.title.medium.fat.underline'),
    padding: EdgeInsets.only(top: 16, bottom: 16, left: 8, right: 0),
    onTap: _onCopyAll,
  );

  Widget get _closeButton =>
    Semantics( label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
      InkWell(onTap : _onTapClose, child:
        Container(padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 16), child:
          Styles().images.getImage('close-circle', excludeFromSemantics: true),
        ),
      ),
    );

  Widget get _contentSplitter => Container(color: Styles().colors.surfaceAccent, height: 1);

  // Implementation

  Future<void> _onRefresh() async {
    _updateController.add(ProfileStoredDataPanel._notifyRefresh);
  }

  void _onCopyAll() {
    Analytics().logSelect(target: 'Copy All');

    String combinedJson = "";
    for (_StoredDataSource dataType in _StoredDataSource.values) {
      _ProfileStoredDataWidgetState? dataTypeState = _storedDataKeys[dataType]?.currentState;
      if (dataTypeState != null) {
        combinedJson += dataTypeState._clipboardText;
      }
    }
    Clipboard.setData(ClipboardData(text: combinedJson)).then((_) {
      AppToast.showMessage(Localization().getStringEx('panel.profile.stored_data.copied_all.succeeded.message', 'Copied everything to your clipboard!'));
    });
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close', source: runtimeType.toString());
    Navigator.of(context).pop();
  }

}


class _ProfileStoredDataWidget extends StatefulWidget {
  final _StoredDataSource dataSource;
  final _UserDataProvider dataProvider;
  final String? title;
  final StreamController<String>? updateController;

  // ignore: unused_element
  _ProfileStoredDataWidget({ super.key,
    required this.dataSource,
    required this.dataProvider,
    this.title,
    this.updateController,
  });

  String get titleKey => this.dataSource.name;

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataWidgetState();
}

class _ProfileStoredDataWidgetState extends State<_ProfileStoredDataWidget> {
  bool _loading = false;
  bool _expanded = false;
  Map<String, String>? _userData;

  @override
  void initState() {

    widget.updateController?.stream.listen((String command) {
      if (command == ProfileStoredDataPanel._notifyRefresh) {
        _refreshUserData();
      }
    });

    _initUserData();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _loadingContent;
    }
    else if (_userData == null) {
      return _errorContent;
    }
    else if (_Utils._isValueNotEmpty(_userData)) {
      return _dataContent;
    }
    else {
      return _emptyContent;
    }
  }

  Widget get _loadingContent => _ProfileStoredDataHeadingWidget(
    title: _displayTitle, hint: '...', progress: true,
  );
  Widget get _errorContent => _ProfileStoredDataHeadingWidget(
    title: _displayTitle, hint: Localization().getStringEx('widget.profile.stored_data.retrieve.failed.message', 'Failed to retrieve data'),
  );

  Widget get _emptyContent => _ProfileStoredDataHeadingWidget(
    title: _displayTitle, hint: Localization().getStringEx('widget.profile.stored_data.retrieve.empty.message', 'No stored information'),
  );

  Widget get _dataHeadingContent => _ProfileStoredDataHeadingWidget(
    title: _displayTitle, expanded: _expanded, onExpand: _onExpand, onCopy: _onCopy,
  );

  Widget get _dataContent =>
    Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      _dataHeadingContent,
      if (_expanded)
        ...dataListContent,
    ],);

  List<Widget> get dataListContent {
    List<Widget> entries = <Widget>[];
    if (_userData != null) {
      for (String entryKey in _userData!.keys) {

        entries.add(Padding(padding: EdgeInsets.only(bottom: 6), child:
          _ProfileStoredDataEntryWidget(
            titleKey: widget.titleKey,
            titleText: widget.title,
            hintKey: entryKey,
            contentText: _userData?[entryKey],
          ),
        ));
      }
    }
    return entries;
  }


  Future<void> _initUserData() async {
    setState(() {
      _loading = true;
    });
    Map<String, dynamic>? userData = await widget.dataProvider();
    if (mounted) {
      setState(() {
        _userData = _toUserData(userData);
        _loading = false;
      });
    }
  }

  Future<void> _refreshUserData() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _userData = null;
      });
      Map<String, dynamic>? userData = await widget.dataProvider();
      if (mounted) {
        setState(() {
          _userData = _toUserData(userData);
          _loading = false;
        });
      }
    }
  }

  Map<String, String>? _toUserData(Map<String, dynamic>? sourceUserData) =>
    sourceUserData?.map((key, value) => MapEntry(key, JsonUtils.encode(value, prettify: true) ?? ''));

  Map<String, dynamic>? _fromUserData(Map<String, String>? userData) =>
    userData?.map((key, value) => MapEntry(key, JsonUtils.decode(value)));

  String get _clipboardText => (_Utils._isValueNotEmpty(_userData)) ?
      "$_displayTitle\n$_displayContent\n\n" : "";

  String get _displayTitle =>
    widget.title ?? Localization().getString('panel.profile.stored_data.source.${widget.titleKey}.title') ?? StringUtils.capitalize(widget.titleKey, allWords: true, splitDelimiter: '_', joinDelimiter: ' ');

  String get _displayContent =>
    JsonUtils.encode(_fromUserData(_userData)) ?? 'NA';

  void _onExpand() {
    Analytics().logSelect(target: _expanded ? 'Colapse' : 'Expand', source: _displayTitle);
    setState(() {
      _expanded = !_expanded;
    });
  }

  void _onCopy() {
    Analytics().logSelect(target: 'Copy', source: _displayTitle);
    Clipboard.setData(ClipboardData(text: _clipboardText)).then((_) {
      final String _sourceMacro = '{{source}}';
      AppToast.showMessage(Localization().getStringEx('panel.profile.stored_data.copied_source.succeeded.message', 'Copied $_sourceMacro information to your clipboard!').replaceAll(_sourceMacro, _displayTitle));
    });
  }
}

class _ProfileStoredDataEntryWidget extends StatefulWidget {
  final String? titleKey;
  final String? titleText;

  final String? hintKey;
  final String? hintText;

  final String? contentText;

  // ignore: unused_element
  _ProfileStoredDataEntryWidget({ super.key,
    this.titleKey, this.titleText,
    // ignore: unused_element
    this.hintKey, this.hintText,
    this.contentText,
  });

  @override
  State<StatefulWidget> createState() => _ProfileStoredDataEntryWidgetState();
}

class _ProfileStoredDataEntryWidgetState extends State<_ProfileStoredDataEntryWidget> {
  late TextEditingController _contentTextController;
  late bool _contentTextNotEmpty;

  @override
  void initState() {
    _contentTextController = TextEditingController(text: widget.contentText ?? '');
    _contentTextNotEmpty = _Utils._isValueNotEmpty(widget.contentText);
    super.initState();
  }

  @override
  void dispose() {
    _contentTextController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(_ProfileStoredDataEntryWidget oldWidget) {
    _contentTextController.text = widget.contentText ?? '';
    _contentTextNotEmpty = _Utils._isValueNotEmpty(widget.contentText);
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) =>
    Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
      Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        _headingWidget,
        if (_contentTextNotEmpty)
          Stack(children: [
            _textContentWidget,
            Positioned.fill(child:
              Align(alignment: Alignment.topRight, child:
                _copyButton,
              ),
            ),
          ]),
      ])
    );

  Widget get _headingWidget {
    List<InlineSpan> headingSpans = <InlineSpan>[];

    String hintText = _displayHint;
    if (StringUtils.isNotEmpty(hintText)) {
      headingSpans.add(TextSpan(text: '• '));
      headingSpans.add(TextSpan(text: hintText));
    }

    if (_contentTextNotEmpty == false) {
      if (StringUtils.isNotEmpty(hintText)) {
        headingSpans.add(TextSpan(text: ' / '));
      }
      headingSpans.add(TextSpan(text: Localization().getStringEx('widget.profile.stored_data.retrieve.empty.message', 'No stored information'), style:
        Styles().textStyles.getTextStyle('widget.title.small.semi_fat.light')
      ));
    }
    return RichText(text:
      TextSpan(style: Styles().textStyles.getTextStyle('widget.title.small.semi_fat'), children:
        headingSpans
      ),
    );
  }

  String get _displayTitle =>
    widget.titleText ?? Localization().getString('panel.profile.stored_data.source.${widget.titleKey}.title') ?? StringUtils.capitalize(widget.titleKey ?? '', allWords: true, splitDelimiter: '_', joinDelimiter: ' ');

  String get _displayHint =>
    widget.hintText ?? Localization().getString('panel.profile.stored_data.source.${widget.titleKey}.${widget.hintKey}.title') ?? StringUtils.capitalize(widget.hintKey ?? '', allWords: true, splitDelimiter: '_', joinDelimiter: ' ');

  Widget get _textContentWidget => TextField(
    maxLines: 5,
    readOnly: true,
    controller: _contentTextController,
    decoration: _contentTextDecoration,
    style: Styles().textStyles.getTextStyle('widget.item.small.thin.italic'), // Styles().textStyles.getTextStyle('widget.input_field.text.regular')
  );

  InputDecoration get _contentTextDecoration => InputDecoration(
    border: _contentTextBorder,
    enabledBorder: _contentTextBorder,
    disabledBorder: _contentTextBorder,
    focusedBorder: _contentTextBorder,
    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)
  );

  InputBorder get _contentTextBorder =>
    OutlineInputBorder(borderSide: BorderSide(color: Styles().colors.mediumGray2, width: 1.0));

  Widget get _copyButton =>
    InkWell(onTap: _onCopy, child:
      Padding(padding: EdgeInsets.all(12), child:
        Styles().images.getImage('copy', excludeFromSemantics: true),
      ),
    );

  void _onCopy() {
    Analytics().logSelect(target: 'Copy', source: "$_displayTitle / $_displayHint");
    if (widget.contentText?.isNotEmpty == true) {
      Clipboard.setData(ClipboardData(text:  widget.contentText ?? '')).then((_) {
        AppToast.showMessage(Localization().getStringEx('widget.profile.stored_data.copied.succeeded.message', 'Copied to your clipboard.'));
      });
    }
  }
}

class _ProfileStoredDataHeadingWidget extends StatelessWidget {
  final String? title;
  final String? hint;
  final bool? progress;
  final bool? expanded;
  final Function()? onExpand;
  final Function()? onCopy;
  final Offset iconPadding = Offset(16, 12);
  final Size iconSize = Size(16, 16);

  // ignore: unused_element
  _ProfileStoredDataHeadingWidget({super.key,
    this.title, this.hint,
    this.progress, this.expanded, this.onExpand, this.onCopy,
  });

  @override
  Widget build(BuildContext context) =>
    InkWell(onTap: ((expanded != null) && (onExpand != null)) ? onTapExpand : null, child:
      Row(children: [
        Expanded(child:
          Padding(padding: EdgeInsets.only(left: iconPadding.dx), child:
          _textContent
          )
        ),
        if (_copyAndExpand)
          _copyIcon,
        _iconContent,
      ],),
    );

  Widget get _textContent => RichText(text:
    TextSpan(style: Styles().textStyles.getTextStyle('widget.title.regular.fat'), children: <InlineSpan>[
      if (StringUtils.isNotEmpty(title))
        TextSpan(text: StringUtils.isNotEmpty(hint) ? "${title} / "  : title, style: Styles().textStyles.getTextStyle('widget.title.regular.fat')),
      if (StringUtils.isNotEmpty(hint))
        TextSpan(text: hint, style: Styles().textStyles.getTextStyle('widget.title.regular.medium_fat.light')),
    ]),
  );

  Widget get _iconContent {
    if (progress == true) {
      return _progressIcon;
    }
    else if (expanded != null) {
      return _expandIcon;
    }
    else if (onCopy != null) {
      return _copyIcon;
    }
    else if (title != null) {
      return _spacerIcon;
    }
    else {
      return Container();
    }
  }

  Widget get _progressIcon =>
    Padding(padding: EdgeInsets.symmetric(horizontal: iconPadding.dx, vertical: iconPadding.dy), child:
      SizedBox(width: iconSize.width, height: iconSize.height, child:
        CircularProgressIndicator(strokeWidth: 2, color: Styles().colors.fillColorSecondary,)
      )
    );

  Widget get _expandIcon =>
    Padding(padding: _expandIconPadding, child:
      Styles().images.getImage((expanded == true) ? 'chevron-up' : 'chevron-down', size: _expandIconSize), // size = 10
    );
  EdgeInsetsGeometry get _expandIconPadding => EdgeInsets.only(
    left: iconPadding.dx + (iconSize.width - _expandIconSize) / 2 / (_copyAndExpand ? 4 : 1),
    right: iconPadding.dx + (iconSize.width - _expandIconSize) / 2,
    top: iconPadding.dy + (iconSize.height - _expandIconSize) / 2,
    bottom: iconPadding.dy + (iconSize.height - _expandIconSize) / 2,
  );
  final double _expandIconSize = 10;

  Widget get _copyIcon =>
    InkWell(onTap: _onTapCopy, child:
      Padding(padding: _copyIconPadding, child:
        Styles().images.getImage('copy', size: _copyIconSize),
      ),
    );
  EdgeInsetsGeometry get _copyIconPadding => EdgeInsets.only(
    left: iconPadding.dx + (iconSize.width - _copyIconSize) / 2,
    right: (iconPadding.dx + (iconSize.width - _copyIconSize) / 2) / (_copyAndExpand ? 4 : 1),
    top: iconPadding.dy + (iconSize.height - _copyIconSize) / 2,
    bottom: iconPadding.dy + (iconSize.height - _copyIconSize) / 2,
  );
  final double _copyIconSize = 18;

  Widget get _spacerIcon =>
    Padding(padding: EdgeInsets.symmetric(horizontal: iconPadding.dx, vertical: iconPadding.dy), child:
      SizedBox(width: iconSize.width, height: iconSize.height, child:
        Container(),
      )
    );

  bool get _copyAndExpand => ((onCopy != null) && (expanded != null));

  void onTapExpand() => (expanded != null) ? onExpand?.call() : null;
  void _onTapCopy() => (onCopy != null) ? onCopy?.call() : null;
}

class _Utils {
  static bool _isValueNotEmpty(dynamic value) {
    if (value is String) {
      if (value.trim().isNotEmpty) {
        dynamic json = JsonUtils.decode(value);
        return  (json != null) ? _isValueNotEmpty(json) : true;
      }
      return false;
    }
    else if (value is Map) {
      if (value.isNotEmpty) {
        // We need at least one not empty value
        for (dynamic entry in value.values) {
          if (_isValueNotEmpty(entry)) {
            return true;
          }
        }
      }
      return false;
    }
    else if (value is Iterable) {
      if (value.isNotEmpty) {
        // We need at least one not empty value
        for (dynamic entry in value) {
          if (_isValueNotEmpty(entry)) {
            return true;
          }
        }
      }
      return false;
    }
    else {
      return (value != null);
    }
  }
}

