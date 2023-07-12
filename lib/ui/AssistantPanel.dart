import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:illinois/model/Assistant.dart';
import 'package:illinois/service/Assistant.dart';
import 'package:illinois/service/Auth2.dart';
import 'package:illinois/service/FirebaseMessaging.dart';
import 'package:illinois/service/FlexUI.dart';
import 'package:illinois/service/IlliniCash.dart';
import 'package:illinois/service/SpeechToText.dart';
import 'package:illinois/ui/widgets/HeaderBar.dart';
import 'package:illinois/ui/widgets/TypingIndicator.dart';
import 'package:illinois/utils/AppUtils.dart';
import 'package:rokwire_plugin/model/auth2.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:rokwire_plugin/utils/utils.dart';

class AssistantPanel extends StatefulWidget {

  static const String notifyRefresh      = "edu.illinois.rokwire.assistant.refresh";

  AssistantPanel();

  @override
  _AssistantPanelState createState() => _AssistantPanelState();
}

class _AssistantPanelState extends State<AssistantPanel> with AutomaticKeepAliveClientMixin<AssistantPanel> implements NotificationsListener {

  List<String>? _contentCodes;
  TextEditingController _inputController = TextEditingController();
  ScrollController _scrollController = ScrollController();

  bool _listening = false;

  List<Message> _messages = [];

  bool _loadingResponse = false;
  Message? _feedbackMessage;

  int? _queryLimit = 5;

