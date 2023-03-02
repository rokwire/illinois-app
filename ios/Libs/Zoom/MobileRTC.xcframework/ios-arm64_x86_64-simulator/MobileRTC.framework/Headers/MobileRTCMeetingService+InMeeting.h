//
//  MobileRTCMeetingService+InMeeting.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2017/2/27.
//  Copyright © 2019年 Zoom Video Communications, Inc. All rights reserved.
//

#import <MobileRTC/MobileRTC.h>
#import <MobileRTC/MobileRTCMeetingUserInfo.h>
#import <MobileRTC/MobileRTCMeetingChat.h>
#import <MobileRTC/MobileRTCRawLiveStreamInfo.h>

/*!
 @brief Process after the host receives the requirement from the user to give the local recording privilege.
 */
@interface MobileRTCRequestLocalRecordingPrivilegeHandler : NSObject
/*!
 @brief Get the request ID.
 @return If the function succeeds, the return value is the request ID.
 */
- (NSString * _Nullable)getRequestId;
/*!
 @brief Get the user ID who requested privilege.
 @return If the function succeeds, the return value is the user ID. Otherwise, this returns 0.
 */
- (NSInteger)getRequesterId;
/*!
 @brief Get the user name who requested privileges.
 @return If the function succeeds, the return value is the user name.
 */
- (NSString * _Nullable)getRequesterName;
/*!
 @brief Allows the user to start local recording.
 @return the result of it.
 */
- (MobileRTCSDKError)grantLocalRecordingPrivilege;
/*!
 @brief Denies the user permission to start local recording.
 @return the result of it.
 */
- (MobileRTCSDKError)denyLocalRecordingPrivilege;

@end

/*!
 @brief Set to provide interfaces for meeting events
 */
@interface MobileRTCMeetingService (InMeeting)

/*!
 @brief Query if the current user is the host of the meeting.
 @return YES means that the current user is the host of the meeting, otherwise not.
 */
- (BOOL)isMeetingHost;

/*!
 @brief Query if the current user is the co-host of the meeting.
 @return YES means that the current user is the co-host of the meeting, otherwise not.
 */
- (BOOL)isMeetingCoHost;

/*!
 @brief Query if the current user is the webinar attendee of the meeting.
 @return YES means that the current user is the webinar attendee of the meeting, otherwise not.
 @warning only for webinar meeting.
 */
- (BOOL)isWebinarAttendee;

/*!
 @brief Query if the current user is the webinar panelist of the meeting.
 @return YES means that the current user is the webinar panelist of the meeting, otherwise not.
 @warning only for webinar meeting.
 */
- (BOOL)isWebinarPanelist;

/*!
 @brief Notify if the meeting is locked by host. Once the meeting is locked, other users out of the meeting can no longer join it.
 @return YES means that the meeting is locked by host, otherwise not.
 */
- (BOOL)isMeetingLocked;

/*!
 @brief Notify if the share is locked by host. Once the meeting is locked by the host/co-host, other user can not share except the host/co-host.
 @return YES means that the screen share is locked by host, otherwise not.
 */
- (BOOL)isShareLocked;

#pragma mark CMR Related
/*!
 @brief Notify if the cloud recording is enabled.
 @return YES means enabled, otherwise not.
 */
- (BOOL)isCMREnabled;

/*!
 @brief Notify if the cloud recording is in progress.
 @return YES means the cloud recording is in progress, otherwise not.
 */
- (BOOL)isCMRInProgress;

/*!
 @brief Notify if the cloud recording is paused.
 @return YES means that the cloud recording is paused, otherwise not.
 */
- (BOOL)isCMRPaused;

/*!
 @brief Set to pause/resume cloud recording in the meeting.
 @return YES means that the method is called successfully, otherwise not.
 */
- (BOOL)resumePauseCMR;

/*!
 @brief Set to turn on/off the cloud recording in the meeting.
 @param on YES means to turn on cloud recording, otherwise not.
 */
