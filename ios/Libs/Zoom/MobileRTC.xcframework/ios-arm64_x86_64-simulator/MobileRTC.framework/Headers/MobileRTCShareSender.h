//
//  MobileRTCShareSender.h
//  MobileRTC
//
//  Created by Zoom on 2022/6/30.
//  Copyright © 2022 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "MobileRTCConstants.h"

@interface MobileRTCShareSender : NSObject

/*!
 @brief Send share raw data in meeting.
 @param frameBuffer The buffer of the data to send.
 @param width The width of the data to send.
 @param height The height of the data to send.
 @param frameLength The length of the data to send.
 */
- (void)sendShareFrameBuffer:(char *)frameBuffer width:(NSUInteger)width height:(NSUInteger)height frameLength:(NSUInteger)dataLength;

@end
