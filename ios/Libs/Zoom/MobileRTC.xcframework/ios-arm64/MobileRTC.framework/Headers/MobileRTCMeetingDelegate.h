//
//  MobileRTCMeetingDelegate.h
//  MobileRTC
//
//  Created by Robust on 2017/11/14.
//  Copyright © 2019年 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileRTCVideoRawData.h"
#import "MobileRTCAudioRawData.h"
#import "MobileRTCBORole.h"
#import "MobileRTCReturnToMainSessionHandler.h"
#import "MobileRTCPreProcessRawData.h"
#import "MobileRTCAudioSender.h"
#import "MobileRTCVideoSender.h"
#import "MobileRTCShareSender.h"
#import "MobileRTCVideoCapabilityItem.h"
#import "MobileRTCLiveTranscriptionLanguage.h"
#import "MobileRTCRawLiveStreamInfo.h"
#import "MobileRTCRequestRawLiveStreamPrivilegeHandler.h"

@class MobileRTCInterpretationLanguage;
@class MobileRTCMeetingParameter;
@class MobileRTCSignInterpreterLanguage;
@class MobileRTCRequestLocalRecordingPrivilegeHandler;

#pragma mark - MobileRTCMeetingServiceDelegate
/*!
 @protocol MobileRTCMeetingServiceDelegate
 @brief Delegate containing callbacks related to meeting state updates.
 */  
@protocol MobileRTCMeetingServiceDelegate <NSObject>
@optional
/*!
 @brief An error has occurred.
 @param error The error code. See [MobileRTCMeetError].
 @param message The message of the error.
 */
- (void)onMeetingError:(MobileRTCMeetError)error message:(NSString * _Nullable)message;

/*!
 @brief Notify the user that the meeting state has changed.
 @param state The new meeting state. [MobileRTCMeetingState].
 */
- (void)onMeetingStateChange:(MobileRTCMeetingState)state;

/*!
 @brief The meeting parameters have been updated.
 @param meetingParam meetingParam Meeting parameter. See [MobileRTCMeetingParameter].
 */
- (void)onMeetingParameterNotification:(MobileRTCMeetingParameter *_Nullable)meetingParam;

/*!
 @brief The meeting has been joined successfully.
 */
- (void)onJoinMeetingConfirmed;

/*!
 @brief The meeting is ready.
 */
- (void)onMeetingReady;

/*!
 @brief Join a meeting without a host. You can show or hide the custom JBH waiting UI.
 @param cmd Show/Hide JBH command.
 */
- (void)onJBHWaitingWithCmd:(JBHCmd)cmd;

/*!
 @brief Determine if the current user has cloud recording privileges.
 @param result The result of checking CMR privilege.
 */
- (void)onCheckCMRPrivilege:(MobileRTCCMRError)result;

/*!
 @brief @brief The cloud recording status has changed.
 @param status The new recording status.
 */
- (void)onRecordingStatus:(MobileRTCRecordingStatus)status;

/*!
 @brief The local recording status has changed.
 @param userId The ID of the user who caused the change.
 @param status The new recording status.
 */
- (void)onLocalRecordingStatus:(NSInteger)userId status:(MobileRTCRecordingStatus)status;

/*!
 @brief The meeting has ended.
 @param reason The reason why the meeting has ended. See [MobileRTCMeetingEndReason].
 */
- (void)onMeetingEndedReason:(MobileRTCMeetingEndReason)reason;

/*!
 @brief The meeting does not have a host and ends.
 @param minutes The minutes remaining until the meeting ends.
 */
- (void)onNoHostMeetingWillTerminate:(NSUInteger)minutes;

/*!
 @brief The user's microphone has encountered an error.
 @param errror The error. See [MobileRTCMicropohoneError]
 */
- (void)onMicrophoneStatusError:(MobileRTCMicrophoneError)error;

/*!
 @brief The user must provide additional information before joining the meeting.
 @param displayName A name to be displayed in the meeting.
 @param password The meeting passcode.
 @param cancel If YES, the attempt to join the meeting is cancelled.
 */
- (void)onJoinMeetingInfo:(MobileRTCJoinMeetingInfo)info
               completion:(void (^_Nonnull)(NSString * _Nonnull displayName, NSString * _Nonnull password, BOOL cancel))completion;

/*!
 @brief The user must provide proxy information.
 @param host Proxy host.
 @param port Proxy port.
 @param completion The SDK asks the user to input proxy information once it detects that the information changed.
 */
- (void)onProxyAuth:(NSString*_Nonnull)host
               port:(NSUInteger)port
         completion:(void (^_Nonnull)(NSString * _Nonnull host, NSUInteger port, NSString *_Nonnull username, NSString * _Nonnull password, BOOL cancel))completion;

/*!
 @brief The user needs to end another ongoing meeting.
 @param completion Ask the user to end another ongoing meeting.
 */
- (void)onAskToEndOtherMeeting:(void (^_Nonnull)(BOOL cancel))completion;

/*!
 @brief Microphone access permission was denied.
 */
- (void)onMicrophoneNoPrivilege;

/*!
 @brief Camera access permission was denied.
 */
- (void)onCameraNoPrivilege;

/*!
 @brief The free meeting ends in 10 minutes.
 @param host If YES, the user is the original host of the meeting.
 @param freeUpgrade If YES, the meeting can be upgraded and the free meeting limitation is removed.
 @param first If YES, this is the first meeting which can ignore the limitation.
 @param completion The SDK calls the module to upgrade the current meeting if the parameter UPGRADE is YES.
 */
- (void)onFreeMeetingReminder:(BOOL)host
               canFreeUpgrade:(BOOL)freeUpgrade
                  isFirstGift:(BOOL)first
                   completion:(void (^_Nonnull)(BOOL upgrade))completion DEPRECATED_ATTRIBUTE;

/*!
 @brief The result of a free meeting upgrade attempt has been received.
 @param result ZERO(0) means the upgrade was successful, otherwise it failed.
 */
- (void)onUpgradeFreeMeetingResult:(NSUInteger)result;

/*!
 @brief The free meeting needs an upgrade.
 @param type See [FreeMeetingNeedUpgradeType], if the type is [FreeMeetingNeedUpgradeType_BY_GIFTURL], the user can upgrade through the url. If the type is [FreeMeetingNeedUpgradeType_BY_ADMIN], only the user's admin can upgrade the meeting.
 @param giftURL The URL through which the meeting can be upgraded.
 */
