import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/ext/Group.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/ui/events2/Event2CreatePanel.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/ui/widgets/FavoriteButton.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class GroupContentSettingsPanel extends StatefulWidget {
  final Group? group;

  const GroupContentSettingsPanel({super.key, required this.group});

  @override
  State<StatefulWidget> createState() => _GroupContentSettingsState();
}

class _GroupContentSettingsState extends State<GroupContentSettingsPanel> implements HomeDragAndDropHost{
  static const String _favoritesHeaderId = 'edit.favorites';
  static const String _unfavoritesHeaderId = 'edit.unfavorites';
  static const int _min_content_count = 1;

  List<String> _selection = <String>[];
  List<String> _availableCodes = [];

  Map<String, GlobalKey> _handleKeys = <String, GlobalKey>{};
  GlobalKey _contentWrapperKey = GlobalKey();
  ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isDragging = false;

  bool _uploading = false;

  List<String> get _unselectedCodes =>
      _availableCodes.where((code) => _selection.contains(code) == false).toList();

  @override
  void initState() {
    _availableCodes = List.from(GroupContentItemExt.availableContentCodes);
    _selection = (widget.group?.settings?.contentCodes ?? List.from(GroupContentItemExt.defaultContentCodes)).reversed.toList(); //We draw in reverse order, so reverse again to match GroupContent

    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Scaffold(
          appBar: HeaderBar(
            title: Localization().getStringEx("", "Group Content"), //TBD localize
            actions: _headerBarActions,
          ),
        backgroundColor: Styles().colors.background,
        body: Listener(onPointerMove: _onPointerMove,
          onPointerUp: (_) => _onPointerCancel,
          onPointerCancel: (_) => _onPointerCancel,
          child: Column(key: _contentWrapperKey, children: <Widget>[
            Expanded(child:
              SingleChildScrollView(controller: _scrollController,
                  child: Column(children: _content,)
              )
            ),
          ]),
        ),
      );

  List<Widget> get _content {
    List<Widget> widgets = [];

    if(CollectionUtils.isEmpty(_availableCodes)){
      widgets.add(_buildStatusMessage("No available content items"));
      return widgets;
    }

    if(CollectionUtils.isNotEmpty(_selection)){
      widgets.add(_buildEditingHeader(
          favoriteId: _favoritesHeaderId, dropAnchorAlignment: CrossAxisAlignment.end,
          title: Localization().getStringEx('', 'CURRENT CONTENT'),
          // linkButtonTitle: Localization().getStringEx('', 'Unstar All'),
          description: Localization().getStringEx('', 'Tap, <b>hold</b>, and drag an item item to reorder your group content. To remove an item, tap the star.'),
          // onTapLinkButton: CollectionUtils.isNotEmpty(_selection) ? () => _onTapUnstarAll() : null,
      ));
      widgets.addAll(_buildCollectionItemsContent(_selection));
    }

    widgets.add(_buildEditingHeader(
      favoriteId: _unfavoritesHeaderId, dropAnchorAlignment: null,
      title: Localization().getStringEx('', 'OTHER CONTENT'),
      linkButtonTitle: Localization().getStringEx('panel.home.edit.unused.star.link.button', 'Star All'),
      onTapLinkButton: _onTapStarAll,
      description: Localization().getStringEx('', 'Tap the star to add an item.'),
    ));
    widgets.addAll(_buildCollectionItemsContent(_unselectedCodes));

    return widgets;
  }

  //UI
  Widget _buildEditingHeader({String? title, String? description, String? linkButtonTitle, void Function()? onTapLinkButton, String? favoriteId, CrossAxisAlignment? dropAnchorAlignment}) {
    return HomeDropTargetWidget(favoriteId: favoriteId, dragAndDropHost: this, dropAnchorAlignment: dropAnchorAlignment, childBuilder: (BuildContext context, { bool? dropTarget, CrossAxisAlignment? dropAnchorAlignment }) {
      return Column(children: [
        Container(height: 2, color: ((dropTarget == true) && (dropAnchorAlignment == CrossAxisAlignment.start)) ? Styles().colors.fillColorSecondary : Colors.transparent,),
        Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
            Text(title ?? '', style: Styles().textStyles.getTextStyle("widget.title.regular.fat")),
          ),
          Expanded(child: Container()),
          Visibility(visible: (onTapLinkButton != null), child: InkWell(onTap: onTapLinkButton, child:
            Padding(padding: EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 16), child:
              Text(StringUtils.ensureNotEmpty(linkButtonTitle), style: Styles().textStyles.getTextStyle("widget.title.small.underline")))
          ))
        ],)),
        Row(children: [
          Expanded(child:
            Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
              HtmlWidget(
                  StringUtils.ensureNotEmpty(description),
                  onTapUrl : (url) {_onTapHtmlLink(url); return true;},
                  textStyle: Styles().textStyles.getTextStyle("widget.description.small"),
                  customStylesBuilder: (element) => (element.localName == "b") ? {"font-weight": "bold"} : null
              )
            ),
          )
        ],),
        Container(height: 2, color: ((dropTarget == true) && (dropAnchorAlignment == CrossAxisAlignment.end)) ? Styles().colors.fillColorSecondary : Colors.transparent,),
      ],);

    },);
  }

  List<Widget> _buildCollectionItemsContent(List<String> collection) {
    List<Widget> widgets = [];
    if(CollectionUtils.isEmpty(collection))
      return widgets;

    int position = 0;
    for (String code in collection.reversed) {
      if(_availableCodes.contains(code)){
        dynamic widget = _buildContentItem(code: code, position: position);
        if(widget != null){
          widgets.add(widget);
          position++;
        }
      }
    }

    return widgets;
  }

  Widget _buildContentItem({required String code, required int position}){
    return HomeHandleWidget(favoriteId: code, dragAndDropHost: this, position: position,
      key: _globalKey(_handleKeys, code),
      childBuilder: (_) =>
          Container(color: Styles().colors.background, child:
            Row(children: <Widget>[

              Semantics(label: 'Drag Handle' /* TBD: Localization */, onLongPress: (){},button: true, child:
                Container(padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16), child:
                  Styles().images.getImage('drag-white', excludeFromSemantics: true),
                ),
              ),

              Expanded(child:
                Padding(padding: EdgeInsets.symmetric(vertical: 12), child:
                  Semantics(label: GroupContentItemExt.getTitleByCode(code), header: true, excludeSemantics: true, child:
                    Text(GroupContentItemExt.getTitleByCode(code), style: Styles().textStyles.getTextStyle("widget.title.medium.fat"),)
                  )
                )
              ),

              _GroupContentSettingsFavoriteButton(
                toggled: _selection.contains(code),
                onTap: () => _toggleContentItem(code: code),
              )
            ],),
          ),
    );
  }

  Key? _globalKey(Map<String, GlobalKey>? globalKeys, String code) =>
      (globalKeys != null) ? (globalKeys[code] ??= GlobalKey()) : null;

  Widget _buildStatusMessage(String message) =>
      Center(child: Text(message)); //TBD

  //onTap
  void _onApply(){
    widget.group?.settings?.contentCodes = _selection.reversed.toList(); // We display reversed so reverse again before save
    Navigator.pop(context);
  }

  // ignore: unused_element
  void _onTapUnstarAll() {
    Analytics().logSelect(source: 'GroupContentSettings', target: 'Unstar All');
    _showUnstarConfirmationDialog(_selection);
  }

  void _showUnstarConfirmationDialog(List<String>? selection) {
    AppAlert.showCustomDialog(context: context, contentPadding: EdgeInsets.zero, contentWidget:
    Container(height: 250, decoration: BoxDecoration(color: Styles().colors.white, borderRadius: BorderRadius.circular(15.0)), child:
      Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
        Padding(padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16), child:
          Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
              Text(Localization().getStringEx('panel.home.edit.favorites.confirmation.dialog.msg', 'Are you sure you want to REMOVE all items from your favorites? Items can always be added back later.'), textAlign: TextAlign.center, style:
                Styles().textStyles.getTextStyle("widget.detail.small")
              )
            ),
            Padding(padding: EdgeInsets.only(top: 40), child:
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Expanded(child: RoundedButton(label: Localization().getStringEx('dialog.no.title', 'No'), borderColor: Styles().colors.fillColorPrimary, onTap: _dismissUnstarConfirmationDialog)),
                Container(width: 16),
                Expanded(child: RoundedButton(label: Localization().getStringEx('dialog.yes.title', 'Yes'), borderColor: Styles().colors.fillColorSecondary, onTap: () { _dismissUnstarConfirmationDialog(); _unstarAvailableContentItems(selection);} ))
              ])
            )
          ])
        ),
        Align(alignment: Alignment.topRight, child:
          GestureDetector(onTap: _dismissUnstarConfirmationDialog, child:
            Padding(padding: EdgeInsets.all(16), child:
              Styles().images.getImage('close-circle', excludeFromSemantics: true)
            )
          )
        )
      ])
    )
    );
  }

  void _dismissUnstarConfirmationDialog() {
    Navigator.of(context).pop();
  }

  void _unstarAvailableContentItems(List<String>? favorites) {
    if (CollectionUtils.isNotEmpty(favorites)) {
      for (String code in favorites!) {
        _setContentItemSelection(code: code, value: false);
      }
    }
  }

  void _onTapStarAll() {
    List<String> notSelected = _unselectedCodes;
    Analytics().logSelect(source: 'GroupContentSettings', target: 'Star All');
    if (CollectionUtils.isNotEmpty(notSelected)) {
      for (String? code in notSelected.reversed) {
          _setContentItemSelection(code: code!, value: true);
        }
    }
  }

  void _onTapHtmlLink(String? url) =>
    AppLaunchUrl.launchExternal(url: url);

  void _toggleContentItem({required String code}){
    setStateIfMounted(() {
      if (_selection.contains(code)) {
        if(_canRemove)
          _selection.remove(code);
      } else {
        _selection.add(code);
      }
    });
  }

  void _setContentItemSelection({required String code, required bool value}) {
    setStateIfMounted(() {
      if(value){
        if(!_selection.contains(code))
          _selection.add(code);
      } else if(_selection.contains(code)) {
        if(_canRemove)
          _selection.remove(code);
      }
    });
  }

