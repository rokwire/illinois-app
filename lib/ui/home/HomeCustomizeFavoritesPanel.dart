
import 'dart:async';
import 'dart:collection';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/config.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeCustomizeFavoritesPanel extends StatefulWidget {

  HomeCustomizeFavoritesPanel._();

  @override
  State<StatefulWidget> createState() => _HomeCustomizeFavoritesPanelState();

  static Future<void> present(BuildContext context) {
    //MediaQueryData mediaQuery = MediaQueryData.fromWindow(WidgetsBinding.instance.window);
    MediaQueryData mediaQuery = MediaQueryData.fromView(View.of(context));
    double height = mediaQuery.size.height - mediaQuery.viewPadding.top - mediaQuery.viewInsets.top - 16;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      useRootNavigator: true,
      clipBehavior: Clip.antiAlias,
      backgroundColor: Styles().colors?.background,
      constraints: BoxConstraints(maxHeight: height, minHeight: height),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => HomeCustomizeFavoritesPanel._(),
    );
    //Navigator.push(context, CupertinoPageRoute(builder: (context) => HomeCustomizeFavoritesPanel._(),));
  }
}

class _HomeCustomizeFavoritesPanelState extends State<HomeCustomizeFavoritesPanel> implements NotificationsListener, HomeDragAndDropHost {

  static const String _favoritesHeaderId = 'edit.favorites';
  static const String _unfavoritesHeaderId = 'edit.unfavorites';

  Map<String, GlobalKey> _handleKeys = <String, GlobalKey>{};
  Set<String>? _availableCodes;
  GlobalKey _contentWrapperKey = GlobalKey();
  ScrollController _scrollController = ScrollController();
  Timer? _scrollTimer;
  bool _isDragging = false;