- (void)onFreeMeetingNeedToUpgrade:(FreeMeetingNeedUpgradeType)type giftUpgradeURL:(NSString*_Nullable)giftURL;

/*!
 @brief The free meeting was upgraded to a free trial and has started.
 */
- (void)onFreeMeetingUpgradeToGiftFreeTrialStart;

/*!
 @brief The free meeting which was upgraded to a free trial has stopped.
 */
- (void)onFreeMeetingUpgradeToGiftFreeTrialStop;

/*!
 @brief The meeting has been upgraded to a pro (licensed) meeting.
 */
- (void)onFreeMeetingUpgradedToProMeeting;

/*!
 @brief The invite button in the UI has been clicked.
 @param parentVC Parent viewcontroller used to present custom invite UI.
 @param array <MobileRTCMeetingInviteActionItem *>Custom invitation actions to be added.
 @return YES: The developer takes a custom action and the SDK does nothing. NO: The SDK still takes its default action.
 */
- (BOOL)onClickedInviteButton:(UIViewController * _Nonnull)parentVC addInviteActionItem:(NSMutableArray * _Nullable)array;

/*!
 @brief The audio button in the UI has been clicked.
 @param parentVC Parent viewcontroller used to present custom audio UI.
 @return YES: The developer takes a custom action and the SDK does nothing. NO: The SDK still takes its default action.
 */
- (BOOL)onClickedAudioButton:(UIViewController * _Nonnull)parentVC;

/*!
 @brief The participants button has been clicked.
 @param parentVC Parent viewcontroller used to present custom participants UI.
 @return YES: The developer takes a custom action and the SDK does nothing. NO: The SDK still takes its default action.
 */
- (BOOL)onClickedParticipantsButton:(UIViewController * _Nonnull)parentVC;

/*!
 @brief The share button has been clicked.
 @param parentVC Parent viewController used to present the custom share UI.
 @return YES: The developer takes a custom action and the SDK does nothing. NO: The SDK still takes its default action.
 NO if user wants to custom Share Action Item, add items to Share ActionSheet via MobileRTCMeetingShareActionItem. Otherwise YES, the user uses the default UI.
 */
- (BOOL)onClickedShareButton:(UIViewController * _Nonnull)parentVC addShareActionItem:(NSMutableArray * _Nonnull)array;

/*!
 @brief The meeting end button has been clicked.
 @param parentVC Parent viewcontroller used to present custom Participants UI.
 @param endButton The end button.
 @return YES: The developer takes a custom action and the SDK does nothing. NO: The SDK still takes its default action.
 */
- (BOOL)onClickedEndButton:(UIViewController * _Nonnull)parentVC endButton:(UIButton * _Nonnull)endButton;

/*!
 @brief All active shares have stopped.
 */
- (void)onOngoingShareStopped;

/*!
 @brief The dial out button has been clicked.
 @param parentVC Parent viewcontroller used to present outgoing call UI.
 @param me If YES, it is a call out. Otherwise, it is an invite by phone. For more information see https://support.zoom.us/hc/en-us/articles/360060596392-Enabling-or-disabling-call-me-and-invite-by-phone.
 */
- (void)onClickedDialOut:(UIViewController * _Nonnull)parentVC isCallMe:(BOOL)me;

/*!
 @brief The status of an outgoing call has changed.
 @param status The new status.
 */
- (void)onDialOutStatusChanged:(DialOutStatus)status;

/*!
 @brief The H.323 pairing code status has been updated and may require the end user to input their code
 @param state The new paring state. See [MobileRTCH323ParingStatus].
 @param meetingNumber The meetng number.
 */
- (void)onSendPairingCodeStateChanged:(MobileRTCH323ParingStatus)state MeetingNumber:(unsigned long long)meetingNumber;

/*!
 @brief The room device state changed.
 @param state The new state. See [H323CallOutStatus].
 */
- (void)onCallRoomDeviceStateChanged:(H323CallOutStatus)state;

/*!
 @brief An in-meeting chat message has been received.
 @param messageID The message ID.
 */
- (void)onInMeetingChat:(NSString * _Nonnull)messageID;

/*!
 @brief A chat message has been deleted.
 @param msgID The ID of the message that was deleted.
 @param deleteBy Information about who deleted the message. See [MobileRTCChatMessageDeleteType].
 */
- (void)onChatMsgDeleteNotification:(NSString *_Nonnull)msgID deleteBy:(MobileRTCChatMessageDeleteType)deleteBy;

/*!
 @brief The live stream status has changed.
 @param liveStreamStatus The new status. See [MobileRTCLiveStreamStatus].
 */
- (void)onLiveStreamStatusChange:(MobileRTCLiveStreamStatus)liveStreamStatus;

/*!
 @brief The current user’s raw live streaming privilege has changed.
 @param hasPrivilege Whether the user has privilege.
 */
- (void)onRawLiveStreamPrivilegeChanged:(BOOL)hasPrivilege;

/*!
 @brief The current user's request for raw live streaming privilege has timed out with no response.
 */
- (void)onRawLiveStreamPrivilegeRequestTimeout;

/*!
 @brief Another user’s raw live streaming privilege has changed.
 @param userid The ID of the user whose privilege has changed.
 @param hasPrivilege Whether the user has privilege.
 */
- (void)onUserRawLiveStreamPrivilegeChanged:(NSUInteger)userId hasPrivilege:(bool)hasPrivilege;

/*!
 @brief A user has requested raw live streaming privilege.
 @param handler A pointer to the IRequestRawLiveStreamPrivilegeHandler. For more details, see [MobileRTCRequestRawLiveStreamPrivilegeHandler].
 */
- (void)onRawLiveStreamPrivilegeRequested:(MobileRTCRequestRawLiveStreamPrivilegeHandler*_Nullable)handler;

/*!
 @brief A user has starte or stopped raw live streaming.
 @param liveStreamList A list of users with an active raw live stream.
 */
- (void)onUserRawLiveStreamingStatusChanged:(NSArray<MobileRTCRawLiveStreamInfo *>*_Nullable)liveStreamList;

/*!
 @brief The ZAK used to authorize the SDK has expired.
 */
- (void)onZoomIdentityExpired;

/*!
 @brief The user has clicked the shared screen.
 @param parentVC Parent viewcontroller used to present the view of Share Screen Usage Guide.
 @warning Application presents Share Screen Usage Guide.
 */
- (void)onClickShareScreen:(UIViewController * _Nonnull)parentVC;

