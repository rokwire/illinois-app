//
//  MobileRTCRequestRawLiveStreamPrivilegeHandler.h
//  MobileRTC
//
//  Created by Zoom on 2022/9/21.
//  Copyright © 2022 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Process after the host receives the requirement from the user to give the raw live stream privilege.
 */
@interface MobileRTCRequestRawLiveStreamPrivilegeHandler : NSObject

/*!
 @brief Get the request ID.
 @return If the function succeeds, the return value is the request ID.
 */
- (NSString *)getRequestId;

/*!
 @brief Get the user ID who requested privilege.
 @return If the function succeeds, the return value is the user ID. Otherwise, this returns 0.
 */
- (NSUInteger)getRequesterId;

/*!
 @brief Get the user name who requested privilege.
 @return If the function succeeds, the return value is the user name.
 */
- (NSString *)getRequesterName;

/*!
 @brief Get the broadcast Url.
 @return If the function succeeds, the return value is the broadcast url.
 */
- (NSString *)getBroadcastUrl;

/*!
 @brief Allows the user to start raw live stream and finally self-destroy.
 */
- (BOOL)grantRawLiveStreamPrivilege;

/*!
 @brief Denies the user permission to start raw live stream and finally self-destroy.
 */
- (BOOL)denyRawLiveStreamPrivilege;

@end
