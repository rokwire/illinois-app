//
//  MobileRTCMeetingService+Chat.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2018/6/6.
//  Copyright © 2019 Zoom Video Communications, Inc. All rights reserved.
//

#import <MobileRTC/MobileRTC.h>

typedef enum {
    ///Chat to all participants in the meeting. 
    MobileRTCChatGroup_All                   = 0,
    ///Chat to panelists in the webinar.
    MobileRTCChatGroup_Panelists             = 1,
    ///Chat to waiting room user
    MobileRTCChatGroup_WaitingRoomUsers       = 2,
}MobileRTCChatGroup;

@interface MobileRTCMeetingService (Chat)

/*!
 @brief Query if the chat is disabled in the meeting.
 @return YES means disabled, otherwise not. 
 */
- (BOOL)isChatDisabled;

/*!
 @brief Query if it is able to send private chat in the meeting. 
 @return YES means disabled, otherwise not.
 */
- (BOOL)isPrivateChatDisabled;

/*!
 @brief Set Attendee Chat Priviledge when in-meeting
 @param privilege The chat privilege of the attendee
 @return YES means sucessfull, otherwise not.
 @warning Only meeting host/co-host can run the function.
 @warning only normal meeting(non webinar meeting) can run the function.
 */
- (BOOL)changeAttendeeChatPriviledge:(MobileRTCMeetingChatPriviledgeType)privilege;

/*!
 @brief get Attendee Chat Priviledge when in-meeting
 @return the result of attendee chat priviledge.
 */
- (MobileRTCMeetingChatPriviledgeType)getAttendeeChatPriviledge;

/*!
 @brief Is meeting chat legal notice available.
 @return available or not.
 */
- (BOOL)isMeetingChatLegalNoticeAvailable;

/*!
 @brief Get chat legal notice prompt.
 @return chat legal notice prompt.
 */
- (NSString *_Nullable)getChatLegalNoticesPrompt;

/*!
 @brief Get explained text for chat legal notice.
 @return explained text for chat legal notice.
 */
- (NSString *_Nullable)getChatLegalNoticesExplained;

/*!
 @brief Get in-meeting chat message. 
 @param messageID The ID of the message sent in the meeting.
 @return The instance of in-meeting chat.
 @warning The method is optional.
 */
- (nullable MobileRTCMeetingChat*)meetingChatByID:(nonnull NSString*)messageID;

/*!
 @brief Send chat message to the specified user in the meeting.
 @param userID The ID of user who receives message in the meeting.
 @param content The message to be sent.
 @return The result of sending the message.
 */
- (MobileRTCSendChatError)sendChatToUser:(NSUInteger)userID WithContent:(nonnull NSString*)content;

/*!
 @brief Send message to group in the meeting.
 @param group Group type in the meeting, see MobileRTCChatGroup.
 @param content The message to be sent.
 @return The result of sending the message.
 */
- (MobileRTCSendChatError)sendChatToGroup:(MobileRTCChatGroup)group WithContent:(nonnull NSString*)content;

/*!
 @brief Delete chat message by message id.
 @param msgId the message id.
 @return The result of delete the message.
 */
- (BOOL)deleteChatMessage:(nonnull NSString *)msgId;

/*!
 @brief Get all chat message id.
 @return The all chat message id list. nil means failed.
 */
- (nullable NSArray <NSString *> *)getAllChatMessageID;

/*!
 @brief Determine whether the message can be delete.
 @param msgId the message id.
 @return The result of  the message can be deleted.
 */
- (BOOL)isChatMessageCanBeDeleted:(nonnull NSString *)msgId;

/*!
 @brief Is share meeting chat legal notice available.
 @return available or not.
 @warning need call in meeting.
 */
- (BOOL)isShareMeetingChatLegalNoticeAvailable;

/*!
 @brief Get start share meeting chat legal notice content.
 @return start share chat legal notice content.
 */
- (NSString *_Nullable)getShareMeetingChatStartedLegalNoticeContent;

/*!
 @brief Get stop share meeting chat legal notice content.
 @return stop share chat legal notice content.
 */
- (NSString *_Nullable)getShareMeetingChatStoppedLegalNoticeContent;

@end