/*!
 @brief A closed caption message has been received. If the meeting supports multi-language transcription and the host set manual captioning to true, attendees must set translation language id to -1 to receive closed caption messages.
 @param message The closed caption text.
 @param speakerID The ID of the speaker.
 @param msgTime The time of the close caption.
 */
- (void)onClosedCaptionReceived:(NSString * _Nonnull)message speakerId:(NSUInteger)speakerID msgTime:(NSDate *_Nullable)msgTime;

/*!
 @brief The waiting room status has changed.
 */
- (void)onWaitingRoomStatusChange:(BOOL)needWaiting;

/*!
 @brief The chat privilege of attendees has changed.
 @param currentPrivilege The new chat privilege. See [MobileRTCMeetingChatPriviledgeType].
 @warning This callback is only invoked for meetings and not webinars.
*/
- (void)onSinkAttendeeChatPriviledgeChanged:(MobileRTCMeetingChatPriviledgeType)currentPrivilege;

/*!
 @brief The chat privilege of panelists has changed.
 @param privilege The new chat privilege. See [MobileRTCPanelistChatPrivilegeType].
 @warning This callback is only invoked for webinars and not meetings.
*/
- (void)onSinkPanelistChatPrivilegeChanged:(MobileRTCPanelistChatPrivilegeType)privilege;

/*!
 @brief The subscription to a user's video has failed.
 @param errorCode The error code. See {@MobileRTCSubscribeFailReason}.
 @param size The subscription's size.
 @param userId The ID of the user whose subscription failed.
 @warning This is only invoked when custom UI mode is enabled.
*/
- (void)onSubscribeUserFail:(MobileRTCSubscribeFailReason)errorCode size:(NSInteger)size userId:(NSUInteger)userId;

/*!
@brief Callback when host received the local recording request from participant.
@param handler the host admit or decline the request through this handler.
*/
- (void)onRequestLocalRecordingPrivilegeReceived:(MobileRTCRequestLocalRecordingPrivilegeHandler * _Nullable)handler;
@end

#pragma mark - MobileRTCAudioServiceDelegate
/*!
 @protocol MobileRTCAudioServiceDelegate
 @brief Callbacks related to updates to in-meeting audio functionality for the current user's device and audio status of other users.
 */
@protocol MobileRTCAudioServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief @brief A user's audio status has changed. To get their updated status, check [MobileRTCMeetingUserInfo.audioStatus] for the associated user.
 @param UserID The ID of user whose audio status has changed.
 */
- (void)onSinkMeetingAudioStatusChange:(NSUInteger)userID;

/*!
 @brief The audio type of the current user has changed.
 */
- (void)onSinkMeetingMyAudioTypeChange;

/*!
 @brief A user's audio type has changed. To get their updated type, check {@link MobileRTCMeetingUserInfo.audioStatus} for the associated user.
 @param UserID The ID of user whose audio type changes.
 */
- (void)onSinkMeetingAudioTypeChange:(NSUInteger)userID;

/*!
 @brief A user's audio status has changed.
 @param UserID The ID of the user whose audio status has changed.
 @param audioStatus The new audio status of the user.
*/
- (void)onSinkMeetingAudioStatusChange:(NSUInteger)userID audioStatus:(MobileRTC_AudioStatus)audioStatus;

/*!
 @brief The current user's audio output selection has changed.
 */
- (void)onAudioOutputChange;

/*!
 @brief The current user's audio state has changed.
 */
- (void)onMyAudioStateChange;

/*!
 @brief The host has requested the current user to unmute their microphone.
 */
- (void)onSinkMeetingAudioRequestUnmuteByHost;
@end

#pragma mark - MobileRTCVideoServiceDelegate
/*!
 @protocol MobileRTCVideoServiceDelegate
 @brief Callbacks related to updates to in-meeting video functionality for the current user's device and video status of other users.
 */
@protocol MobileRTCVideoServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief The user being displayed in the active video view has changed.
 @param userID The ID of user whose video is being displayed.
 */
- (void)onSinkMeetingActiveVideo:(NSUInteger)userID;


/*!
 @brief A participant's video status has changed. To get their updated status, check {@link MobileRTCMeetingUserInfo.videoStatus} for the associated user.
 @param userID The ID of the user whose video status has changed.
 */
- (void)onSinkMeetingVideoStatusChange:(NSUInteger)userID;

/*!
 @brief The current user's video status has changed.
 */
- (void)onMyVideoStateChange;

/*!
 @brief A participant's video status has changed.
 @param userID The ID of the user whose video status has changed.
 @param videoStatus The new video status of the user.
 */
- (void)onSinkMeetingVideoStatusChange:(NSUInteger)userID videoStatus:(MobileRTC_VideoStatus)videoStatus;

/*!
 @brief The video status of a spotlit user has changed.
 @param on Whether the user's video was turned on.
 */
- (void)onSpotlightVideoChange:(BOOL)on;

/*!
 @brief The list of spotlit users has changed.
 @param spotlightedUserList The users who are currently spotlit.
 */
- (void)onSpotlightVideoUserChange:(NSArray <NSNumber *>* _Nonnull)spotlightedUserList;

/*!
 @brief The SDK has stopped the current user's video preview.
 @warning When this is invoked, any instances of {@link MobileRTCPreviewVideoView} no longer render video and should be removed.
 */
- (void)onSinkMeetingPreviewStopped;

/*!
 @brief The active video user has changed.
 @param userID The ID of the newly displayed user.
 */
- (void)onSinkMeetingActiveVideoForDeck:(NSUInteger)userID;

/*!
 @brief The video quality of a user has changed.
 @param qality The user's new video quality. See {@link MobileRTCVideoQuality}.
 @param userID The ID of the user whose video quality has changed.
 */
- (void)onSinkMeetingVideoQualityChanged:(MobileRTCVideoQuality)qality userID:(NSUInteger)userID;

/*!
 @brief The host has requested the current user to unmute their video.
 */
- (void)onSinkMeetingVideoRequestUnmuteByHost:(void (^_Nonnull)(BOOL Accept))completion;

/*!
 @brief The meeting UI has been minimized or returned to fullscreen.
 @param state The new state of the meeting UI.
 @warning This callback is only compatible with the default meeting UI. It is invoked if you are using a custom meeting UI
 */
- (void)onSinkMeetingShowMinimizeMeetingOrBackZoomUI:(MobileRTCMinimizeMeetingState)state;

/*!
 @brief The order of users' videos in gallery view has been changed by the host.
 @param orderArr The updated order of user videos.
 @warning This callback is only invoked if the host has enabled the "Follow Host's Video Order" setting.
 */