  List<String>? _userContext;

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
        "Hello! I am the new Illinois Assistant in training. "
            "Ask me anything about the University "
            "--type a question below to get started.",),
        // sources: ["https://google.com", "https://illinois.edu", "https://grad.illinois.edu", "https://uillinois.edu"],
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
        "How many students attend UIUC?"),
      user: true,
      example: true
    ));

    _contentCodes = buildContentCodes();

    _onPullToRefresh();

    _userContext = _getUserContext();

    super.initState();
  }

  @override
  void dispose() {
    NotificationService().unsubscribe(this);
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
          Expanded(child:
            SingleChildScrollView(
              physics: AlwaysScrollableScrollPhysics(),
              controller: _scrollController,
              reverse: true,
              child: Padding(
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

    contentList.add(_buildDisclaimer());

    for (Message message in _messages) {
      contentList.add(_buildChatBubble(message));
      contentList.add(SizedBox(height: 16.0));
    }

    if (_loadingResponse) {
      contentList.add(_buildTypingChatBubble());
      contentList.add(SizedBox(height: 16.0));
    }

    return contentList;
  }

  Widget _buildDisclaimer() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
      child: Text(Localization().getStringEx('',
          'As an in-progress experimental feature, the Illinois Assistant may present inaccurate results '
              'requiring verification with other official university sources. '
              'Your input will be recorded to help improve the Illinois Assistant.'),
        style: Styles().textStyles?.getTextStyle('widget.item.small.thin.italic')
      ),
    );
  }

  Widget _buildChatBubble(Message message) {
    EdgeInsets bubblePadding = message.user ? const EdgeInsets.only(left: 32.0) :
      const EdgeInsets.only(right: 0);

    List<Link>? deepLinks = message.links;

    List<Widget> sourceLinks = [];
    for (String source in message.sources) {
      Uri? uri = Uri.tryParse(source);
      if (uri != null && uri.host.isNotEmpty) {
        sourceLinks.add(Material(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Styles().colors?.fillColorSecondary ?? Colors.white, width: 1),
          ),
          color: Styles().colors?.fillColorPrimaryVariant,
          child: InkWell(
            onTap: () => _onTapSourceLink(source),
            borderRadius: BorderRadius.circular(16.0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(mainAxisSize: MainAxisSize.min,
                children: [
                  Text(uri.host, style: Styles().textStyles?.getTextStyle('widget.title.light.small')),
                  SizedBox(width: 8),
                  Styles().images?.getImage('external-link') ?? Container(),
                ],
              ),
            )
          ),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: bubblePadding,
          child: Row(mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: message.user ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Opacity(
                  opacity: message.example ? 0.5 : 1.0,
                  child: Material(
                    color: message.user ? message.example ? Styles().colors?.background : Styles().colors?.surface : Styles().colors?.fillColorPrimary,
                    borderRadius: BorderRadius.circular(16.0),
                    child: InkWell(
                      onTap: message.example ? () {
                        _messages.remove(message);
                        _submitMessage(message.content);
                      } : null,
                      child: Container(
                        decoration: message.example ? BoxDecoration(borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: Styles().colors?.fillColorPrimary ?? Colors.black)) : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              message.example ?
                                Text(Localization().getStringEx('', "eg. ") + message.content,
                                  style: message.user ? Styles().textStyles?.getTextStyle('widget.title.regular') :
                                  Styles().textStyles?.getTextStyle('widget.title.light.regular'))
                                  : SelectableText(message.content,
                                  style: message.user ? Styles().textStyles?.getTextStyle('widget.title.regular') :
                                  Styles().textStyles?.getTextStyle('widget.title.light.regular')),
                              Visibility(
                                visible: sourceLinks.isNotEmpty,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Wrap(
                                        alignment: WrapAlignment.start,
                                        crossAxisAlignment: WrapCrossAlignment.center,
                                        spacing: 8.0,
                                        runSpacing: 8.0,
                                        children: [
                                          Text(Localization().getStringEx('', "More from the web: "),
                                              style: Styles().textStyles?.getTextStyle('widget.title.light.small.fat')),
                                          ...sourceLinks
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: message.acceptsFeedback,
                child: Column(crossAxisAlignment: CrossAxisAlignment.center,
                  children: [// TODO: Handle material icons in styles images
                    IconButton(onPressed: _onTapFeedbackInfo,
                        icon: Icon(Icons.info_outline,
                            size: 24, color: Styles().colors?.fillColorPrimary),
                        iconSize: 24,
                        splashRadius: 24),
                    IconButton(onPressed: message.feedbackExplanation == null ? () {
                      _sendFeedback(message, true);
                    }: null,
                      icon: Icon(message.feedback == MessageFeedback.good ? Icons.thumb_up : Icons.thumb_up_outlined,
                          size: 24, color: message.feedbackExplanation == null ? Styles().colors?.fillColorPrimary : Styles().colors?.disabledTextColor),
                      iconSize: 24,
                      splashRadius: 24),
                    IconButton(onPressed: message.feedbackExplanation == null ? () {
                      _sendFeedback(message, false);
                    }: null,
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
        Visibility(visible: CollectionUtils.isNotEmpty(deepLinks), child: Padding(
          padding: const EdgeInsets.only(top: 8.0, left: 24.0, right: 32.0),
          child: _buildLinkWidgets(deepLinks),
        ))
      ],
    );
  }

  void _onTapFeedbackInfo() {
    AppAlert.showDialogResult(context, Localization().getStringEx("", "Provide feedback on this response to help us improve the Illinois Assistant!"
        "\n\nIf you found the response helpful and accurate give it a 'thumbs up' to let us know. "
        "\n\nIf you noticed an issue with the response give it a 'thumbs down' and you will "
        "be prompted to provide a brief explanation of the problem."));
  }

  void _sendFeedback(Message message, bool good) {
    if (message.feedbackExplanation != null) {
      return;
    }

    bool bad = false;

    setState(() {
      if (good) {
        if (message.feedback == MessageFeedback.good) {
          message.feedback = null;
        } else {
          message.feedback = MessageFeedback.good;
        }
      } else {
        if (message.feedback == MessageFeedback.bad) {
          message.feedback = null;
        } else {
          message.feedback = MessageFeedback.bad;
          _messages.add(Message(content: Localization().getStringEx('',
              "Thank you for providing feedback! Could you please explain "
                  "the issue with my response?"),
              user: false));
          _feedbackMessage = message;
          bad = true;
        }
      }
    });

    if (!bad && _feedbackMessage != null) {
      _messages.removeLast();
      _feedbackMessage = null;
    }

    Assistant().sendFeedback(message);
  }

  Widget _buildTypingChatBubble() {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: 100,
        height: 50,
        child: Material(
          color: Styles().colors?.fillColorPrimary,
          borderRadius: BorderRadius.circular(16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: TypingIndicator(
              flashingCircleBrightColor: Styles().colors?.surface ?? Colors.white,
              flashingCircleDarkColor: Styles().colors?.fillColorPrimary ?? Colors.black12),
          ),
        ),
      ),
    );
  }

  Widget _buildLinkWidgets(List<Link>? links) {
    List<Widget> linkWidgets = [];
    for (Link link in links ?? []) {
      if (linkWidgets.isNotEmpty) {
        linkWidgets.add(SizedBox(height: 8.0));
      }
      linkWidgets.add(_buildLinkWidget(link));
    }
    return Column(children: linkWidgets);
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
            NotificationService().notify('${FirebaseMessaging.notifyBase}.${link.link}', link.params);
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Visibility(visible: link.iconKey != null, child: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Styles().images?.getImage(link.iconKey ?? '') ?? Container(),
                )),
                Expanded(child: Text(link.name, style: Styles().textStyles?.getTextStyle('widget.title.light.regular'))),
                Styles().images?.getImage('chevron-right-white') ?? Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBar() {
    bool enabled = _feedbackMessage != null || _queryLimit == null || _queryLimit! > 0;
    return Material(
      color: Styles().colors?.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(mainAxisSize: MainAxisSize.max,
              children: [
                Visibility(
                  visible: enabled && SpeechToText().isEnabled,
                  child: IconButton(//TODO: Enable support for material icons in styles images
                    splashRadius: 24,
                    icon: Icon(_listening ? Icons.stop_circle_outlined : Icons.mic, color: Styles().colors?.fillColorSecondary),
                    onPressed: enabled ? () {
                      if (_listening) {
                        _stopListening();
                      } else {
                        _startListening();
                      }
                    } : null,
                  ),
                ),
                Expanded(
                  child: Material(
                    color: Styles().colors?.background,
                    borderRadius: BorderRadius.circular(16.0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        enabled: enabled,
                        controller: _inputController,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        textInputAction: TextInputAction.send,
                        onSubmitted: _submitMessage,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: _feedbackMessage == null ?
                            enabled ? Localization().getStringEx('', 'Type your question here...') :
                              Localization().getStringEx(
                                '', 'Sorry you are out of questions for today. '
                                'Please check back tomorrow to ask more questions!')
                            : Localization().getStringEx('', 'Type your feedback here...'),
                        ),
                        style: Styles().textStyles?.getTextStyle('widget.title.regular')
                      ),
                    ),
                  ),
                ),
                IconButton(//TODO: Enable support for material icons in styles images
                  splashRadius: 24,
                  icon: Icon(Icons.send, color: enabled ? Styles().colors?.fillColorSecondary : Styles().colors?.disabledTextColor),
                  onPressed: enabled ? () {
                    _submitMessage(_inputController.text);
                  }: null,
                ),
              ],
            ),
            _buildQueryLimit(),
            Visibility(visible: Auth2().isDebugManager,
                child: _buildContextButton()),
          ],
        ),
      ),
    );
  }

  Widget _buildQueryLimit() {
    if (_queryLimit == null) {
      return Container();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          height: 10,
          width: 10,
          decoration: BoxDecoration(
            color: (_queryLimit ?? 0) > 0 ? Styles().colors?.saferLocationWaitTimeColorGreen :
              Styles().colors?.saferLocationWaitTimeColorRed,
            shape: BoxShape.circle
          ),
        ),
        SizedBox(width: 8),
        Text(Localization().getStringEx('', "{{query_limit}} questions remaining today")
            .replaceAll('{{query_limit}}', _queryLimit.toString()),
          style: Styles().textStyles?.getTextStyle('widget.title.small'),
        ),
      ]),
    );
  }

  Widget _buildContextButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: RoundedButton(
        label: Localization().getStringEx('', 'Context'),
        onTap: _showContext,
      ),
    );
  }

  Future<void> _showContext() {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        List<String>? userContext = _userContext;
        return StatefulBuilder(
          builder: (context, setStateForDialog) {
          List<Widget> contextFields = [];
          for (int i = 0; i < (_userContext?.length ?? 0); i++) {
            String context = _userContext?[i] ?? '';
            // TextEditingController controller = TextEditingController();
            // controller.text = context;
            contextFields.add(TextFormField(initialValue: context, onChanged: (value) {
              userContext?[i] = value;
            }));
          }
          return AlertDialog(
            title: Text('User Context'),
            content: SingleChildScrollView(
              child: ListBody(
                children: contextFields,
              ),
            ),
            actions: [
              RoundedButton(
                label: Localization().getStringEx('', 'Add'),
                onTap: () {
                  setStateForDialog(() {
                    if (userContext == null) {
                      userContext = [];
                    }
                    userContext?.add('');
                  });
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: RoundedButton(
                  label: Localization().getStringEx('', 'Profile 1'),
                  onTap: () {
                    _userContext = _getUserContext(
                        name: 'John Doe',
                        netID: 'jdoe',
                        college: 'Media',
                        department: 'Journalism',
                        studentLevel: 'Sophomore'
                    );
                    Navigator.of(context).pop();
                    _showContext();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: RoundedButton(
                  label: Localization().getStringEx('', 'Profile 2'),
                  onTap: () {
                    _userContext = _getUserContext(
                        name: 'Jane Smith',
                        netID: 'jsmith',
                        college: 'Grainger Engineering',
                        department: 'Electrical and Computer Engineering',
                        studentLevel: 'Senior'
                    );
                    Navigator.of(context).pop();
                    _showContext();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: RoundedButton(
                  label: Localization().getStringEx('', 'Save'),
                  onTap: () {
                    userContext?.removeWhere((element) => element.isEmpty);
                    _userContext = userContext;
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          );
        });
      },
    );
  }

  Future<void> _submitMessage(String message) async {
    if (_loadingResponse) {
      return;
    }

    setState(() {
      if (message.isNotEmpty) {
        _messages.add(Message(content: message, user: true));
      }
      _inputController.text = '';
      _loadingResponse = true;
    });

    if (_feedbackMessage != null) {
      _feedbackMessage?.feedbackExplanation = message;
      Message? response = await Assistant().sendFeedback(_feedbackMessage!);
      setState(() {
        if (response != null){
          _messages.add(response);
        } else {
          _messages.add(Message(
              content: Localization().getStringEx('', 'Thank you for the explanation! '
                  'Your response has been recorded and will be used to improve results in the future.'),
              user: false));
        }
        _loadingResponse = false;
      });
      _feedbackMessage = null;
      return;
    }

    int? limit = _queryLimit;
    if (limit != null && limit <= 0) {
      setState(() {
        _messages.add(Message(
            content: Localization().getStringEx(
                '', 'Sorry you are out of questions for today. '
                'Please check back tomorrow to ask more questions!'),
            user: false));
      });
      return;
    }

    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: Duration(seconds: 1),
      curve: Curves.fastOutSlowIn,
    );

    Message? response = await Assistant().sendQuery(message, context: _userContext);
    if (mounted) {
      setState(() {
        if (response != null){
          _messages.add(response);
          if (_queryLimit != null) {
            if (response.queryLimit != null) {
              _queryLimit = response.queryLimit;
            } else {
              _queryLimit = _queryLimit! - 1;
            }
          }
        } else {
          _messages.add(Message(content: Localization().getStringEx('', 'Sorry something went wrong! Please try asking your question again.'), user: false));
          _inputController.text = message;
        }
        _loadingResponse = false;
      });
    }
  }

  List<String>? _getUserContext({String? name, String? netID, String? college, String? department, String? studentLevel}) {
    List<String> context = [];

    name ??= Auth2().profile?.fullName;
    if (name != null) {
      context.add('My name is $name');
    }

    netID ??= Auth2().netId;
    if (netID != null) {
      context.add('My netID is $netID');
    }

    college ??= IlliniCash().studentClassification?.collegeName;
    department ??= IlliniCash().studentClassification?.departmentName;
    if (college != null && department != null) {
      context.add('I am a student in the $department department in the $college college');
    }
    studentLevel ??= IlliniCash().studentClassification?.studentLevelDescription;
    if (studentLevel != null) {
      context.add('I have $studentLevel standing as a student');
    }

    return context.isNotEmpty ? context : null;
  }

  void _onTapSourceLink(String source) {
    UrlUtils.launchExternal(source);
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
    if (mounted) {
      Assistant().getQueryLimit().then((limit) {
        if (limit != null) {
          setState(() {
            _queryLimit = limit;
          });
        }
      });
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