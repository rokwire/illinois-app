//
//  MobileRTCRawLiveStreamInfo.h
//  MobileRTC
//
//  Created by Zoom on 2022/9/21.
//  Copyright © 2022 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

/*!
 @brief Raw live stream information, such as the broadcast name and URL.
 */
@interface MobileRTCRawLiveStreamInfo : NSObject

/*!
 @brief User ID.
 */
@property(nonatomic, assign, readonly) NSUInteger userId;
/*!
 @brief Broadcast URL (hosted by you or the URL to your Zoom App Marketplace page)
 */
@property(nonatomic, copy, readonly) NSString * _Nullable broadcastUrl;

@end

