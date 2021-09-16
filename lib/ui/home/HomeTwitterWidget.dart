import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:illinois/service/Config.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/Twitter.dart';
import 'package:illinois/ui/WebPanel.dart';
import 'package:illinois/ui/widgets/TrianglePainter.dart';
import 'package:illinois/utils/Utils.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeTwitterWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeTwitterWidget({this.refreshController});

  @override
  _HomeTwitterWidgetState createState() => _HomeTwitterWidgetState();
}

class _HomeTwitterWidgetState extends State<HomeTwitterWidget> implements NotificationsListener {

  List<Tweet> _tweets;

  @override
  void initState() {
    super.initState();

    NotificationService().subscribe(this, [
      Twitter.notifyChanged,
    ]);


    if (widget.refreshController != null) {
      widget.refreshController.stream.listen((_) {
        Twitter().refresh();
      });
    }

    _tweets = _buildTweets();
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  // NotificationsListener

  @override
  void onNotification(String name, dynamic param) {
    if (name == Twitter.notifyChanged) {
      setState(() {
        _tweets = _buildTweets();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: AppCollection.isCollectionNotEmpty(_tweets), child:
      Semantics(container: true, child:
        Column(children: <Widget>[
          _buildHeader(),
          Stack(children:<Widget>[
            _buildSlant(),
            _buildContent(),
          ]),
        ]),
    ));
  }

  Widget _buildHeader() {
    return Container(color: Styles().colors.fillColorPrimary, child:
      Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
        Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Padding(padding: EdgeInsets.only(right: 16), child: Image.asset('images/campus-tools.png')),
          Expanded(child: 
            Text("Twitter", style:
              TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20,),),),
      ],),),);
  }

  Widget _buildSlant() {
    return Column(children: <Widget>[
      Container(color:  Styles().colors.fillColorPrimary, height: 45,),
      Container(color: Styles().colors.fillColorPrimary, child:
        CustomPaint(painter: TrianglePainter(painterColor: Styles().colors.background, left : true), child:
          Container(height: 65,),
        )),
    ],);
  }

  Widget _buildContent() {
    List<Widget> pages = <Widget>[];
    if (_tweets != null) {
      for (Tweet tweet in _tweets) {
        pages.add(_TweetWidget(tweet: tweet,));
      }
    }

    double screenWidth = MediaQuery.of(context).size.width;
    double pageHeight = screenWidth - 20 * 2 + 5;
    double pageViewport = (screenWidth - 40) / screenWidth;
    
    return
      Padding(padding: EdgeInsets.only(top: 10, bottom: 50), child:
        Container(height: pageHeight, child:
          PageView(controller: PageController(viewportFraction: pageViewport), children: pages,)
        )
      );
  }

  static List<Tweet> _buildTweets() {
    List<Tweet> tweets = Twitter().tweets?.tweets;
    if (tweets != null) {
      return (Config().twitterTweetsCount < tweets.length) ? tweets.sublist(0, Config().twitterTweetsCount) : tweets;
    }
    return null;
  }
}

class _TweetWidget extends StatelessWidget {

  final Tweet tweet;

  _TweetWidget({this.tweet});

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: 5, right: 20), child:
      Container(
        decoration: BoxDecoration(
            color: Styles().colors.white,
            boxShadow: [BoxShadow(color: Styles().colors.blackTransparent018, spreadRadius: 1.0, blurRadius: 3.0, offset: Offset(1, 1))],
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(4)) // BorderRadius.all(Radius.circular(4))
        ),
        clipBehavior: Clip.none,
        child:
          Column(children: <Widget>[
            
            Expanded(child: 
              SingleChildScrollView(child:
                Column(children: [
                  AppString.isStringNotEmpty(tweet?.media?.url) ?
                    InkWell(onTap: () => _onTap(context), child:
                      Image.network(tweet?.media?.url)) :
                  Container(),
                  Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
                    //Text(tweet.text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium, fontSize: 16, ),),
                    Html(data: tweet.html,
                      onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
                      style: { "body": Style(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium, fontSize: FontSize(16), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },),
                  ),
                ],)
              ),
            ),

            Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
              Row(children: [
                Expanded(child: AppString.isStringNotEmpty(tweet?.author?.userName) ?
                  //Text("@${tweet?.author?.userName}", style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: 14, ),) :
                  Html(data: tweet?.author?.html,
                    onLinkTap: (url, renderContext, attributes, element) => _launchUrl(url, context: context),
                    style: { "body": Style(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: FontSize(14), padding: EdgeInsets.zero, margin: EdgeInsets.zero), },) :
                  Container(),
                ),
                Text(tweet?.displayTime ?? '', style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: 14, ),),
              ],)
            )
          ])
      )
    );
  }

  void _onTap(BuildContext context) {
    _launchUrl(tweet.detailUrl, context: context);
  }

  void _launchUrl(String url, {BuildContext context}) {
    if (AppString.isStringNotEmpty(url)) {
      if (AppUrl.launchInternal(url)) {
        Navigator.push(context, CupertinoPageRoute(builder: (context) => WebPanel(url: url)));
      } else {
        launch(url);
      }
    }
  }
}