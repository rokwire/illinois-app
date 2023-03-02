//
//  MobileRTCInMeetingDeviceInfo.h
//  MobileRTC
//
//  Created by Zoom on 2022/11/17.
//  Copyright © 2022 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
/*!
 @brief information of meeting device info.
 Here are more detailed structural descriptions..
*/
@interface MobileRTCInMeetingDeviceInfo : NSObject
/*!
 @brief index
 */
@property(nonatomic, assign, readonly) NSInteger index;
/*!
 @brief device name
 */
@property(nonatomic, copy, readonly) NSString * _Nullable deviceName;
/*!
 @brief meeting topic
 */
@property(nonatomic, copy, readonly) NSString * _Nullable meetingTopic;
/*!
 @brief meeting number
 */
@property(nonatomic, assign, readonly) NSUInteger meetingNumber;

@end
