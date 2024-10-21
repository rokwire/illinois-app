/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:neom/model/Analytics.dart';
import 'package:rokwire_plugin/model/group.dart';
import 'package:neom/ext/Group.dart';
import 'package:rokwire_plugin/service/Log.dart';
import 'package:rokwire_plugin/service/groups.dart';
import 'package:rokwire_plugin/service/localization.dart';
import 'package:neom/utils/AppUtils.dart';
import 'package:rokwire_plugin/service/notification_service.dart';
import 'package:rokwire_plugin/service/styles.dart';
import 'package:neom/ui/groups/GroupWidgets.dart';
import 'package:rokwire_plugin/ui/widgets/rounded_button.dart';
import 'package:neom/ui/widgets/TabBar.dart' as uiuc;
import 'package:rokwire_plugin/utils/utils.dart';
import 'package:sprintf/sprintf.dart';

class GroupPostEditPanel extends StatefulWidget with AnalyticsInfo {
  final GroupPost? post;
  final Group? group;

  GroupPostEditPanel({required this.group, this.post});

  @override
  _GroupPostEditPanelState createState() => _GroupPostEditPanelState();

  @override
  AnalyticsFeature? get analyticsFeature => (group?.researchProject == true) ? AnalyticsFeature.ResearchProject : AnalyticsFeature.Groups;

  @override
  Map<String, dynamic>? get analyticsPageAttributes => group?.analyticsAttributes;
}

class _GroupPostEditPanelState extends State<GroupPostEditPanel> implements NotificationsListener {
  static final double _outerPadding = 16;
  //Main Post - Edit/Show
  GroupPost? _post; //Main post {Data Presentation}
  late PostDataModel? _mainPostUpdateData;//Main Post Edit
  List<Member>? _allMembersAllowedToPost;

  bool _loading = false;

