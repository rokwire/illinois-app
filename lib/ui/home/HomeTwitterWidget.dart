import 'dart:async';
import 'dart:math';

import 'package:expandable_page_view/expandable_page_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:rokwire_plugin/service/app_livecycle.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:illinois/service/Twitter.dart';
import 'package:rokwire_plugin/ui/widgets/triangle_painter.dart';
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTwitterWidget extends StatefulWidget {

  final StreamController<void>? refreshController;

  HomeTwitterWidget({this.refreshController});

  @override
  _HomeTwitterWidgetState createState() => _HomeTwitterWidgetState();
}

class _HomeTwitterWidgetState extends State<HomeTwitterWidget> implements NotificationsListener {

  List<TweetsPage> _tweetsPages = <TweetsPage>[];
  String? _tweetsUserCategory;
  bool _loadingPage = false;
  DateTime? _pausedDateTime;
  PageController? _pageController;
  GlobalKey _viewPagerKey = GlobalKey();

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      AppLivecycle.notifyStateChanged,
      FlexUI.notifyChanged,
    ]);


    if (widget.refreshController != null) {
      widget.refreshController!.stream.listen((_) {
        Future.delayed(Duration.zero, ()
        {
          _refresh(noCache: true);
        });
      });
    }

    _loadingPage = true;
    Twitter().loadTweetsPage(count: Config().twitterTweetsCount, userCategory: userCategory).then((TweetsPage? tweetsPage) {
      Future.delayed(Duration.zero, ()
      {
        if (mounted) {
          setState(() {
            _loadingPage = false;
            if (tweetsPage != null) {
              _tweetsPages.add(tweetsPage);
              _tweetsUserCategory = userCategory;
            }
          });
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
      _onTwitterUserChanged();
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
          Future.delayed(Duration.zero, ()
          {
            _refresh(/*count: Config().twitterTweetsCount*/);
          });
        }
      }
    }
  }

  void _onTwitterUserChanged() {
    if (_tweetsUserCategory != userCategory) {
      Future.delayed(Duration.zero, ()
      {
        _refresh(count: Config().twitterTweetsCount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    int displayPagesCount = tweetsCount + ((_loadingPage == true) ? 1 : 0);
    return Visibility(visible: (0 < displayPagesCount), child:
      Semantics(container: true, child:
        Column(children: <Widget>[
          _buildHeader(),
          Stack(children:<Widget>[
            _buildSlant(),
            _buildContent(),
          ])
        ]),
        )
    );
  }

  Widget _buildHeader() {
    return Semantics(container: true , header: true,
    child: Container(color: Styles().colors!.fillColorPrimary, child:
      Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: EdgeInsets.only(right: 16), child: Image.asset('images/campus-tools.png', excludeFromSemantics: true,)),
          Expanded(child: 
            Text("Twitter", style:
              TextStyle(color: Styles().colors!.white, fontFamily: Styles().fontFamilies!.extraBold, fontSize: 20,),),),
      ],),),));
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
          pages.add(_TweetWidget(tweet: tweet,));
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
      // _needsSecondRefresh = false;
      Future.delayed(Duration.zero, () {
        setState(() {
          _loadingPage = true;
        });
      });
      TweetsPage? lastTweetsPage = (0 < _tweetsPages.length) ? _tweetsPages.last : null;
      Tweet? lastTweet = ((lastTweetsPage?.tweets != null) && (0 < lastTweetsPage!.tweets!.length)) ? lastTweetsPage.tweets!.last : null;
      Twitter().loadTweetsPage(count: Config().twitterTweetsCount, endTimeUtc: lastTweet?.createdAtUtc, userCategory: userCategory).then((TweetsPage? tweetsPage) {
      Future.delayed(Duration.zero, ()
      {
        if (mounted) {
          setState(() {
            _loadingPage = false;
            if (tweetsPage != null) {
              _tweetsPages.add(tweetsPage);
              _tweetsUserCategory = userCategory;
            }
          });
        }
      });
      }).then((_){ //TBD this is workaround for ExpandablePageView getting stuck as last element and need to refresh
        // if(_needsSecondRefresh = true){
        //   _needsSecondRefresh = false;
        //   _refresh(count: tweetsCount + 1);
        // }

      });
    } else if(_loadingPage==true){
      //TBD we stuck on page 3 and need to refresh
      // _needsSecondRefresh = true;
    }
  }

  void _refresh({int? count, bool? noCache}) {
    Future.delayed(Duration.zero, () {
      setState(() {
        _loadingPage = true;
      });
    });
    Twitter().loadTweetsPage(
        count: count ?? max(tweetsCount, Config().twitterTweetsCount!),
        noCache: noCache,
        userCategory: userCategory).then((TweetsPage? tweetsPage) {
          Future.delayed(Duration.zero, ()
          {
            if (mounted) {
              // Future.delayed(Duration.zero,(){
              setState(() {
                _loadingPage = false;
                if (tweetsPage != null) {
                  _tweetsPages = [tweetsPage];
                  _tweetsUserCategory = userCategory;
                }
              });
            }
          });
        Future.delayed((Duration.zero),(){
        if (tweetsPage != null) {
          _pageController!.animateToPage(
              0, duration: Duration(milliseconds: 500), curve: Curves.easeIn);
        }
        }
        );
      });
  }

  String? get userCategory {
    List<dynamic>? twitterUserList = FlexUI()['home.twitter.user'];
    return ((twitterUserList != null) && twitterUserList.isNotEmpty) ? twitterUserList.first : null;
  }
}

class _TweetWidget extends StatelessWidget {

  final Tweet? tweet;

  _TweetWidget({this.tweet});

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
            
            // Expanded(child:
            //   SingleChildScrollView(child:
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
            //   ),
            // ),

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
    return Padding(padding: EdgeInsets.only(bottom: 5, right: 20), child:
      Container(
        decoration: BoxDecoration(
            color: Styles().colors!.white,
            boxShadow: [BoxShadow(color: Styles().colors!.blackTransparent018!, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
        ),
        clipBehavior: Clip.none,
        child:
          Center(child: 
            SizedBox(height: 24, width: 24, child:
              CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color?>(Styles().colors!.fillColorPrimary), )
            ),
          ),
      )
    );
  }
}