- (void)onHostVideoOrderUpdated:(NSArray <NSNumber *>* _Nullable)orderArr;

/*!
 @brief The order of users' videos in gallery view has been changed locally.
 @param localOrderArr The updated order of user videos.
 */
- (void)onLocalVideoOrderUpdated:(NSArray <NSNumber *>* _Nullable)localOrderArr;

/*!
 @brief The host has enabled/disabled the "Follow Host's Video Order" setting.
 @param follow If yes, the host has enabled the setting. Otherwise, it was disabled.
 */
- (void)onFollowHostVideoOrderChanged:(BOOL)follow;

@end


#pragma mark - MobileRTCUserServiceDelegate
/*!
 @protocol MobileRTCUserServiceDelegate
 @brief The attendee's status changes.
 */
@protocol MobileRTCUserServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief The current user's hand state changes.
 */
- (void)onMyHandStateChange;

/*!
 @brief The user state is updated in the meeting.
 */
- (void)onInMeetingUserUpdated;

/*!
 @brief A user joins the meeting.
 @param userID The ID of the user who joins the meeting.
 */
- (void)onSinkMeetingUserJoin:(NSUInteger)userID;

/*!
 @brief A user leaves the meeting.
 @param userID The ID of the user who leaves the meeting.
 */
- (void)onSinkMeetingUserLeft:(NSUInteger)userID;

/*!
 @brief A user raises their hand.
 @param userID The ID of the user who raises their hand.
 */
- (void)onSinkMeetingUserRaiseHand:(NSUInteger)userID;

/*!
 @brief A user lowers their hand.
 @param userID The ID of the user who lowers their hand.
 */
- (void)onSinkMeetingUserLowerHand:(NSUInteger)userID;

/*!
 @brief A host or cohost lowers all hands.
 */
- (void)onSinkLowerAllHands;

/*!
 @brief A user changes their screen name.
 @param userID Specify the user ID whose screen name changes.
 @param userName The new screen name displayed.
 */
- (void)onSinkUserNameChanged:(NSUInteger)userID userName:(NSString *_Nonnull)userName DEPRECATED_ATTRIBUTE;

/*!
 @brief A user changes their screen name.
 @param userNameChangedArr The user IDs whose user name(s) changed.
 @warning The old interface virtual void '-(void)onSinkUserNameChanged:userName:' is marked as deprecated, and uses this new callback. This is because in a webinar, when the host renames an attendee, only the attendee could receive the old callback. The host/cohost/panlist is not able to receive it, which leads to the developer not being able to update the UI.
 */
- (void)onSinkUserNameChanged:(NSArray <NSNumber *>* _Nullable)userNameChangedArr;

/*!
 @brief The meeting host changes.
 @param hostId The new host's user ID.
 */
- (void)onMeetingHostChange:(NSUInteger)hostId;

/*!
 @brief The meeting co-host changes.
 @param userID The new co-host's user ID.
 @param isCoHost Indicates the user (userID) be assigned to co-host or be remove co-host.
 */
- (void)onMeetingCoHostChange:(NSUInteger)userID isCoHost:(BOOL)isCoHost;

/*!
 @brief A user claims the host.
 */
- (void)onClaimHostResult:(MobileRTCClaimHostError)error;
@end

#pragma mark - MobileRTCShareServiceDelegate
/*!
 @protocol MobileRTCShareServiceDelegate
 @brief The meeting sharing status changes.
 */
@protocol MobileRTCShareServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief A meeting starts by sharing.
 */
- (void)onAppShareSplash;

/*!
 @brief The sharing starts.
 @param userID The presenter's user ID.
 @warning userID == 0 means that the user stopped sharing.
 @deprecated replace with {@link onSinkSharingStatus:userID:}
 */
- (void)onSinkMeetingActiveShare:(NSUInteger)userID DEPRECATED_ATTRIBUTE;

/*!
 @brief The sharing content changes.
 @param userID The presenter's user ID.
 @deprecated replace with {@link onSinkSharingStatus:userID:}
 */
- (void)onSinkMeetingShareReceiving:(NSUInteger)userID DEPRECATED_ATTRIBUTE;

/*!
 @brief The share status changes.
 @param status Sharing status.
 @param userID Specify the user ID whose share status changes.
*/
- (void)onSinkSharingStatus:(MobileRTCSharingStatus)status userID:(NSUInteger)userID;

/*!
 @brief The sharing settings change.
 @param shareSettingType The share setting type of current meeting.
 */
- (void)onSinkShareSettingTypeChanged:(MobileRTCShareSettingType)shareSettingType;


/*!
 @brief The presenter resizes the sharing content.
 @param userID New size of the shared content and user ID.
 */
- (void)onSinkShareSizeChange:(NSUInteger)userID;

@end

#pragma mark - MobileRTCInterpretationServiceDelegate
/*!
 @protocol MobileRTCInterpretationServiceDelegate
 @brief Callback event when the Interpretaion status change.
 */
@protocol MobileRTCInterpretationServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional

/*!
 @brief Interpretation starts. Informs the user that interpretation has been started. All users in the meeting get the event.
*/
- (void)onInterpretationStart;

/*!
 @brief Interpretation stops. Informs the user that interpretation has been stopped. All users in the meeting get the event.
*/
- (void)onInterpretationStop;

/*!
 @brief The meeting's interpreter list changes. When one or more interpreters leave or a preset interpreter joins. Only the host gets the event.
*/
- (void)onInterpreterListChanged;

/*!
 @brief Interpreter role changes. When a user's role changed (participant <-> interpreter), all users in meeting get the event.
 @param userID Specify the user ID whose status changed.
 @param isInterpreter Specify if user's role is interpreter or not.
*/
- (void)onInterpreterRoleChanged:(NSUInteger)userID isInterpreter:(BOOL)isInterpreter;

/*!
 @brief interpreter active language changed callback. When a interpreter's active language changes, all users in meeting get the event.
 @param userID Specify the user ID whose active language changed.
 @param activeLanID Specify the interpreter current active language ID.
*/
- (void)onInterpreterActiveLanguageChanged:(NSInteger)userID activeLanguageId:(NSInteger)activeLanID;

/*!
 @brief interpreter languages changed callback. When a interpreter's languages changed, only the interpreter can get the event.
 @param lanID1 Specify the new language ID1.
 @param lanID2 Specify the new language ID2.
*/
- (void)onInterpreterLanguageChanged:(NSInteger)lanID1 andLanguage2:(NSInteger)lanID2;

