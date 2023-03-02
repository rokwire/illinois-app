//
//  MobileRTCMeetingUserInfo.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2017/2/27.
//  Copyright © 2019年 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @class MobileRTCVideoStatus
 @brief The object of video status of the current user in the meeting.
 */
@interface MobileRTCVideoStatus : NSObject
/*!
 @brief Query if the user is sending video.
 */
@property (nonatomic, assign) BOOL  isSending;
/*!
 @brief Query if the user is receiving video.
 */
@property (nonatomic, assign) BOOL  isReceiving;
/*!
 @brief Check if the camera is connected to the current meeting. 
 */
@property (nonatomic, assign) BOOL  isSource;

@end

/*!
 @brief An Enum for Audio Type.
 */
typedef NS_ENUM(NSUInteger, MobileRTCAudioType) {
    ///VoIP
    MobileRTCAudioType_VoIP   = 0,
    ///Telephony
    MobileRTCAudioType_Telephony,
    ///None
    MobileRTCAudioType_None,
};
/*!
 @class MobileRTCVideoStatus
 @brief The object of the audio status of the current user in the meeting. 
 */
@interface MobileRTCAudioStatus : NSObject
/*!
 @brief Query if the audio of the current user is muted.
 */
@property (nonatomic, assign) BOOL  isMuted;
/*!
 @brief Query if the current user is speaking.
 @warning webinar attenddee can not get the property.
 */
@property (nonatomic, assign) BOOL  isTalking;
/*!
 @brief Check the audio type of the current meeting.
 */
@property (nonatomic, assign) MobileRTCAudioType  audioType;

@end

typedef NS_ENUM(NSUInteger, MobileRTCFeedbackType) {
	/*!
	 @brief There is no feedback from user.
	 */
    MobileRTCFeedbackType_None    = 0,
	/*!
	 @brief User rises hand.
	 */
    MobileRTCFeedbackType_Hand,
	/*!
	 @brief YES.
	 */
    MobileRTCFeedbackType_Yes,
	/*!
	 @brief NO.
	 */
    MobileRTCFeedbackType_No,
	/*!
	 @brief faster.
	 */
    MobileRTCFeedbackType_Fast,
	/*!
	 @brief Slow/Slowly.
	 */
    MobileRTCFeedbackType_Slow,
	/*!
	 @brief Good.
	 */
    MobileRTCFeedbackType_Good,
	/*!
	 @brief Bad.
	 */
    MobileRTCFeedbackType_Bad,
	/*!
	 @brief Clap.
	 */
    MobileRTCFeedbackType_Clap,
	/*!
	 @brief Coffee.
	 */
    MobileRTCFeedbackType_Coffee,
	/*!
	 @brief Clock.
	 */
    MobileRTCFeedbackType_Clock,
	/*!
	 @brief Other expression.
	 */
    MobileRTCFeedbackType_Emoji,
};

/*!
 @brief The information of the current user in the meeting.
 */
@interface MobileRTCMeetingUserInfo : NSObject
/*!
 @brief The ID of user.
 */
@property (nonatomic, assign) NSUInteger       userID;
/*!
 @brief Get the user persistent ID matched with the current user information.This ID persists for the duration of the main meeting.Once the main meeting ends, the ID will be discarded.
 */
@property (nonatomic, retain) NSString* _Nullable       persistentId;
/*!
 @brief Determine if the information corresponds to the current user.
 */
@property (nonatomic, assign) BOOL             isMySelf;
/*!
 @brief The value of customerKey.
 */
@property (nonatomic, retain) NSString* _Nullable       customerKey;
/*!
 @brief The screen name of user.
 */
@property (nonatomic, retain) NSString* _Nonnull        userName;
/*!
 @brief The path to store the head portrait.
 */
@property (nonatomic, retain) NSString* _Nonnull       avatarPath;
/*!
 @brief User's video status in the meeting.
 */
@property (nonatomic, retain) MobileRTCVideoStatus* _Nonnull videoStatus;
/*!
 @brief User's audio status in the meeting.
 */
@property (nonatomic, retain) MobileRTCAudioStatus* _Nonnull audioStatus;
/*!
 @brief The user raised his hand.
 */
@property (nonatomic, assign) BOOL             handRaised;
/*!
 @brief User enter the waiting room when joins the meeting.
 */
@property (nonatomic, assign) BOOL             inWaitingRoom;
/*!
 @brief Query if the current user is the co-host.
 */
@property (nonatomic, assign) BOOL             isCohost;
/*!
 @brief Query if the current user is the host.
 */
@property (nonatomic, assign) BOOL             isHost;
/*!
 @brief Query if the current user is h323 user.
 */
@property (nonatomic, assign) BOOL             isH323User;
/*!
 @brief Query if the current user is Telephone user.
 */
@property (nonatomic, assign) BOOL             isPureCallInUser;
/*!
 @brief Query if the user is sharing only the sounds of computer.
 */
@property (nonatomic, assign) BOOL             isSharingPureComputerAudio;
/*!
 @brief The feedback type from the user.
 */
@property (nonatomic, assign) MobileRTCFeedbackType  feedbackType;
/*!
 @brief the type of role of the user specified by the current information.
 */
@property (nonatomic, assign) MobileRTCUserRole  userRole;
/*!
 @brief Determine if user is interpreter.
 */
@property (nonatomic, assign) BOOL             isInterpreter;
/*!
 @brief Get interpreter active language.
 */
@property (nonatomic, retain) NSString* _Nullable   interpreterActiveLanguage;
@end

/*!
 @brief The information of user in the webinar.
 */
@interface MobileRTCMeetingWebinarAttendeeInfo : NSObject
/*!
 @brief The ID of user.
 */
@property (nonatomic, assign) NSUInteger userID;
/*!
 @brief Determine if the information corresponds to the current user.
 */
@property (nonatomic, assign) BOOL             isMySelf;
/*!
 @brief The screen name of user.
 */
@property (nonatomic, retain) NSString * _Nullable userName;
/*!
 @brief the type of role of the user specified by the current information.
 */
@property (nonatomic, assign) MobileRTCUserRole  userRole;
/*!
 @brief The user raised his hand.
 */
@property (nonatomic, assign) BOOL             handRaised;
/*!
 @brief Attendee can talk or not.
 */
@property (nonatomic, assign) BOOL             isAttendeeCanTalk;
/*!
 @brief User's audio status in the webinar meeting.
 */
@property (nonatomic, retain) MobileRTCAudioStatus* _Nonnull audioStatus;

@end
