import 'dart:async';

import 'package:flutter/material.dart';
import 'package:illinois/model/Twitter.dart';
import 'package:illinois/service/NotificationService.dart';
import 'package:illinois/service/Styles.dart';
import 'package:illinois/service/Twitter.dart';
import 'package:illinois/utils/Utils.dart';

class HomeTwitterWidget extends StatefulWidget {

  final StreamController<void> refreshController;

  HomeTwitterWidget({this.refreshController});

  @override
  _HomeStudentGuideHighlightsWidgetState createState() => _HomeStudentGuideHighlightsWidgetState();
}

class _HomeStudentGuideHighlightsWidgetState extends State<HomeTwitterWidget> implements NotificationsListener {

  List<Tweet> _tweets;
  PageController _pageController = PageController();

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

    _tweets = Twitter().tweets.tweets;
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
        _tweets = Twitter().tweets.tweets;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(visible: AppCollection.isCollectionNotEmpty(_tweets), child:
      Semantics(container: true, child:
          Row(children: <Widget>[
            Column(children: <Widget>[
              _buildHeader(),
              _buildContent(),
            ]),
          ]),
    ));
  }

  Widget _buildHeader() {
    return Container(color: Styles().colors.fillColorPrimary, child:
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Expanded(child: 
          Padding(padding: EdgeInsets.only(left: 20, top: 10, bottom: 10), child:
            Text("Twitter", style:
              TextStyle(color: Styles().colors.white, fontFamily: Styles().fontFamilies.extraBold, fontSize: 20,),),),),
      ],),);
  }

  Widget _buildContent() {
    List<Widget> pages = <Widget>[];
    if (_tweets != null) {
      for (Tweet tweet in _tweets) {
        //pages.add(_TweetWidget(tweet: tweet,));
        pages.add(Center(
          child: Text(tweet.text),
        ));
      }
    }

    return Container(width: 300, height: 300, child:
      Padding(padding: EdgeInsets.symmetric(horizontal: 20, vertical: 30), child: 
        PageView(controller: _pageController, children: pages,)
      ));
  }
}

class _TweetWidget extends StatelessWidget {

  final Tweet tweet;

  _TweetWidget({this.tweet});

  @override
  Widget build(BuildContext context) {
    return Column(children: <Widget>[
      Image.network('https://pbs.twimg.com/media/E_AwJXHXMAU2c_X.jpg'),
      Expanded(child:
        Padding(padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24), child:
          Column(children: <Widget>[
            Text(tweet.text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium, fontSize: 16, ),),
            Padding(padding: EdgeInsets.only(top: 12), child:
              Row(children: [
                Text('@illinois_alma', style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: 14, ),),
                Container(width: 32),
                Text('34 min', style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: 14, ),),
              ],)
            )
          ])
        ),
      ),

    ]);
  }
}