/*!
 @brief available languages changed callback. When available languages in meeting are changed, all non-interpreter users in a meeting get the event.
 @param availableLanguageList Specify the available languages list.
*/
- (void)onAvailableLanguageListUpdated:(NSArray <MobileRTCInterpretationLanguage *> *_Nullable)availableLanguageList;

/*!
 @brief Indicates a change in the list of available languages that interpreters can hear. When the list of available languages that interpreters can hear in a meeting changes, all interpreters in the meeting get this event.
 @param interpreterAvailableListenLanList The list of available languages that interpreters can hear.
*/
- (void)onInterpreterLanguagesUpdated:(NSArray <MobileRTCInterpretationLanguage *> *_Nullable)availableLanguages;

@end

@protocol MobileRTCSignInterpretationServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Sign interpretation staus change callback. Informs the user that sign interpretation has been started or stopped. All users in meeting can get the event.
 @param status Specify current sign interpretation status.
 */
- (void)onSignInterpretationStatusChange:(MobileRTCSignInterpretationStatus)status;

/*!
 @brief Sign interpreter list changed callback. Informs the host that some interpreter left meeting or a preset interpreter joined meeting, or host add or remove interpreter. Only the host can get the event.
 */
- (void)onSignInterpreterListChanged;

/*!
 @brief Indicate when a user's role changed (participant <-> interpreter). Only that specific user gets the event.
 */
- (void)onSignInterpreterRoleChanged;

/*!
 @brief Indicate when a sign interpreter's languages changed. Only the sign interpreter can get the event.
 */
- (void)onSignInterpreterLanguageChanged;

/*!
 @brief Indicate when available sign languages in a meeting change. All users in the meeting can get the event.
 @param availableSignLanguageList Specify the available sign languages list. For more details, see {@link ZoomSDKSignInterpretationLanguageInfo} object.
 */
- (void)onAvailableSignLanguageListUpdated:(NSArray<MobileRTCSignInterpreterLanguage *> *_Nullable)availableSignLanguageList;

/*!
 @brief Callback event of the requirement to unmute the audio from the host.
 @param handler A pointer to the ZoomSDKSignInterpterToTalkHander. For more details, see {@link ZoomSDKSignInterpterToTalkHander} object.
 */
- (void)onRequestSignInterpreterToTalk;

/*!
 @brief The host blocks the sign interpreter from talking (mutes them).
 */
- (void)onDisallowSignInterpreterToTalk DEPRECATED_MSG_ATTRIBUTE("Use -onTalkPrivilegeChanged:(BOOL)hasPrivilege instead");

/*!
 @brief Callback event for the user talk privilege changed. When the interpreter role changed, host changed, host allow or disallow interpreter talk, this will be triggered, and only the sign interpreter itself can get the event.
 @param hasPrivilege Specify whether the user has talk privilege or not
 */
- (void)onTalkPrivilegeChanged:(BOOL)hasPrivilege;

@end


#pragma mark - MobileRTCWebinarServiceDelegate
/*!
 @protocol MobileRTCWebinarServiceDelegate
 @brief Indicates when the Webinar changes.
 */
@protocol MobileRTCWebinarServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Indicates when Question and Answer (Q&A) connection starts
 */
- (void)onSinkQAConnectStarted;

/*!
 @brief Callback event when Q&A is connected or disconnected.
 @param connected The flag of Q&A is connected ordisconnected.
 */
- (void)onSinkQAConnected:(BOOL)connected;

/*!
 @brief Callback event when the open-ended question changes.
 @param count The count of open-ended questions.
 */
- (void)onSinkQAOpenQuestionChanged:(NSInteger)count;

/*!
 @brief Callback event when adding a new question.
 @param questionID The question ID.
 @param success Successful or not.
 */
- (void)onSinkQAAddQuestion:(NSString *_Nonnull)questionID success:(BOOL)success;

/*!
 @brief Callback event when adding a new answer.
 @param answerID The answer user ID.
 @param success Successful or not.
 */
- (void)onSinkQAAddAnswer:(NSString *_Nonnull)answerID success:(BOOL)success;

/*!
 @brief Callback event when a new question is marked as dismissed.
 @param questionID The question ID.
 */
- (void)onSinkQuestionMarkedAsDismissed:(NSString *_Nonnull)questionID;

/*!
 @brief Callback event when a question is opened.
 @param questionID The question ID.
 */
- (void)onSinkReopenQuestion:(NSString *_Nonnull)questionID;

/*!
 @brief Callback event when a new question is received.
 @param questionID The question ID.
 */
- (void)onSinkReceiveQuestion:(NSString *_Nonnull)questionID;

/*!
 @brief Callback event when a new answer is received.
 @param questionID The question ID.
 */
- (void)onSinkReceiveAnswer:(NSString *_Nonnull)answerID;

/*!
 @brief Callback event when the question is replied to live.
 @param questionID The question ID.
 */
- (void)onSinkUserLivingReply:(NSString *_Nonnull)questionID;

/*!
 @brief Callback event when the question live reply ends.
 @param questionID The question ID.
 */
- (void)onSinkUserEndLiving:(NSString *_Nonnull)questionID;

/*!
 @brief Callback event when the question is upvoted.
 @param questionID The question ID.
 @param order_changed Order changed.
 */
- (void)onSinkVoteupQuestion:(NSString *_Nonnull)questionID orderChanged:(BOOL)orderChanged;

/*!
 @brief Callback event when the question upvote is revoked.
 @param questionID The question ID.
 @param order_changed Order changed.
 */
- (void)onSinkRevokeVoteupQuestion:(NSString *_Nonnull)questionID orderChanged:(BOOL)orderChanged;

/*!
 @brief Callback event when a question is deleted.
 @param questionIDArray The question IDs.
*/
- (void)onSinkDeleteQuestion:(NSArray *_Nonnull)questionIDArray;

/*!
 @brief Callback event when an answer is deleted.
 @param answerIDArray The answer IDs.
*/
- (void)onSinkDeleteAnswer:(NSArray *_Nonnull)answerIDArray;

/*!
 @brief Callback event of the permission change to allow users to ask questions anonymously.
 @param beAllowed YES means that user can ask question anonymously. Otherwise, they cannot.
 */
- (void)onSinkQAAllowAskQuestionAnonymouslyNotification:(BOOL)beAllowed;

/*!
 @brief Callback event of the permission change that allows the attendee to view all questions.
 @param beAllowed YES means that user can view all questions. Otherwise, they cannot.
 */
