//
//  MobileRTCMeetingService.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 8/7/14.
//  Copyright (c) 2019 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MobileRTCConstants.h"
#import "MobileRTCMeetingDelegate.h"

/**
 * @brief Provides settings for starting a meeting, such as enabling screen sharing, microphone, and camera.
 */ 
@interface MobileRTCMeetingStartParam : NSObject

/**
 * @brief Start meeting with screen sharing immediately enabled.
 */
@property (nonatomic, assign, readwrite) BOOL  isAppShare;

/**
 * @brief Start meeting with microphone disabled.
 */
@property (nonatomic, assign, readwrite) BOOL  noAudio;

/**
 * @brief Start meeting with camera disabled.
 */
@property (nonatomic, assign, readwrite) BOOL  noVideo;

/**
 * @brief Developer-specified string to track end user.
 * @note Provided in webhook event, not used internally by SDK.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * customerKey;

/**
 *@brief Special ID for the personal link name in organization URL, like "yourcompany" in yourcompany.zoom.us.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * vanityID;

/**
 * @brief Meeting number, in format like 123456789.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * meetingNumber;

@end

/**
 * @brief Provides settings for a logged-in user to start a meeting.
 */
@interface MobileRTCMeetingStartParam4LoginlUser : MobileRTCMeetingStartParam

@end

/**
 * @brief Provides parameters for a non-logged-in user (an anonymous user) to start a meeting.
 * @warning The ZAK cannot be null.
 */
@interface MobileRTCMeetingStartParam4WithoutLoginUser : MobileRTCMeetingStartParam

/**
 * @brief User type enum defined in {@link MobileRTCUserType}.
 */
@property (nonatomic, assign, readwrite) MobileRTCUserType userType;

/**
 * @brief The user's display name in the meeting.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * userName;

/**
 * @brief The user's Zoom Access Key (ZAK) token.
 * @warning The ZAK cannot be null.
 */
@property (nonnull, nonatomic, retain, readwrite) NSString * zak;

@end

/**
 * @brief Provides settings for joining a meeting, such as start meeting with microphone or camera disabled.
 */
@interface MobileRTCMeetingJoinParam : NSObject

/**
 * @brief Start meeting with microphone disabled.
 */
@property (nonatomic, assign, readwrite) BOOL  noAudio;

/**
 * @brief Start meeting with camera disabled.
 */
@property (nonatomic, assign, readwrite) BOOL  noVideo;

/**
 * @brief Developer-specified string to track end user.
 * @note Provided in webhook event, not used internally by SDK.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * customerKey;
/**
 *  @brief Special ID for the personal link name in the organization URL, like "yourcompany" in yourcompany.zoom.us.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * vanityID;
/**
 * @brief Meeting number, in format like 123456789.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * meetingNumber;
/**
 * @brief User name.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * userName;
/**
 * @brief Password.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * password;
/**
 * @brief WebinarToken.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * webinarToken;

/**
 * @brief The user's Zoom Access Key (ZAK) token.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * zak;

/**
 * @brief Token that provides privileges when a user joins a meeting, for example, local recording permissions, streaming to raw, or archiving to raw.
 */
@property(nullable, nonatomic, retain, readwrite) NSString *appPrivilegeToken;

/**
 * @brief Token to join a meeting.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * join_token;

@end

/**
 * @brief Interface that provides settings for legal notice content for Webinar registration.
 */
@interface MobileRTCWebinarRegistLegalNoticeContent : NSObject

/**
 * @brief Formatted HTML content string.
 * @note Formatting parameters in order are account owner URL, terms URL, and privacy policy URL.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * formattedHtmlContent;

/**
 * @brief Account owner URL in formatted HTML content.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * accountOwnerUrl;

/**
 *@brief Terms URL in formatted HTML content.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * termsUrl;

/**
 * @brief Privacy policy URL in formatted HTML content.
 */
@property (nullable, nonatomic, retain, readwrite) NSString * privacyPolicyUrl;

@end

/**
 * @brief Provides settings for meetings.
 */
@interface MobileRTCMeetingParameter : NSObject

/**
 * @brief Meeting type. {@link MobileRTCMeetingType}
 */
@property (nonatomic, assign) MobileRTCMeetingType meetingType;

/**
 * @brief View only or not. YES indicates to view only.
 */
@property (nonatomic, assign) BOOL isViewOnly;