- (void)turnOnCMR:(BOOL)on;

/*!
 @brief Get current cloud recording.
 @return return If the function succeeds, the return value is recording status.
 */
- (MobileRTCRecordingStatus)getCloudRecordingStatus;

#pragma mark Meeting Info Related
/*!
 @brief Query if the meeting is failover.
 @return YES means failover, otherwise not.
 @warning The method is optional.
 */
- (BOOL)isFailoverMeeting;

/**
 * @brief Get the type of current meeting.
 * @return If the function succeeds, it will return the type of meeting, otherwise failed.
 */
- (MobileRTCMeetingType)getMeetingType;

/*!
 @brief Query if the meeting is Webinar.
 @return YES means Webinar, otherwise not.
 @warning It will return NO as MobileRTCMeetingState is not equal to MobileRTCMeetingState_InMeeting.
 */
- (BOOL)isWebinarMeeting;

/*!
 @brief Set to lock the meeting.
 @return YES means that the method is called successfully, otherwise not.
 @warning Only meeting host/co-host can call the function.
 */
- (BOOL)lockMeeting:(BOOL)lock;

/*!
 @brief Set to lock the share.
 @return YES means that the method is called successfully, otherwise not.
 @warning Only meeting host/co-host can call the function.
 */
- (BOOL)lockShare:(BOOL)lock;

/*!
 @brief Check in-meeting network status.
 @param type Meeting component types, now we can only query three components network status: MobileRTCComponentType_AUDIO, MobileRTCComponentType_VIDEO and MobileRTCComponentType_AS
 @param sending, if YES means that query sending data; if NO means that query receiving data
 @return the level of network quality.
 @warning The method is optional, you can query the network quality of audio, video and sharing.
 */
- (MobileRTCNetworkQuality)queryNetworkQuality:(MobileRTCComponentType)type withDataFlow:(BOOL)sending;

/*!
 @brief Set to present Zoom original Meeting Chat ViewController.
 @param parentVC which use to present ViewController.
 @param userId userId of the user you would like to chat.
 @return YES means that the method is called successfully, otherwise not.
 @warning If userId = 0 or nil, it will send to everyone.
 */
- (BOOL)presentMeetingChatViewController:(nonnull UIViewController*)parentVC userId:(NSInteger)userId;

/*!
 @brief Set to present Zoom original Participants ViewController.
 @param parentVC which use to present ViewController
 @return YES means that the method is called successfully, otherwise not.
 */
- (BOOL)presentParticipantsViewController:(nonnull UIViewController*)parentVC;

/*!
 @brief Configure DSCP values for audio and video.
 @param audioValue Audio values in the meeting.
 @param videoValue Video values in the meeting
 @return YES means that the method is called successfully, otherwise not.
 @warning The function should be invoked before meeting starts.
 */
- (BOOL)configDSCPWithAudioValue:(NSUInteger)audioValue VideoValue:(NSUInteger)videoValue;

#pragma mark Live Stream
/*!
 @brief Set to start Live Stream.
 @param streamingURL The live stream URL by which you can live the meeting. 
 @param key Stream key offered by the third platform on which you want to live stream your meeting. 
 @param broadcastURL The URL of live stream page.
 @return YES means that the method is called successfully, otherwise not.
 @warning Only meeting host can start live Stream successfully.
 */
- (BOOL)startLiveStreamWithStreamingURL:(nonnull NSString*)streamingURL StreamingKey:(nonnull NSString*)key BroadcastURL:(nonnull NSString*)broadcastURL;

/*!
 @brief Get live stream server URL.
 @return The dictionary of live stream URL if the function succeeds.
 @warning The function is available only for host.
 For Facebook Live Stream Service, "facebook" as the key in Dictionary.
 For Workplace by Facebook Live Stream Service, "fb_workplace" as the key in Dictionary.
 For YouTube Live Stream Service, "youtube" as the key in Dictionary.
 For Custom Live Stream Service, "custom" as the key in Dictionary.
 */