//Pointer listener
  void _onPointerMove(PointerMoveEvent event) {
    if (_isDragging) {
      RenderBox render = _contentWrapperKey.currentContext?.findRenderObject() as RenderBox;
      Offset position = render.localToGlobal(Offset.zero);
      double topY = position.dy;  // top position of the widget
      double bottomY = topY + render.size.height; // bottom position of the widget

      const detectedRange = 64;
      const double maxScrollDistance = 64;
      if (event.position.dy < topY + detectedRange) {
        // scroll up
        double scrollOffet = (topY + detectedRange - max(event.position.dy, topY)) / detectedRange * maxScrollDistance;
        _scrollUp(scrollOffet);

        if (_scrollTimer != null) {
          _scrollTimer?.cancel();
        }
        _scrollTimer = Timer.periodic(Duration(milliseconds: 100), (time) => _scrollUp(scrollOffet));
      }
      else if (event.position.dy > bottomY - detectedRange) {
        // scroll down
        double scrollOffet = (min(event.position.dy, bottomY) - bottomY + detectedRange) / detectedRange * maxScrollDistance;
        _scrollDown(scrollOffet);

        if (_scrollTimer != null) {
          _scrollTimer?.cancel();
        }
        _scrollTimer = Timer.periodic(Duration(milliseconds: 100), (time) => _scrollDown(scrollOffet));
      }
      else {
        _cancelScrollTimer();
      }
    }
  }

  void _onPointerCancel() {
    _cancelScrollTimer();
  }

  void _scrollUp(double scrollDistance) {
    double offset = max(_scrollController.offset - scrollDistance, _scrollController.position.minScrollExtent);
    if (offset < _scrollController.offset) {
      _scrollController.jumpTo(offset);
    }
  }

  void _scrollDown(double scrollDistance) {
    double offset = min(_scrollController.offset + scrollDistance, _scrollController.position.maxScrollExtent);
    if (_scrollController.offset < offset) {
      _scrollController.jumpTo(offset);
    }
  }

  void _cancelScrollTimer() {
    if (_scrollTimer != null) {
      _scrollTimer?.cancel();
      _scrollTimer = null;
    }
  }

  //Home Drag
  @override
  set isDragging(bool value)=> _isDragging;

  @override
  void onAccessibilityMove({String? dragFavoriteId, int? delta}) {
      if (dragFavoriteId != null) {
        List<String> selection = _selection;
        int dragIndex = selection.indexOf(dragFavoriteId);
        if (0 <= dragIndex) {
          // Moving a favorite item. Where?
          int dropIndex = dragIndex + (delta ?? 0);
          if (dropIndex < selection.length) {
            if (0 <= dropIndex) {
              // Inside the favorites list => Reorder Favorites
              if (dragIndex != dropIndex) {
                selection.swap(dragIndex, dropIndex);
                selection.insert(dropIndex, dragFavoriteId);
                _ensureVisibleHandle(dragFavoriteId);
              }
            }
            else {
              // Outside the favorites list => Remove Favorite
              HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
                if (result == true) {
                  _setContentItemSelection(code: dragFavoriteId,  value: false);
                  _ensureVisibleHandle(dragFavoriteId);
                }
              });
            }
          }
        }
        else {
          // Moving unused item. Where?
          int dropIndex = -1 + (delta ?? 0);
          if ((0 <= dropIndex) && (dropIndex <= selection.length)) {
            // Inside favorites list => Add Favorite
            HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                selection.insert(dropIndex, dragFavoriteId);
                _setContentItemSelection(code: dragFavoriteId, value: true);
                _ensureVisibleHandle(dragFavoriteId);
              }
            });
          }
        }
      }
  }

  @override
  void onDragAndDrop({String? dragFavoriteId, String? dropFavoriteId, CrossAxisAlignment? dropAnchor}) {
        isDragging = false;

        if (dragFavoriteId != null) {
          int dragIndex = _selection.indexOf(dragFavoriteId);
          int dropIndex = (dropFavoriteId != null) ? _selection.indexOf(dropFavoriteId) : -1;

          if ((0 <= dragIndex) && (0 <= dropIndex)) {
            // Reorder favorites
            if (dragIndex != dropIndex) {
              _selection.removeAt(dragIndex);
              if (dragIndex < dropIndex) {
                dropIndex--;
              }
              if (dropAnchor == CrossAxisAlignment.start) {
                dropIndex++;
              }
              _selection.insert(dropIndex, dragFavoriteId);
            }
          }
          else if (0 <= dropIndex) {
            // Add favorite at specific position
            HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                if (dropAnchor == CrossAxisAlignment.start) {
                  dropIndex++;
                }
                _selection.insert(dropIndex, dragFavoriteId);
                _setContentItemSelection(code: dragFavoriteId, value: true);
              }
            });
          }
          else if (dropFavoriteId == _favoritesHeaderId) {
            if (0 <= dragIndex) {
              // move drag favorite at
              _selection.removeAt(dragIndex);
              _selection.insert(_selection.length, dragFavoriteId);
            }
            else {
              // add favorite
              HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
                if (result == true) {
                  _setContentItemSelection(code: dragFavoriteId, value: true);
                }
              });
            }
          }
          else if (dropFavoriteId == _unfavoritesHeaderId) {
            if (dropAnchor == CrossAxisAlignment.start) {
              // move or add drag favorite
              if (0 <= dragIndex) {
                _selection.removeAt(dragIndex);
              }
              _selection.insert(0, dragFavoriteId);
              _setContentItemSelection(code: dragFavoriteId, value: true);
            }
            else {
              if (0 <= dragIndex) {
                // remove favorite
                HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
                  if (result == true) {
                    _setContentItemSelection(code: dragFavoriteId, value: false);
                  }
                });
              }
            }
          }
          else {
            // remove favorite
            HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                _setContentItemSelection(code: dragFavoriteId, value: false);
              }
            });
          }

          setState(() {});
        }
  }

  void _ensureVisibleHandle(String favoriteId) {
    BuildContext? handleContext = _handleKeys[favoriteId]?.currentContext;
    if (handleContext != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Scrollable.ensureVisible(handleContext, duration: Duration(milliseconds: 300)).then((_) {
        });
      });
    }
  }

  List<Widget>? get _headerBarActions {
    if (_uploading) {
      return [Event2CreatePanel.buildHeaderBarActionProgress()];
    }
    else if(_hasChanged) {
      return [Event2CreatePanel.buildHeaderBarActionButton(
        title: Localization().getStringEx('dialog.apply.title', 'Apply'),
        onTap: _onApply,
      )];
    }
    else
      return null;
  }

  bool get _hasChanged => !CollectionUtils.equals(widget.group?.settings?.contentCodes, _selection);

  bool get _canRemove => _selection.length > _min_content_count;
}

class _GroupContentSettingsFavoriteButton extends FavoriteButton {
  final bool toggled;
  final void Function()? onTap;

  _GroupContentSettingsFavoriteButton({required this.onTap, required this.toggled}) : super(style: FavoriteIconStyle.Handle);

  @override
  bool? get isFavorite => toggled;

  @override
  void toggleFavorite() => onTap?.call();
}