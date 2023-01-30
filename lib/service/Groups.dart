import 'package:flutter/material.dart';
import 'package:rokwire_plugin/service/groups.dart' as rokwire;

class Groups extends rokwire.Groups {

  static String get notifyUserGroupsUpdated             => rokwire.Groups.notifyUserGroupsUpdated;
  static String get notifyUserMembershipUpdated         => rokwire.Groups.notifyUserMembershipUpdated;
  static String get notifyGroupEventsUpdated            => rokwire.Groups.notifyGroupEventsUpdated;
  static String get notifyGroupCreated                  => rokwire.Groups.notifyGroupCreated;
  static String get notifyGroupUpdated                  => rokwire.Groups.notifyGroupUpdated;
  static String get notifyGroupDeleted                  => rokwire.Groups.notifyGroupDeleted;
  static String get notifyGroupPostsUpdated             => rokwire.Groups.notifyGroupPostsUpdated;
  static String get notifyGroupPostReactionsUpdated     => rokwire.Groups.notifyGroupPostReactionsUpdated;
  static String get notifyGroupDetail                   => rokwire.Groups.notifyGroupDetail;

  static String get notifyGroupMembershipRequested      => rokwire.Groups.notifyGroupMembershipRequested;
  static String get notifyGroupMembershipCanceled       => rokwire.Groups.notifyGroupMembershipCanceled;
  static String get notifyGroupMembershipQuit           => rokwire.Groups.notifyGroupMembershipQuit;
  static String get notifyGroupMembershipApproved       => rokwire.Groups.notifyGroupMembershipApproved;
  static String get notifyGroupMembershipRejected       => rokwire.Groups.notifyGroupMembershipRejected;
  static String get notifyGroupMembershipRemoved        => rokwire.Groups.notifyGroupMembershipRemoved;
  static String get notifyGroupMembershipSwitchToAdmin  => rokwire.Groups.notifyGroupMembershipSwitchToAdmin;
  static String get notifyGroupMembershipSwitchToMember => rokwire.Groups.notifyGroupMembershipSwitchToMember;
  static String get notifyGroupMemberAttended           => rokwire.Groups.notifyGroupMemberAttended;

  // Singletone Factory

  @protected
  Groups.internal() : super.internal();

  factory Groups() => ((rokwire.Groups.instance is Groups) ? (rokwire.Groups.instance as Groups) : (rokwire.Groups.instance = Groups.internal()));

  // Service

  @override
  void createService() {
    super.createService();
  }

  @override
  void destroyService() {
    super.destroyService();
  }

  @override
  Future<void> initService() async {
    await super.initService();
  }

}