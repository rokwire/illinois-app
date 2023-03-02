//
//  MobileRTCMeetingService+LiveTranscription.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2021/10/27.
//  Copyright © 2021 Zoom Video Communications, Inc. All rights reserved.
//

#import <MobileRTC/MobileRTC.h>
#import "MobileRTCConstants.h"
#import "MobileRTCLiveTranscriptionLanguage.h"

@interface MobileRTCMeetingService (LiveTranscription)

/*!
 @brief Query if the current meeting is supported closed caption.
 @return YES means that the current meeting is supported close caption.
 */
- (BOOL)isMeetingSupportCC;

/*!
 @brief Query if the user is can be assigned to send closed caption.
 @param userid the user id.
 @return TRUE means that the user can be assigned to send closed caption.
 */
- (BOOL)canBeAssignedToSendCC:(NSUInteger)userId;

/*!
 @brief Assign the user privilege to send closed caption.
 @param userid the user id.
 @return If the function succeeds, the return value is YES. Otherwise failed.
 */
- (BOOL)assignCCPrivilege:(NSUInteger)userId;

/*!
 @brief WithDraw the user privilege to send closed caption.
 @param userid the user id.
 @return If the function succeeds, the return value is YES. Otherwise failed.
 */
- (BOOL)withdrawCCPrivilege:(NSUInteger)userId;

/*!
 @brief Query if the current user can assign the privilege of send closed caption to others.
 @return YES means that the user can assign others privilege to send closed caption.
 */
- (BOOL)canAssignOthersToSendCC;

/*!
 @brief Hosts only API to set meeting language for the entire meeting
 */
- (BOOL)enableMeetingManualCaption:(BOOL)bEnable;
/*!
 @brief Determine whether it is enabled to manual input CC for meeting.
 */
- (BOOL)isMeetingManualCaptionEnabled;

/*!
 @brief Query if this meeting support the live transcription feature.
 @return YES means that the live transcription feature is supported.
 */
- (BOOL)isLiveTranscriptionFeatureEnabled;

/*!
 @brief Query the current live transcription status.
 @return @return the live transcription status.  For more details, see MobileRTCLiveTranscriptionStatus.
 */
- (MobileRTCLiveTranscriptionStatus)getLiveTranscriptionStatus;

/*!
 @brief Query if meeting participants can start live transcription.
 @return YES means that the participant can start live transcription.
 */
- (BOOL)canStartLiveTranscription;

/*!
 @brief Start live transcription. If the meeting enable multi language transcription,all user can start live transcription otherwise only host can start.
 @return If the function succeeds, the return value is YES. Otherwise failed.
 */
- (BOOL)startLiveTranscription;

/*!
 @brief Stop live transcription. If the meeting enable multi language transcription,all user can stop live transcription,otherwise only host can stop.
 @return If the function succeeds, the return value is YES. Otherwise failed.
 */
- (BOOL)stopLiveTranscription;

/*!
 @brief The host enable/disable the request live transcription.
 @param enable YES means that enable the request live transcription; FALSE means that disable the request live transcription.
 @return If the function succeeds, the return value is YES. Otherwise failed.
 */
- (BOOL)enableRequestLiveTranscription:(BOOL)enable;

/*!
 @brief Query if it is enabled to request to start live transcription.
 @return YES means that it is enabled to request to start live transcription.
 */
- (BOOL)isRequestToStartLiveTranscriptionEnabled;

/*!
 @brief Request the host to start live transcription.
 @param requestAnonymous TRUE means that it is anonymous to request the host to start live transcription.
 @return If the function succeeds, the return value is YES. Otherwise failed.
 */
- (BOOL)requestToStartLiveTranscription:(BOOL)requestAnonymous;

/*!
 @brief Determine whether the multi language transcription feature is enabled.
 @return returns YES if multi-language transcription enabled. Otherwise failed.
 */
- (BOOL)isMultiLanguageTranscriptionEnabled;

/**
 @brief Determine whether the translated captions feature is enabled.
 @return YES means enabled, otherwise not.
 */
- (BOOL)isTextLiveTranslationEnabled;

/**
 @brief Enable or disable to receive original and translated content.If enable this feature,you need start live transcription.
 @return If the function succeeds, the return value is MobileRTCSDKError_Success. Otherwise the function fails and returns an error. To get extended error information, see [MobileRTCSDKError] enum.
 */
- (MobileRTCSDKError)enableReceiveSpokenlLanguageContent:(BOOL)enabled;

/**
 @brief  Determine whether receive original and translated is available.
 @return True indicates receive original and translated is available. Otherwise False.
 */

- (BOOL)isReceiveSpokenLanguageContentEnabled;

/*!
 @brief Get the list of all available spoken languages in meeting.
 @return If the function succeeds, the return value is the list of the available spoken languages in meeting. Otherwise failed, the return value is NULL.
 */
- (NSArray<MobileRTCLiveTranscriptionLanguage*>*)getAvailableMeetingSpokenLanguages;

/*!
 @brief set spoken language of the current user.
 @param languageID: the speak language id.
 @return If the function succeeds, the return value is SDKErr_Success. Otherwise failed. To get extended error information, see \link SDKError \endlink enum.
 */
- (BOOL)setMeetingSpokenLanguage:(NSInteger)languageID;

/*!
 @brief Get the spoken language of the current user.
 */
- (MobileRTCLiveTranscriptionLanguage *)getMeetingSpokenLanguage;

/*!
 @brief Get the list of all available translation languages in meeting.
 @return If the function succeeds, the return value is the list of all available translation languages in meeting. Otherwise failed, the return value is NULL.
 */
- (NSArray<MobileRTCLiveTranscriptionLanguage*>*)getAvailableTranslationLanguages;

/*!
 @brief set the translation language of the current user.
 @param languageID: the translation language id. If the language ID is set to -1, live translation will be disabled,then you can reveive closed caption when host set meeting manual caption is true.
 @return If the function succeeds, the return value is SDKErr_Success. Otherwise failed. To get extended error information, see \link SDKError \endlink enum.
 */
- (BOOL)setTranslationLanguage:(NSInteger)languageID;

/*!
@brief Get the translation language of the current user.
 */
- (MobileRTCLiveTranscriptionLanguage *)getTranslationLanguage;

@end