/**
 * @brief Auto local recording enabled or not. YES indicates to enable auto local recording.
 */
@property (nonatomic, assign) BOOL isAutoRecordingLocal;

/**
 * @brief Auto cloud recording enabled or not. YES indicates to enable auto cloud recording.
 */
@property (nonatomic, assign) BOOL isAutoRecordingCloud;

/**
 * @brief Meeting number.
 */
@property (nonatomic, assign) unsigned long long meetingNumber;

/**
 * @brief Meeting topic.
 */
@property (nonatomic, retain) NSString * _Nullable meetingTopic;

/**
 * @brief Meeting host.
 */
@property (nonatomic, retain) NSString * _Nullable meetingHost;

@end

@protocol MobileRTCMeetingServiceDelegate;

/**
 * @brief Enables the client to start or join a meeting.
 * @warning The meeting service allows only one concurrent operation at a time. Only one API call is in progress at any given time.
 */
@interface MobileRTCMeetingService : NSObject

/**
 * @brief Callback to receive meeting events.
 */
@property (nullable, assign, nonatomic) id<MobileRTCMeetingServiceDelegate> delegate;

/**
 * @brief Callback for custom UI meeting events. Custom UI features enable you to customize the user interface instead of using the default client view.
 */
@property (nullable, assign, nonatomic) id<MobileRTCCustomizedUIMeetingDelegate> customizedUImeetingDelegate;

/**
 * @brief Start a meeting with MobileRTCMeetingStartParam parameter.
 * @note For a non-logged-in user, create an instance via MobileRTCMeetingStartParam4WithoutLoginUser to pass the parameters. For a logged-in user, create an instance via MobileRTCMeetingStartParam4LoginlUser to pass the parameters.
 * @param param Create an instance with settings via MobileRTCMeetingStartParam.
 * @return The state of the meeting: started or failed.
 * @warning A meeting started with wrong parameters will return MobileRTCMeetError_InvalidArguments.
 */
- (MobileRTCMeetError)startMeetingWithStartParam:(nonnull MobileRTCMeetingStartParam*)param;

/**
 * @brief Join a meeting with MobileRTCMeetingJoinParam parameter.
 * @param param Create an instance with settings via MobileRTCMeetingJoinParam.
 * @return The state of the meeting: started or failed.
 * @note If the app is in CallKit mode, set parameter:userName to empty. CallKit lets you integrate your calling services with other call-related apps on the system.
 */
- (MobileRTCMeetError)joinMeetingWithJoinParam:(nonnull MobileRTCMeetingJoinParam*)param;

/**
 * @brief Start or join a Zoom meeting with zoom web URL.
 * @param meetingUrl Zoom web meeting URL.
 * @return The state of the meeting: started or failed.
 */
- (MobileRTCMeetError)handZoomWebUrl:(nonnull NSString*)meetingUrl;

/**
 * @brief Get the current meeting state.
 * @return Current meeting state.  {@link MobileRTCMeetingState}
 */
- (MobileRTCMeetingState)getMeetingState;

/**
 * @brief End or leave the current meeting.
 * @param cmd The command for leaving the current meeting. Only a host can end the meeting.  {@link LeaveMeetingCmd}
 */
- (void)leaveMeetingWithCmd:(LeaveMeetingCmd)cmd;

/**
 * @brief This method will return the view of meeting UI, which enables customers to add their own view in the meeting UI.
 * @return The view of the current meeting. If there is no ongoing meeting, it will return nil.
 * @warning Only valid in non-custom UI (only valid in Zoom meeting UI).
 */
- (UIView * _Nullable)meetingView;

/**
 * @brief Set the customized invitation domain.
 * @param invitationDomain: Specify the customized invitation domain. For example, https://example.com.
 * @return YES means success, otherwise it's not successful.
 * @warning This method can only be called after auth ready and before join or start meeting.
 */
- (BOOL)setCustomizedInvitationDomain:(NSString *_Nonnull)invitationDomain;

/**
 * @brief Get annotation over share legal notices prompt.
 * @return annotation over share legal notices prompt.
 */
- (NSString *_Nullable)getWebinarRegistrationLegalNoticesPrompt;

/**
 * @brief Get annotation over share legal notices explained.
 * @return annotation over share legal notices explained.
 */
- (MobileRTCWebinarRegistLegalNoticeContent *_Nullable)getWebinarRegistrationLegalNoticesExplained;

@end
