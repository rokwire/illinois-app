import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Assistant.dart';
import 'package:illinois/service/DeepLink.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AssistantPanel extends StatefulWidget {

  static const String notifyRefresh      = "edu.illinois.rokwire.assistant.refresh";

  AssistantPanel();

  @override
  _AssistantPanelState createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> with AutomaticKeepAliveClientMixin<AssistantPanel> implements NotificationsListener {

  List<String>? _contentCodes;
  StreamController<String> _updateController = StreamController.broadcast();
  TextEditingController _inputController = TextEditingController();

  bool _listening = false;

  List<Message> _messages = [];

  bool _loadingResponse = false;

  @override
  void initState() {
    NotificationService().subscribe(this, [
      FlexUI.notifyChanged,
      Auth2UserPrefs.notifyFavoritesChanged,
      Localization.notifyStringsUpdated,
      Styles.notifyChanged,
      SpeechToText.notifyError,
    ]);

    _messages.add(Message(content: Localization().getStringEx('',
        "Hey there! I'm the Illinois Assistant. "
            "You can ask me anything about the University. "
            "Type a question below to get started."),
        user: false));

    // _messages.add(Message(content: Localization().getStringEx('',
    //     "Where can I find out more about the resources available on campus?"),
    //     user: true,
    // ));

    // _messages.add(Message(content: Localization().getStringEx('',
    //     "There are many resources available for students on campus. "
    //         "Try checking out the Campus Guide for more information."),
    //     user: false,
    //     link: Link(name: "Campus Guide", link: '${DeepLink().appUrl}/guide',
    //         iconKey: 'guide')));

    _messages.add(Message(content: Localization().getStringEx('',
        "What's for dinner at my dining hall today?"),
      user: true,
      example: true
    ));
    
    _contentCodes = buildContentCodes();
    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
    _updateController.close();
    super.dispose();
  }

  // AutomaticKeepAliveClientMixin
  @override
  bool get wantKeepAlive => true;


  // NotificationsListener
  @override
  void onNotification(String name, dynamic param) {
    if (name == FlexUI.notifyChanged) {
      _updateContentCodes();
      if (mounted) {
        setState(() { });
      }
    }
    else if((name == Auth2UserPrefs.notifyFavoritesChanged) ||
      (name == Localization.notifyStringsUpdated) ||
      (name == Styles.notifyChanged)) {
      if (mounted) {
        setState(() { });
      }
    }
    else if (name == SpeechToText.notifyError) {
      setState(() {
        _listening = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      appBar: RootHeaderBar(title: Localization().getStringEx('panel.assistant.label.title', 'Assistant')),
      body: RefreshIndicator(onRefresh: _onPullToRefresh, child:
        Column(children: [
          _buildDisclaimer(),
          Expanded(child:
            SingleChildScrollView(reverse: true, child:
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(children: _buildContentList(),),
              )
            )
          ),
          _buildChatBar(),
        ]),
      ),
      backgroundColor: Styles().colors!.background,
      bottomNavigationBar: null,
    );
  }

  List<Widget> _buildContentList() {
    List<Widget> contentList = <Widget>[];

    for (Message message in _messages) {
      contentList.add(_buildChatBubble(message));
      contentList.add(SizedBox(height: 16.0));
    }

    if (_loadingResponse) {
      contentList.add(_buildChatBubble(Message(content: '...', user: false), hideFeedback: true));
      contentList.add(SizedBox(height: 16.0));
    }

    return contentList;
  }

  Widget _buildDisclaimer() {
    return Container(
      color: Styles().colors?.fillColorPrimary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Flexible(child: Text(Localization().getStringEx('',
            'This is an experimental feature which may present inaccurate results. '
                'Please verify all information with official University sources. '
                'Your input will be recorded to improve the quality of results.'),
          style: Styles().textStyles?.getTextStyle('widget.title.light.regular')
        )),
      ),
    );
  }

  Widget _buildChatBubble(Message message, {bool hideFeedback = false}) {
    EdgeInsets bubblePadding = message.user ? const EdgeInsets.only(left: 32.0) :
      const EdgeInsets.only(right: 0);
    Link? link = message.link;

    List<Widget> sourceLinks = [];
    for (String source in message.sources) {
      Uri? uri = Uri.tryParse(source);
      if (uri != null) {
        sourceLinks.add(Material(
          borderRadius: BorderRadius.circular(8.0),
          child: Text(uri.host),
        ));
      }
    }

    return Align(
      alignment: message.user ? AlignmentDirectional.centerEnd : AlignmentDirectional.centerStart,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: bubblePadding,
            child: Row(mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Opacity(
                    opacity: message.example ? 0.5 : 1.0,
                    child: Material(
                      color: message.user ? message.example ? Styles().colors?.background : Styles().colors?.surface : Styles().colors?.fillColorPrimary,
                      borderRadius: BorderRadius.circular(16.0),
                      child: InkWell(
                        onTap: message.example ? () {
                          setState(() {
                            _messages.remove(message);
                            _messages.add(Message(content: message.content, user: true));
                          });
                        } : null,
                        child: Container(
                          decoration: message.example ? BoxDecoration(borderRadius: BorderRadius.circular(16.0),
                              border: Border.all(color: Styles().colors?.fillColorPrimary ?? Colors.black)) : null,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: message.example ?
                              Text(Localization().getStringEx('', "eg. ") + message.content,
                                  style: message.user ? Styles().textStyles?.getTextStyle('widget.title.regular') :
                                  Styles().textStyles?.getTextStyle('widget.title.light.regular'))
                              : SelectableText(message.content,
                              style: message.user ? Styles().textStyles?.getTextStyle('widget.title.regular') :
                                Styles().textStyles?.getTextStyle('widget.title.light.regular')),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: !message.user && !hideFeedback,
                  child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                    children: [// TODO: Handle material icons in styles images
                      IconButton(onPressed: () {
                        setState(() {
                          if (message.feedback == MessageFeedback.good) {
                            message.feedback = null;
                          } else {
                            message.feedback = MessageFeedback.good;
                          }
                        });
                      },
                        icon: Icon(message.feedback == MessageFeedback.good ? Icons.thumb_up : Icons.thumb_up_outlined,
                            size: 24, color: Styles().colors?.fillColorPrimary),
                        iconSize: 24,
                        splashRadius: 24),
                      IconButton(onPressed: () {
                        setState(() {
                          if (message.feedback == MessageFeedback.bad) {
                            message.feedback = null;
                          } else {
                            message.feedback = MessageFeedback.bad;
                          }
                        });
                      },
                        icon: Icon(message.feedback == MessageFeedback.bad ? Icons.thumb_down :Icons.thumb_down_outlined,
                            size: 24, color: Styles().colors?.fillColorPrimary),
                        iconSize: 24,
                        splashRadius: 24),
                    ],
                  ),
                )
              ],
            ),
          ),
          Visibility(visible: link != null, child: Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 24.0, right: 32.0),
            child: _buildLinkWidget(link),
          ))
        ],
      ),
    );
  }

  Widget _buildLinkWidget(Link? link) {
    if (link == null) {
      return Container();
    }
    EdgeInsets padding = const EdgeInsets.only(right: 32.0);
    return Padding(
      padding: padding,
      child: Material(
        color: Styles().colors?.fillColorPrimary,
        borderRadius: BorderRadius.circular(8.0),
        child: InkWell(
          borderRadius: BorderRadius.circular(8.0),
          onTap: () {
            if (DeepLink().isAppUrl(link.link)) {
              DeepLink().launchUrl(link.link);
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Visibility(visible: link.iconKey != null, child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Styles().images?.getImage(link.iconKey ?? '') ?? Container(),
                )),
                Text(link.name, style: Styles().textStyles?.getTextStyle('widget.title.light.regular')),
                Expanded(child: Container()),
                Styles().images?.getImage('chevron-right-white') ?? Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBar() {
    return Material(
      color: Styles().colors?.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Row(mainAxisSize: MainAxisSize.max,
          children: [
            Visibility(
              visible: SpeechToText().isEnabled,
              child: IconButton(//TODO: Enable support for material icons in styles images
                splashRadius: 24,
                icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic, color: Styles().colors?.fillColorSecondary),
                onPressed: () {
                  if (_listening) {
                    _stopListening();
                  } else {
                    _startListening();
                  }
                },
              ),
            ),
            Expanded(
              child: Material(
                color: Styles().colors?.background,
                borderRadius: BorderRadius.circular(16.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Expanded(
                    child: TextField(
                      controller: _inputController,
                      minLines: 1,
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _submitMessage,
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: Localization().getStringEx('', 'Type your question here...'),
                      ),
                      style: Styles().textStyles?.getTextStyle('widget.title.regular')
                    ),
                  ),
                ),
              ),
            ),
            IconButton(//TODO: Enable support for material icons in styles images
              splashRadius: 24,
              icon: Icon(Icons.send, color: Styles().colors?.fillColorSecondary),
              onPressed: () {
                _submitMessage(_inputController.text);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitMessage(String message) async {
    setState(() {
      if (message.isNotEmpty) {
        _messages.add(Message(content: message, user: true));
      }
      _inputController.text = '';
      _loadingResponse = true;
    });

    Message? response = await Assistant().sendQuery(message);
    if (response != null && mounted) {
      setState(() {
        _messages.add(response);
        _loadingResponse = false;
      });
    }
  }

  void _startListening() {
    SpeechToText().listen(onResult: _onSpeechResult);
    setState(() {
      _listening = true;
    });
  }

  void _stopListening() async {
    await SpeechToText().stopListening();
    setState(() {
      _listening = false;
    });
  }

  void _onSpeechResult(String result, bool finalResult) {
    setState(() {
      _inputController.text = result;
      if (finalResult) {
        _listening = false;
      }
    });
  }

  void _updateContentCodes() {
    List<String>?  contentCodes = buildContentCodes();
    if ((contentCodes != null) && !DeepCollectionEquality().equals(_contentCodes, contentCodes)) {
      if (mounted) {
        setState(() {
          _contentCodes = contentCodes;
        });
      }
      else {
        _contentCodes = contentCodes;
      }
    }
  }
  
  Future<void> _onPullToRefresh() async {
    _updateController.add(AssistantPanel.notifyRefresh);
    if (mounted) {
      setState(() {});
    }
  }

  static List<String>? buildContentCodes() {
    List<String>? codes = JsonUtils.listStringsValue(FlexUI()['assistant']);
    // codes?.sort((String code1, String code2) {
    //   String title1 = _BrowseSection.title(sectionId: code1);
    //   String title2 = _BrowseSection.title(sectionId: code2);
    //   return title1.toLowerCase().compareTo(title2.toLowerCase());
    // });
    return codes;
  }
}