  @override
  void initState() {
    _availableCodes = _buildAvailableCodes();

    NotificationService().subscribe(this, [
      Auth2UserPrefs.notifyFavoritesChanged,
      FlexUI.notifyChanged,
    ]);

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _scrollController.dispose();

    super.dispose();
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateAvailableCodes();
    }
    else if (name == Auth2UserPrefs.notifyFavoritesChanged) {
      setStateIfMounted((){});
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(children: [
      Container(color: Styles().colors?.white, child:
        Row(children: [
          Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16), child:
                Text(Localization().getStringEx('panel.home.header.editing.title', 'Customize'), style: Styles().textStyles?.getTextStyle("widget.label.medium.fat"))
              )
          ),
          Semantics(label: Localization().getStringEx('dialog.close.title', 'Close'), hint: Localization().getStringEx('dialog.close.hint', ''), inMutuallyExclusiveGroup: true, button: true, child:
            InkWell(onTap : _onTapClose, child:
              Container(padding: EdgeInsets.only(left: 8, right: 16, top: 16, bottom: 16), child:
                Styles().images?.getImage('close', excludeFromSemantics: true),
              ),
            ),
          ),
        ],),
      ),
      Container(color: Styles().colors?.surfaceAccent, height: 1,),
      Expanded(child:
        RefreshIndicator(onRefresh: _onPullToRefresh, child:
          Listener(onPointerMove: _onPointerMove, onPointerUp: (_) => _onPointerCancel, onPointerCancel: (_) => _onPointerCancel, child:
            Column(key: _contentWrapperKey, children: <Widget>[
              Expanded(child:
                SingleChildScrollView(controller: _scrollController, child:
                  Column(children: _buildContentList())
                )
              ),
            ]),
          ),
        ),
      ),
    ],);
  }

  List<Widget> _buildContentList() {
    List<Widget> widgets = [];

    LinkedHashSet<String>? homeFavorites = Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName());

    if (homeFavorites != null) {

      widgets.add(_buildEditingHeader(
        favoriteId: _favoritesHeaderId, dropAnchorAlignment: CrossAxisAlignment.end,
        title: Localization().getStringEx('panel.home.edit.favorites.header.title', 'Current Favorites'),
        linkButtonTitle: Localization().getStringEx('panel.home.edit.favorites.unstar.link.button', 'Unstar All'),
        onTapLinkButton: CollectionUtils.isNotEmpty(homeFavorites) ? () => _onTapUnstarAll(homeFavorites.toList()) : null,
        description: Localization().getStringEx('panel.home.edit.favorites.header.description', 'Tap, <b>hold</b>, and drag an item to reorder your favorites. To remove an item from Favorites, tap the star.'),
      ));
       
      int position = 0;
      for (String code in List<String>.from(homeFavorites).reversed) {
        if (_availableCodes?.contains(code) ?? false) {
          dynamic widget = HomePanel.dataFromCode(code, handle: true, position: position, globalKeys: _handleKeys, dragAndDropHost: this);
          if (widget is Widget) {
            widgets.add(widget);
            position++;
          }
        }
      }
    }

    List<String>? fullContent = JsonUtils.listStringsValue(FlexUI()['home']);
    if (fullContent != null) {

      List<Map<String, dynamic>> unusedList = <Map<String, dynamic>>[];

      for (String code in fullContent) {
        if ((_availableCodes?.contains(code) ?? false) && !(homeFavorites?.contains(code) ?? false)) {
          dynamic title = HomePanel.dataFromCode(code, title: true);
          if (title is String) {
            unusedList.add({'title' : title, 'code': code});
          }
        }
      }
      
      unusedList.sort((Map<String, dynamic> entry1, Map<String, dynamic> entry2) {
        String title1 = JsonUtils.stringValue(entry1['title'])?.toLowerCase() ?? '';
        String title2 = JsonUtils.stringValue(entry2['title'])?.toLowerCase() ?? '';
        return title1.compareTo(title2);
      });


      widgets.add(_buildEditingHeader(
        favoriteId: _unfavoritesHeaderId, dropAnchorAlignment: null,
        title: Localization().getStringEx('panel.home.edit.unused.header.title', 'Other Items to Favorite'),
        linkButtonTitle: Localization().getStringEx('panel.home.edit.unused.star.link.button', 'Star All'),
        onTapLinkButton: CollectionUtils.isNotEmpty(unusedList) ? () => _onTapStarAll(unusedList) : null,
        description: Localization().getStringEx('panel.home.edit.unused.header.description', 'Tap the star to add any below items to Favorites.'),
      ));

      int position = 0;
      for (Map<String, dynamic> entry in unusedList) {
        String? code = JsonUtils.stringValue(entry['code']);
        dynamic widget = (code != null) ? HomePanel.dataFromCode(code, handle: true, position: position, globalKeys: _handleKeys, dragAndDropHost: this) : null;
          if (widget is Widget) {
            widgets.add(widget);
            position++;
          }
      }
    }

    widgets.add(Container(height: 24,));

    return widgets;
  }

  Widget _buildEditingHeader({String? title, String? description, String? linkButtonTitle, void Function()? onTapLinkButton, String? favoriteId, CrossAxisAlignment? dropAnchorAlignment}) {
    return HomeDropTargetWidget(favoriteId: favoriteId, dragAndDropHost: this, dropAnchorAlignment: dropAnchorAlignment, childBuilder: (BuildContext context, { bool? dropTarget, CrossAxisAlignment? dropAnchorAlignment }) {
      return Column(children: [
          Container(height: 2, color: ((dropTarget == true) && (dropAnchorAlignment == CrossAxisAlignment.start)) ? Styles().colors?.fillColorSecondary : Colors.transparent,),
          Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
              Text(title ?? '', style: Styles().textStyles?.getTextStyle("widget.title.medium_large.extra_fat")),
            ),
            Expanded(child: Container()),
            Visibility(visible: (onTapLinkButton != null), child: InkWell(onTap: onTapLinkButton, child: 
              Padding(padding: EdgeInsets.only(left: 5, top: 5, bottom: 5, right: 16), child:
                Text(StringUtils.ensureNotEmpty(linkButtonTitle), style: Styles().textStyles?.getTextStyle("widget.home.link_button.regular.accent.underline")))
            ))
          ],)),
          Row(children: [
            Expanded(child:
              Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 16), child:
              HtmlWidget(
                  StringUtils.ensureNotEmpty(description),
                  onTapUrl : (url) {_onTapHtmlLink(url); return true;},
                  textStyle: Styles().textStyles?.getTextStyle("widget.description.regular"),
                  customStylesBuilder: (element) => (element.localName == "b") ? {"font-weight": "bold"} : null
              )
                // Html(data: StringUtils.ensureNotEmpty(description),
                //   onLinkTap: (url, context, attributes, element) => _onTapHtmlLink(url),
                //   style: {
                //     "body": Style(color: Styles().colors!.textColorPrimaryVariant, fontFamily: Styles().fontFamilies!.regular, fontSize: FontSize(16), textAlign: TextAlign.left, padding: EdgeInsets.zero, margin: EdgeInsets.zero),
                //     "b": Style(fontFamily: Styles().fontFamilies!.bold)
                //   })
              ),
            )
          ],),
          Container(height: 2, color: ((dropTarget == true) && (dropAnchorAlignment == CrossAxisAlignment.end)) ? Styles().colors?.fillColorSecondary : Colors.transparent,),
        ],);

    },);
  }

  void _onTapClose() {
    Analytics().logSelect(target: 'Close');
    Navigator.of(context).pop();
  }

  Future<void> _onPullToRefresh() async {
    if (kDebugMode || (Config().configEnvironment == ConfigEnvironment.dev)) {
      _initDefaultFavorites();
    }
    else {
      setStateIfMounted((){});
    }
  }

  static LinkedHashSet<String>? _initDefaultFavorites() {
    Map<String, dynamic>? defaults = FlexUI().content('defaults.favorites');
    if (defaults != null) {
      List<String>? defaultContent = JsonUtils.listStringsValue(defaults['home']);
      if (defaultContent != null) {

        // Init content of all compound widgets that bellongs to home favorites content
        for (String code in defaultContent) {
          List<String>? defaultWidgetContent = JsonUtils.listStringsValue(defaults['home.$code']);
          if (defaultWidgetContent != null) {
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: code),
              LinkedHashSet<String>.from(defaultWidgetContent.reversed));
          }
        }

        // Clear content of all compound widgets that do not bellongs to home favorites content
        Iterable<String>? favoriteKeys = Auth2().prefs?.favoritesKeys;
        if (favoriteKeys != null) {
          for (String favoriteKey in List.from(favoriteKeys)) {
            String? code = HomeFavorite.parseFavoriteKeyCategory(favoriteKey);
            if ((code != null) && !defaultContent.contains(code)) {
              Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(category: code), null);
            }
          }
        }

        // Init content of home favorites
        LinkedHashSet<String>? defaultFavorites = LinkedHashSet<String>.from(defaultContent.reversed);
        Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), defaultFavorites);
        return defaultFavorites;
      }
    }
    return null;
  }

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

  Set<String> _buildAvailableCodes() {
    Set<String> availableCodes = <String>{};
    List<String>? fullContent = JsonUtils.listStringsValue(FlexUI()['home']);
    if (fullContent != null) {
      for (String code in fullContent) {
        if (_isCodeAvailable(code)) {
          availableCodes.add(code);
        }
      }
    }
    return availableCodes;
  }

  bool _isCodeAvailable(String code) {
    dynamic codeContent = FlexUI()['home.$code'];
    return !(codeContent is Iterable) || (0 < codeContent.length);
  }

  void _updateAvailableCodes() {
    Set<String> availableCodes = _buildAvailableCodes();
    if (!DeepCollectionEquality().equals(_availableCodes, availableCodes) && mounted) {
      setState(() {
        _availableCodes = availableCodes;
      });
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

  void _onTapHtmlLink(String? url) {
    if (StringUtils.isNotEmpty(url)) {
      Uri? uri = Uri.tryParse(url!);
      if (uri != null) {
        launchUrl(uri);
      }
    }
  }

  void _onTapUnstarAll(List<String>? favorites) {
    Analytics().logSelect(source: 'Customize', target: 'Unstar All');
    _showUnstarConfirmationDialog(favorites);
  }

  void _showUnstarConfirmationDialog(List<String>? favorites) {
    AppAlert.showCustomDialog(context: context, contentPadding: EdgeInsets.zero, contentWidget:
      Container(height: 250, decoration: BoxDecoration(color: Styles().colors!.white, borderRadius: BorderRadius.circular(15.0)), child:
        Stack(alignment: Alignment.center, fit: StackFit.loose, children: [
          Padding(padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16), child:
            Column(crossAxisAlignment: CrossAxisAlignment.center, mainAxisSize: MainAxisSize.min, children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child:
                Text(Localization().getStringEx('panel.home.edit.favorites.confirmation.dialog.msg', 'Are you sure you want to REMOVE all items from your favorites? Items can always be added back later.'), textAlign: TextAlign.center, style:
                  Styles().textStyles?.getTextStyle("widget.detail.small")
                )
              ),
              Padding(padding: EdgeInsets.only(top: 40), child:
                Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(child: RoundedButton(label: Localization().getStringEx('dialog.no.title', 'No'), borderColor: Styles().colors!.fillColorPrimary, onTap: _dismissUnstarConfirmationDialog)),
                  Container(width: 16),
                  Expanded(child: RoundedButton(label: Localization().getStringEx('dialog.yes.title', 'Yes'), borderColor: Styles().colors!.fillColorSecondary, onTap: () { _dismissUnstarConfirmationDialog(); _unstarAvailableFavorites(favorites);} ))
                ])
              )
            ])
          ),
          Align(alignment: Alignment.topRight, child:
            GestureDetector(onTap: _dismissUnstarConfirmationDialog, child:
              Padding(padding: EdgeInsets.all(16), child:
                Styles().images?.getImage('close', excludeFromSemantics: true)
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

  void _unstarAvailableFavorites(List<String>? favorites) {
    if (CollectionUtils.isNotEmpty(favorites)) {
      for (String code in favorites!) {
        _setFavorite(code: code, value: false);
      }
    }
  }

  void _onTapStarAll(List<Map<String, dynamic>>? notFavorites) {
    Analytics().logSelect(source: 'Customize', target: 'Star All');
    if (CollectionUtils.isNotEmpty(notFavorites)) {
      for (Map<String, dynamic>? entry in notFavorites!.reversed) {
        if (entry != null) {
          String? code = entry['code'];
          if (StringUtils.isNotEmpty(code)) {
            _setFavorite(code: code!, value: true);
          }
        }
      }
    }
  }

  void _setFavorite({required String code, required bool value}) {
    HomeFavorite favorite = HomeFavorite(code);
    List<String>? availableSectionFavorites = JsonUtils.listStringsValue(FlexUI()['home.${favorite.id}']);
    if (availableSectionFavorites != null) {
      List<Favorite> favorites = <Favorite>[favorite];
      for (String sectionEntry in availableSectionFavorites) {
        favorites.add(HomeFavorite(sectionEntry, category: favorite.id));
      }
      Auth2().prefs?.setListFavorite(favorites, value);
      HomeFavorite.log(favorites, value);
    } else {
      Auth2().prefs?.setFavorite(favorite, value);
      HomeFavorite.log(favorite, value);
    }
  }

  // HomeDragAndDropHost
  
  bool get isDragging => _isDragging;

  set isDragging(bool value) {
    if (_isDragging != value) {
      _isDragging = value;
      
      if (_isDragging) {
      }
      else {
        _cancelScrollTimer();
      }
    }
  }

  void onDragAndDrop({String? dragFavoriteId, String? dropFavoriteId, CrossAxisAlignment? dropAnchor}) {

    isDragging = false;

    if (dragFavoriteId != null) {
      List<String> favoritesList = List.from(Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName()) ?? <String>{});
      int dragIndex = favoritesList.indexOf(dragFavoriteId);
      int dropIndex = (dropFavoriteId != null) ? favoritesList.indexOf(dropFavoriteId) : -1;
      
      if ((0 <= dragIndex) && (0 <= dropIndex)) {
        // Reorder favorites
        if (dragIndex != dropIndex) {
          favoritesList.removeAt(dragIndex);
          if (dragIndex < dropIndex) {
            dropIndex--;
          }
          if (dropAnchor == CrossAxisAlignment.start) {
            dropIndex++;
          }
          favoritesList.insert(dropIndex, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
          HomeFavorite.log(HomeFavorite(dragFavoriteId));
        }
      }
      else if (0 <= dropIndex) {
        // Add favorite at specific position
        HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
          if (result == true) {
            if (dropAnchor == CrossAxisAlignment.start) {
              dropIndex++;
            }
            favoritesList.insert(dropIndex, dragFavoriteId);
            Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
            _setSectionFavorites(dragFavoriteId, true);
            HomeFavorite.log(HomeFavorite(dragFavoriteId));
          }
        });
      }
      else if (dropFavoriteId == _favoritesHeaderId) {
        if (0 <= dragIndex) {
          // move drag favorite at 
          favoritesList.removeAt(dragIndex);
          favoritesList.insert(favoritesList.length, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
          HomeFavorite.log(HomeFavorite(dragFavoriteId));
        }
        else {
          // add favorite
          HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
            if (result == true) {
              Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), true);
              _setSectionFavorites(dragFavoriteId, true);
              HomeFavorite.log(HomeFavorite(dragFavoriteId));
            }
          });
        }
      }
      else if (dropFavoriteId == _unfavoritesHeaderId) {
        if (dropAnchor == CrossAxisAlignment.start) {
          // move or add drag favorite
          if (0 <= dragIndex) {
            favoritesList.removeAt(dragIndex);
          }
          favoritesList.insert(0, dragFavoriteId);
          Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
          _setSectionFavorites(dragFavoriteId, true);
          HomeFavorite.log(HomeFavorite(dragFavoriteId));
        }
        else {
          if (0 <= dragIndex) {
            // remove favorite
            HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), false);
                _setSectionFavorites(dragFavoriteId, false);
                HomeFavorite.log(HomeFavorite(dragFavoriteId));
              }
            });
          }
        }
      }
      else {
        // remove favorite
        HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
          if (result == true) {
            Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), false);
            _setSectionFavorites(dragFavoriteId, false);
            HomeFavorite.log(HomeFavorite(dragFavoriteId));
          }
        });
      }
    }
  }

  void onAccessibilityMove({String? dragFavoriteId, int? delta}) {
    if (dragFavoriteId != null) {
      List<String> favoritesList = List.from(Auth2().prefs?.getFavorites(HomeFavorite.favoriteKeyName()) ?? <String>{});
      int dragIndex = favoritesList.indexOf(dragFavoriteId);
      if (0 <= dragIndex) {
        // Moving a favorite item. Where?
        int dropIndex = dragIndex + (delta ?? 0);
        if (dropIndex < favoritesList.length) {
          if (0 <= dropIndex) {
            // Inside the favorites list => Reorder Favorites
            if (dragIndex != dropIndex) {
              favoritesList.swap(dragIndex, dropIndex);
              favoritesList.insert(dropIndex, dragFavoriteId);
              Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
              _ensureVisibleHandle(dragFavoriteId);
              HomeFavorite.log(HomeFavorite(dragFavoriteId));
            }
          }
          else {
            // Outside the favorites list => Remove Favorite
            HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
              if (result == true) {
                Auth2().prefs?.setFavorite(HomeFavorite(dragFavoriteId), false);
                _setSectionFavorites(dragFavoriteId, false);
                _ensureVisibleHandle(dragFavoriteId);
                HomeFavorite.log(HomeFavorite(dragFavoriteId));
              }
            });
          }
        }
      }
      else {
        // Moving unused item. Where?
        int dropIndex = -1 + (delta ?? 0);
        if ((0 <= dropIndex) && (dropIndex <= favoritesList.length)) {
          // Inside favorites list => Add Favorite
          HomeFavoriteButton.promptFavorite(context, favorite: HomeFavorite(dragFavoriteId)).then((bool? result) {
            if (result == true) {
              favoritesList.insert(dropIndex, dragFavoriteId);
              Auth2().prefs?.setFavorites(HomeFavorite.favoriteKeyName(), LinkedHashSet<String>.from(favoritesList));
              _setSectionFavorites(dragFavoriteId, true);
              _ensureVisibleHandle(dragFavoriteId);
              HomeFavorite.log(HomeFavorite(dragFavoriteId));
            }
          });
        }
      }
    }
  }

  void _setSectionFavorites(String favoriteId, bool value) {
      List<String>? availableSectionFavorites = JsonUtils.listStringsValue(FlexUI()['home.$favoriteId']);            
      if (availableSectionFavorites != null) {
        Iterable<Favorite> favorites = availableSectionFavorites.map((e) => HomeFavorite(e, category: favoriteId));
        Auth2().prefs?.setListFavorite(favorites, value);
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
}