- (void)onSinkQAAllowAttendeeViewAllQuestionNotification:(BOOL)beAllowed;

/*!
 @brief Callback event of the permission change that allows the attendee to submit questions.
 @param beAllowed YES means that the user can submit questions. Otherwise, they cannot.
 */
- (void)onSinkQAAllowAttendeeUpVoteQuestionNotification:(BOOL)beAllowed;

/*!
 @brief Callback event of the permission change that allows the user to answer questions.
 @param beAllowed YES means that user can answer questions. Otherwise, they cannot.
 */
- (void)onSinkQAAllowAttendeeAnswerQuestionNotification:(BOOL)beAllowed;

/*!
 @brief Callback event that a user joins a webinar which requires manual approval.
 @param registerURL The register URL.
 */
- (void)onSinkWebinarNeedRegister:(NSString * _Nonnull)registerURL;

/*!
 @brief Callback event that a user joins a webinar which requires username and email.
 @param completion User needs to provide username and email to join meeting or cancel the join action.
 @warning In ZoomUI mode, user can implement this method to avoid Zoom's UI shown. If not implementing this method, Zoom's UI is shown.
 */
- (void)onSinkJoinWebinarNeedUserNameAndEmailWithCompletion:(BOOL (^_Nonnull)(NSString * _Nonnull username, NSString * _Nonnull email, BOOL cancel))completion;

/*!
 @brief Invoke this function once the number of panelists exceeds the upper limit.
 */
- (void)onSinkPanelistCapacityExceed;

/*!
 @brief Invoke this function once a given number of attendees are promoted successfully from attendee to panelist.
 @param errorCode Promotion successful or error type.
 @warning Only the meeting host or co-host can get the callback.
 */
- (void)onSinkPromptAttendee2PanelistResult:(MobileRTCWebinarPromoteorDepromoteError)errorCode;

/*!
 @brief Invoke this function when panelist is demoted successfully from panelist to attendee.
 @param errorCode Demotion successful or error type.
 @warning Only meeting host/co-host can get the callback.
 */
- (void)onSinkDePromptPanelist2AttendeeResult:(MobileRTCWebinarPromoteorDepromoteError)errorCode;

/*!
 @brief Invoke this function when the chat privilege of attendees changes.
 @param currentPrivilege The chat privilege of the current attendee.
 @warning Only webinar meeting can get the callback.
 */
- (void)onSinkAllowAttendeeChatNotification:(MobileRTCChatAllowAttendeeChat)currentPrivilege;

/*!
 @brief When attendee agrees or declines the promote invitation, the host receives this callback.
 @param agree, If attendee agrees, return true. Otherwise, return false.
 @param userid, The attendee user ID.
 */
- (void)onSinkAttendeePromoteConfirmResult:(BOOL)agree userId:(NSUInteger)userId;

/*!
 @brief Invoke this function when the attendee is allowed to talk.
*/
- (void)onSinkSelfAllowTalkNotification;

/*!
 @brief Invoke this function when the attendee is not allowed to talk.
*/
- (void)onSinkSelfDisallowTalkNotification;
@end

/*!
 @brief Invoke this function when the attendee is not allowed to talk.
*/
@protocol MobileRTCLiveTranscriptionServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Sink the event of live transcription status.
 @param status The live transcription status. For more details, see MobileRTCLiveTranscriptionStatus
*/
- (void)onSinkLiveTranscriptionStatus:(MobileRTCLiveTranscriptionStatus)status;

/*!
 @brief Sink the event of receive the live transcription message.
 @param msg The received live transcription message.
 @param speakerId The speaker ID of the received live transcription message.
 @param type The live transcription operation type. For more details, see MobileRTCLiveTranscriptionOperationType.
*/
- (void)onSinkLiveTranscriptionMsgReceived:(NSString *_Nonnull)msg speakerId:(NSUInteger)speakerId type:(MobileRTCLiveTranscriptionOperationType)type;

/*!
 @brief Translation message error callback.
 @param speakingLanguage: an object of the speak message language.
 @param translationLanguage: an object of the message language you want to translate.
 */
- (void)onLiveTranscriptionMsgError:(MobileRTCLiveTranscriptionLanguage * _Nullable)speakLanguage
                 transcriptLanguage:(MobileRTCLiveTranscriptionLanguage * _Nullable)transcriptLanguage;

/*!
 @brief Sink the event of request for start the live transcription. Only the host can retrieve this callback. You can approve request call start live transcription, or decline as do nothing.
 @param requesterUserId The user ID of the request from. If bAnonymous is TRUE, requesterUserId has no meaning.
 @param bAnonymous TRUE means the request is anonymous.
*/
- (void)onSinkRequestForLiveTranscriptReceived:(NSUInteger)requesterUserId bAnonymous:(BOOL)bAnonymous;

@end

/*!
@brief Invoke this function when using a 3D avatar.
*/
@protocol MobileRTC3DAvatarDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Callback event to notify that all 3D avatar items' thumbnails have been download.
*/
- (void)on3DAvatarItemThumbnailsDownloaded;

/*!
 @brief Callback event to notify that the selected 3D avatar item is downloading.
 @param index The index of the selected 3D avatar item.
*/
- (void)on3DAvatarItemDataDownloading:(int)index;

/*!
 @brief Callback event to notify whether the selected 3D avatar item has been downloaded successfully.
 @param index The index of the selected 3D avatar item.
 @param success Yes indicates the selected 3D avatar item has been downloaded successfully.
*/
- (void)on3DAvatarItemDataDownloaded:(bool)success andIndex:(int)index;
@end
#pragma mark - MobileRTCCustomizedUIMeetingDelegate
/*!
 @protocol MobileRTCCustomizedUIMeetingDelegate
 @brief The class that conform to the MobileRTCCustomizedUIMeetingDelegate protocol can provide
        methods for tracking the In-Meeting Event and determining policy for each event.
 @discussion The MobileRTCCustomizedUIMeetingDelegate protocol is required in the custom meeting UI view.
 */ 
@protocol MobileRTCCustomizedUIMeetingDelegate <NSObject>
@required
/*!
 @brief Notify user to create a custom in-meeting UI. 
 */
- (void)onInitMeetingView;

/*!
 @brief Notify user to destroy the custom in-meeting UI. 
 */
- (void)onDestroyMeetingView;

@end