- (nullable NSDictionary*)getLiveStreamURL;

/*!
 @brief Set to stop live streaming.
 @return YES means stopping live streaming successfully, otherwise not.
 @warning The function is available only for host. 
 */
- (BOOL)stopLiveStream;

/*
 @brief Query Whether the meeting supports raw live streams.
 @return YES if supported, NO if not supported.
 */
- (BOOL)isRawLiveStreamSupported;

/*
 @brief Whether the current user is able to start raw live streaming.
 @return If the current user is able to start raw live streaming, the return value is MobileRTCSDKError_Success.
 Otherwise it fails. To get extended error information, see [MobileRTCSDKError] enum.
 */
- (MobileRTCSDKError)canStartRawLiveStream;

/*
 @brief Send a request to enable the SDK to start a raw live stream.
 @return If the function succeeds, the return value is MobileRTCSDKError_Success and the SDK will send the request.
 Otherwise it fail and the request will not be sent. To get extended error information, see [MobileRTCSDKError] enum.
 */
- (MobileRTCSDKError)requestRawLiveStream:(nonnull NSString *)broadcastURL;

/*!
 @brief Start a rawData live stream.
 @param broadcastURL Everyone who uses this link can watch the live broadcast.
 @return If the function succeeds, it will return the MobileRTCSDKError_Success, otherwise failed.
 */
- (MobileRTCSDKError)startRawLiveStream:(nonnull NSString *)broadcastURL;

/*!
 @brief Stop a rawData live stream.
 @return If the function succeeds, it will return the MobileRTCSDKError_Success, otherwise failed.
 */
- (MobileRTCSDKError)stopRawLiveStream;

/*!
 @brief Remove the raw live stream privilege.
 @param userId Specify the ID of the user whose privilege will be removed.
 @return If the function succeeds, the return value is SDKErr_Success. Otherwise it fails. To get extended error information, see [MobileRTCSDKError] enum.
 */
- (MobileRTCSDKError)removeRawLiveStreamPrivilege:(NSUInteger)userId;

/*
 @brief Get a list of current active raw live streams.
 @return If the function succeeds, the return value is a pointer to the NSArray object.
 */
- (NSArray<MobileRTCRawLiveStreamInfo *> * _Nullable)getRawLiveStreamingInfoList;

/*
 @brief Get the list of users’ IDs who have raw live stream privileges.
 @return If the function succeeds, the return value is a pointer to the NSArray object.
 */
- (NSArray <NSNumber *> * _Nullable)getRawLiveStreamPrivilegeUserList;


#pragma mark Display/Hide Meeting UI
/*!
 @brief Set to show UI of meeting.
 @param completion User can do other operations once the meeting UI comes out.
 @return YES means that the method is called successfully, otherwise not.
 @warning The method does not work if you have set mobileRTCRootController via [MobileRTC setMobileRTCRootController]
 */
- (BOOL)showMobileRTCMeeting:(void (^_Nonnull)(void))completion;

/*!
 @brief Set to hide the UI of meeting.
 @param completion User can do other operations once the meeting UI hide.
 @return YES means that the method is called successfully, otherwise not.
 @warning The method does not work if you have set mobileRTCRootController via [MobileRTC setMobileRTCRootController]
 */
- (BOOL)hideMobileRTCMeeting:(void (^_Nonnull)(void))completion;

/*!
 @brief If you add a full-screen view to our zoom meeting UI, you can display the control bar by this method when the control bar is hidden
 @warning The zoom meeting UI is only valid, the customized UI is invalid.
 */
- (void)showMeetingControlBar;

/*!
 @brief Switch to active scene.The sequence of video frames is { drive scene(only iPhone), active scene, gallery scene(if has)}
 @warning The zoom meeting UI is only valid, the customized UI is invalid.
 @warning Both the iPad and the iPhone can use this method
 */