  //Scroll and focus utils
  ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollContainerKey = GlobalKey();
  //Refresh
  GlobalKey _postImageHolderKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    NotificationService().subscribe(this, [Groups.notifyGroupPostsUpdated, Groups.notifyGroupPostReactionsUpdated]);
    _loadMembersAllowedToPost();
    _post = widget.post ?? GroupPost(); //If no post then prepare data for post creation
    _mainPostUpdateData = PostDataModel(body:_post?.body, imageUrl: _post?.imageUrl, members: GroupMembersSelectionWidget.constructUpdatedMembersList(selection:_post?.members, upToDateMembers: _allMembersAllowedToPost), dateScheduled: _post?.dateScheduledUtc);
  }

  @override
  void dispose() {
    super.dispose();
    NotificationService().unsubscribe(this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          leading: HeaderBackButton(),
          title: Text(
            Localization().getStringEx('panel.group.detail.post.header.title', 'Post'),
            style:  Styles().textStyles.getTextStyle("widget.heading.regular.extra_fat.light"),),
          centerTitle: false,
          titleSpacing: 0,),
      backgroundColor: Styles().colors.background,
      bottomNavigationBar: uiuc.TabBar(),
      body: _buildContent(),
    );
  }

  Widget _buildContent(){
    return Stack(children: [
      SingleChildScrollView(key: _scrollContainerKey, controller: _scrollController, child:
        Column(children: [
          ImageChooserWidget(key: _postImageHolderKey, buttonVisible: true,
            imageUrl: _mainPostUpdateData?.imageUrl,
            onImageChanged: (url) => _mainPostUpdateData?.imageUrl = url,),
          _buildPostContent(),
        ],)
      ),
      Visibility(
          visible: _loading,
          child: Center(child: CircularProgressIndicator())),
    ]);
  }

  Widget _buildPostContent() {
    TextEditingController bodyController = TextEditingController();
    bodyController.text = _mainPostUpdateData?.body ?? '';
    return Semantics(
        sortKey: OrdinalSortKey(4),
        container: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.only(
                  left: _outerPadding,
                  top: 0,
                  right: _outerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                            padding: EdgeInsets.only(top: 8, bottom: _outerPadding),
                            child: PostInputField(
                              text: _mainPostUpdateData?.body ?? '',
                              onBodyChanged: (text) => _mainPostUpdateData?.body = text,
                              hint: Localization().getStringEx("panel.group.detail.post.edit.hint", "Edit the post"),
                            ),
                        ),
                        Row(children: [
                          Flexible(
                              flex: 1,
                              child: RoundedButton(
                                  label: Localization().getStringEx('panel.group.detail.post.update.button.update.title', 'Update'),
                                  textStyle: Styles().textStyles.getTextStyle("widget.button.title.large.fat"),
                                  borderColor: Styles().colors.fillColorSecondary,
                                  backgroundColor: Styles().colors.surface,
                                  onTap: _onTapUpdateMainPost)),
                        ])
                      ]),
                  Semantics(
                      sortKey: OrdinalSortKey(2),
                      container: true,
                      child: Padding(
                          padding: EdgeInsets.only(top: 4, right: _outerPadding),
                          child: Text(
                            StringUtils.ensureNotEmpty(
                                _post?.member?.displayShortName ),
                            style: Styles().textStyles.getTextStyle("widget.detail.large.thin"),
                          ))),
                  Semantics(
                      sortKey: OrdinalSortKey(3),
                      container: true,
                      child: Padding(
                          padding: EdgeInsets.only(top: 3, right: _outerPadding),
                          child: Text(
                            StringUtils.ensureNotEmpty(
                                _post?.displayDateTime),
                            semanticsLabel:  sprintf(Localization().getStringEx("panel.group.detail.post.updated.ago.format", "Updated %s ago"),[widget.post?.displayDateTime ?? ""]),
                            style: Styles().textStyles.getTextStyle("widget.detail.medium"),))),
                  Container(height: 6,),
                  GroupMembersSelectionWidget(
                    selectedMembers: GroupMembersSelectionWidget.constructUpdatedMembersList(selection:(_mainPostUpdateData?.members), upToDateMembers: _allMembersAllowedToPost),
                    allMembers: _allMembersAllowedToPost,
                    groupId: widget.group?.id,
                    groupPrivacy: widget.group?.privacy,
                    onSelectionChanged: (members){
                      setStateIfMounted(() {
                        _mainPostUpdateData?.members = members;
                      });
                    },),
                  Container(height: 6,),
                  Visibility(visible: widget.post?.dateScheduledUtc != null, child:
                  GroupScheduleTimeWidget(
                    timeZone: null,//TBD pass timezone
                    scheduleTime: widget.post?.dateScheduledUtc,
                    enabled: false, //_isEditMainPost, Disable editing since the BB do not support editing of the create notification
                    onDateChanged: (DateTime? dateTimeUtc){
                      setStateIfMounted(() {
                        Log.d(groupUtcDateTimeToString(dateTimeUtc)??"");
                        _mainPostUpdateData?.dateScheduled = dateTimeUtc;
                      });
                    },
                  )
                  )
                ],
              )),

        ]));
  }

  void _loadMembersAllowedToPost() {
    _setLoading(true);
    Groups().loadMembersAllowedToPost(groupId: widget.group!.id).then((members) {
      _allMembersAllowedToPost = members;
      _setLoading(false);
    });
  }

  void _onTapUpdateMainPost(){
    String? body = _mainPostUpdateData?.body;
    String? imageUrl = _mainPostUpdateData?.imageUrl ?? _post?.imageUrl;
    List<Member>? toMembers = _mainPostUpdateData?.members;
    if (StringUtils.isEmpty(body)) {
      String? validationMsg = Localization().getStringEx('panel.group.detail.post.create.validation.body.msg', "Post message required");
      AppAlert.showDialogResult(context, validationMsg);
      return;
    }
    String htmlModifiedBody = HtmlUtils.replaceNewLineSymbols(body);

    _setLoading(true);
    GroupPost postToUpdate = GroupPost(id: _post?.id, subject: _post?.subject, body: htmlModifiedBody, imageUrl: imageUrl, members: toMembers, dateScheduledUtc: _mainPostUpdateData?.dateScheduled, private: true);
    Groups().updatePost(widget.group?.id, postToUpdate).then((succeeded) {
      _setLoading(false);
      Navigator.of(context).pop();
    });
  }

  void _reloadPost() {
    //TODO: Can we optimize this to only load data for the relevant updated post(s)?
    _setLoading(true);
    Groups().loadGroupPosts(widget.group?.id).then((posts) {
      if (CollectionUtils.isNotEmpty(posts)) {
        try {
          // GroupPost? post = (posts as List<GroupPost?>).firstWhere((post) => (post?.id == _post?.id), orElse: ()=> null); //Remove to fix reload Error: type '() => Null' is not a subtype of type '(() => GroupPost)?' of 'orElse'
          List<GroupPost?> nullablePosts = List.of(posts!);
          _post = nullablePosts.firstWhere((post) => (post?.id == _post?.id), orElse: ()=> null);
        } catch (e) {
          print(e);
        }
        setStateIfMounted(() {}); // Refresh MainPost
      } else {
        _post = null;
      }
      _setLoading(false);
    });
  }

  void _setLoading(bool loading) {
    setStateIfMounted(() {
      _loading = loading;
    });
  }

  //Utils
  GroupPost? deepFindPost(List<GroupPost>? posts, String? id){
    if(CollectionUtils.isEmpty(posts) || StringUtils.isEmpty(id)){
      return null;
    }

    GroupPost? result;
    for(GroupPost post in posts!){
      if(post.id == id){
        result = post;
        break;
      } else {
        result = deepFindPost(post.replies, id);
        if(result!=null){
          break;
        }
      }
    }

    return result;
  }

  // Notifications Listener
  @override
  void onNotification(String name, param) {
    if (name == Groups.notifyGroupPostsUpdated) {
      _reloadPost();
    } else if (name == Groups.notifyGroupPostReactionsUpdated) {
      setStateIfMounted(() { });
    }
  }
}