#pragma mark - MobileRTCVideoRawDataDelegate
@class MobileRTCRenderer;
/*!
 @protocol MobileRTCVideoRawDataDelegate
 @brief This class is used to receive video raw data.
 @discussion The MobileRTCVideoRawDataDelegate protocol is required in the custom meeting UI view.
 */
@protocol MobileRTCVideoRawDataDelegate <NSObject>
@optional

/*!
 @brief This method is used to receive video's NV12 data(CVPixelBufferRef).
 @param pixelBuffer Video's CVPixelBufferRef data.
 @param renderer The MobileRTCRenderer’s object.
 */
- (void)onMobileRTCRender:(MobileRTCRenderer *_Nonnull)renderer
        framePixelBuffer:(CVPixelBufferRef _Nullable )pixelBuffer
                rotation:(MobileRTCVideoRawDataRotation)rotation;

/*!
 @brief This method is used to receive video's YUV420 data.
 @param rawData Video's YUV420 data.
 @param renderer The MobileRTCRenderer’s object.
 */
- (void)onMobileRTCRender:(MobileRTCRenderer *_Nonnull)renderer
            frameRawData:(MobileRTCVideoRawData *_Nonnull)rawData;

/*!
 @brief Callback event when the sender stop/start to sending raw data.
 @param renderer The MobileRTCRenderer’s object.
 @param on Raw data is sending or not.
 */
- (void)onMobileRTCRender:(MobileRTCRenderer *_Nonnull)renderer
          rawDataSending:(BOOL)on;

@end

#pragma mark - MobileRTCAudioRawDataDelegate
/*!
 @protocol MobileRTCAudioRawDataDelegate
 @brief Receive audio raw data.
 @discussion The MobileRTCAudioRawDataDelegate protocol is required in the custom meeting UI view.
 */
@protocol MobileRTCAudioRawDataDelegate <NSObject>
@optional

/*!
 @brief Receive mixed raw audio data.
 @param rawData Raw audio data.
 */
- (void)onMobileRTCMixedAudioRawData:(MobileRTCAudioRawData *_Nonnull)rawData;

/*!
 @brief Receive each road user raw audio data.
 @param rawData Raw audio data.
 */
- (void)onMobileRTCOneWayAudioAudioRawData:(MobileRTCAudioRawData *_Nonnull)rawData userId:(NSUInteger)userId;
@end

#pragma mark - MobileRTCAudioSourceDelegate
/*!
 @protocol MobileRTCAudioSourceDelegate
 @brief Send your own raw audio data.
 @discussion The MobileRTCAudioSourceDelegate protocol is required in the custom meeting UI view.
*/
@protocol MobileRTCAudioSourceDelegate <NSObject>
@optional

/*!
 @brief Virtual audio source to do some initialization.
 @param rawdataSender A pointer of audio sender object.
 */
- (void)onDeviceInitialize:(MobileRTCAudioSender *_Nonnull)rawdataSender;
/*!
 @brief The virtual audio source can send raw data with 'rawdataSender'.
 */
- (void)onStartSendData;
/*!
 @brief The virtual audio source should stop sending raw data.
 */
- (void)onStopSendData;
/*!
 @brief Virtual audio source is uninitialized.
 */
- (void)onDeviceUninitialize;

@end

#pragma mark - MobileRTCPreProcessorDelegate
/*!
 @protocol MobileRTCPreProcessorDelegate
 @brief Preprocess raw data data before rendering.
 @discussion The MobileRTCPreProcessorDelegate protocol is required in the custom meeting UI view.
*/
@protocol MobileRTCPreProcessorDelegate <NSObject>
@optional
/*!
 @brief Preprocess video's YUV420 data before rendering receive.
 @param rawData Video's YUV420 data.
*/
- (void)onPreProcessRawData:(MobileRTCPreProcessRawData *_Nonnull)rawData;

@end

#pragma mark - MobileRTCVideoSourceDelegate
/*!
 @protocol MobileRTCVideoSourceDelegate
 @brief Send your own raw video data.
 @discussion The MobileRTCVideoSourceDelegate protocol is required in the custom meeting UI view.
*/
@protocol MobileRTCVideoSourceDelegate <NSObject>
@optional
/*!
 @brief Send data for initialization.
 @param rawDataSender See MobileRTCVideoSender.
 @param supportCapabilityArray Support capability list.
 @param suggestCapabilityItem Suggest capability.
*/
- (void)onInitialize:(MobileRTCVideoSender *_Nonnull)rawDataSender supportCapabilityArray:(NSArray *_Nonnull)supportCapabilityArray suggestCapabilityItem:(MobileRTCVideoCapabilityItem *_Nonnull)suggestCapabilityItem;

/*!
 @brief Send data for initialization.
 @param rawDataSender See MobileRTCVideoSender.
 @param supportCapabilityArray Support capability list.
 @param suggestCapabilityItem Suggest capability.
*/
- (void)onPropertyChange:(NSArray *_Nonnull)supportCapabilityArray suggestCapabilityItem:(MobileRTCVideoCapabilityItem *_Nonnull)suggestCapabilityItem;

/*!
 @brief Start send data.
*/
- (void)onStartSend;

/*!
 @brief Stop send data.
*/
- (void)onStopSend;

/*!
 @brief Uninitialize send data.
*/
- (void)onUninitialized;

@end

#pragma mark - MobileRTCVideoSourceDelegate
/*!
 @protocol MobileRTCVideoSourceDelegate
 @brief Send your own share raw data.
*/
@protocol MobileRTCShareSourceDelegate <NSObject>
@optional
/*!
 @brief Notify to start send share source.
 @param sender The object of MobileRTCShareSender to send share source.
 */
- (void)onStartSend:(MobileRTCShareSender *_Nonnull)sender;

/*!
 @brief Notify to stop send share source.
 */
- (void)onStopSend;

@end

#pragma mark - MobileRTCAudioRawDataDelegate

@class MobileRTCRealNameCountryInfo;
@class MobileRTCRetrieveSMSHandler;
@class MobileRTCVerifySMSHandler;

/*!
 @protocol MobileRTCSMSServiceDelegate
 @brief Retrieve and verify SMS.
 */
@protocol MobileRTCSMSServiceDelegate <NSObject>
@optional

/*!
 @brief Notify support country list for send SMS, privacy URL, and send SMS handle.
 @param supportCountryList, privacyUrl, retrieveHandle
 */
- (void)onNeedRealNameAuth:(NSArray<MobileRTCRealNameCountryInfo *> * _Nonnull)supportCountryList privacyURL:(NSString * _Nonnull)privacyUrl retrieveHandle:(MobileRTCRetrieveSMSHandler * _Nonnull)handle;

