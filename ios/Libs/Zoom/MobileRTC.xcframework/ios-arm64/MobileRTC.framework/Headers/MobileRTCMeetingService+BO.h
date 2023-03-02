//
//  MobileRTCMeetingService+BO.h
//  MobileRTC
//
//  Created by Zoom Video Communications on 2020/2/11.
//  Copyright © 2020 Zoom Video Communications, Inc. All rights reserved.
//


#import <MobileRTC/MobileRTC.h>
#import "MobileRTCBORole.h"

/*!
 @brief Creates Breakout Room meetings-related objects and fetches Breakout Room-related status information.
 */
@interface MobileRTCMeetingService (BO)

/*!
@brief Object for creating Breakout Room meetings defined in  [MobileRTCBOCreator].
*/
- (MobileRTCBOCreator * _Nullable)getCreatorHelper;

/*!
@brief Object for administrator management of Breakout Room meetings defined in [MobileRTCBOAdmin].
*/
- (MobileRTCBOAdmin * _Nullable)getAdminHelper;

/*!
@brief Object for help assistant of Breakout Room meetings defined in [MobileRTCBOAssistant].
*/
- (MobileRTCBOAssistant * _Nullable)getAssistantHelper;

/*!
@brief Object for attendee functionality of Breakout Room meetings defined in [MobileRTCBOAttendee].
*/
- (MobileRTCBOAttendee * _Nullable)getAttedeeHelper;

/*!
@brief Object for Breakout Room meeting id information defined in [MobileRTCBOData].
*/
- (MobileRTCBOData * _Nullable)getDataHelper;

/*!
@brief Has Breakout Room meeting began.
*/
- (BOOL)isBOMeetingStarted;

/*!
@brief Is Breakout Room feature enabled in meeting.
*/
- (BOOL)isBOMeetingEnabled;

/*!
@brief Is currently in Breakout Room during meeting.
*/
- (BOOL)isInBOMeeting;

/*!
@brief Get current Breakout status.
@return Enum for Breakout status. [MobileRTCBOStatus]
*/
- (MobileRTCBOStatus)getBOStatus;

@end


