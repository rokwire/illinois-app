//
//  MobileRTCBORole.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2020/2/11.
//  Copyright © 2020 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    BOUserStatusUnassigned  = 1, //User is in main conference, not assigned to BO
    BOUserStatusNotJoin     = 2, //User is assigned to BO, but not join
    BOUserStatusInBO        = 3, //User is already in BO
} MobileRTCBOUserStatus;


@interface MobileRTCBOUser : NSObject
/*!
@brief get bo meeting user id.
*/
- (NSString * _Nullable)getUserId;

/*!
@brief get bo meeting user name.
*/
- (NSString * _Nullable)getUserName;

/*!
@brief get bo meeting user status.
*/
- (MobileRTCBOUserStatus)getUserStatus;
@end

@interface MobileRTCBOMeeting : NSObject
/*!
@brief get bo meeting id.
*/
- (NSString * _Nullable)getBOMeetingId;

/*!
@brief get bo meeting name.
*/
- (NSString * _Nullable)getBOMeetingName;

/*!
@brief get bo meeting user array.
*/
- (NSArray * _Nullable)getBOMeetingUserList;
@end

/*!
@brief enum for BO stop countdown.
*/
typedef NS_ENUM(NSUInteger, MobileRTCBOStopCountDown) {
    MobileRTCBOStopCountDown_Not_CountDown  = 0,
    MobileRTCBOStopCountDown_Seconds_10,
    MobileRTCBOStopCountDown_Seconds_15,
    MobileRTCBOStopCountDown_Seconds_30,
    MobileRTCBOStopCountDown_Seconds_60,
    MobileRTCBOStopCountDown_Seconds_120,
};

/*!
 @brief BO option.
 */
@interface MobileRTCBOOption : NSObject

/*!
 @brief BO Count Down Second.
 */
@property (nonatomic, assign) MobileRTCBOStopCountDown countdownSeconds;
/*!
 @brief Enable/Disable that participant can choose breakout room.
 */
@property (nonatomic, assign) BOOL isParticipantCanChooseBO;
/*!
 @brief Enable/Disable that participant can return to main session at any time.
 */
@property (nonatomic, assign) BOOL isParticipantCanReturnToMainSessionAtAnyTime;
/*!
 @brief Enable/Disable that auto move all assigned participants to breakout room.
 */
@property (nonatomic, assign) BOOL isAutoMoveAllAssignedParticipantsEnabled;
/*!
 @brief true: it's timer BO false: not timer BO
 */
@property (nonatomic, assign) BOOL isBOTimerEnabled;
/*!
 @brief true: if time is up, will stop BO auto. false: don't auto stop.
 */
@property (nonatomic, assign) BOOL isTimerAutoStopBOEnabled;
/*!
 @brief seconds of BO timer duration
 @warning when timerDuration is 0, it means that the BO duration is 30*60 seconds.
 */
@property (nonatomic, assign) NSInteger timerDuration;

@end

/*!
 *    //////////////////////////// Creator ////////////////////////////
 *    1. Main Functions:
 *        1) create|delete|rename BO
 *        2) assign|remove user to BO
 *       3) set BO option
 *    2. Remarks:
 *       1) These editing can only be done before BO is started
 *
 *    //////////////////////////// Admin ////////////////////////////
 *   1. Main Functions:
 *        1) after BO is started, assign new user to BO,
 *        2) after BO is started, switch user from BO-A to BO-B
 *       3) stop BO
 *        4) start BO
 *
 *    //////////////////////////// Assistant ////////////////////////////
 *    1. Main Functions:
 *        1) join BO with BO id
 *        2) leave BO
 *
 *   //////////////////////////// Attendee ////////////////////////////
 *   1. Main Functions:
 *        1) join BO
 *       2) leave BO
 *       3) request help
 *
 *    //////////////////////////// DataHelper ////////////////////////////
 *    1. Main Functions:
 *        1) get unassigned user list
 *        2) get BO list
 *       3) get BO object
 *
 *
 *    host in master conference     : creator + admin + assistant + dataHelper
 *    host in BO conference         : admin + assistant + dataHelper
 *    CoHost in master conference   : [attendee] or [creator + admin + assistant + dataHelper]
 *    CoHost in BO conference       : [attendee] or [admin + assistant + dataHelper]
 *    attendee in master conference : attendee + [assistant + dataHelper]
 *   attendee in BO conference     : attendee + [assistant + dataHelper]
 *
 *   Import Remarks:
 *   1. attendee in master conference/attendee in BO conference
 *       1) if BOOption.IsParticipantCanChooseBO is true, attendee has objects:  [attendee + assistant + dataHelper]
 *      2) if BOOption.IsParticipantCanChooseBO is false, attendee has object:  [attendee]
 *   2. CoHost in master conference
 *       1) if CoHost is desktop client, and host is desktop client, the CoHost has objects: [creator + admin + assistant + dataHelper]
 *      2) if CoHost is desktop client, and host is mobile client, the CoHost has object: [attendee]
 *      3) if CoHost is mobile client, the CoHost has object: [attendee]
*/

@interface MobileRTCBOCreator : NSObject

/*!
@brief create a bo meeting.
@param boName the BO name.
@return bo meeting id.
*/
- (NSString * _Nullable)createBO:(NSString * _Nonnull)boName;

/*!
@brief create bo meetings in batches.
@param boNameList the BO name list.
@return batch bo create success or not
*/
- (BOOL)createGroupBO:(NSArray<NSString*> * _Nonnull)boNameList;