- (void)switchToActiveSpeaker;

/*!
 @brief Switch to gallery scene.The sequence of video frames is { drive scene(only iPhone), active scene, gallery scene(if has)}
 @warning The zoom meeting UI is only valid, the customized UI is invalid.
 @warning Both the iPad and the iPhone can use this method
 */
- (void)switchToVideoWall;

/*!
 @brief Switch to drive scene.The sequence of video frames is { drive scene(only iPhone), active scene, gallery scene(if has)}
 @warning The zoom meeting UI is only valid, the customized UI is invalid.
 @warning Only iPhone can use this method
 */
- (void)switchToDriveScene;

/*!
 @brief show app signaling pannel in designated position of container view.
 @param containerView the view container to show app signaling pannel.
 @param originXY the origin position of app signaling pannel in container view.
 @return MobileRTCANNError_Success means the operation succeed, otherwise not
 @warning originXY only take effect on iPad device, behavior of iphone always pop up from the bottom with the device width.
 */
- (MobileRTCANNError)showAANPanelInView:(UIView *_Nullable)containerView originPoint:(CGPoint)originXY;

/*!
 @brief hide app signaling pannel.
 @return MobileRTCANNError_Success means the operation succeed, otherwise not
 @warning suggest to hide ANNPannel when device orietation changed or trait collection changed to avoid layout issues
 */
- (MobileRTCANNError)hideAANPanel;


#pragma mark - Q&A Related
/*!
 @brief Query if Q&A is enabled.
 @return YES means that Q&A is enabled, otherwise not.
 */
- (BOOL)isQAEnabled;

/*!
 @brief Set to present Zoom original Q&A ViewController.
 @param parentVC which use to present ViewController
 @return YES means that the method is called successfully, otherwise not.
 */
- (BOOL)presentQAViewController:(nonnull UIViewController*)parentVC;

/*!
 @brief Get current meeting's password
 @return The current meeting's password
 */
- (NSString *_Nullable)getMeetingPassword;

/*!
 @brief call the method to show Minimize meeting when in Zoom UI meeting.
 @warning The method only for Zoom UI.
 */
- (BOOL)showMinimizeMeetingFromZoomUIMeeting;

/*!
 @brief call the methond to back Zoom UI meeting when in minimize meeting.
 @warning The method only for Zoom UI
 */
- (BOOL)backZoomUIMeetingFromMinimizeMeeting;

/*!
@brief Query if the meeting is allow participants to rename themselves.
@warning Only in-meeting can call the function.
*/
- (BOOL)isParticipantsRenameAllowed;

/*!
@brief Set the meeting is allow participants to rename themselves.
@warning Only meeting host/co-host can call the function.
@warning Only in-meeting can call the function.
*/
- (void)allowParticipantsToRename:(BOOL)allow;

/*!
@brief Query if the meeting is allow participants to unmute themselves.
@warning Only meeting host/co-host can call the function.
@warning Only in-meeting can call the function.
*/
- (BOOL)isParticipantsUnmuteSelfAllowed;

/*!
@brief Query if the meeting is allow participants to unmute themselves.
@warning Only meeting host/co-host can call the function.
@warning Only in-meeting can call the function.
*/
- (void)allowParticipantsToUnmuteSelf:(BOOL)allow;

/*!
 @brief Is live transcript legal notice available.
 @return available or not.
 */
- (BOOL)isLiveTranscriptLegalNoticeAvailable;

/*!
 @brief Get live transcript legal noticesPrompt.
 @return live transcript legal noticesPrompt.
 */
- (NSString *_Nullable)getLiveTranscriptLegalNoticesPrompt;

/*!
 @brief Get live transcript legal notices explained.
 @return live transcript legal notices explained.
 */
- (NSString *_Nullable)getLiveTranscriptLegalNoticesExplained;

@end
