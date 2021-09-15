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
        Column(children: <Widget>[
          _buildHeader(),
          _buildContent(),
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
        pages.add(_TweetWidget(tweet: tweet,));
      }
    }

    double screenWidth = MediaQuery.of(context).size.width;
    
    return 
      Padding(padding: EdgeInsets.symmetric(vertical: 20), child: Container(
        height: screenWidth - 20 * 2 + 5,
        child:
          PageView(controller: PageController(viewportFraction: (screenWidth - 40) / screenWidth ), children: pages,)
        )
      );
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
            AppString.isStringNotEmpty(tweet?.media?.url) ? Image.network(tweet?.media?.url) : Container(),
            Expanded(child:
              Padding(padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20), child:
                Column(children: <Widget>[
                  Expanded(child:
                    Text(tweet.text, style: TextStyle(color: Styles().colors.fillColorPrimary, fontFamily: Styles().fontFamilies.medium, fontSize: 16, ),),
                  ),
                  Padding(padding: EdgeInsets.only(top: 12), child:
                    Row(children: [
                      Text(tweet.author.name, style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: 14, ),),
                      Container(width: 32),
                      Text('34 min', style: TextStyle(color: Styles().colors.textSurface, fontFamily: Styles().fontFamilies.medium, fontSize: 14, ),),
                    ],)
                  )
                ])
              ),
            ),

          ])
      )
    );
  }
}