/*!
@brief update bo meeting name with bo id.
@param boId the BO id.
@param boName the BO name.
@return update success or not.
*/
- (BOOL)updateBO:(NSString * _Nonnull)boId name:(NSString * _Nonnull)boName;

/*!
@brief remove a bo meeting.
@param boId the BO id.
@return remove bo meting success or not.
*/
- (BOOL)removeBO:(NSString * _Nonnull)boId;

/*!
@brief assign a user to a bo meeting.
@param boUserId the BO user id.
@param boId the BO id.
@return assign success or not.
*/
- (BOOL)assignUser:(NSString * _Nonnull)boUserId toBO:(NSString * _Nonnull)boId;

/*!
@brief remove a user from a bo meeting.
@return remove success or not.
*/
- (BOOL)removeUser:(NSString * _Nonnull)boUserId fromBO:(NSString * _Nonnull)boId;

/*!
@brief Set BO option.
@param option, the option that you want to set.
@return if success the return value is true, otherwise false.
*/
- (BOOL)setBOOption:(MobileRTCBOOption *_Nonnull)option;

/*!
@brief Get BO option.
@return the BOOption value.
*/
- (MobileRTCBOOption * _Nullable)getBOOption;
@end

@interface MobileRTCBOAdmin : NSObject
/*!
@brief start bo meeting which assigned.
@return start success or not
*/
- (BOOL)startBO;

/*!
@brief stop bo meeting which assigned.
@return stop success or not
*/
- (BOOL)stopBO;

/*!
@brief assign a bo user to a started bo meeting.
@param boUserId the BO user id.
@param boId the BO id.
@return the result of call the method.
*/
- (BOOL)assignNewUser:(NSString * _Nonnull)boUserId toRunningBO:(NSString * _Nonnull)boId;

/*!
@brief switch a user to a new started bo meeting.
@param boUserId the BO user id.
@param boId the BO id.
@return the result of call the method.
*/
- (BOOL)switchUser:(NSString * _Nonnull)boUserId toRunningBO:(NSString * _Nonnull)boId;

/*!
@brief indicate that the bo can be start or not.
@return the result of call the method.
*/
- (BOOL)canStartBO;

/*!
@brief join bo meeting for designated bo user id.
@param boUserId the BO user id.
@return the result of call the method.
*/
- (BOOL)joinBOByUserRequest:(NSString * _Nonnull)boUserId;

/*!
@brief reply ignore for the help request from bo attendees
@param boUserId the BO user id.
@return the result of call the method.
*/
- (BOOL)ignoreUserHelpRequest:(NSString * _Nonnull)boUserId;

/*!
@brief broadcase message for all attendees in the meeting.
@param strMsg the bo message.
@return the result of call the method.
*/
- (BOOL)broadcastMessage:(NSString * _Nonnull)strMsg;

/*!
@brief Host invite user return to main session, When BO is started and user is in BO.
@param boUserId the bo user id.
@return true indicates success, otherwise fail.
*/
- (BOOL)inviteBOUserReturnToMainSession:(NSString * _Nonnull)boUserId;
@end

@interface MobileRTCBOAssistant : NSObject

/*!
@brief join a bo meeting with bo id..
@param boId the BO id.
@return the result of call the method.
*/
- (BOOL)joinBO:(NSString * _Nonnull)boId;

/*!
@brief leave joined bo meeting.
@return the result of call the method.
*/
- (BOOL)leaveBO;

@end

@interface MobileRTCBOAttendee : NSObject

/*!
@brief join to assined bo meeting.
@return the result of call the method.
*/
- (BOOL)joinBO;

/*!
@brief leave assined bo meeting.
@return the result of call the method.
*/
- (BOOL)leaveBO;

/*!
@brief get bo meeting name.
@return the bo name.
*/
- (NSString * _Nullable)getBOName;

/*!
@brief send help to admin
@return the result of call the method.
*/
- (BOOL)requestForHelp;

/*!
@brief if the host in current bo.
@return the result of call the method.
*/
- (BOOL)isHostInThisBO;

/*!
 @brief Determine if participant can return to main session.
 @return true if can, otherwise false.
*/
- (BOOL)isCanReturnMainSession;

@end

@interface MobileRTCBOData : NSObject

/*!
@brief get un assined user list.
@return the unassigned user list.
*/
- (NSArray * _Nullable)getUnassignedUserList;

/*!
@brief get all bo meeting id list.
@return the BOMeeting id list.
*/
- (NSArray * _Nullable)getBOMeetingIDList;

/*!
@brief get bo user object by bo user id
@param userId the user id.
@return the object of MobileRTCBOUser.
*/
- (MobileRTCBOUser * _Nullable)getBOUserByUserID:(NSString * _Nonnull)userId;

/*!
@brief get bo meeting object by bo meeting id.
@param boId the BO id.
@return the object of MobileRTCBOMeeting.
*/
- (MobileRTCBOMeeting * _Nullable)getBOMeetingByID:(NSString * _Nonnull)boId;

/*!
@brief get bo meeting name of current BO.
@return the current BO name.
*/
- (NSString  * _Nullable)getCurrentBOName;

/*!
@brief whether the boUserId is current user.
@param boUserId the bo user id.
 @return the result of call the method.
*/
- (BOOL)isBOUserMyself:(NSString *_Nonnull)boUserId;

@end

