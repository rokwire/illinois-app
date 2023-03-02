//
//  MobileRTCMeetingService+AppShare.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2017/2/27.
//  Copyright © 2019年 Zoom Video Communications, Inc. All rights reserved.
//

#import <MobileRTC/MobileRTC.h>

/*!
 @brief Starts an App share meeting.
 */
@interface MobileRTCMeetingService (AppShare)

/*!
 @brief Query if the current meeting was started with App Share.
 @return YES means that meeting was started by App Share, otherwise not.
 */
- (BOOL)isDirectAppShareMeeting;


/*!
 @brief Share content with current view.
 @param view - The view shared.
 @warning view, recommend to pass a single UIView object e.g. UIView, UIImageView or WKWebView.
 @warning The UIView passed should not have any child subviews.
 */
- (void)appShareWithView:(nonnull id)view;

/*!
 @brief Set to start App Share.
 @return YES means starting App Share successfully, otherwise not.
 */
- (BOOL)startAppShare;

/*!
 @brief Set to stop App Share.
 */
- (void)stopAppShare;

/*!
 @brief Notify the current user if sharing has started.
 @return YES means that the current user is sharing, otherwise not.
 */
- (BOOL)isStartingShare;

/*!
 @brief Notify the current user if they are currently viewing an App Share.
 @return YES means that user is viewing the share, otherwise not.
 */
- (BOOL)isViewingShare;

/*!
 @brief Notify the current user if annotation is enabled.
 @return YES if enabled, otherwise not.
 */
- (BOOL)isAnnotationOff;

/*!
 @brief Suspend App Sharing.
 @param suspend - YES if sharing should be suspended, otherwise resume sharing.
 @return YES means successful, otherwise not.
 @warning When the customer goes to share content, consider the effects on device performance, and use this method to pause sharing when UI changes, and resume sharing when UI changes stop, see WebViewController.m in sample project.
 */
- (BOOL)suspendSharing:(BOOL)suspend;

/*!
 @brief Is whiteboard legal notice available.
 @return YES if notice is available, otherwise not.
 */
- (BOOL)isWhiteboardLegalNoticeAvailable;

/*!
 @brief Get whiteboard legal notices message.
 @return The whiteboard legal notices message as a string.
 */
- (NSString *_Nullable)getWhiteboardLegalNoticesPrompt;

/*!
 @brief Get whiteboard legal notices detailed description.
 @return Whiteboard legal notices detailed description.
 */
- (NSString *_Nullable)getWhiteboardLegalNoticesExplained;

/*!
 @brief Enable the sending of device audio.
 @param enableAudio - YES if device audio sharing should be enabled, otherwise disable.
 */
- (void)setShareAudio:(BOOL)enableAudio;

/*!
 @brief Get state of device audio sharing.
 @return YES if device is currently audio sharing.
 */
- (BOOL)isSharedAudio;

/*!
 @brief Get state of device screen sharing.
 @return YES if device is currently screen sharing.
 @warning When the onSinkMeetingActiveShare callback return. developer nned to judge that share screen state.
 */
- (BOOL)isDeviceSharing;

@end
