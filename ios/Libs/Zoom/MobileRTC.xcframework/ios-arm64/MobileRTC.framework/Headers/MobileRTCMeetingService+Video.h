//
//  MobileRTCMeetingService+Video.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2018/6/6.
//  Copyright © 2019 Zoom Video Communications, Inc. All rights reserved.
//

#import <MobileRTC/MobileRTC.h>

@interface MobileRTCMeetingService (Video)

/*!
 @brief Query if the user is sending video.  
 @return YES means sending, otherwise not.
 */
- (BOOL)isSendingMyVideo;

/*!
 @brief Query if user can unmute his video himself.
 @return YES means able, otherwise not.
 */
- (BOOL)canUnmuteMyVideo;

/*!
 @brief Set to mute video of the current user.
 @param mute YES means to mute video of the current user, otherwise not.
 @return The result of operation.
 */
- (MobileRTCSDKError)muteMyVideo:(BOOL)mute;

/*!
 @brief Rotate my video.
 @return the result of it.
 */
- (BOOL)rotateMyVideo:(UIDeviceOrientation)rotation;

/*!
 @brief Query if user's video is spotlighted. Once the user's video is spotlighted, it will show only the specified video in the meeting instead of active user's.  
 @param userId The ID of user in meeting.
 @return YES means spotlighted, otherwise not.
 */
- (BOOL)isUserSpotlighted:(NSUInteger)userId;

/*!
 @brief Set whether to spotlight user's video.
 @param on YES means to spotlight user's video; NO means that spotlight user's video will be canceled.
 @param userId The ID of user whose video will be spotlighted in the meeting.
 @return YES means that the method is called successfully, otherwise not.
 @warning Only meeting host/cohost can run the function, and user spotlighted should not be the host himself.
 */
- (BOOL)spotlightVideo:(BOOL)on withUser:(NSUInteger)userId;

/*!
 @brief Un-spotlight all the user.
 @return Yes means follow, otherwise not.
 @warning Only meeting host/cohost can run the function, and user spotlighted should not be the host himself.
 */
- (BOOL)unSpotlightAllVideos;

/*!
 @brief get spotlight user list.
 @return userId array.
 */
- (NSArray <NSNumber *>* _Nullable)getSpotLightedVideoUserList;

/*!
 @brief Query if the user's video is pinned. 
 @param userId The ID of user whose video will be pinned in the meeting.
 @return YES means that the user's video is pinned, otherwise not.
 @warning The function is only for Zoom UI.
 */
- (BOOL)isUserPinned:(NSUInteger)userId;

/*!
 @brief Set whether to pin user's video or not. 
 @param on YES means to pin user's video, otherwise not. 
 @param userId The ID of user whose video will be pinned.
 @return YES means that the method is called successfully, otherwise not.
 @warning The function is only for Zoom UI.
 */
- (BOOL)pinVideo:(BOOL)on withUser:(NSUInteger)userId;

/*!
 @brief Query if user's video is being sent.
 @param userID The ID of user whose video will be sent in meeting
 @return YES means that the video is being sent, otherwise not.
 */
- (BOOL)isUserVideoSending:(NSUInteger)userID;

/*!
 @brief Set to stop user's video.
 @param userID The ID of other users except the host in the meeting. 
 @return YES means that the method is called successfully, otherwise not.
 @warning Only host can run the function in the meeting.
 */
- (BOOL)stopUserVideo:(NSUInteger)userID;

/*!
 @brief Host can use this function to demand user to start video.
 @param userID The ID of user who needs to turn on video in meeting.
 @return YES means that the method is called successfully, otherwise not.
 @warning Only host can run the function in the meeting.
 */
- (BOOL)askUserStartVideo:(NSUInteger)userID;

/*!
 @brief Get the size of user's video.
 @param userID The ID of user in the meeting
 @return The size of user's video.
 */
- (CGSize)getUserVideoSize:(NSUInteger)userID;

#pragma mark Camera Related
/*!
 @brief Query if user is using back camera.
 @return YES means using Back camera, otherwise not.
 */
- (BOOL)isBackCamera;

/*!
 @brief Set to Switch the camera of the current user in local device.
 @return The result of operation. 
 */
- (MobileRTCCameraError)switchMyCamera;

/*!
 @brief Qurry if the account support follow host video order feature or not.
 @return Yes means support, otherwise not.
 */
- (BOOL)isSupportFollowHostVideoOrder;

/*!
 @brief Qurry if follow host video order or not currently.
 @return Yes means follow, otherwise not.
 */
- (BOOL)isFollowHostVideoOrderOn;

/*!
 @brief get follow host video order array currently.
 @return userId array.
 */
- (NSArray <NSNumber *>* _Nullable)getVideoOrderList;

/*!
 @brief Stop the incoming video.
 @param enable YES indicates to enable to stop incoming video.
 @return If the function succeeds, the return value is MobileRTCSDKError_Success.
 Otherwise the function fails and returns an error. To get extended error information, see [MobileRTCSDKError] enum.
 */
- (MobileRTCSDKError)stopIncomingVideo:(BOOL)enable;

/*!
 @brief Determine if the incoming video is stopped.
 @return YES indicates to the incoming video is stopped.
 */
- (BOOL)isIncomingVideoStoped;

/*!
 @brief Determine if the incoming video is supported.
 @return YES indicates to the incoming video is supported.
 */
- (BOOL)isStopIncomingVideoSupported;

@end
