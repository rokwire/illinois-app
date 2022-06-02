import 'dart:async';
import 'dart:math';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:illinois/service/Analytics.dart';
import 'package:illinois/service/Storage.dart';
import 'package:illinois/ui/home/HomePanel.dart';
import 'package:illinois/ui/home/HomeWidgets.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
//import 'package:rokwire_plugin/service/config.dart' as rokwire;
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/service/Twitter.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTwitterWidget extends StatefulWidget {

  final String? favoriteId;
  final StreamController<String>? updateController;
  final HomeDragAndDropHost? dragAndDropHost;

  HomeTwitterWidget({Key? key, this.favoriteId, this.updateController, this.dragAndDropHost}) : super(key: key);

  @override
  _HomeTwitterWidgetState createState() => _HomeTwitterWidgetState();
}

class _HomeTwitterWidgetState extends State<HomeTwitterWidget> implements NotificationsListener {

  List<TweetsPage> _tweetsPages = <TweetsPage>[];
  String? _tweetsAccountKey;
  String? _selectedAccountKey;
  bool _loadingPage = false;
  DateTime? _pausedDateTime;
  PageController? _pageController;
  GlobalKey _viewPagerKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _selectedAccountKey = Storage().selectedTwitterAccount;
    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      FlexUI.notifyChanged,
    ]);


    if (widget.updateController != null) {
      widget.updateController!.stream.listen((String command) {
        if (command == HomePanel.notifyRefresh) {
          _refresh(noCache: true);
        }
      });
    }

    _loadingPage = true;
    String? accountKey = _currentAccountKey;
    Twitter().loadTweetsPage(count: Config().twitterTweetsCount, accountKey: accountKey).then((TweetsPage? tweetsPage) {
      _setState(() {
        _loadingPage = false;
        if (tweetsPage != null) {
          _tweetsPages.add(tweetsPage);
          _tweetsAccountKey = accountKey;
        }
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == AppLivecycle.notifyStateChanged) {
      _onAppLivecycleStateChanged(param);
    }
    else if (name == FlexUI.notifyChanged) {
      _onTwitterAccountChanged();
    }
  }

  void _onAppLivecycleStateChanged(AppLifecycleState? state) {
    if (state == AppLifecycleState.paused) {
      _pausedDateTime = DateTime.now();
    }
    else if (state == AppLifecycleState.resumed) {
      if (_pausedDateTime != null) {
        Duration pausedDuration = DateTime.now().difference(_pausedDateTime!);
        if (Config().refreshTimeout < pausedDuration.inSeconds) {
          _refresh(/*count: Config().twitterTweetsCount*/);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    int displayPagesCount = tweetsCount + ((_loadingPage == true) ? 1 : 0);
    return Visibility(visible: (0 < displayPagesCount), child:
      HomeDropTargetWidget(favoriteId: widget.favoriteId, dragAndDropHost: widget.dragAndDropHost, child:
        Semantics(container: true, child:
          Column(children: <Widget>[
            _buildHeader(),
            (widget.dragAndDropHost == null) ?
              Stack(children:<Widget>[
                _buildSlant(),
                _buildContent(),
              ]) :
              Container(height: 3,),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Semantics(child:
      Padding(padding: EdgeInsets.zero, child: 
        Container(color: Styles().colors!.fillColorPrimary, child:
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

            (widget.dragAndDropHost != null) ?
              Semantics(label: 'Drag Handle' /* TBD: Localization */, button: true, child:
                Draggable<HomeFavorite>(
                  data: HomeFavorite(widget.favoriteId),
                  onDragStarted: () { widget.dragAndDropHost?.isDragging = true; },
                  onDragEnd: (details) { widget.dragAndDropHost?.isDragging = false; },
                  onDragCompleted: () { widget.dragAndDropHost?.isDragging = false; },
                  onDraggableCanceled: (velocity, offset) { widget.dragAndDropHost?.isDragging = false; },
                  feedback: HomeSlantFeedback(title: 'Twitter'),
                  childWhenDragging: HomeDragHandle(),
                  child: HomeDragHandle()
                ),
              ) :
            HomeTitleIcon(image: Image.asset('images/campus-tools.png')),

            Expanded(child:
              Padding(padding: EdgeInsets.only(top: 14), child:
                Semantics(label: 'Twitter', header: true, excludeSemantics: true, child:
                  Text('Twitter', style: TextStyle(color: Styles().colors?.textColorPrimary, fontFamily: Styles().fontFamilies?.extraBold, fontSize: 20),)
                )
              )
            ),

            ((1 < _accountKeys.length) && (widget.dragAndDropHost == null)) ?
              Semantics(container: true,  button: true, child: buildAccountDropDown(), ) :
              Container(),

            HomeFavoriteButton(favoriteId: widget.favoriteId,),
            
        ],),),),);
  }

  Widget buildAccountDropDown() {
    String? currentAccountName = twitterAccountName(_currentAccountKey);

    return Semantics(label: currentAccountName, hint: "Double tap to select account", button: true, container: true, child:
      DropdownButtonHideUnderline(child:
        DropdownButton<String>(
          icon: Padding(padding: EdgeInsets.only(left: 4), child: Image.asset('images/icon-down-white.png')),
          isExpanded: false,
          style: TextStyle(color: Styles().colors?.white, fontFamily: Styles().fontFamilies?.medium, fontSize: 16, ),
          hint: (currentAccountName != null) ? Text(currentAccountName, style: TextStyle(color: Styles().colors?.white, fontFamily: Styles().fontFamilies?.medium, fontSize: 16)) : null,
          items: _buildDropDownItems(),
          onChanged: _onDropDownValueChanged
        ),
      ),
    );
  }

  List<DropdownMenuItem<String>>? _buildDropDownItems() {
    List<DropdownMenuItem<String>> dropDownItems = [];
    for (String accountKey in _accountKeys) {
      String? accountName = twitterAccountName(accountKey);
      dropDownItems.add(DropdownMenuItem<String>(value: accountKey, child:
        // BlockSemantics(blocking: true, child:
          Semantics(label: accountName, hint: "Double tap to select account", button:false, excludeSemantics: true,child:
            Text(accountName ?? '', style: TextStyle(color: Styles().colors?.fillColorPrimary, fontFamily: Styles().fontFamilies?.medium, fontSize: 16)),
          )
        // )
      ));
    }
    return dropDownItems;
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors!.fillColorPrimary, height: 45,),
      Container(color: Styles().colors!.fillColorPrimary, child:
        CustomPaint(painter: TrianglePainter(painterColor: Styles().colors!.background, horzDir: TriangleHorzDirection.rightToLeft), child:
          Container(height: 65,),
        )),
    ],);
  }

  Widget _buildContent() {
    List<Widget> pages = <Widget>[];
    for (TweetsPage tweetsPage in _tweetsPages) {
      if (tweetsPage.tweets != null) {
        for (Tweet? tweet in tweetsPage.tweets!) {
          bool isFirst = pages.isEmpty;
          pages.add(_TweetWidget(
            tweet: tweet,
            onTapPrevious: isFirst? null : _onTapPrevious,
            onTapNext: _onTapNext,
          ));
        }
      }
    }

    if (_loadingPage == true) {
      pages.add(_TweetLoadingWidget());
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double pageHeight = screenWidth - 20 * 2 + 5;
    double pageViewport = (screenWidth - 40) / screenWidth;
    
    if (_pageController == null) {
      _pageController = PageController(viewportFraction: pageViewport, keepPage: true, initialPage: 0);
    }

    return
      Padding(padding: EdgeInsets.only(top: 10, bottom: 50), child:
        Container(
          constraints: BoxConstraints(minHeight: 20),
          child: ExpandablePageView(key: _viewPagerKey, controller: _pageController, onPageChanged: _onPageChanged, children: pages, estimatedPageSize: pageHeight,)
        )
      );
  }

  int get tweetsCount {
    int tweetsCount = 0;
    for (TweetsPage tweetsPage in _tweetsPages) {
      tweetsCount += (tweetsPage.tweets?.length ?? 0);
    }
    return tweetsCount;
  }

  void _onPageChanged(int index) {
    if ((tweetsCount <= (index + 1)) && (_loadingPage != true)) {
      _setStateDelayed(() {
        _loadingPage = true;
      });
      TweetsPage? lastTweetsPage = (0 < _tweetsPages.length) ? _tweetsPages.last : null;
      Tweet? lastTweet = ((lastTweetsPage?.tweets != null) && (0 < lastTweetsPage!.tweets!.length)) ? lastTweetsPage.tweets!.last : null;
      String? accountKey = _currentAccountKey;
      Twitter().loadTweetsPage(count: Config().twitterTweetsCount, endTimeUtc: lastTweet?.createdAtUtc, accountKey: accountKey).then((TweetsPage? tweetsPage) {
        _setState(() {
          _loadingPage = false;
          if (tweetsPage != null) {
            _tweetsPages.add(tweetsPage);
            _tweetsAccountKey = accountKey;
          }
        });
      });
    }
  }

  void _refresh({int? count, bool? noCache}) {
    _setState(() {
      _loadingPage = true;
    });
    String? accountKey = _currentAccountKey;
    Twitter().loadTweetsPage(
        count: count ?? max(tweetsCount, Config().twitterTweetsCount!),
        noCache: noCache,
        accountKey: accountKey).then((TweetsPage? tweetsPage) {
          _setState(() {
            _loadingPage = false;
            if (tweetsPage != null) {
              _tweetsPages = [tweetsPage];
              _tweetsAccountKey = accountKey;
            }
          });
        // Future.delayed((Duration.zero),(){
        if (mounted && (tweetsPage != null)) {
          _pageController!.animateToPage(
              0, duration: Duration(milliseconds: 500), curve: Curves.easeIn);
        }
        // });
      });
  }

  void _onTapPrevious(){
   _pageController?.previousPage(duration:  Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  void _onTapNext(){
    _pageController?.nextPage(duration:  Duration(milliseconds: 500), curve: Curves.easeIn);
  }

  String get _currentAccountKey => _selectedAccountKey ?? _defaultAccountKey;

  static String get _defaultAccountKey => _accountKeys.first;

  static List<String> get _accountKeys => JsonUtils.listStringsValue(FlexUI()['home.twitter.account']) ?? [ Config.twitterDefaultAccountKey ];

  static String? twitterAccountName(String accountKey) {
    String? accountName = Config().twitterAccountName(accountKey);
    return (accountName != null) ? "@$accountName" : null;
  }

  void _onDropDownValueChanged(String? value) {
    Analytics().logSelect(target: "Twitter account selected: $value");
    Storage().selectedTwitterAccount = _selectedAccountKey = (value != _defaultAccountKey) ? value : null;
    _refresh(count: Config().twitterTweetsCount);
  }

  void _onTwitterAccountChanged() {
    if ((_selectedAccountKey != null) && (!_accountKeys.contains(_selectedAccountKey) || (_selectedAccountKey == _defaultAccountKey))) {
      Storage().selectedTwitterAccount = _selectedAccountKey = null;
    }
    if ((_tweetsAccountKey != _currentAccountKey)) {
      _refresh(count: Config().twitterTweetsCount);
    }
    else if (mounted) {
      setState(() {});
    }
  }

  void _setState(VoidCallback fn) {
    if (mounted) {
      setState(fn);
    }
  }

  void _setStateDelayed(VoidCallback fn, { Duration duration = Duration.zero }) {
    Future.delayed(duration, () {
      if (mounted) {
        setState(fn);
      }
    });
  }
}

class _TweetWidget extends StatelessWidget {

  final Tweet? tweet;
  final void Function()? onTapNext;
  final void Function()? onTapPrevious;

  _TweetWidget({this.tweet, this.onTapNext, this.onTapPrevious});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: 5, right: 20), child:
      Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
        ),
        clipBehavior: Clip.none,
        child:
          Column(children: <Widget>[
                Column(children: [
                  StringUtils.isNotEmpty(tweet?.media?.imageUrl) ?
                    InkWell(onTap: () => _onTap(context), child:
                      Image.network(tweet!.media!.imageUrl!, excludeFromSemantics: true)) :
                  Container(),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
                    //Text(tweet.text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium, fontSize: 16, ),),
                    Html(data: tweet!.html,
                      onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
                      style: { "body": Style(color: Styles().colors!.fillColorPrimary, fontFamily: Styles().fontFamilies!.medium, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
                  ),
                ],),
            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
              Row(children: [
                Expanded(child: StringUtils.isNotEmpty(tweet?.author?.userName) ?
                  //Text("@${tweet?.author?.userName}", style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: 14, ),) :
                  Html(data: tweet?.author?.html,
                    onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
                    style: { "body": Style(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.medium, fontSize: FontSize(14), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },) :
                  Container(),
                ),
                Text(tweet?.displayTime ?? '', style: TextStyle(color: Styles().colors!.textSurface, fontFamily: Styles().fontFamilies!.medium, fontSize: 14, ),),
              ],)
            ),

            Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Visibility(
                  visible: onTapPrevious!=null,
                  child: Semantics(
                    label: "Previous Page",
                    button: true,
                    child: GestureDetector(
                      onTap: onTapPrevious?? (){},
                      child: Container(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          "<",
                          semanticsLabel: "",
                          style: TextStyle(
                            color : Styles().colors!.fillColorPrimary,
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: 26,
                          ),),)
                    )
                  )
                ),
                Visibility(
                  visible: onTapNext!=null,
                  child: Semantics(
                    label: "Next Page",
                    button: true,
                    child: GestureDetector(
                      onTap: onTapNext?? (){},
                      child: Container(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          ">",
                          semanticsLabel: "",
                          style: TextStyle(
                            color : Styles().colors!.fillColorPrimary,
                            fontFamily: Styles().fontFamilies!.bold,
                            fontSize: 26,
                          ),),)
                    )
                  )
                )
              ],
            )
          ])
      )
    );
  }

  void _onTap(BuildContext context) {
    _launchUrl(tweet!.detailUrl, context: context);
  }

  void _launchUrl(String? url, {BuildContext? context}) {
    if (StringUtils.isNotEmpty(url)) {
      launch(url!);
    }
  }
}

class _TweetLoadingWidget extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: 24, vertical: 24), child:
      Container(
        color: Colors.transparent,
        clipBehavior: Clip.none,
        child:
          Center(child: 
            SizedBox(height: 24, width: 24, child:
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.white), )
            ),
          ),
      )
    );
  }
}