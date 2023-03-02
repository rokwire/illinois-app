//
//  MobileRTCAudioSender.h
//  MobileRTC
//
//  Created by Zoom on 2022/7/25.
//  Copyright © 2022 Zoom Video Communications, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MobileRTCAudioSender : NSObject

/**
 @brief Send audio raw data, channel number must be mono, and sampling bits must be 16.
 @param data The address of audio data.
 @param length The length of audio data (it must be even numbers).
 @param rate Sample rate of audio data(8000/11025/32000/44100/48000/50000/50400/96000/192000/2822400).
 */
- (MobileRTCRawDataError)send:(char*)data dataLength:(unsigned int)length sampleRate:(int)rate;

@end