/*!
 @brief Notify the result of send SMS, and verify SMS handle.
 @param result, verifyHandle
 */
- (void)onRetrieveSMSVerificationCodeResultNotification:(MobileRTCSMSRetrieveResult)result verifyHandle:(MobileRTCVerifySMSHandler * _Nonnull)handler;

/*!
 @brief Notify the result verify SMS.
 @param result of verify SMS.
 */
- (void)onVerifySMSVerificationCodeResultNotification:(MobileRTCSMSVerifyResult)result;

@end

#pragma mark - MobileRTCBOServiceDelegate
@protocol MobileRTCBOServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Notify that the creator role is given.
 @param creator the creator role is given.
*/
- (void)onHasCreatorRightsNotification:(MobileRTCBOCreator *_Nonnull)creator;

/*!
 @brief Notify that the admin role is given.
 @param admin The admin role is given.
*/
- (void)onHasAdminRightsNotification:(MobileRTCBOAdmin * _Nonnull)admin;

/*!
 @brief Notify that the assistant role is given.
 @param assistant The assistant role is given.
*/
- (void)onHasAssistantRightsNotification:(MobileRTCBOAssistant * _Nonnull)assistant;

/*!
 @brief Notify that the attendee role is given.
 @param attendee The attendee role is given.
*/
- (void)onHasAttendeeRightsNotification:(MobileRTCBOAttendee * _Nonnull)attendee;

/*!
 @brief Notify that the data helper role is given.
 @param dataHelper The data helper role is given.
*/
- (void)onHasDataHelperRightsNotification:(MobileRTCBOData * _Nonnull)dataHelper;

/*!
 @brief A lost creator role notification.
*/
- (void)onLostCreatorRightsNotification;

/*!
 @brief A lost admin role notification.
*/
- (void)onLostAdminRightsNotification;

/*!
 @brief A lost assistant role notification.
*/
- (void)onLostAssistantRightsNotification;

/*!
 @brief A lost attendee role notification.
*/
- (void)onLostAttendeeRightsNotification;

/*!
 @brief A lost data helper role notification.
*/
- (void)onLostDataHelperRightsNotification;

/*!
 @brief A broadcast message notification.
 @param broadcastMsg The broadcast message received from host.
 @param senderID The senderID.
*/
- (void)onNewBroadcastMessageReceived:(NSString *_Nullable)broadcastMsg senderID:(NSUInteger)senderID;

/*!
 @brief When BOOption.countdownSeconds != MobileRTCBOStopCountDown_Not_CountDown, host stop the breakout room and all users receive the event.
 @param seconds The countdown in seconds.
 @warning Please leave the breakout room when the countdown ends.
*/
- (void)onBOStopCountDown:(NSUInteger)seconds;

/*!
 @brief When you are in a breakout room and the host invites you return to main session, you receive the event.
 @param hostName the host name.
 @param replyHandler the handler to reply for the main session invitation.
*/
- (void)onHostInviteReturnToMainSession:(NSString *_Nullable)hostName replyHandler:(MobileRTCReturnToMainSessionHandler *_Nullable)replyHandler;

/*!
 @brief When host change the breakout room status, all users receive the event.
 @param status The current status of the breakout room.
*/
- (void)onBOStatusChanged:(MobileRTCBOStatus)status;

/*!
 @brief When the host modifies the breakout room, all users receive the event.
 @param newBOName The new brekaout room name.
 @param newBOID The new breakout room ID.
 */
- (void)onBOSwitchRequestReceived:(NSString *_Nullable)newBOName newBOID:(NSString *_Nullable)newBOID;
@end

#pragma mark - MobileRTCReactionServiceDelegate
@protocol MobileRTCReactionServiceDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Notify receipt of the emoji reaction.
 @param userId The user ID of the send emoji reaction.
 @param type The send emoji reaction type.
 @param skinTone The send emoji reaction skintone.
 */
- (void)onEmojiReactionReceived:(NSUInteger)userId reactionType:(MobileRTCEmojiReactionType)type reactionSkinTone:(MobileRTCEmojiReactionSkinTone)skinTone;

/*!
 @brief Emoji reaction callback. This callback notifies the user when an emoji is received in the webinar.
 @param type Specify the received reaction's type.
 */
- (void)onEmojiReactionReceivedInWebinar:(MobileRTCEmojiReactionType)type;

@end


#pragma mark - MobileRTCBOServiceDelegate
@protocol MobileRTCBODataDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief The updated breakout meeting information.
 @param boId The identifier for the breakout meeting.
*/
- (void)onBOInfoUpdated:(NSString *_Nullable)boId;

/*!
 @brief The unassigned user update.
*/
- (void)onUnAssignedUserUpdated;

@end

#pragma mark - MobileRTCBOServiceDelegate
@protocol MobileRTCBOAdminDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Admin receives help request from userID.
 @param strUserID The identifier of the breakout room meeting user.
*/
- (void)onHelpRequestReceived:(NSString *_Nullable)strUserID;

/*!
 @brief Admin receives an error when breakout room start fails.
 @param errType The error type defail of the failure.
*/
- (void)onStartBOError:(MobileRTCBOControllerError)errType;

/*!
 @brief In a timed breakout, after starting a breakout room, you receive the event.
 @param remaining Remaining time.
 @param isTimesUpNotice true: when time is up, auto stop breakout room. false: don't auto stop breakout room.
 */
- (void)onBOEndTimerUpdated:(NSUInteger)remaining isTimesUpNotice:(BOOL)isTimesUpNotice;

@end

#pragma mark - MobileRTCBOServiceDelegate
@protocol MobileRTCBOAttendeeDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Receive the result of sending a help request.
 @param eResult The response result for the help request.
*/
- (void)onHelpRequestHandleResultReceived:(MobileRTCBOHelpReply)eResult;

/*!
 @brief The host joins the current breakout meeting.
*/
- (void)onHostJoinedThisBOMeeting;

/*!
 @brief The host leaves the current breakout meeting.
*/
- (void)onHostLeaveThisBOMeeting;

@end

#pragma mark - MobileRTCBOServiceDelegate
@protocol MobileRTCBOCreatorDelegate <MobileRTCMeetingServiceDelegate>
@optional
/*!
 @brief Creator receives breakout identifier when successfully creating the breakout room.
 @param BOID The identifier of the created breakout.
*/
- (void)onBOCreateSuccess:(NSString *_Nullable)BOID;

@end
